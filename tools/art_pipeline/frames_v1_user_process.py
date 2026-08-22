#!/usr/bin/env python3
"""
frames-v1 user-crop frame pipeline → Godot SpriteFrames.

Vendored from the user's hand-tuned `/tmp/frames_v1_user_process.py`
(checkerboard matting + label/divider/ground-line cleanup + 256px resize +
12-action classification + right/mirrored-left sheet composition) and improved
for fix-002 / fix-004b with three additions:

- **despeckle** — after matting and after the 256×256 resize, removes small
  near-black specks floating in transparency (matting leftovers), while
  preserving dark details enclosed inside the silhouette.
- **salt-and-pepper despeckle** — after `despeckle`, erodes specks attached to
  the silhouette via anti-aliased bridges pixel-by-pixel (fix-004b).
- **idle-collapse** — the idle row is temporarily collapsed to a single
  duplicated frame (the user will supply new idle art later).

The script also emits `player_frames.tres` / `player_left_frames.tres` via
`godot_format.generate_sprite_frames_tres` with the existing UIDs pinned.

Usage:
    python tools/art_pipeline/frames_v1_user_process.py \
        --src "/Users/aj/Desktop/素材/art/frames-v1" --project-root .
"""

import argparse
import re
import sys
from collections import Counter, deque
from pathlib import Path

import numpy as np
from PIL import Image

from godot_format import generate_sprite_frames_tres
from image_utils import save_image

# Row order is the 12-row sheet contract (docs/character-sprite-mapping.md).
MAP = [
    "idle", "run", "jump", "fall", "land", "attack_1", "attack_2",
    "attack_3", "attack_air", "hit", "dodge", "death",
]

# Loop flags per row: idle/run/fall loop; the rest are one-shots.
LOOP = {
    "idle": True, "run": True, "jump": False, "fall": True, "land": False,
    "attack_1": False, "attack_2": False, "attack_3": False, "attack_air": False,
    "hit": False, "dodge": False, "death": False,
}

# folder → (3 actions for its 3 rows of 6 frames).
FOLDERS = [
    ("0,1,2_frames", ["idle", "run", "jump"]),
    ("3,4,5_frames", ["fall", "land", "attack_1"]),
    ("6,7,8_frames", ["attack_2", "attack_3", "attack_air"]),
    ("9,10,11_frames", ["hit", "dodge", "death"]),
]

# Existing SpriteFrames UIDs pinned so player.tscn's by-path reference and any
# cached UID lookups keep resolving after regeneration.
RIGHT_UID = "uid://2k97uge7sf4w"
LEFT_UID = "uid://a2tle527t5pf"

TOL = 30.0
CELL = 256
COLUMNS = 6


def _fail(message: str) -> None:
    raise SystemExit(f"Error: {message}")


