# art_pipeline — character art → Godot SpriteFrames

Python 3.11+ tools (Pillow + NumPy only) that turn character animation art into per-action
frame PNGs, a composed sheet, and a Godot 4.7 `SpriteFrames` `.tres`. Two entry points cover
the two art sources; both read `character_sheet_map.json` (now a 13-row × 8-column grid).

## Install

```bash
pip install pillow numpy
```

## `compose_from_user_frames.py` — hand-cleaned frames (official)

This is the official pipeline for the user's hand-cleaned per-action frame folders (each action
is its own directory of PNGs, e.g. `idle/idle_000.png`, `walk/frame_000.png`). It formalizes the
previous ad-hoc rebuild: it NEAREST-resizes any non-256px frame to 256×256, writes the flat
project frames and the mirrored `frames_left` folders, composes both sheets at `columns` ×
`len(rows)` cells, and emits both `.tres` with the existing UIDs pinned. It also writes the two
composed sheets back to the user's working directory (`<src parent>/character_sheet.png` and
`character_sheet_left.png`) so `out_user/` stays in sync; opt out with `--no-write-user-sheets`.

```bash
# Process the user's hand-cleaned frames (defaults to the Desktop 素材 out_user/frames path)
python tools/art_pipeline/compose_from_user_frames.py

# Full flags
python tools/art_pipeline/compose_from_user_frames.py \
  --src "/Users/aj/Desktop/素材/art/frames-v1/out_user/frames" \
  --project-root . \
  --map tools/art_pipeline/character_sheet_map.json
```

| Flag | Description |
|---|---|
| `--src` | Directory of per-action frame subdirectories. Default: the out_user/frames path. |
| `--project-root` | Project root for output paths and `res://` computation. Default: current directory. |
| `--map` | Editable mapping table. Default: `character_sheet_map.json` next to this script. |
| `--write-user-sheets` | Write the composed sheets back to `<src parent>/character_sheet(_left).png`. Default: true; `--no-write-user-sheets` opts out. |

It fails fast when an action in the map has no frames, any frame is not square, or an action
overflows the grid width.

## `process_character_sheet.py` — pre-composed sheet (legacy)

Splits a single pre-composed character sheet (a `columns` × `rows` grid of 256px cells) into
per-row cleaned frames and a Godot `SpriteFrames`. It can also render the blank authoring
template and a labeled placeholder sheet.

```bash
# Process a character sheet (output defaults to assets/sprites/<input-stem>/)
python tools/art_pipeline/process_character_sheet.py --input sheet.png

# Full flags
python tools/art_pipeline/process_character_sheet.py \
  --input sheet.png \
  --output-dir assets/sprites/player \
  --map tools/art_pipeline/character_sheet_map.json \
  --speed 10 \
  --remove-gemini-watermark \
  --white-to-alpha 240

# Render the blank authoring template
python tools/art_pipeline/process_character_sheet.py --make-template --output-dir docs/templates

# Render a labeled placeholder sheet
python tools/art_pipeline/process_character_sheet.py --make-placeholder-sheet --output-dir assets/placeholders
```

| Flag | Description |
|---|---|
| `--input` | Input sheet PNG (columns × rows of 256px cells per the map). Required unless rendering. |
| `--output-dir` | Output directory. Default: `assets/sprites/<input-stem>/` under `--project-root`. |
| `--map` | Editable mapping table. Default: `character_sheet_map.json` next to this script. |
| `--speed` | Animation speed in fps (10 → 100 ms/frame). Default: 10. |
| `--remove-gemini-watermark` | Opt-in Gemini watermark removal. |
| `--white-to-alpha [THRESHOLD]` | Opt-in white→transparent conversion (default threshold 240). |
| `--project-root` | Project root for computing the `res://` path. Default: current directory. |
| `--make-template` | Render the blank authoring grid instead of processing a sheet. |
| `--make-placeholder-sheet` | Render a labeled placeholder sheet instead of processing a sheet. |

## Outputs

- `<output-dir>/frames/<animation>_<nnn>.png` — per-row frames (right-facing).
- `<src>/../frames_left/<animation>/<animation>_<nnn>.png` — mirrored left frames (compose script only).
- `<output-dir>/<stem>_sheet.png` — composed sheet (right-facing).
- `<output-dir>/<stem>_left_sheet.png` — mirrored sheet (compose script writes `player_left_sheet.png`).
- `<output-dir>/<stem>_frames.tres` — Godot `SpriteFrames` resource.

## Mapping table

`character_sheet_map.json` is the single editable source: `cell_width`/`cell_height` (256),
`columns` (8), and an ordered `rows` array of 13 `{"name", "loop", "frames"}` entries (idle,
walk, run, jump, fall, land, attack_1..3, attack_air, hit, dodge, death). `frames` is authoring
guidance only; the compose script derives each animation's real frame count from its directory
(walk: 8, others: 6).

## Legacy pipelines (do NOT change)

- `frames_v1_user_process.py` is the legacy checkerboard-matting pipeline. It stays on its
  12-action contract (no walk) and its own 12-row × 6-column sheet layout — do not change it;
  `compose_from_user_frames.py` supersedes it for hand-cleaned frames.

## See also

- `VENDOR.md` — upstream provenance and local fixes.
- `LICENSE` — upstream MIT license text.
- `docs/character-sprite-mapping.md` — the authoritative row/grid contract.
