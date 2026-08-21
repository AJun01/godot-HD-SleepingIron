# 001 — Vendor and build the art-pipeline processing tool

## Context files (read for understanding — do not modify)
- `.spec/sprite-asset-pipeline/intake.md` — the 12-row mapping table (Q6), the two upstream
  defects to fix while vendoring, the vendor pin (FrameRonin-MCP @ `dc31d2b`, MIT), and the
  reuse list (do NOT recreate).
- `assets/sprites/trial_gemini/character_frames.tres` — the correct Godot 4.7 `SpriteFrames`
  output shape to reproduce: raw `&"name"` StringName, `AtlasTexture` regions, per-frame
  `duration`, per-animation `speed`/`loop`.

## Reference files (STRICT STYLE MATCH)
- `/Users/aj/projects/porfolios/FrameRonin-MCP/frame_ronin_mcp/lib/godot_format.py` — upstream
  `.tres` generator being vendored; imitate its docstring/type-hint style and fix its defects.
- `/Users/aj/projects/porfolios/FrameRonin-MCP/frame_ronin_mcp/tools/gif_sprite.py` — upstream
  split/compose functions (`handle_spritesheet_split`, `handle_spritesheet_compose`) to vendor.
- `/Users/aj/projects/porfolios/FrameRonin-MCP/frame_ronin_mcp/lib/image_utils.py` — upstream
  `load_image`/`save_image`/`white_to_alpha`/resize to vendor.

## Required Skills
- None (scope.md declares no Required Skills).

## Files to create/modify (suggested)
- `tools/art_pipeline/LICENSE` — create | upstream MIT license text (verbatim).
- `tools/art_pipeline/VENDOR.md` — create | vendor record: upstream repo
  `GOODDAYDAY/FrameRonin-MCP`, pinned commit `dc31d2baf9ae32cb3faee6bf84d3456b37993cf7`
  (`dc31d2b`), MIT license, list of vendored modules and the local fixes.
- `tools/art_pipeline/image_utils.py` — create | vendored load/save/white_to_alpha/resize.
- `tools/art_pipeline/watermark.py` — create | vendored `remove_gemini_watermark` as-is.
- `tools/art_pipeline/godot_format.py` — create | vendored `.tres` generator with the two fixes.
- `tools/art_pipeline/gif_sprite.py` — create | vendored split/compose helpers.
- `tools/art_pipeline/character_sheet_map.json` — create | single editable 12-row table.
- `tools/art_pipeline/process_character_sheet.py` — create | CLI entry point wiring it all together.
- `tools/art_pipeline/README.md` — create | usage, `pip install pillow numpy`, flags.

## Description
Vendor the pure-processing core of FrameRonin-MCP into `tools/art_pipeline/` (pillow + numpy only,
Python 3.11+, no venv coupling) and add a `process_character_sheet` CLI. Reference `design.md` for
the global pipeline. This task delivers the complete tool: load → optional clean → split →
blank-skip → compose → `.tres`, plus the editable mapping table and the two template/placeholder
render modes.

While vendoring `godot_format.py`, fix the two known defects plus a correctness detail:
1. Serialize animation names as raw Godot StringNames (`"name": &"idle"`), never escaped strings
   (`"name": "&\"idle\""`).
2. Emit per-animation frame counts instead of forcing `columns` frames — the caller supplies each
   animation's list of non-blank cell columns, and only referenced cells get an `AtlasTexture`.
3. Emit a Godot-valid `uid` (lowercase `[a-z0-9]` only) or omit the uid so Godot assigns one on
   import — never emit `-`/`_` from `token_urlsafe`.

`character_sheet_map.json` is the single editable source: `cell_width`/`cell_height` (256),
`columns` (6), and an ordered `rows` array of exactly 12 `{"name", "loop", "frames"}` entries in
the intake Q6 order (`idle`, `run`, `jump`, `fall`, `land`, `attack_1`, `attack_2`, `attack_3`,
`attack_air`, `hit`, `dodge`, `death`). `frames` is authoring guidance surfaced in the run summary,
NOT a hard constraint — actual per-row counts come from blank-cell detection (fully-transparent
cells are skipped).

