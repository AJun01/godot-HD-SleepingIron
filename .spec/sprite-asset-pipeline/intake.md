# Intake: Character Sprite Asset Pipeline

## PR target branch
master

## Raw prompt
"我桌面有个素材文件夹，里面有个art然后有个Gemini_Generated_Image_lwrm64lwrm64lwrm。你帮我基于这个跑MCP，直接产出角色动画素材到godot里面，这一个任务比较大，先跑一次这个管线试试效果，然后走specs开发"

Follow-up direction from the user (verbatim intent, translated to English):
- Trial run of the FrameRonin MCP pipeline on the Gemini image (DONE before this feature — trial artifacts committed as chore).
- Game target: 2.5D side-scrolling ACT (横版 ACT) with HD-2D scenes (Octopath-style). Only left/right-facing actions needed.
- Define the sprite-sheet mapping convention FIRST, prepare assets manually, automate generation later once the pipeline matures.
- This feature = the asset pipeline itself. ACT gameplay (movement/animation state machine) is a SEPARATE future feature.

## Clarifications (Q&A)

### Q1 — Feature behavior (scope): what is in this feature?
**Recommended:** pipeline only: mapping doc + blank template + processing tool (FrameRonin vendor + bug fixes + per-row frame counts) + Godot .tres output + dev preview scene + validation. ACT gameplay is a separate feature.
**User answered:** 只做素材管线本体 (pipeline only, as recommended).

### Q2 — Architecture fit: how does FrameRonin code enter the project?
**Recommended:** vendor-copy the needed MIT core into a new `tools/art_pipeline/` dir (LICENSE + upstream commit recorded), fix known bugs locally, self-contained and CI-runnable. Upstream clone stays untouched for research/generation backends.
**User answered:** vendor 拷贝进项目 (as recommended).

### Q3 — Trial artifacts fate:
**Recommended:** copy source jpeg + pre-split 16 frames into `tools/art_pipeline/testdata/` as pinned fixtures; the throwaway project files (`assets/sprites/trial_gemini/`, `scenes/trial_gemini_anim.tscn`) get replaced by this feature's outputs and then removed.
**User answered:** 转为 testdata 夹具 (as recommended).

### Q4 — Reference files (Gold Standard):
**User answered:** confirm BOTH `scenes/actors/player.tscn` (Sprite3D billboard + collision shape integration shape) and `scenes/trial_gemini_anim.tscn` (AnimatedSprite2D dev-preview pattern).

### Q5 — Dependency scope of the vendored tool:
**Recommended:** vendor the pure-processing path only (white→alpha, Gemini watermark removal, split/compose, resize, SpriteFrames .tres generation). Runtime deps = pillow + numpy only. rembg/OpenCV/pixelate paths stay in the external FrameRonin for manual use.
**User answered:** 仅 pillow+numpy (as recommended).

### Q6 — Character sheet mapping convention (agreed BEFORE intake):
- 12 rows, fixed row order = action dictionary. Right-facing only; left = `AnimatedSprite2D.flip_h` mirror.
- Cell size 256×256, power-of-two, feet aligned to cell bottom; max 6 columns per row; short actions pad with fully-blank cells.
- Frame duration default 100 ms per frame (Godot animation speed 10).
- Aseprite tag name = row name = Godot animation name.

| Row | Animation | Frames | Loop |
|---|---|---|---|
| 0 | idle | 4 | yes |
| 1 | run | 6 | yes |
| 2 | jump | 3 | no |
| 3 | fall | 3 | yes |
| 4 | land | 2 | no |
| 5 | attack_1 | 4 | no |
| 6 | attack_2 | 4 | no |
| 7 | attack_3 | 6 | no |
| 8 | attack_air | 4 | no |
| 9 | hit | 3 | no |
| 10 | dodge | 6 | no |
| 11 | death | 6 | no |

### Q7 — Git state handling (before branch creation):
**User answered:** commit all dirty-tree items as a chore on the previous branch (DONE — `chore(assets): FrameRonin 管线试运行产物与导入元数据`), then branch `feature/sprite-asset-pipeline` (DONE, clean).

## Confirmed feature behavior

- **Inputs:** a character sheet PNG laid out per the 12×6 mapping above (RGBA, any of the 12 rows may be shorter than 6 frames via blank cells). Fixtures: `tools/art_pipeline/testdata/` (Gemini jpeg + pre-split frames, copied from `~/Desktop/素材/art/`).
- **Outputs:**
  - `docs/character-sprite-mapping.md` — the mapping spec (English, design reference).
  - `docs/templates/character-sheet-template.png` — blank 12×6 grid template (3072×1536, 256 px cells, faint grid lines + row labels) for manual art / AI generation guidance.
  - `tools/art_pipeline/` — vendored processing tool (Python, pillow+numpy only): `process_character_sheet` → per-row cleaned frames → composed sheet → Godot `SpriteFrames` .tres with the 12 animations, per-row actual frame counts (blank cells skipped), animation names exactly as the table above, loop flags, speed 10.
  - A dev preview scene (AnimatedSprite2D pattern per `scenes/trial_gemini_anim.tscn`) that plays any produced .tres, e.g. `scenes/dev/sprite_anim_preview.tscn`.
- **Edge cases handled:** blank padding cells skipped per row; zero-frame row → clear error; sheet size not a multiple of the expected grid → clear error with expected/actual; non-RGBA input → converted; transparency preserved; loop vs one-shot flags per row.
- **Out of scope (explicit):** ACT gameplay state machine / movement rewrite (separate feature); hitbox window data Resources (separate feature); AI generation backends (manual art first); rembg/OpenCV/pixelate paths; Aseprite importer changes; left-facing sheet variants.

## Reference Files (confirmed by user)
- `scenes/actors/player.tscn` — Gold Standard for runtime sprite integration shape (Sprite3D billboard + collision).
- `scenes/trial_gemini_anim.tscn` — Gold Standard for dev preview scene pattern (AnimatedSprite2D + SpriteFrames).

## Architecture constraints (confirmed)
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

## Unverified assumptions (RISK)
- The 12-row order/frame counts above are agreed but not yet validated against real art; the pipeline must treat the table as data (a single editable source) so the user can adjust rows/frames without code changes.
- Frame duration 100 ms is a default, not a rule; speed must be a per-run parameter.
- Aseprite-side workflow (tags per row) is documented in the mapping doc but not automated in this feature.
