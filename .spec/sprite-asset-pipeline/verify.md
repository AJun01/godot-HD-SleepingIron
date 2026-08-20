# Verify: Character Sprite Asset Pipeline

## Status
PASS

## Acceptance criteria
- [x] `docs/character-sprite-mapping.md` documents the 12-row × max-6-column mapping, exact 12 animation names, per-row loop flags, 256×256 cell size, feet-aligned-to-cell-bottom, blank-cell padding, and 100 ms default frame duration — `docs/character-sprite-mapping.md` §2 (grid), §3 (cell invariants), §4 (mapping table); commit `817b4c6`.
- [x] `docs/templates/character-sheet-template.png` is a blank 12×6 grid of 256 px cells with faint grid lines and row labels — file exists, measured 1536×3072 RGBA (PIL); regenerated via `--make-template` in smoke test; commit `817b4c6`.
- [x] Running the tool on a valid RGBA sheet produces per-row cleaned frames and a composed output sheet — smoke `process-valid-sheet` passed (exit 0, emitted `*_frames.tres` + `*_sheet.png`); commit `d14f9bb`.
- [x] Emits a SpriteFrames `.tres` with exactly the 12 animations, named exactly as the map, per-row loop flags, and speed 10 — `assets/sprites/placeholder_character/character_frames.tres` verified programmatically (12 animations in map order, every per-anim frames/loop/speed correct, `"speed": 10` ×12); commit `2fc95ea`.
- [x] Blank padding cells are skipped per row — per-row frame counts in the `.tres` equal the row's non-blank cell count (51 frames / 51 AtlasTextures, matching the map's `frames` hints); commit `2fc95ea`.
- [x] A row with zero non-blank frames produces a clear error — smoke `zero-frame-row-error` returned exit 1 with `Error: Row 1 (run) has zero non-blank cells — refusing to emit an empty animation`; `tools/art_pipeline/process_character_sheet.py:197-198`; commit `d14f9bb`.
- [x] A sheet whose dimensions are not a multiple of the grid produces a clear error reporting expected vs actual — smoke `wrong-dim-error` returned exit 1 with `Error: Sheet size mismatch: expected 1536x3072 (6 cols x 12 rows of 256x256), got 100x100`; `process_character_sheet.py:57-64`; commit `d14f9bb`.
- [x] Non-RGBA input is converted to RGBA and transparency is preserved — `image_utils.py:32` `img.convert("RGBA")`; smoke `non-rgba-to-rgba` fed a mode-`RGB` PNG and processed cleanly; commit `d14f9bb`.
- [x] `scenes/dev/sprite_anim_preview.tscn` loads and plays the produced `.tres` (AnimatedSprite2D pattern) — headless run printed `[sprite_anim_preview] idle (flip_h=false)` (defaults to `idle`, `playing = true`); commit `8ce3467`.
- [x] The produced `.tres` loads cleanly in Godot 4.7 headless — strict import pass, boot smoke, and preview-scene smoke all grep-clean for `ERROR:`/`SCRIPT ERROR`/`Parse Error`/`Failed loading`; commits `2fc95ea`, `8ce3467`.

## Tests
- Project has tests: no (per `tasks.index.md`) — no test command to run.
- AGENTS.md validation gates:
  - `gdlint .` (GDToolkit 4.5.0) → `Success: no problems found` (exit 0). Vendored `tools/art_pipeline/` is Python and exempt per scope.md.
  - `godot --headless --editor --path . --quit-after 60` (strict, warm cache) → clean (exit 0, no ERROR/SCRIPT ERROR/Parse Error/Failed loading).
  - `godot --headless --path . --quit-after 10 scenes/boot.tscn` → clean.
  - `godot --headless --path . --quit-after 10 scenes/dev/sprite_anim_preview.tscn` → clean, printed the preview state line.
- Python tool smoke (Pillow 12.3.0 + NumPy 2.5.2, Python 3.12 venv): 9/9 checks passed — `--make-template` (1536×3072), `--make-placeholder-sheet` (1536×3072), valid-sheet process, 12 names in order, speed 10, raw `&"name"` StringName, zero-frame-row error, wrong-dimension error, non-RGBA→RGBA.

## Developer log integrity
- Tasks with filled Implementation log: 4 / 4
- Commit/file mismatches: 0 — `d14f9bb` (9 files), `817b4c6` (2 files), `2fc95ea` (created/deleted as logged), `8ce3467` (4 files) all match their logged lists.
  - Note (non-blocking): in `2fc95ea`, git recorded `assets/sprites/trial_gemini/character_sheet.png.import` as a rename (R071) into `assets/sprites/placeholder_character/character_sheet.png.import` rather than a delete+add pair; the net effect exactly matches the log (trial `.import` removed, placeholder `.import` added).
