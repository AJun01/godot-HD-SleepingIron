#!/usr/bin/env python3
"""
Compose the user's hand-cleaned per-action frame folders into the player's
Godot SpriteFrames assets.

This is the official pipeline for hand-cleaned frames (supersedes the ad-hoc
rebuild). Source frames live under ``<src>/<set>/<action>/`` where ``<set>`` is
``alert`` or ``non_alert``. Every frame is normalized to a 256x256 cell:
non-square frames are center-cropped by the shorter side first, then everything
is NEAREST-resized. For each set the script writes:

- flat right-facing project frames ``assets/sprites/player/frames/<set>/<action>_NNN.png``
- mirrored left frames ``<src>/../frames_left/<set>/<action>/<action>_NNN.png``
- the set's sheet (right-facing) at the map's ``sheet`` path, laid out as
  ``columns`` x ``len(rows)`` 256px cells
- the same sheet written back to the user's working directory as
  ``<src parent>/character_sheet.png`` (alert) / ``character_sheet_nonalert.png``
  (non_alert); opt out with ``--no-write-user-sheets``
- the set's ``SpriteFrames`` .tres via ``godot_format.generate_sprite_frames_tres``
  with the map's pinned uid

Per-animation speed and loop come from the row definition (fps); ``from``
resolves an alternative source action dir and ``columns`` slices the frame list
(e.g. jump/land/fall all read the ``jump`` source). Fails fast when an action in
the map has no frames, a frame is not PNG, or an action overflows the grid width.

Usage:
    python tools/art_pipeline/compose_from_user_frames.py \
        --src "/Users/aj/Desktop/素材/art/frames-v1/out_user/frames" --project-root .
"""

import argparse
import json
import sys
from pathlib import Path

from PIL import Image

from godot_format import generate_sprite_frames_tres
from image_utils import save_image

MAP_PATH = Path(__file__).resolve().parent / "character_sheet_map.json"

# Default source: the user's hand-cleaned frames under their Desktop 素材 dir.
DEFAULT_SRC = "/Users/aj/Desktop/素材/art/frames-v1/out_user/frames"

CELL = 256
DEFAULT_SPEED = 10.0


def _fail(message: str) -> None:
    raise SystemExit(f"Error: {message}")


def _load_map(map_path: Path) -> dict:
    if not map_path.exists():
        _fail(f"Map file not found: {map_path}")
    with map_path.open("r", encoding="utf-8") as fh:
        data = json.load(fh)
    sets = data.get("sets")
    if not isinstance(sets, dict) or len(sets) == 0:
        _fail(f"Map must define a non-empty 'sets' object: {map_path}")
    for set_name, set_def in sets.items():
        if not isinstance(set_def, dict):
            _fail(f"Set '{set_name}' must be an object: {map_path}")
        rows = set_def.get("rows")
        if not isinstance(rows, list) or len(rows) == 0:
            _fail(f"Set '{set_name}' must define at least one row: {map_path}")
    return data


def _center_crop_square(img: Image.Image) -> Image.Image:
    """Center-crop to a square using the shorter side."""
    w, h = img.size
    if w == h:
        return img
    side = min(w, h)
    left = (w - side) // 2
    top = (h - side) // 2
    return img.crop((left, top, left + side, top + side))


def _load_frames(action: str, action_dir: Path, cell: int) -> list[Image.Image]:
    files = sorted(action_dir.glob("*.png"))
    if not files:
        _fail(f"Action '{action}' has no PNG frames in {action_dir}")
    frames: list[Image.Image] = []
    for fp in files:
        try:
            with Image.open(fp) as opened:
                fmt = opened.format
                img = opened.convert("RGBA")
        except Exception as exc:  # noqa: BLE001 - report a clean pipeline error
            _fail(f"Failed to open frame {fp}: {exc}")
        if fmt != "PNG":
            _fail(f"Frame not PNG: {fp} is {fmt}")
        if img.width != img.height:
            img = _center_crop_square(img)
        if img.size != (cell, cell):
            img = img.resize((cell, cell), Image.Resampling.NEAREST)
        frames.append(img)
    return frames


