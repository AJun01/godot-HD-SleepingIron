"""
Character-sheet → Godot SpriteFrames pipeline CLI.

Loads a 12-row character sheet, optionally cleans it (Gemini watermark removal,
white-to-alpha), splits the grid, skips fully-transparent blank cells, writes
per-row cleaned frame PNGs and a composed sheet, and emits a Godot 4.7
SpriteFrames .tres. Also renders the blank authoring template and a labeled
placeholder sheet.

Usage:
    python process_character_sheet.py --input sheet.png [options]
    python process_character_sheet.py --make-template --output-dir docs/templates
    python process_character_sheet.py --make-placeholder-sheet --output-dir assets/placeholders
"""

import argparse
import colorsys
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

from godot_format import generate_sprite_frames_tres
from image_utils import load_image, save_image, white_to_alpha
from watermark import remove_gemini_watermark

MAP_PATH = Path(__file__).resolve().parent / "character_sheet_map.json"


def _fail(message: str) -> None:
    raise SystemExit(f"Error: {message}")


def _load_map(map_path: Path) -> dict:
    if not map_path.exists():
        _fail(f"Map file not found: {map_path}")
    with map_path.open("r", encoding="utf-8") as fh:
        data = json.load(fh)
    rows = data.get("rows")
    if not isinstance(rows, list) or len(rows) != 12:
        count = len(rows) if isinstance(rows, list) else "none"
        _fail(f"Map must define exactly 12 rows, got {count}: {map_path}")
    return data


def _resolve_dir(value: str | None, project_root: Path, default: Path) -> Path:
    if value is None:
        return default
    path = Path(value)
    if not path.is_absolute():
        path = project_root / path
    return path.resolve()


def _validate_grid(img: Image.Image, cell_w: int, cell_h: int, columns: int, rows: int) -> None:
    expected_w = columns * cell_w
    expected_h = rows * cell_h
    if img.width != expected_w or img.height != expected_h:
        _fail(
            f"Sheet size mismatch: expected {expected_w}x{expected_h} "
            f"({columns} cols x {rows} rows of {cell_w}x{cell_h}), got {img.width}x{img.height}"
        )


def _is_blank(cell: Image.Image) -> bool:
    """True when the cell is fully transparent (alpha channel all zero)."""
    alpha = np.asarray(cell)[:, :, 3]
    return not alpha.any()


def _res_path(path: Path, project_root: Path) -> str:
    try:
        rel = path.relative_to(project_root)
    except ValueError:
        _fail(
            f"Output sheet {path} is outside project root {project_root}; cannot compute "
            "res:// path. Pass --project-root or an --output-dir under the project root."
        )
    return rel.as_posix()


def _load_font(size: int):
    try:
        return ImageFont.load_default(size=size)
    except TypeError:
        return ImageFont.load_default()


