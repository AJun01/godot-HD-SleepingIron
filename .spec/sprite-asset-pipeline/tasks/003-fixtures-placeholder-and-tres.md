# 003 — Pin fixtures, produce placeholder sheet + real .tres, clean trial

## Context files (read for understanding — do not modify)
- `tools/art_pipeline/process_character_sheet.py` and `tools/art_pipeline/README.md` — the CLI
  flags and output layout to run.
- `~/Desktop/素材/art/Gemini_Generated_Image_lwrm64lwrm64lwrm.jpeg` and the sibling
  `Gemini_Generated_Image_lwrm64lwrm64lwrm_frames/` (16 pre-split `frame_*.png`) — the trial source
  to pin as fixtures.
- `assets/sprites/trial_gemini/character_frames.tres`, `assets/sprites/trial_gemini/character_sheet.png`,
  `assets/sprites/trial_gemini/character_sheet.png.import`, `scenes/trial_gemini_anim.tscn` — the
  throwaway trial artifacts to replace/remove.
- `.spec/sprite-asset-pipeline/intake.md` (Q3) — fixture copying + trial-artifact fate.

## Reference files (STRICT STYLE MATCH)
- `assets/sprites/trial_gemini/character_frames.tres` — the `.tres` format the new output must
  reproduce/supersede (raw `&"name"`, `AtlasTexture` regions).

## Required Skills
- None (scope.md declares no Required Skills).

## Files to create/modify (suggested)
- `tools/art_pipeline/testdata/gemini_source.jpeg` — create | pinned source fixture.
- `tools/art_pipeline/testdata/gemini_frames/frame_000.png` … `frame_015.png` — create | pinned
  pre-split frames (16).
- `assets/placeholders/placeholder_character_sheet.png` — create | placeholder 12×6 sheet via
  `--make-placeholder-sheet` (status: placeholder).
- `assets/sprites/placeholder_character/character_sheet.png` — create | tool composed output sheet.
- `assets/sprites/placeholder_character/character_frames.tres` — create | tool `.tres` (12 animations).
- `assets/sprites/trial_gemini/` (all files) — delete | superseded throwaway trial output.
- `scenes/trial_gemini_anim.tscn` — delete | superseded by the Task 004 preview scene.

## Description
Produce the feature's real, Godot-loadable output and retire the throwaway trial artifacts.
Reference `design.md` for the global pattern. This is the end-to-end validation task.

First pin the Gemini fixtures into `tools/art_pipeline/testdata/` (source jpeg + 16 pre-split
frames) and run the cleaning path
(`--remove-gemini-watermark --white-to-alpha`) on the source to confirm the vendored cleaning
reproduces the trial's 16 clean frames + a 4×4 composed sheet.

Then generate a placeholder 12×6 sheet (`--make-placeholder-sheet`) into
`assets/placeholders/` — flat-color, labeled cells, some rows intentionally blank-padded — and run
the full pipeline on it into `assets/sprites/placeholder_character/`. This produces the composed
sheet and the 12-animation `.tres` (correct names/loop, per-row counts = non-blank cells, speed 10).
Commit the generated `.import` for the new sheet (it is tracked per `godot-sdd`).

Finally delete the throwaway trial artifacts. Validate headless from the project root and grep for
`ERROR:` / `SCRIPT ERROR` / `Parse Error` / `Failed loading` (any match = FAIL).

## Acceptance
- [ ] `tools/art_pipeline/testdata/` pins the Gemini jpeg + 16 frames; the cleaning run reproduces
  16 clean frames + a 4×4 composed sheet.
- [ ] `assets/placeholders/placeholder_character_sheet.png` is a 12×6 labeled sheet with some rows
  blank-padded, registered as `status: placeholder`.
- [ ] Running the tool on it emits `character_frames.tres` with exactly 12 animations (correct names
  and loop flags), per-row frame counts equal to non-blank cells, speed 10.
