# Character Sprite Mapping — Contract

- **Status:** active — authoritative mapping for the character sprite asset pipeline
- **Date:** 2026-08-20
- **Supersedes:** `docs/art/sprite-pipeline-technical-spec.md` (Route A: 3D → 2D bake) mapping
  assumptions — 64 px body, 4-direction, 8 fps, `idle`/`walk` only. Those are retired by this
  document; the pipeline and the authoring template both follow the contract below.
- **Rationale:** character animation art is authored as a single sprite sheet whose rows map to
  named animations. A fixed, documented grid lets artists lay out art and lets the
  `tools/art_pipeline/process_character_sheet.py` tool split and import it without manual frame
  cutting.

This document is the **contract** both ends must satisfy:

1. **Authoring side** (human artist): how to lay out and label a character sheet.
2. **Pipeline side** (the vendored tool): how the sheet is split into per-animation frames and a
   Godot `SpriteFrames` resource.

## 1. Single editable source

The mapping is **data, not prose**. The authoritative definition lives in
`tools/art_pipeline/character_sheet_map.json` — one ordered JSON table of the 12 rows plus the grid
constants. The tool reads that file directly, so changing a row name, its loop flag, or the authoring
`frames` hint never requires a code change or a doc edit. The table below is a human-readable
reproduction of that file; if the two ever disagree, the JSON is correct.

```json
{
  "cell_width": 256,
  "cell_height": 256,
  "columns": 6,
  "rows": [
    {"name": "idle",      "loop": true,  "frames": 4},
    {"name": "run",       "loop": true,  "frames": 6},
    {"name": "jump",      "loop": false, "frames": 3},
    {"name": "fall",      "loop": true,  "frames": 3},
    {"name": "land",      "loop": false, "frames": 2},
    {"name": "attack_1",  "loop": false, "frames": 4},
    {"name": "attack_2",  "loop": false, "frames": 4},
    {"name": "attack_3",  "loop": false, "frames": 6},
    {"name": "attack_air", "loop": false, "frames": 4},
    {"name": "hit",       "loop": false, "frames": 3},
    {"name": "dodge",     "loop": false, "frames": 6},
    {"name": "death",     "loop": false, "frames": 6}
  ]
}
```

## 2. Grid geometry

| property | value | notes |
|---|---|---|
| cell size | **256 × 256 px** | square; every cell is exactly this size |
| columns | **6** | max 6 frames per animation (see blank-cell padding, §3) |
| rows | **12** | one row per animation, top-to-bottom in map order |
| sheet size | **1536 × 3072 px** | 6 columns wide × 12 rows tall |
| orientation | rows = animations (vertical), columns = frames (horizontal) | row 0 is the top row |
| format | RGBA PNG, transparent background | no baked backdrop color |

### Orientation note

Scope acceptance criterion 2 writes the template size as "3072×1536", but a 12-row × 6-column grid
of 256 px cells is 6 columns wide × 12 rows tall = **1536 × 3072** (12 rows down, 6 columns across).
This contract — and the tool, which derives dimensions from the JSON map — assumes the vertical
12-row orientation. Flag for the human if a landscape orientation was intended.

## 3. Cell invariants

- **Feet aligned to the cell bottom.** Each frame's ground contact sits on the bottom edge of its
  256 px cell, with the character anchored to the ground-center of the cell horizontally. This keeps
  every frame of an animation vertically registered so frames do not "bob" when played.
- **Blank-cell padding.** Rows with fewer than 6 frames are padded to the right with
  **fully transparent** cells. The tool detects these by zero alpha and skips them, so the actual
  frame count of an animation is its number of non-blank cells — never a hard 6.
- **Frame duration default 100 ms.** The tool's `--speed 10` (fps) produces a default of
  100 ms per frame. This is a default, not a rule: `--speed` is a per-run parameter.
- **No resampling.** Cells keep their source pixel resolution and aspect ratio; the pipeline copies
  them verbatim (nearest-neighbor). Do not pre-scale or pad the art.

## 4. Mapping table (reproduction for readers)

| row | name | loop | `frames` hint | meaning |
|---:|---|---|:--:|---|
| 0 | `idle` | yes | 4 | standing breath |
| 1 | `run` | yes | 6 | run cycle |
| 2 | `jump` | no | 3 | jump rise (one-shot) |
| 3 | `fall` | yes | 3 | falling/airborne |
| 4 | `land` | no | 2 | landing recovery (one-shot) |
| 5 | `attack_1` | no | 4 | basic attack, chain 1 |
| 6 | `attack_2` | no | 4 | basic attack, chain 2 |
| 7 | `attack_3` | no | 6 | basic attack, chain 3 (finisher) |
| 8 | `attack_air` | no | 4 | air attack |
| 9 | `hit` | no | 3 | hurt reaction (one-shot) |
| 10 | `dodge` | no | 6 | dodge/dash |
| 11 | `death` | no | 6 | death (one-shot, hold last frame) |

- `loop` is the per-row playback flag written into the generated `SpriteFrames`. `yes` = looped
  animation, `no` = one-shot.
- `frames` is **authoring guidance only** — the number of cells to fill in that row. The pipeline
  derives the real count from blank-cell detection, so an artist may fill fewer cells and the row
  still imports correctly.

## 5. Aseprite-side workflow (guidance only)

For artists authoring in Aseprite, the recommended workflow keeps the sheet and the mapping in lock
step:

1. Create one **tag** per animation row, named exactly as the map (`idle`, `run`, `jump`, …).
2. Each tag covers that animation's frames in one strip; export the strip to its row in the sheet
   with feet aligned to the cell bottom and blank cells left transparent.
3. The tag name = animation name is the link that keeps the Aseprite source consistent with the JSON
   map.

This workflow is **documented only** — it is not automated in this feature. Aseprite importer
changes and tag-driven import are out of scope; the pipeline consumes the exported sheet grid, not
Aseprite files directly.

## 6. Regenerating the blank template

The authoring template is generated by the tool, never hand-drawn:

```bash
python tools/art_pipeline/process_character_sheet.py --make-template --output-dir docs/templates
```

It emits `docs/templates/character-sheet-template.png` — a 1536 × 3072 grid with faint cell lines
and one row label per animation (`name (frames, loop|once)`). Any change to the JSON map is reflected
by re-running this command.

## 7. Related documents

- `tools/art_pipeline/character_sheet_map.json` — single editable source (this doc mirrors it).
- `tools/art_pipeline/README.md` — CLI usage and flags.
- `docs/art/sprite-pipeline-technical-spec.md` — superseded Route A proposal; kept for history only.