The CLI (`process_character_sheet.py`) supports: `--input`, `--output-dir` (defaults under
`assets/sprites/`), `--map` (defaults to the JSON), `--speed` (default 10 → 100 ms/frame),
`--remove-gemini-watermark` and `--white-to-alpha [threshold]` (opt-in), `--project-root` (to
compute the `res://` path in the `.tres`), plus `--make-template` and `--make-placeholder-sheet`
render modes. Error paths: zero non-blank cells in a row → clear error (no empty animation, no
crash); sheet dimensions not a multiple of the grid → clear error reporting expected vs actual.

## Acceptance
- [ ] `tools/art_pipeline/` contains `LICENSE` + `VENDOR.md` recording upstream
  `GOODDAYDAY/FrameRonin-MCP` @ `dc31d2baf9ae32cb3faee6bf84d3456b37993cf7` (MIT) — and does NOT
  reference the unrelated godot-aseprite SHA.
- [ ] `character_sheet_map.json` is the single editable source with exactly 12 rows in the intake
  Q6 order and per-row loop flags; cell 256; columns 6.
- [ ] Running the CLI on a valid RGBA 12×6 sheet produces per-row cleaned frame PNGs and a composed
  output sheet with blank cells skipped.
- [ ] The emitted `.tres` has exactly 12 animations named exactly as the map, raw `&"name"`
  serialization, per-row loop flags, per-row frame count = non-blank cells, and speed 10 by default.
- [ ] A row with zero non-blank cells produces a clear error (no empty animation, no crash).
- [ ] A sheet whose dimensions are not a multiple of the grid produces a clear error reporting
  expected vs actual size.
- [ ] Non-RGBA input is converted to RGBA and transparency is preserved; `--remove-gemini-watermark`
  and `--white-to-alpha` are opt-in.
- [ ] `--speed` is a per-run parameter (default 10); `--make-template` and `--make-placeholder-sheet`
  render the blank grid and a labeled placeholder sheet respectively.

## Needs tests
no

---

## Implementation log (filled by dev after successful commit)
- Commit: d14f9bb — feat(sprite-asset-pipeline): 内置 FrameRonin 素材管线处理工具并修复 Godot 输出缺陷
- Files modified:
  - tools/art_pipeline/LICENSE (created)
  - tools/art_pipeline/README.md (created)
  - tools/art_pipeline/VENDOR.md (created)
  - tools/art_pipeline/character_sheet_map.json (created)
  - tools/art_pipeline/gif_sprite.py (created)
  - tools/art_pipeline/godot_format.py (created)
  - tools/art_pipeline/image_utils.py (created)
  - tools/art_pipeline/process_character_sheet.py (created)
  - tools/art_pipeline/watermark.py (created)
- Tests added: none required
- Context & Reference files read:
  - .spec/sprite-asset-pipeline/intake.md
  - assets/sprites/trial_gemini/character_frames.tres
  - /Users/aj/projects/porfolios/FrameRonin-MCP/frame_ronin_mcp/lib/godot_format.py
  - /Users/aj/projects/porfolios/FrameRonin-MCP/frame_ronin_mcp/tools/gif_sprite.py
  - /Users/aj/projects/porfolios/FrameRonin-MCP/frame_ronin_mcp/lib/image_utils.py
- Notes: Also read upstream `frame_ronin_mcp/lib/watermark.py` (to vendor `remove_gemini_watermark`), plus `scope.md`, `design.md`, and `AGENTS.md` per role process. `godot_format.py` trimmed to the SpriteFrames generator + serialization helpers; tscn/tileset/project.godot generators omitted (out of scope). `gif_sprite.py`/`image_utils.py` trimmed to the split/compose and load/save/resize/white_to_alpha helpers named in the reuse list.