- Tasks missing Implementation log: 0
- Context & Reference files read: complete for all 4 tasks — every declared Context/Reference file appears in each task's read list; no claimed repo file is missing (external `~/Desktop` and `/Users/aj/projects/porfolios/FrameRonin-MCP/...` paths are declared reference locations, not repo files).

## Convention compliance (AGENTS.md / CLAUDE.md)
- Static typing everywhere: HONORED — `scripts/dev/sprite_anim_preview.gd` is fully typed (`Array[StringName]`, `int`, `AnimatedSprite2D`, typed `@onready`, typed params/returns).
- Signals for decoupling, no `get_node("../../...")`: HONORED — dev scene is self-contained (no EventBus needed); uses `$AnimatedSprite2D`.
- Composition over inheritance: HONORED — no new class hierarchy.
- Tunables in Resource/@export: HONORED for the pipeline (the 12-row table is data in `character_sheet_map.json`; `--speed` is a per-run parameter). The dev preview script hardcodes the 12 animation names in a `const` because `SpriteFrames.get_animation_names()` returns hash order (non-blocking, dev-only, documented in the script).
- `call_deferred`: n/a — no physics/signal tree mutation.
- Explicit collision layers/masks: n/a — dev preview is a Node2D, no physics bodies.
- Naming (`snake_case` files, `PascalCase` nodes/classes): HONORED.
- Comments explain "why": HONORED — docstrings explain the hash-order and self-containment rationale.
- Conventional commits, one per task: HONORED — 3 `feat:` + 1 `docs:` (Chinese, matching the user's language).
- HD-2D invariants (nearest-neighbor, aspect ratio, transparency): HONORED — pipeline copies cells verbatim (no resampling); nearest-neighbor is the project-wide default.
- Placeholder policy: HONORED — `assets/placeholders/placeholder_character_sheet.png` is a generated flat-color labeled sheet registered `status: placeholder` in the artifact registry.

## Architecture fidelity
- Vendoring matches scope "Reuse": `image_utils.py`, `watermark.py`, `godot_format.py`, `gif_sprite.py` vendored with the two defects fixed (raw `&"name"` StringName; per-animation frame counts) plus a valid lowercase-alnum uid generator — `tools/art_pipeline/godot_format.py` and `VENDOR.md`.
- Single editable source: `tools/art_pipeline/character_sheet_map.json` holds exactly 12 rows in intake Q6 order with loop flags; the tool derives grid + rows from it (no hardcoded table in code) — satisfies scope RISK "treat the table as data".
- No engine-code changes beyond the dev preview scene; out-of-scope items (gameplay state machine, hitbox data, rembg/OpenCV, Aseprite importer changes) untouched.
- Artifact registry `docs/sdd/artifacts/sprite-asset-pipeline.yml` registers every non-code artifact with type/role/invariants/validation, placeholder marked `status: placeholder`.

## Docs updated
- `docs/character-sprite-mapping.md` — new mapping contract (supersedes Route A assumptions).
- `docs/templates/character-sheet-template.png` — new blank authoring template.
- `docs/sdd/artifacts/sprite-asset-pipeline.yml` — new artifact registry.
- No AGENTS.md change required (scope explicitly leaves the `tools/` directory line to the human owner).

## Advisory (non-blocking)
- **Template dimension wording.** scope.md criterion 2 writes the template size as "3072×1536"; the 12-row × 6-column grid of 256 px cells is 6 columns wide × 12 rows tall = **1536×3072**. The implementation (and `design.md` "Gaps for human attention") uses 1536×3072, and the tool derives dimensions from the JSON map, so either orientation works. Recorded per the scope/design note; no action required.
- **Branch base carries 5 pre-existing commits.** `feature/sprite-asset-pipeline` was branched from the stale local `feature/chapter-1-demo` tip, so the PR against `master` additionally includes 2 unmerged chapter-1-demo fixes (`2f8efdd`, `41d3c49` — camera + 4K/Retina) and 3 sprite-pipeline setup/trial commits (`af1cb2a` docs/art, `ef173c2` Aseprite addon, `616cd3d` FrameRonin trial artifacts). All are already on `origin` feature branches; none touch this feature's acceptance surface. The human merging should be aware the PR carries them.
- **Vendored `gif_sprite.py` split/compose is not the code path used.** The CLI's `_process_sheet` performs an integrated split/blank-skip/compose loop rather than calling the vendored `handle_spritesheet_split`/`handle_spritesheet_compose`. The vendored functions are present per the scope reuse list but are currently unexercised by the CLI (non-blocking; blank-skip is the new behavior that the generic helpers do not express).

## PR
- Target branch: master
- Pushed: yes
- PR URL: https://github.com/AJun01/godot-HD-SleepingIron/pull/28