def _res_path(path: Path, project_root: Path) -> str:
    try:
        rel = path.resolve().relative_to(project_root.resolve())
    except ValueError:
        _fail(
            f"Output {path} is outside project root {project_root}; cannot compute "
            "res:// path. Pass --project-root or keep outputs under the project root."
        )
    return rel.as_posix()


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Compose the user's hand-cleaned per-action frame folders into the player SpriteFrames assets."
    )
    parser.add_argument("--src", default=DEFAULT_SRC,
                        help="Directory of per-set per-action frame subdirectories. Default: the user's out_user/frames path.")
    parser.add_argument("--project-root", default=str(Path.cwd()),
                        help="Project root for output paths and res:// computation. Default: current directory.")
    parser.add_argument("--map", default=str(MAP_PATH),
                        help="Editable mapping table JSON. Default: character_sheet_map.json next to this script.")
    parser.add_argument(
        "--write-user-sheets",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="Write the composed sheets back to <src parent>/character_sheet.png and "
             "character_sheet_nonalert.png. Default: true; pass --no-write-user-sheets to skip.",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = _build_parser()
    args = parser.parse_args(argv)

    project_root = Path(args.project_root).resolve()
    map_path = Path(args.map)
    if not map_path.is_absolute():
        map_path = (Path.cwd() / map_path).resolve()
    map_data = _load_map(map_path)

    cell_w = int(map_data["cell_width"])
    cell_h = int(map_data["cell_height"])
    sets = map_data["sets"]

    src = Path(args.src)
    if not src.is_dir():
        _fail(f"--src is not a directory: {src}")
    frames_left_root = src.parent / "frames_left"

    player_dir = project_root / "assets" / "sprites" / "player"
    frames_dir = player_dir / "frames"
    frames_dir.mkdir(parents=True, exist_ok=True)

    for set_name, set_def in sets.items():
        columns = int(set_def["columns"])
        sheet_rel = set_def["sheet"]
        tres_rel = set_def["tres"]
        uid = set_def["uid"]
        rows = set_def["rows"]

        all_frames: dict[str, list[Image.Image]] = {}
        animations: list[dict] = []
        for row_idx, row_def in enumerate(rows):
            name = row_def["name"]
            loop = bool(row_def.get("loop", False))
            speed = float(row_def.get("speed", DEFAULT_SPEED))
            src_action = row_def.get("from", name)
            action_dir = src / set_name / src_action
            if not action_dir.is_dir():
                _fail(f"Action '{src_action}' (for '{name}') directory not found: {action_dir}")
            frames = _load_frames(src_action, action_dir, cell_w)
            cols = row_def.get("columns")
            if cols is None:
                cols = list(range(len(frames)))
            else:
                cols = [int(c) for c in cols]
                for c in cols:
                    if c < 0 or c >= len(frames):
                        _fail(
                            f"Action '{name}' column index {c} out of range "
                            f"(source '{src_action}' has {len(frames)} frames)"
                        )
            selected = [frames[c] for c in cols]
            if len(selected) > columns:
                _fail(f"Action '{name}' has {len(selected)} frames, exceeds grid columns {columns}")
            all_frames[name] = selected
            animations.append({
                "name": name,
                "row": row_idx,
                "speed": speed,
                "loop": loop,
                "columns": list(range(len(selected))),
            })

        # Flat project frames (right-facing) + mirrored left frames for the author.
        set_frames_dir = frames_dir / set_name
        set_frames_dir.mkdir(parents=True, exist_ok=True)
        for name, frames in all_frames.items():
            left_dir = frames_left_root / set_name / name
            left_dir.mkdir(parents=True, exist_ok=True)
            for i, frame in enumerate(frames):
                save_image(frame, set_frames_dir / f"{name}_{i:03d}.png")
                mirrored = frame.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
                save_image(mirrored, left_dir / f"{name}_{i:03d}.png")

        # Composed sheet (right-facing), columns x len(rows) cells.
        sheet = Image.new("RGBA", (columns * cell_w, len(rows) * cell_h), (0, 0, 0, 0))
        for row_idx, row_def in enumerate(rows):
            for col, frame in enumerate(all_frames[row_def["name"]]):
                x, y = col * cell_w, row_idx * cell_h
                sheet.paste(frame, (x, y), frame)

        sheet_path = save_image(sheet, project_root / sheet_rel)

        # Keep the user's working dir in sync: mirror the composed sheet back so the
        # stale out_user/character_sheet*.png files match what the project consumes.
        user_sheet_path: Path | None = None
        if args.write_user_sheets:
            user_sheet_name = Path(sheet_rel).name.replace("player_sheet", "character_sheet", 1)
            user_sheet_path = save_image(sheet, src.parent / user_sheet_name)

        tres_path = project_root / tres_rel
        tres_path.write_text(generate_sprite_frames_tres(
            spritesheet_path=_res_path(sheet_path, project_root),
            cell_width=cell_w,
            cell_height=cell_h,
            rows=len(rows),
            columns=columns,
            animations=animations,
            uid=uid,
        ), encoding="utf-8")

        print(f"composed [{set_name}]")
        print(f"  sheet: {sheet_path}")
        print(f"  frames: {set_frames_dir}")
        print(f"  frames_left: {frames_left_root / set_name}")
        print(f"  .tres: {tres_path}  uid={uid}")
        if user_sheet_path is not None:
            print(f"  sheet (user): {user_sheet_path}")
        for name in (r["name"] for r in rows):
            print(f"    {name}: {len(all_frames[name])} frames")

    return 0


if __name__ == "__main__":
    sys.exit(main())
