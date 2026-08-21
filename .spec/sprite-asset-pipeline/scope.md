# Scope: Character Sprite Asset Pipeline

## Objective
Enable the developer/artist to turn a single character-sheet PNG into Godot-ready sprite animation assets so that character animation content for the HD-2D game can be produced repeatably without manual frame splitting.

## User stories
- As an artist, I want a documented sprite-sheet mapping convention so that I can lay out and prepare character art that the pipeline accepts.
- As an artist, I want a blank character-sheet template so that I can draw or generate art that conforms to the grid.
- As a developer, I want a processing tool that converts a character sheet into cleaned frames and a Godot SpriteFrames asset so that I can import animations into Godot.
- As a developer, I want a dev preview scene that plays any produced SpriteFrames asset so that I can visually verify the generated animations.

## Acceptance criteria
- [ ] Returns `docs/character-sprite-mapping.md` documenting the 12-row × max-6-column mapping, the exact 12 animation names, per-row loop flags, 256×256 cell size, feet-aligned-to-cell-bottom, blank-cell padding, and 100 ms default frame duration.
- [ ] Produces `docs/templates/character-sheet-template.png` sized 3072×1536 (12×6 grid of 256 px cells) with faint grid lines and row labels.
- [ ] Running the tool on a valid RGBA character sheet produces per-row cleaned frames and a composed output sheet.
- [ ] Emits a Godot SpriteFrames `.tres` containing exactly the 12 animations, named exactly as the mapping table, with per-row loop flags and animation speed 10.
- [ ] Blank padding cells are skipped per row, so each animation's frame count equals that row's actual non-blank frame count.
- [ ] A row with zero frames produces a clear error rather than an empty animation or a crash.
- [ ] A sheet whose dimensions are not a multiple of the expected grid produces a clear error reporting expected vs actual size.
- [ ] Non-RGBA input is converted to RGBA and transparency is preserved through the whole pipeline.
- [ ] The dev preview scene `scenes/dev/sprite_anim_preview.tscn` loads and plays any produced `.tres` (AnimatedSprite2D pattern).
- [ ] The produced `.tres` loads cleanly in Godot 4.7 headless (no `ERROR:`/`SCRIPT ERROR`/`Parse Error`/`Failed loading`).

## External Tools & Design Mocks
- Figma: none
- Other Tools: none

## Reference Files (Gold Standards)
- `scenes/actors/player.tscn` — Gold Standard for runtime sprite integration shape (Sprite3D billboard + collision).
- `scenes/trial_gemini_anim.tscn` — Gold Standard for dev preview scene pattern (AnimatedSprite2D + SpriteFrames).

## Architecture constraints
- Vendored tool lives in a NEW top-level dir `tools/art_pipeline/` (AGENTS.md does not list it; it is tooling, not engine code — user owns AGENTS.md and may add a line later; feature must not require it).
- Python tool: pillow + numpy only, Python 3.11+ (CI ubuntu python 3.11; local 3.14). No venv coupling to the external FrameRonin clone.
- Vendor record: include upstream MIT LICENSE text and the pinned upstream commit SHA (`b0433ce516dc05631f6e2b388fdb980317b9eba1` of `lucacicada/godot-aseprite` is UNRELATED — do not confuse; FrameRonin-MCP upstream = `github.com/GOODDAYDAY/FrameRonin-MCP` @ `dc31d2b`).
- Godot invariants: nearest-neighbor filtering (already global), original aspect ratio, art stays out of code, tunables in Resources.
- The .tres output must load in Godot 4.7 headless (AGENTS.md gates: `gdlint .` clean — vendored Python is exempt, headless editor + boot scene smoke clean).

## Reuse (do NOT recreate)
- Vendor from external `FrameRonin-MCP` clone (at `/Users/aj/projects/porfolios/FrameRonin-MCP`, MIT): `lib/image_utils.py` (`white_to_alpha`, load/save/resize), `lib/watermark.py` (`remove_gemini_watermark`), `tools/gif_sprite.py` (`handle_spritesheet_split`, `handle_spritesheet_compose`), `lib/godot_format.py` (`generate_sprite_frames_tres` + its helpers).
- Known upstream defects to FIX while vendoring:
  1. `generate_sprite_frames_tres` serializes animation names as escaped strings (`"name": "&\"walk\""`) → Godot cannot find the animation. Must emit raw `"name": &"walk"`.
  2. All animations are forced to `columns` frames (blank cells included). Must support per-animation frame counts (skip blank cells), driven by the row table above.
  3. (Upstream meta-bug, N/A after vendoring: `mcp>=1.0.0` unpinned breaks with mcp 2.x — only affects the MCP server, not the vendored libs.)

## Out of scope
- ACT gameplay state machine / movement rewrite (separate feature).
- Hitbox window data Resources (separate feature).
- AI generation backends (manual art first).
- rembg/OpenCV/pixelate processing paths.
- Aseprite importer changes.
- Left-facing sheet variants (left-facing is handled by `flip_h` mirroring).

## Unverified assumptions (RISK)
- The 12-row order/frame counts above are agreed but not yet validated against real art; the pipeline must treat the table as data (a single editable source) so the user can adjust rows/frames without code changes.
- Frame duration 100 ms is a default, not a rule; speed must be a per-run parameter.
- Aseprite-side workflow (tags per row) is documented in the mapping doc but not automated in this feature.

## Context
The project is a 2.5D side-scrolling ACT with HD-2D scenes that needs a repeatable way to get character animation frames into Godot. Today, character art is prepared manually and split by hand, which is error-prone and does not scale across the roster. This feature establishes the asset pipeline itself — mapping convention, blank template, processing tool, and preview scene — so that future ACT gameplay work can consume reliably generated animation assets. It is intentionally a trial-run feature: build the pipeline once, validate it against the existing Gemini test asset, and mature automation later.