def learn_palette(img: Image.Image) -> np.ndarray:
    """Adaptive per-folder checkerboard palette from the image border ring."""
    a = np.array(img.convert("RGB"))
    ring = np.concatenate([a[0, :, :], a[-1, :, :], a[:, 0, :], a[:, -1, :]])
    q = (ring // 8 * 8).astype(np.int16)
    lum = q.sum(axis=1)
    cnt = Counter(map(tuple, q[lum > 60 * 3].tolist()))
    palette = [np.array(c, np.float32) for c, _ in cnt.most_common(4)]
    white = np.array([255, 255, 255], np.float32)
    if not any(np.abs(p - white).max() < 12 for p in palette):
        palette.append(white)
    return np.stack(palette)


def bg_mask(rgb: np.ndarray, palette: np.ndarray) -> np.ndarray:
    """Per-pixel boolean: within TOL of any palette tone."""
    d = np.abs(rgb[:, :, None, :] - palette[None, None, :, :]).max(axis=3)
    return d.min(axis=2) <= TOL


def flood(mask: np.ndarray) -> np.ndarray:
    """4-connected flood fill of `mask` seeded from every border pixel."""
    H, W = mask.shape
    filled = np.zeros((H, W), bool)
    q: deque[tuple[int, int]] = deque()
    for x in range(W):
        if mask[0, x]:
            filled[0, x] = True
            q.append((0, x))
        if mask[H - 1, x]:
            filled[H - 1, x] = True
            q.append((H - 1, x))
    for y in range(H):
        if mask[y, 0]:
            filled[y, 0] = True
            q.append((y, 0))
        if mask[y, W - 1]:
            filled[y, W - 1] = True
            q.append((y, W - 1))
    while q:
        y, x = q.popleft()
        for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
            if 0 <= ny < H and 0 <= nx < W and mask[ny, nx] and not filled[ny, nx]:
                filled[ny, nx] = True
                q.append((ny, nx))
    return filled


def components(alpha_bool: np.ndarray) -> list[list[tuple[int, int]]]:
    """4-connected components of a boolean mask, as lists of (y, x) points."""
    H, W = alpha_bool.shape
    seen = np.zeros((H, W), bool)
    comps: list[list[tuple[int, int]]] = []
    for y in range(H):
        for x in range(W):
            if alpha_bool[y, x] and not seen[y, x]:
                q: deque[tuple[int, int]] = deque([(y, x)])
                seen[y, x] = True
                pts: list[tuple[int, int]] = []
                while q:
                    cy, cx = q.popleft()
                    pts.append((cy, cx))
                    for ny, nx in ((cy + 1, cx), (cy - 1, cx), (cy, cx + 1), (cy, cx - 1)):
                        if 0 <= ny < H and 0 <= nx < W and alpha_bool[ny, nx] and not seen[ny, nx]:
                            seen[ny, nx] = True
                            q.append((ny, nx))
                comps.append(pts)
    return comps


def clean_frame(img: Image.Image, palette: np.ndarray) -> Image.Image:
    """Checkerboard matting + label/divider/ground-line cleanup + 1px erosion."""
    img = img.convert("RGBA")
    a = np.array(img)
    rgb = a[:, :, :3].astype(np.float32)
    H, W = rgb.shape[:2]
    filled = flood(bg_mask(rgb, palette))
    alpha = a[:, :, 3].copy()
    alpha[filled] = 0

    # 0) Enclosed background regions (checker holes between the legs that the
    # border flood cannot reach): clear when large (>=800px) and containing >=2
    # palette tones. Only bright tones (lum >=240) participate so the character's
    # dark shadows are never eaten.
    bright_palette = palette[palette.sum(axis=1) >= 240]
    if bright_palette.size == 0:
        bright_palette = palette
    bm = bg_mask(rgb, bright_palette)
    enclosed = bm & ~filled
    for pts in components(enclosed):
        if len(pts) < 800:
            continue
        tone_ids = []
        for y, x in pts:
            d = np.abs(rgb[y, x] - bright_palette).max(axis=1)
            tone_ids.append(int(np.argmin(d)))
        tone_ids = np.array(tone_ids)
        fracs = [(tone_ids == t).mean() for t in range(len(bright_palette))]
        if sum(1 for f in fracs if f >= 0.15) >= 2:
            for y, x in pts:
                alpha[y, x] = 0

    # 1) Label islands (small components in the top 30%) and edge/ground-line
    # residue. The user's crops keep a positive margin on all four edges, so a
    # component touching the border is always divider/line residue, never body.
    comps = components(alpha > 0)
    comps.sort(key=len, reverse=True)
    for pts in comps[1:]:
        ys = [p[0] for p in pts]
        xs = [p[1] for p in pts]
        area = len(pts)
        touches = (min(ys) == 0 or max(ys) == H - 1 or min(xs) == 0 or max(xs) == W - 1)
        if area < 0.05 * H * W and min(ys) < 0.30 * H:
            for y, x in pts:
                alpha[y, x] = 0
        elif touches and area < 0.015 * H * W:
            for y, x in pts:
                alpha[y, x] = 0
        elif area < 0.03 * H * W and min(ys) > 0.85 * H:
            for y, x in pts:
                alpha[y, x] = 0

    # 2) Structural line clear: full rows/columns that are >=80% near-black,
    # thickness <=12, and adjacent to transparency.
    dark = (a[:, :, :3].max(axis=2) < 80) & (alpha > 0)
    transparent = (alpha == 0).astype(np.float32)
    hor = dark.mean(axis=1) >= 0.80
    ver = dark.mean(axis=0) >= 0.80
    for mask, axis in ((hor, 0), (ver, 1)):
        n = len(mask)
        i = 0
        while i < n:
            if mask[i]:
                j = i
                while j + 1 < n and mask[j + 1]:
                    j += 1
                if j - i + 1 <= 12:
                    if axis == 0:
                        below = transparent[j + 1, :].mean() if j + 1 < n else 1.0
                        if below >= 0.60:
                            alpha[i:j + 1, :] = 0
                    else:
                        left = transparent[:, i - 1].mean() if i > 0 else 1.0
                        right = transparent[:, j + 1].mean() if j + 1 < n else 1.0
                        if left >= 0.60 and right >= 0.60:
                            alpha[:, i:j + 1] = 0
                i = j + 1
            else:
                i += 1

    a[:, :, 3] = alpha

    # 3) Clear everything below the main body's bottom edge, then drop secondary
    # islands once more (same rules as step 1).
    comps2 = components(a[:, :, 3] > 0)
    if comps2:
        comps2.sort(key=len, reverse=True)
        main = comps2[0]
        bottom = max(p[0] for p in main)
        a[bottom + 1:, :, 3] = 0
        for pts in comps2[1:]:
            ys = [p[0] for p in pts]
            xs = [p[1] for p in pts]
            area = len(pts)
            touches = (min(ys) == 0 or max(ys) == H - 1 or min(xs) == 0 or max(xs) == W - 1)
            if (area < 0.05 * H * W and min(ys) < 0.30 * H) or \
               (touches and area < 0.015 * H * W) or \
               (area < 0.03 * H * W and min(ys) > 0.85 * H):
                for y, x in pts:
                    a[y, x, 3] = 0

    # 4) 1px erosion (the user's crops keep a margin on all sides, so safe).
    body = a[:, :, 3] > 0
    er = np.zeros_like(body)
    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        sh = np.roll(body, (dy, dx), axis=(0, 1))
        if dy == 1:
            sh[0, :] = False
        if dy == -1:
            sh[-1, :] = False
        if dx == 1:
            sh[:, 0] = False
        if dx == -1:
            sh[:, -1] = False
        er |= sh
    a[(~er & body), 3] = 0
    a[(a[:, :, 3] == 0), :3] = 0
    return Image.fromarray(a, "RGBA")


def despeckle(img: Image.Image) -> tuple[Image.Image, int]:
    """
    Remove small near-black specks floating in transparency (fix-002).

    A "dark" opaque pixel has max(R,G,B) < 80 and alpha > 0. For each 4-connected
    dark component, clear it (alpha = 0, RGB = 0) iff area < 25 AND
    perimeter_transparent_fraction >= 0.5. Specks in transparency have most of
    their perimeter against transparent pixels; dark details inside the
    silhouette are enclosed by opaque body pixels, so their fraction is ~0 and
    they survive.
    """
    a = np.array(img.convert("RGBA"))
    H, W = a.shape[:2]
    alpha = a[:, :, 3]
    dark = (a[:, :, :3].max(axis=2) < 80) & (alpha > 0)
    transparent = alpha == 0
    removed = 0
    for pts in components(dark):
        area = len(pts)
        if area >= 25:
            continue
        ptrans = 0
        for y, x in pts:
            if (y + 1 < H and transparent[y + 1, x]) or \
               (y - 1 >= 0 and transparent[y - 1, x]) or \
               (x + 1 < W and transparent[y, x + 1]) or \
               (x - 1 >= 0 and transparent[y, x - 1]):
                ptrans += 1
        if ptrans / area >= 0.5:
            for y, x in pts:
                a[y, x, 3] = 0
                a[y, x, :3] = 0
            removed += 1
    return Image.fromarray(a, "RGBA"), removed


def _transparent_neighbor_count(alpha: np.ndarray) -> np.ndarray:
    """Count, per pixel, how many of its 8 neighbors are transparent (alpha == 0)."""
    transparent = alpha == 0
    count = np.zeros(alpha.shape, dtype=np.uint8)
    for dy, dx in (
        (-1, -1), (-1, 0), (-1, 1),
        (0, -1), (0, 1),
        (1, -1), (1, 0), (1, 1),
    ):
        sh = np.roll(transparent, (dy, dx), axis=(0, 1))
        # Zero the wrapped border after each shift so edges do not wrap around,
        # mirroring the 1px-erosion edge handling in clean_frame().
        if dy == 1:
            sh[0, :] = False
        if dy == -1:
            sh[-1, :] = False
        if dx == 1:
            sh[:, 0] = False
        if dx == -1:
            sh[:, -1] = False
        count += sh
    return count


def despeckle_salt_pepper(img: Image.Image) -> tuple[Image.Image, int, int]:
    """
    Remove attached salt-and-pepper specks pixel-by-pixel (fix-004b).

    despeckle() only clears *isolated* near-black components, so it misses specks
    attached to the silhouette via anti-aliased bridges: those are part of the
    main component and never match area<25 / perimeter_transparent_fraction>=0.5.
    This pass erodes them one pixel at a time: every opaque pixel (alpha > 0)
    with Rec.601 luminance < 100 and more than 5 of its 8 neighbors transparent
    (alpha == 0) is cleared (alpha = 0, RGB = 0).

    Iterated 3 times, recomputing opacity each pass, so AA bridges erode first
    and the now-detached speck pixels follow. Outline pixels survive because
    several interior neighbors are opaque (<= 5 transparent); enclosed dark
    details (eyes) have ~0 transparent neighbors and survive; attached specks
    and their AA bridges have 6-8 transparent neighbors and are removed.

    Returns (cleaned image, pixels removed across all sweeps, residual
    matching-pixel count after the final sweep — should be 0).
    """
    a = np.array(img.convert("RGBA"))
    alpha = a[:, :, 3]
    removed = 0
    for _ in range(3):
        count = _transparent_neighbor_count(alpha)
        lum = 0.299 * a[:, :, 0] + 0.587 * a[:, :, 1] + 0.114 * a[:, :, 2]
        remove = (alpha > 0) & (lum < 100) & (count > 5)
        removed += int(remove.sum())
        alpha[remove] = 0
        a[remove, :3] = 0
    count = _transparent_neighbor_count(alpha)
    lum = 0.299 * a[:, :, 0] + 0.587 * a[:, :, 1] + 0.114 * a[:, :, 2]
    residual = int(((alpha > 0) & (lum < 100) & (count > 5)).sum())
    return Image.fromarray(a, "RGBA"), removed, residual


def _pin_uid(tres_text: str, uid: str) -> str:
    """Replace the generated random resource uid with the pinned one."""
    return re.sub(r'uid="uid://[0-9a-z]+"', f'uid="{uid}"', tres_text, count=1)


def _res_path(path: Path, project_root: Path) -> str:
    return path.resolve().relative_to(project_root.resolve()).as_posix()


def _emit_tres(project_root: Path, sheet_path: Path, tres_path: Path, uid: str, speed: float) -> Path:
    animations = [
        {
            "name": name,
            "row": row,
            "speed": speed,
            "loop": LOOP[name],
            "columns": list(range(COLUMNS)),
        }
        for row, name in enumerate(MAP)
    ]
    tres_text = generate_sprite_frames_tres(
        spritesheet_path=_res_path(sheet_path, project_root),
        cell_width=CELL,
        cell_height=CELL,
        rows=len(MAP),
        columns=COLUMNS,
        animations=animations,
    )
    tres_text = _pin_uid(tres_text, uid)
    tres_path.write_text(tres_text, encoding="utf-8")
    return tres_path


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Process the user's hand-cropped frames-v1 folders into the player SpriteFrames asset."
    )
    parser.add_argument("--src", required=True, help="frames-v1 directory containing the 4 action folders.")
    parser.add_argument("--project-root", default=str(Path.cwd()),
                        help="Project root for output paths and res:// computation. Default: current directory.")
    parser.add_argument("--idle-frame", type=int, default=0,
                        help="Index (0-5) of the cleaned idle frame to collapse the idle row to. Default: 0.")
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = _build_parser()
    args = parser.parse_args(argv)

    src = Path(args.src)
    if not src.is_dir():
        _fail(f"--src is not a directory: {src}")
    if not 0 <= args.idle_frame < COLUMNS:
        _fail(f"--idle-frame must be in [0, {COLUMNS - 1}], got {args.idle_frame}")

    project_root = Path(args.project_root).resolve()
    player_dir = project_root / "assets" / "sprites" / "player"
    frames_dir = player_dir / "frames"
    frames_dir.mkdir(parents=True, exist_ok=True)

    all_frames: dict[str, list[Image.Image]] = {name: [] for name in MAP}
    stats: list[tuple[str, float]] = []
    total_removed = 0
    sp_total = 0
    sp_by_action: dict[str, int] = {name: 0 for name in MAP}
    sp_residual_total = 0

    for folder, actions in FOLDERS:
        folder_dir = src / folder
        files = sorted(folder_dir.glob("frame_*.png"))
        if len(files) != 18:
            _fail(f"{folder}: expected 18 frames, got {len(files)}")
        palette = learn_palette(Image.open(files[0]))
        print(f"{folder}: palette {palette.tolist()}")
        for i, fp in enumerate(files):
            row, _col = divmod(i, COLUMNS)
            action = actions[row]
            clean = clean_frame(Image.open(fp), palette)
            clean256 = clean.resize((CELL, CELL), Image.Resampling.NEAREST)
            despeckled, removed = despeckle(clean256)
            despeckled, sp_removed, sp_residual = despeckle_salt_pepper(despeckled)
            all_frames[action].append(despeckled)
            total_removed += removed
            sp_total += sp_removed
            sp_by_action[action] += sp_removed
            sp_residual_total += sp_residual
            if removed:
                print(f"  despeckle {action}_{len(all_frames[action]) - 1:03d}: removed {removed} component(s)")
            print(f"  salt-pepper {action}_{len(all_frames[action]) - 1:03d}: removed {sp_removed} px, residual {sp_residual}")
            arr = np.array(clean)
            stats.append((action, float((arr[:, :, 3] == 0).mean())))

    bad = [(a, p) for a, p in stats if p < 0.10]
    print("cells <10% transparent:", bad if bad else "none")
    print(f"despeckle total removed components: {total_removed}")
    print("salt-pepper per-action removal (px):")
    for name in MAP:
        print(f"  {name}: {sp_by_action[name]}")
    print(f"salt-pepper total removed px: {sp_total}")
    if sp_residual_total:
        _fail(f"salt-pepper residual pixels after final sweep: {sp_residual_total} (expected 0)")
    print("salt-pepper residual pixels after final sweep: 0")

    # Idle collapse (fix-002): the idle row is temporarily a single duplicated
    # frame until the user supplies new idle art.
    if len(all_frames["idle"]) != COLUMNS:
        _fail(f"idle action has {len(all_frames['idle'])} frames, expected {COLUMNS}")
    idle_frame = all_frames["idle"][args.idle_frame]
    all_frames["idle"] = [idle_frame] * COLUMNS
    print(f"idle row collapsed to idle_{args.idle_frame:03d} (temporary single-frame)")

    # Per-frame right-facing PNGs (flat layout, matching the current repo).
    for row, name in enumerate(MAP):
        for col in range(COLUMNS):
            save_image(all_frames[name][col], frames_dir / f"{name}_{col:03d}.png")

    # Composed sheets: right + mirrored left, 12 rows x 6 columns.
    sheet = Image.new("RGBA", (COLUMNS * CELL, len(MAP) * CELL), (0, 0, 0, 0))
    sheet_left = Image.new("RGBA", (COLUMNS * CELL, len(MAP) * CELL), (0, 0, 0, 0))
    for row, name in enumerate(MAP):
        for col in range(COLUMNS):
            frame = all_frames[name][col]
            sheet.paste(frame, (col * CELL, row * CELL), frame)
            flipped = frame.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
            sheet_left.paste(flipped, (col * CELL, row * CELL), flipped)

    sheet_path = save_image(sheet, player_dir / "player_sheet.png")
    left_path = save_image(sheet_left, player_dir / "player_left_sheet.png")

    right_tres = _emit_tres(project_root, sheet_path, player_dir / "player_frames.tres", RIGHT_UID, speed=10.0)
    left_tres = _emit_tres(project_root, left_path, player_dir / "player_left_frames.tres", LEFT_UID, speed=10.0)

    print("done")
    print(f"  composed sheet (right): {sheet_path}")
    print(f"  composed sheet (left):  {left_path}")
    print(f"  frames: {frames_dir}")
    print(f"  .tres (right): {right_tres}  uid={RIGHT_UID}")
    print(f"  .tres (left):  {left_tres}  uid={LEFT_UID}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
