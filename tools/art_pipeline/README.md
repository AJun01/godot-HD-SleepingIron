# art_pipeline — character art → Godot SpriteFrames

Python 3.11+ tools (Pillow + NumPy only) that turn character animation art into per-action
frame PNGs, a composed sheet, and a Godot 4.7 `SpriteFrames` `.tres`. Two entry points cover
the two art sources; both read `character_sheet_map.json` (now a `sets` structure: `alert`
16 columns, `non_alert` 8 columns).

## Install

```bash
pip install pillow numpy
```

## `compose_from_user_frames.py` — hand-cleaned frames (official)

This is the official pipeline for the user's hand-cleaned per-action frame folders, now split
into two sets (`<src>/alert/<action>/` and `<src>/non_alert/<action>/`). It center-crops any
non-square frame by the shorter side, then NEAREST-resizes every frame to 256×256; per-animation
`loop`/`speed` come from the map row (`from` resolves an alternative source action, `columns`
slices its frames). For each set it writes the flat project frames under
`frames/<set>/`, the mirrored `frames_left/<set>/<action>/` folders, the set's sheet at
`columns` × `len(rows)` cells, and the set's `.tres` with the map's pinned uid. It also writes
both composed sheets back to the user's working directory (`<src parent>/character_sheet.png`
for alert and `character_sheet_nonalert.png` for non_alert); opt out with
`--no-write-user-sheets`.

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

It fails fast when an action in the map has no frames, any frame is not PNG, or an action
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

- `<output-dir>/frames/<set>/<animation>_<nnn>.png` — per-set per-row frames (right-facing).
- `<src>/../frames_left/<set>/<animation>/<animation>_<nnn>.png` — mirrored left frames (compose script only).
- `assets/sprites/player/player_sheet.png` / `player_sheet_nonalert.png` — composed sheets (right-facing).
- `assets/sprites/player/player_frames.tres` / `player_frames_nonalert.tres` — Godot `SpriteFrames` resources.

## Mapping table

`character_sheet_map.json` is the single editable source: `cell_width`/`cell_height` (256) and a
`sets` object with one entry per animation set. Each set has `columns` (16 for alert, 8 for
non_alert), `sheet`/`tres` output paths, a pinned `uid`, and an ordered `rows` array of
`{"name", "loop", "speed", "from"?, "columns"?}` entries. `from` (default `name`) resolves the
source action directory; `columns` (default all) slices its frame list, letting `jump`/`land`/
`fall` share the `jump` source in the alert set and `fall` reuse `land` in the non_alert set.

## Legacy pipelines (do NOT change)

- `frames_v1_user_process.py` is the legacy checkerboard-matting pipeline. It stays on its
  12-action contract (no walk) and its own 12-row × 6-column sheet layout — do not change it;
  `compose_from_user_frames.py` supersedes it for hand-cleaned frames.

## See also

- `VENDOR.md` — upstream provenance and local fixes.
- `LICENSE` — upstream MIT license text.
- `docs/character-sprite-mapping.md` — the authoritative row/grid contract.
