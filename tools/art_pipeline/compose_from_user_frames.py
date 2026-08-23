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

Palette unification (optional): when the map's top-level ``palette_colors`` is a
positive integer, every frame is remapped onto one global N-color palette shared
by BOTH sets, so hand-cleaned frames stop drifting in color between frames. The
palette is extracted from all opaque pixels with Pillow median cut, cached to
``<src parent>/palette_<N>.png``, and reused on later runs so adding new frames
does not shift old frames' colors (``--refresh-palette`` forces re-extraction).
Per-frame remap uses 4x4 Bayer ordered dithering against each pixel's two nearest
palette colors. ``palette_colors`` 0 or absent disables the filter.

Usage:
    python tools/art_pipeline/compose_from_user_frames.py \
        --src "/Users/aj/Desktop/素材/art/frames-v1/out_user/frames" --project-root .
"""

import argparse
import json
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image

from godot_format import generate_sprite_frames_tres
from image_utils import save_image

MAP_PATH = Path(__file__).resolve().parent / "character_sheet_map.json"

# Default source: the user's hand-cleaned frames under their Desktop 素材 dir.
DEFAULT_SRC = "/Users/aj/Desktop/素材/art/frames-v1/out_user/frames"

CELL = 256
DEFAULT_SPEED = 10.0

# 4x4 Bayer ordered-dithering matrix, normalized to [0, 1).
BAYER_4X4 = np.array([
    [0, 8, 2, 10],
    [12, 4, 14, 6],
    [3, 11, 1, 9],
    [15, 7, 13, 5],
], dtype=np.float32) / 16.0

# Color-grid index resolution: each 32x32x32 cell precomputes its two nearest
# palette colors so per-pixel nearest/second-nearest lookup is O(1) instead of
# an O(palette) scan over 76 frames of 256x256.
GRID_BITS = 5
GRID_SIZE = 1 << GRID_BITS


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


def _extract_palette(frames: list[Image.Image], n_colors: int) -> np.ndarray:
    """Extract an n-color palette from all opaque pixels via Pillow median cut.

    The spec's merged strip is built as a compact square of every opaque pixel
    (alpha > 0), so fully-transparent pixels never pollute the palette. The
    strip is then median-cut quantized without dithering to yield the palette.
    """
    blocks: list[np.ndarray] = []
    for frame in frames:
        arr = np.asarray(frame, dtype=np.uint8)
        opaque = arr[arr[:, :, 3] > 0, :3]
        if opaque.size:
            blocks.append(opaque)
    if not blocks:
        return np.zeros((n_colors, 3), dtype=np.float32)

    data = np.concatenate(blocks, axis=0)
    side = max(1, math.isqrt(data.shape[0]))
    if side * side < data.shape[0]:
        side += 1
    strip = np.zeros((side * side, 3), dtype=np.uint8)
    strip[: data.shape[0]] = data

    merged = Image.fromarray(strip.reshape(side, side, 3), "RGB")
    pal_img = merged.quantize(
        colors=n_colors,
        method=Image.Quantize.MEDIANCUT,
        dither=Image.Dither.NONE,
    )
    # getpalette() returns either the used colors (N*3 values) or a fixed 768;
    # reshape then truncate/pad so we always hand back n_colors RGB rows.
    palette = np.array(pal_img.getpalette(), dtype=np.float32).reshape(-1, 3)
    if palette.shape[0] < n_colors:
        pad = np.zeros((n_colors - palette.shape[0], 3), dtype=np.float32)
        palette = np.concatenate([palette, pad], axis=0)
    else:
        palette = palette[:n_colors].copy()
    return palette


def _save_palette(palette: np.ndarray, path: Path) -> None:
    """Persist the palette as a 1 x N RGB swatch PNG."""
    n = palette.shape[0]
    swatch = Image.fromarray(palette.astype(np.uint8).reshape(1, n, 3), "RGB")
    save_image(swatch, path)


def _load_palette(path: Path, n_colors: int) -> np.ndarray | None:
    """Load a cached palette swatch; return None when absent or malformed."""
    try:
        with Image.open(path) as img:
            arr = np.asarray(img.convert("RGB"), dtype=np.float32)
    except Exception:  # noqa: BLE001 - a bad cache simply triggers re-extraction
        return None
    flat = arr.reshape(-1, 3)
    if flat.shape[0] < n_colors:
        return None
    return flat[:n_colors].copy()


def _resolve_palette(
    frames: list[Image.Image],
    n_colors: int,
    src_parent: Path,
    refresh: bool,
) -> np.ndarray:
    """Return the global palette, reusing the cache unless forced to refresh."""
    cache_path = src_parent / f"palette_{n_colors}.png"
    if not refresh and cache_path.exists():
        cached = _load_palette(cache_path, n_colors)
        if cached is not None:
            print(f"palette: {n_colors} colors (cached: {cache_path})")
            return cached
    palette = _extract_palette(frames, n_colors)
    _save_palette(palette, cache_path)
    print(f"palette: {n_colors} colors (fresh -> {cache_path})")
    return palette


def _build_grid_index(palette: np.ndarray) -> np.ndarray:
    """Precompute each 32x32x32 color cell's two nearest palette colors.

    Returns an int32 array of shape (32, 32, 32, 2) holding palette indices
    ordered nearest-first by distance from the cell center.
    """
    n = palette.shape[0]
    grid = np.zeros((GRID_SIZE, GRID_SIZE, GRID_SIZE, 2), dtype=np.int32)
    if n < 2:
        return grid  # degenerate: both candidates fall back to color 0
    coords = np.arange(GRID_SIZE, dtype=np.float32) * 8 + 4  # cell centers
    rr, gg, bb = np.meshgrid(coords, coords, coords, indexing="ij")
    centers = np.stack([rr, gg, bb], axis=-1)  # (32,32,32,3)
    diff = centers[:, :, :, None, :] - palette[None, None, None, :, :]
    dist = np.einsum("...c,...c->...", diff, diff)  # (32,32,32,n)
    top2 = np.argsort(dist, axis=-1)[..., :2].astype(np.int32)
    return top2


def _remap_frame(frame: Image.Image, palette: np.ndarray, grid: np.ndarray) -> Image.Image:
    """Remap one RGBA frame onto the palette with 4x4 Bayer ordered dithering.

    For each opaque pixel we take the grid cell's two candidate palette colors
    and compute exact L2 distances d1/d2 for that pixel. With
    ``t = d1 / (d1 + d2)`` the pixel sits fraction t of the way from the nearest
    color toward the second; standard ordered dithering picks the second color
    when ``t`` exceeds the Bayer threshold at that pixel. Alpha is untouched and
    fully-transparent pixels stay transparent black.
    """
    arr = np.asarray(frame, dtype=np.uint8)
    h, w = arr.shape[:2]
    alpha = arr[:, :, 3]
    rgb = arr[:, :, :3].astype(np.float32)

    cell = arr[:, :, :3] >> (8 - GRID_BITS)  # (h,w,3) in 0..31
    ci = cell[:, :, 0].astype(np.intp)
    gi = cell[:, :, 1].astype(np.intp)
    bi = cell[:, :, 2].astype(np.intp)
    candidates = grid[ci, gi, bi]  # (h,w,2) palette indices

    p1 = palette[candidates[:, :, 0]]  # (h,w,3)
    p2 = palette[candidates[:, :, 1]]  # (h,w,3)
    d1 = np.einsum("...c,...c->...", rgb - p1, rgb - p1)
    d2 = np.einsum("...c,...c->...", rgb - p2, rgb - p2)

    denom = d1 + d2
    t = np.zeros_like(d1)
    np.divide(d1, denom, out=t, where=denom > 0)

    ys = np.arange(h, dtype=np.intp)[:, None] % 4
    xs = np.arange(w, dtype=np.intp)[None, :] % 4
    bayer = BAYER_4X4[ys, xs]  # (h,w)

    choose_c2 = t > bayer
    out_rgb = np.where(choose_c2[:, :, None], p2, p1).astype(np.uint8)

    out = np.zeros_like(arr)
    out[:, :, 3] = alpha
    opaque = alpha > 0
    out[opaque, :3] = out_rgb[opaque]
    return Image.fromarray(out, "RGBA")


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
    parser.add_argument(
        "--refresh-palette",
        action="store_true",
        help="Re-extract the global palette instead of reusing <src parent>/palette_<N>.png.",
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
    palette_colors = int(map_data.get("palette_colors", 0))

    src = Path(args.src)
    if not src.is_dir():
        _fail(f"--src is not a directory: {src}")
    frames_left_root = src.parent / "frames_left"

    player_dir = project_root / "assets" / "sprites" / "player"
    frames_dir = player_dir / "frames"
    frames_dir.mkdir(parents=True, exist_ok=True)

    # Load every frame for every set up front so the palette stage sees both
    # sets before any sheet is composed.
    sets_data: dict[str, dict] = {}
    for set_name, set_def in sets.items():
        columns = int(set_def["columns"])
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
        sets_data[set_name] = {
            "columns": columns,
            "sheet_rel": set_def["sheet"],
            "tres_rel": set_def["tres"],
            "uid": set_def["uid"],
            "rows": rows,
            "all_frames": all_frames,
            "animations": animations,
        }

    # Palette unification: one global palette, remap every frame before composing.
    if palette_colors > 0:
        all_frames_flat = [
            frame
            for sd in sets_data.values()
            for frames in sd["all_frames"].values()
            for frame in frames
        ]
        palette = _resolve_palette(all_frames_flat, palette_colors, src.parent, args.refresh_palette)
        grid = _build_grid_index(palette)
        for sd in sets_data.values():
            for name, frames in sd["all_frames"].items():
                sd["all_frames"][name] = [_remap_frame(f, palette, grid) for f in frames]

    for set_name, sd in sets_data.items():
        columns = sd["columns"]
        sheet_rel = sd["sheet_rel"]
        tres_rel = sd["tres_rel"]
        uid = sd["uid"]
        rows = sd["rows"]
        all_frames = sd["all_frames"]
        animations = sd["animations"]

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
