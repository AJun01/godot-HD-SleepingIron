#!/usr/bin/env python3
"""
Compose the user's hand-cleaned per-action frame folders into the player's
Godot SpriteFrames assets.

This is the official pipeline for hand-cleaned frames (supersedes the ad-hoc
rebuild). Each action is a subdirectory of PNGs under ``--src``; the script
NEAREST-resizes any non-256px frame to 256x256, then writes:

- flat right-facing project frames ``assets/sprites/player/frames/<action>_NNN.png``
- mirrored left frames ``<src>/../frames_left/<action>/<action>_NNN.png``
- ``player_sheet.png`` (right) and ``player_left_sheet.png`` (mirrored), laid out
  as ``columns`` x ``len(map rows)`` 256px cells
- the same two sheets written back to the user's working directory as
  ``<src parent>/character_sheet.png`` and ``<src parent>/character_sheet_left.png``
  (opt out with ``--no-write-user-sheets``)
- ``player_frames.tres`` / ``player_left_frames.tres`` via
  ``godot_format.generate_sprite_frames_tres`` with the existing UIDs pinned

Per-animation frame count is the action's real file count (walk: 8, others: 6);
the grid width is the map's ``columns``. Fails fast when an action in the map has
no frames, any frame is not square, or an action overflows the grid width.

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

# Existing SpriteFrames UIDs pinned so player.tscn's by-path reference and any
# cached UID lookups keep resolving after regeneration.
RIGHT_UID = "uid://2k97uge7sf4w"
LEFT_UID = "uid://a2tle527t5pf"

SPEED = 10.0
CELL = 256


def _fail(message: str) -> None:
    raise SystemExit(f"Error: {message}")


def _load_map(map_path: Path) -> dict:
    if not map_path.exists():
        _fail(f"Map file not found: {map_path}")
    with map_path.open("r", encoding="utf-8") as fh:
        data = json.load(fh)
    rows = data.get("rows")
    if not isinstance(rows, list) or len(rows) == 0:
        _fail(f"Map must define at least one row: {map_path}")
    return data


def _load_frames(action: str, action_dir: Path, cell: int) -> list[Image.Image]:
    files = sorted(action_dir.glob("*.png"))
    if not files:
        _fail(f"Action '{action}' has no PNG frames in {action_dir}")
    frames: list[Image.Image] = []
    for fp in files:
        img = Image.open(fp).convert("RGBA")
        if img.width != img.height:
            _fail(f"Frame not square: {fp} is {img.width}x{img.height}")
        if img.width != cell:
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
                        help="Directory of per-action frame subdirectories. Default: the user's out_user/frames path.")
    parser.add_argument("--project-root", default=str(Path.cwd()),
                        help="Project root for output paths and res:// computation. Default: current directory.")
    parser.add_argument("--map", default=str(MAP_PATH),
                        help="Editable mapping table JSON. Default: character_sheet_map.json next to this script.")
    parser.add_argument(
        "--write-user-sheets",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="Write the composed sheets back to <src parent>/character_sheet(_left).png. "
             "Default: true; pass --no-write-user-sheets to skip.",
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
    columns = int(map_data["columns"])
    rows = map_data["rows"]

    src = Path(args.src)
    if not src.is_dir():
        _fail(f"--src is not a directory: {src}")
    frames_left_root = src.parent / "frames_left"

    player_dir = project_root / "assets" / "sprites" / "player"
    frames_dir = player_dir / "frames"
    frames_dir.mkdir(parents=True, exist_ok=True)

    all_frames: dict[str, list[Image.Image]] = {}
    animations: list[dict] = []
    for row_idx, row_def in enumerate(rows):
        name = row_def["name"]
        loop = bool(row_def.get("loop", False))
        action_dir = src / name
        if not action_dir.is_dir():
            _fail(f"Action '{name}' directory not found: {action_dir}")
        frames = _load_frames(name, action_dir, cell_w)
        if len(frames) > columns:
            _fail(f"Action '{name}' has {len(frames)} frames, exceeds grid columns {columns}")
        all_frames[name] = frames
        animations.append({
            "name": name,
            "row": row_idx,
            "speed": SPEED,
            "loop": loop,
            "columns": list(range(len(frames))),
        })

    # Flat project frames (right-facing) + mirrored left frames for the author.
    for name, frames in all_frames.items():
        left_dir = frames_left_root / name
        left_dir.mkdir(parents=True, exist_ok=True)
        for i, frame in enumerate(frames):
            save_image(frame, frames_dir / f"{name}_{i:03d}.png")
            mirrored = frame.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
            save_image(mirrored, left_dir / f"{name}_{i:03d}.png")

    # Composed sheets: right + mirrored left, columns x len(rows) cells.
    sheet = Image.new("RGBA", (columns * cell_w, len(rows) * cell_h), (0, 0, 0, 0))
    sheet_left = Image.new("RGBA", (columns * cell_w, len(rows) * cell_h), (0, 0, 0, 0))
    for row_idx, row_def in enumerate(rows):
        for col, frame in enumerate(all_frames[row_def["name"]]):
            x, y = col * cell_w, row_idx * cell_h
            sheet.paste(frame, (x, y), frame)
            mirrored = frame.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
            sheet_left.paste(mirrored, (x, y), mirrored)

    sheet_path = save_image(sheet, player_dir / "player_sheet.png")
    left_path = save_image(sheet_left, player_dir / "player_left_sheet.png")

    # Keep the user's working dir in sync: mirror the composed sheets back so the
    # stale out_user/character_sheet*.png files match what the project consumes.
    user_sheet_path: Path | None = None
    user_left_path: Path | None = None
    if args.write_user_sheets:
        user_sheet_path = save_image(sheet, src.parent / "character_sheet.png")
        user_left_path = save_image(sheet_left, src.parent / "character_sheet_left.png")

    right_tres = player_dir / "player_frames.tres"
    left_tres = player_dir / "player_left_frames.tres"
    right_tres.write_text(generate_sprite_frames_tres(
        spritesheet_path=_res_path(sheet_path, project_root),
        cell_width=cell_w,
        cell_height=cell_h,
        rows=len(rows),
        columns=columns,
        animations=animations,
        uid=RIGHT_UID,
    ), encoding="utf-8")
    left_tres.write_text(generate_sprite_frames_tres(
        spritesheet_path=_res_path(left_path, project_root),
        cell_width=cell_w,
        cell_height=cell_h,
        rows=len(rows),
        columns=columns,
        animations=animations,
        uid=LEFT_UID,
    ), encoding="utf-8")

    print("composed")
    print(f"  sheet (right): {sheet_path}")
    print(f"  sheet (left):  {left_path}")
    print(f"  frames: {frames_dir}")
    print(f"  frames_left:  {frames_left_root}")
    print(f"  .tres (right): {right_tres}  uid={RIGHT_UID}")
    print(f"  .tres (left):  {left_tres}  uid={LEFT_UID}")
    if user_sheet_path is not None and user_left_path is not None:
        print(f"  sheet (user right): {user_sheet_path}")
        print(f"  sheet (user left):  {user_left_path}")
    for name in (r["name"] for r in rows):
        print(f"    {name}: {len(all_frames[name])} frames")
    return 0


if __name__ == "__main__":
    sys.exit(main())
