# art_pipeline — character sheet → Godot SpriteFrames

Python 3.11+ tool (Pillow + NumPy only) that converts a 12-row character sheet into per-row
cleaned frame PNGs, a composed sheet, and a Godot 4.7 `SpriteFrames` `.tres`. It can also
render the blank authoring template and a labeled placeholder sheet.

## Install

```bash
pip install pillow numpy
```

## Usage

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

## Flags

| Flag | Description |
|---|---|
| `--input` | Input sheet PNG (12 rows × 6 columns of 256 px cells). Required unless rendering. |
| `--output-dir` | Output directory. Default: `assets/sprites/<input-stem>/` under `--project-root`. |
| `--map` | Editable mapping table. Default: `character_sheet_map.json` next to this script. |
| `--speed` | Animation speed in fps (10 → 100 ms/frame). Default: 10. |
| `--remove-gemini-watermark` | Opt-in Gemini watermark removal. |
| `--white-to-alpha [THRESHOLD]` | Opt-in white→transparent conversion (default threshold 240). |
| `--project-root` | Project root for computing the `res://` path. Default: current directory. |
| `--make-template` | Render the blank authoring grid instead of processing a sheet. |
| `--make-placeholder-sheet` | Render a labeled placeholder sheet instead of processing a sheet. |

## Outputs (normal mode)

- `<output-dir>/frames/<animation>_<nnn>.png` — per-row cleaned frames (blank cells skipped).
- `<output-dir>/<stem>_sheet.png` — composed sheet (blank cells transparent).
- `<output-dir>/<stem>_frames.tres` — Godot `SpriteFrames` resource.

## Mapping table

`character_sheet_map.json` is the single editable source: `cell_width`/`cell_height` (256),
`columns` (6), and an ordered `rows` array of exactly 12 `{"name", "loop", "frames"}` entries.
`frames` is authoring guidance only; the actual per-animation frame count is derived from
blank-cell detection (fully transparent cells are skipped).

## See also

- `VENDOR.md` — upstream provenance and local fixes.
- `LICENSE` — upstream MIT license text.