def _draw_label(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], text: str, font, fill) -> None:
    x0, y0, x1, y1 = box
    left, top, right, bottom = draw.textbbox((0, 0), text, font=font)
    tw = right - left
    th = bottom - top
    draw.text((x0 + ((x1 - x0) - tw) // 2 - left, y0 + ((y1 - y0) - th) // 2 - top), text, fill=fill, font=font)


def _row_color(index: int, total: int) -> tuple[int, int, int, int]:
    hue = index / total
    r, g, b = colorsys.hsv_to_rgb(hue, 0.55, 0.95)
    return (int(r * 255), int(g * 255), int(b * 255), 255)


def _render_grid(map_data: dict, mode: str) -> Image.Image:
    cell_w = int(map_data["cell_width"])
    cell_h = int(map_data["cell_height"])
    columns = int(map_data["columns"])
    rows = map_data["rows"]

    sheet = Image.new("RGBA", (columns * cell_w, len(rows) * cell_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)
    font = _load_font(20)
    small = _load_font(14)

    for row_idx, row_def in enumerate(rows):
        name = row_def["name"]
        loop = bool(row_def.get("loop", False))
        frames = int(row_def.get("frames", columns))
        color = _row_color(row_idx, len(rows))

        if mode == "placeholder":
            # Fill only the authored `frames` cells; the rest stay blank so
            # blank-skip derives the same counts from the placeholder sheet.
            for col in range(min(frames, columns)):
                x, y = col * cell_w, row_idx * cell_h
                draw.rectangle((x, y, x + cell_w - 1, y + cell_h - 1), fill=color)
                _draw_label(draw, (x, y, x + cell_w, y + cell_h), f"{name}_{col}", font, (0, 0, 0, 255))
        else:
            for col in range(columns):
                x, y = col * cell_w, row_idx * cell_h
                draw.rectangle((x, y, x + cell_w - 1, y + cell_h - 1), outline=(120, 120, 120, 90))
            label = f"{name} ({frames}f, {'loop' if loop else 'once'})"
            _draw_label(draw, (0, row_idx * cell_h, cell_w, row_idx * cell_h + cell_h), label, small, (100, 100, 100, 255))

    if mode == "template":
        draw.rectangle((0, 0, columns * cell_w - 1, len(rows) * cell_h - 1), outline=(120, 120, 120, 90))

    return sheet


def _print_summary(summary: list[tuple[str, int, int, bool]], speed: float, sheet_path: Path, tres_path: Path, frames_dir: Path) -> None:
    print("Character sheet processed.")
    print(f"  speed: {speed}")
    print(f"  composed sheet: {sheet_path}")
    print(f"  frames: {frames_dir}")
    print(f"  .tres: {tres_path}")
    print()
    print(f"{'animation':<12} {'frames (map)':>12} {'actual':>6} {'loop':>5}")
    for name, mapped, actual, loop in summary:
        print(f"{name:<12} {mapped:>12} {actual:>6} {'yes' if loop else 'no':>5}")


def _process_sheet(args: argparse.Namespace, project_root: Path, map_data: dict) -> int:
    cell_w = int(map_data["cell_width"])
    cell_h = int(map_data["cell_height"])
    columns = int(map_data["columns"])
    rows = map_data["rows"]

    input_path = Path(args.input).resolve()
    if not input_path.exists():
        _fail(f"Input sheet not found: {input_path}")

    img = load_image(input_path)

    if args.remove_gemini_watermark:
        img = remove_gemini_watermark(img)
    if args.white_to_alpha is not None:
        img = white_to_alpha(img, int(args.white_to_alpha))

    _validate_grid(img, cell_w, cell_h, columns, len(rows))

    output_dir = _resolve_dir(args.output_dir, project_root, project_root / "assets" / "sprites" / input_path.stem)
    output_dir.mkdir(parents=True, exist_ok=True)
    frames_dir = output_dir / "frames"
    frames_dir.mkdir(parents=True, exist_ok=True)

    stem = input_path.stem
    sheet_path = output_dir / f"{stem}_sheet.png"
    tres_path = output_dir / f"{stem}_frames.tres"

    sheet = Image.new("RGBA", (columns * cell_w, len(rows) * cell_h), (0, 0, 0, 0))
    animations = []
    summary = []
    for row_idx, row_def in enumerate(rows):
        name = row_def["name"]
        loop = bool(row_def.get("loop", False))
        non_blank_cols: list[int] = []
        for col in range(columns):
            x, y = col * cell_w, row_idx * cell_h
            cell = img.crop((x, y, x + cell_w, y + cell_h))
            if _is_blank(cell):
                continue
            non_blank_cols.append(col)
            sheet.paste(cell, (x, y))

        if not non_blank_cols:
            _fail(f"Row {row_idx} ({name}) has zero non-blank cells — refusing to emit an empty animation")

        for i, col in enumerate(non_blank_cols):
            x, y = col * cell_w, row_idx * cell_h
            frame = img.crop((x, y, x + cell_w, y + cell_h))
            save_image(frame, frames_dir / f"{name}_{i:03d}.png")

        animations.append({
            "name": name,
            "row": row_idx,
            "speed": args.speed,
            "loop": loop,
            "columns": non_blank_cols,
        })
        summary.append((name, int(row_def.get("frames", 0)), len(non_blank_cols), loop))

    save_image(sheet, sheet_path)

    res_path = _res_path(sheet_path, project_root)
    tres_text = generate_sprite_frames_tres(
        spritesheet_path=res_path,
        cell_width=cell_w,
        cell_height=cell_h,
        rows=len(rows),
        columns=columns,
        animations=animations,
    )
    tres_path.write_text(tres_text, encoding="utf-8")

    _print_summary(summary, args.speed, sheet_path, tres_path, frames_dir)
    return 0


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Process a 12-row character sheet into Godot SpriteFrames, or render template/placeholder sheets."
    )
    parser.add_argument("--input", help="Input character-sheet PNG (12 rows x 6 columns of 256px cells).")
    parser.add_argument("--output-dir", help="Output directory. Default: assets/sprites/<input-stem>/ under --project-root.")
    parser.add_argument("--map", default=str(MAP_PATH), help="Editable mapping table JSON. Default: character_sheet_map.json next to this script.")
    parser.add_argument("--speed", type=float, default=10.0, help="Animation speed in fps (10 -> 100 ms/frame). Default: 10.")
    parser.add_argument("--remove-gemini-watermark", action="store_true", help="Opt-in: remove the Gemini watermark.")
    parser.add_argument("--white-to-alpha", nargs="?", const=240.0, type=float, default=None, metavar="THRESHOLD",
                        help="Opt-in: convert near-white pixels to transparent (threshold 0-255, default 240).")
    parser.add_argument("--project-root", default=str(Path.cwd()), help="Project root for computing the res:// path. Default: current directory.")

    group = parser.add_mutually_exclusive_group()
    group.add_argument("--make-template", action="store_true", help="Render the blank authoring grid instead of processing a sheet.")
    group.add_argument("--make-placeholder-sheet", action="store_true", help="Render a labeled placeholder sheet instead of processing a sheet.")
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = _build_parser()
    args = parser.parse_args(argv)

    project_root = Path(args.project_root).resolve()
    map_data = _load_map(Path(args.map))

    if args.make_template or args.make_placeholder_sheet:
        mode = "template" if args.make_template else "placeholder"
        sheet = _render_grid(map_data, mode)
        default_dir = project_root / ("docs/templates" if mode == "template" else "assets/placeholders")
        out_dir = _resolve_dir(args.output_dir, project_root, default_dir)
        filename = "character-sheet-template.png" if mode == "template" else "character-sheet-placeholder.png"
        path = save_image(sheet, out_dir / filename)
        print(f"Wrote {mode} sheet: {path}")
        return 0

    if not args.input:
        parser.error("--input is required unless --make-template or --make-placeholder-sheet is given")

    return _process_sheet(args, project_root, map_data)


if __name__ == "__main__":
    sys.exit(main())