- [ ] The produced `.tres` loads in Godot 4.7 headless with no `ERROR:`/`SCRIPT ERROR`/`Parse
  Error`/`Failed loading`.
- [ ] `assets/sprites/trial_gemini/` and `scenes/trial_gemini_anim.tscn` are removed and no
  remaining scene/resource references them.
- [ ] `gdlint .` is clean and the headless editor + boot scene smoke runs are clean (AGENTS.md gates).

## Needs tests
no

---

## Implementation log (filled by dev after successful commit)
- Commit: 2fc95eabf35e4827fb50c89a3704ae72d0f293e0 — feat(sprite-asset-pipeline): 固定夹具并生成占位角色精灵表与 .tres，清理试运行产物
- Files modified:
  - assets/placeholders/placeholder_character_sheet.png (created)
  - assets/placeholders/placeholder_character_sheet.png.import (created)
  - assets/sprites/placeholder_character/character_sheet.png (created)
  - assets/sprites/placeholder_character/character_sheet.png.import (created)
  - assets/sprites/placeholder_character/character_frames.tres (created)
  - docs/sdd/artifacts/sprite-asset-pipeline.yml (created)
  - tools/art_pipeline/testdata/gemini_source.jpeg (created)
  - tools/art_pipeline/testdata/gemini_frames/frame_000.png … frame_015.png (created, 16 files)
  - assets/sprites/trial_gemini/character_frames.tres (deleted)
  - assets/sprites/trial_gemini/character_sheet.png (deleted)
  - assets/sprites/trial_gemini/character_sheet.png.import (deleted)
  - scenes/trial_gemini_anim.tscn (deleted)
- Tests added: none required
- Context & Reference files read:
  - tools/art_pipeline/process_character_sheet.py
  - tools/art_pipeline/README.md
  - ~/Desktop/素材/art/Gemini_Generated_Image_lwrm64lwrm64lwrm.jpeg
  - ~/Desktop/素材/art/Gemini_Generated_Image_lwrm64lwrm64lwrm_frames/ (16 frame_*.png)
  - assets/sprites/trial_gemini/character_frames.tres
  - assets/sprites/trial_gemini/character_sheet.png
  - assets/sprites/trial_gemini/character_sheet.png.import
  - scenes/trial_gemini_anim.tscn
  - .spec/sprite-asset-pipeline/intake.md
- Notes:
  - Cleaning confirmation: vendored `remove_gemini_watermark` + `white_to_alpha(240)` on the pinned source reproduced 16 clean frames + a 1024×1024 composed sheet matching the trial sheet (mean pixel diff 0.128; the bottom-right cell is a blank/watermark cell that correctly becomes transparent).
  - The placeholder sheet is emitted by `--make-placeholder-sheet` as `character-sheet-placeholder.png`; renamed to `placeholder_character_sheet.png` to honor AGENTS.md placeholder naming.
  - The CLI names outputs `{input-stem}_sheet.png`/`{input-stem}_frames.tres`, so the placeholder was fed via a temporary `character.png` copy to emit the task-required `character_sheet.png`/`character_frames.tres`.
  - The run's intermediate per-row `frames/` directory (51 PNGs) is not a task deliverable (the `.tres` references the composed sheet via AtlasTexture regions) and was removed before commit.
  - Godot also auto-imports `tools/art_pipeline/testdata/` (17 `.import` files) and `docs/templates/character-sheet-template.png.import`; these are tool fixtures/template, not game assets, so their `.import` files are left untracked (consistent with the already-untracked template `.import`).
  - `docs/sdd/artifacts/sprite-asset-pipeline.yml` added (outside the suggested list) to register the placeholder as `status: placeholder` and the produced sheet/`.tres`, per the godot-sdd artifact-registry convention.
  - Additional files read for style/verification: design.md, scope.md, tool modules (godot_format.py, image_utils.py, watermark.py, gif_sprite.py, character_sheet_map.json), existing artifact registries (game-skeleton.yml, chapter-1-demo.yml), and the godot-sdd skill.
