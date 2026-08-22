# Verify: ACT Player Foundation (XZ depth movement + jump + camera + animation state machine)

## Status
PASS

## Acceptance criteria

### Base scope (scope.md) — superseded criteria noted
- [x] move_left → −X + face left (mirror), move_right → +X + face right — `scripts/world/player.gd:50` (`Input.get_axis("move_left","move_right")` → X), `:93-97` (`_update_facing`), mirror `scripts/world/player_animator.gd:44` (commit `fc0e2e5`, `8e6f906`)
- [x] ~~Moves only X/Y plane; Z pinned~~ **SUPERSEDED by fix-001** — XZ depth walking restored: `player.gd:49-54` reads `move_up`/`move_down` into Z, `:61-64` applies accel/friction to `velocity.z`; no `velocity.z = 0.0` remains (commit `f40bc15`)
- [x] ~~move_up/move_down have no effect~~ **SUPERSEDED by fix-001** — now `move_up` → −Z (deeper), `move_down` → +Z (toward camera); diagonal normalized via `.limit_length(1.0)` at `player.gd:54` (commit `f40bc15`)
- [x] Grounded + no input → idle — `scripts/world/player_animator.gd:70-77` (commit `8e6f906`)
- [x] `jump` triggered by Space + gamepad A — `project.godot:57` (keycode 32 = Space; button_index 0 = Joypad A) (commit `fc0e2e5`)
- [x] Jump only on floor; air press inert unless within buffer window — `player.gd:74-81` (`_consume_jump_buffer`) (commit `fc0e2e5`)
- [x] Buffered press fires on landing (`jump_buffer_time` = 0.1) — `player.gd:78` (commit `fc0e2e5`)
- [x] Jump-cut shortens ascent on early release — `player.gd:84-90` (`_apply_jump_cut`) (commit `fc0e2e5`)
- [x] run (grounded moving) / jump (ascending) / fall (descending) — `player_animator.gd:70-80` (commit `8e6f906`)
- [x] land plays once then returns to idle — `player_animator.gd:89-97` (commit `8e6f906`)
- [x] Facing is `flip_h` mirror of right sheet; left sheet unused — `player_animator.gd:44`; `scenes/actors/player.tscn:4` references only `player_frames.tres` (commit `8e6f906`)
- [x] Renders via AnimatedSprite3D billboard, default "idle" — `scenes/actors/player.tscn:19-25` (billboard=1, centered, pixel_size=0.01, offset (0, 0.28, 0)) (commit `8e6f906`)
- [x] Arena camera = fixed side-view (X-follow smoothing, Y≈1.2, Z fixed behind plane, horizontal forward) — `scripts/world/side_view_camera.gd:37-46` (commit `a4af8a0`; docstring updated in `f40bc15`)
- [x] New arena boots headless; GameFlow / chapter flow unchanged — `scenes/act/arena.tscn` (commit `6fd2e02`, rebuilt `f40bc15`); no GameFlow/SceneRouter/DialogueService/EventBus/chapter `.tscn` touched by feature commits
- [x] Tunables in PlayerConfig (7.0 / 60 / 70 / 22 / 8.5); no gravity `@export` on script — `resources/player_config.tres`, `scripts/config/player_config.gd` (commit `fc0e2e5`)

### fix-001 — Restore XZ depth walking + 3D arena (commit `f40bc15`)
- [x] `gdlint .` → 0 problems
- [x] `godot --headless --editor --path . --quit-after 10` clean (no ERROR / SCRIPT ERROR / Parse Error / Failed loading)
- [x] Arena / player / chapter_home smokes clean
- [x] REGRESSION: `move_up` → −Z, `move_down` → +Z; ∓X unchanged; all four axes simultaneous with no diagonal speed-up (`limit_length(1.0)`); `velocity.z` no longer pinned — `player.gd:44-64`
- [x] Jump still Y-only (Space / A) with buffer + jump-cut unchanged — `player.gd:67-90`
- [x] Facing flips only on X input sign; pure-Z movement does not flip — `player.gd:93-97`
- [x] `run` plays on any horizontal direction (XZ speed, not `velocity.x` only) — `player_animator.gd:75`
- [x] Arena ground is a 3D walkable floor (24×1×16, top Y=0) with steps at distinct Z (StepLow top≈0.5 @ Z=−4, StepHigh top≈1.0 @ Z=+3); player spawns Z=0 — `scenes/act/arena.tscn:47-96`
- [x] Camera keeps identity rotation (side view), follows X only, Y=1.2 fixed, Z=12 fixed (`z_distance` behind the +8 walkable edge; never follows Z) — `side_view_camera.gd:21-22,37-46`, `arena.tscn:91-96`
- [x] `project.godot` `run/main_scene` = `res://scenes/boot.tscn`; no stray `.import` flag change committed — `project.godot:14`
- [x] `docs/sdd/artifacts/act-player-foundation.yml` describes XZ walking + 3D arena (no "Z pinned" wording) — registry lines 5-31

### fix-002 — Despeckle + idle collapse + vendored pipeline (commit `67de694`)
- [x] REGRESSION (black specks): vendored `tools/art_pipeline/frames_v1_user_process.py` implements the despeckle rule (`area < 25` AND `perimeter_transparent_fraction >= 0.5` → clear); self-check removed 110 components, 0 residual matching the rule; Vision QC accepted by Orchestrator
- [x] REGRESSION (idle jitter): idle row collapsed to one frame — `idle_000..idle_005.png` are byte-identical (sha256 `059f33b0…`)
- [x] `player_frames.tres` / `player_left_frames.tres` keep UIDs `uid://2k97uge7sf4w` / `uid://a2tle527t5pf`, 12 animations × 6 frames, correct loop flags (idle/run/fall loop=true, rest false); `player.tscn` resolves them
- [x] Sheets are 1536×3072 RGBA, feet aligned to cell bottom, blank cells transparent, nearest-neighbor preserved
- [x] Headless editor import clean (regenerates `.import` sidecars)
- [x] `scenes/actors/player.tscn` + `scenes/dev/sprite_anim_preview.tscn` smoke clean
- [x] Script reproducible: `python tools/art_pipeline/frames_v1_user_process.py --src <dir> --project-root .` (Pillow + NumPy; syntax-checked, despeckle/idle-collapse/UID-pin logic present)
- [x] Registry registers regenerated sprite assets + marks idle row as temporary single-frame collapse — registry lines 40-73
- [x] Vision QC not self-certified by developer; deferred to (and passed by) Orchestrator

## Tests
- Command: `uvx --from gdtoolkit gdlint .`
- Result: `Success: no problems found` (0 problems)
- Command: `godot --headless --editor --path . --quit-after 10`
- Result: clean — no `ERROR` / `SCRIPT ERROR` / `Parse Error` / `Failed loading`
- Command: headless scene smokes (`--quit-after 5`) for `scenes/boot.tscn`, `scenes/act/arena.tscn`, `scenes/actors/player.tscn`, `scenes/world/chapter_home.tscn`, `scenes/dev/sprite_anim_preview.tscn`
- Result: all 5 clean — no errors

## Developer log integrity
- Tasks with filled Implementation log: 6 / 6 (4 base + fix-001 + fix-002)
- Commit/file mismatches: 0 — fix-001 `f40bc15` = 5 files (matches log); fix-002 `67de694` = 76 files (72 frame PNGs grouped as "all 72" + 2 sheets + script + yml, matches log); base commits fc0e2e5=4, 8e6f906=3, a4af8a0=2, 6fd2e02=2
- Tasks missing Implementation log: 0
- Context/Reference read lists: complete for all 6 tasks; all declared files exist in-repo (no hallucination)
- fix-002 note: `.tres` files re-emitted byte-identically (UIDs/structure preserved), so git reports no change — consistent with the "keep UIDs/structure" acceptance criterion

## Convention compliance (AGENTS.md / CLAUDE.md)
- Static typing everywhere (#1): HONORED — all vars/params/returns typed
- Signals for decoupling, no `get_node("../../...")` (#2): HONORED — `landed` signal + `@export` Node/NodePath injection
- Composition over inheritance (#3): HONORED — animator + camera are small composable components
- Tunables in Resource files (#4): HONORED — PlayerConfig holds all movement/jump values
- `call_deferred` for physics-callback tree mutation (#5): HONORED — `landed` handler only flips a flag; state applied in `_process`
- Explicit collision layers/masks (#6): HONORED — player layer 2/mask 1; world layer 1/mask 2 (arena + player)
- snake_case files / PascalCase nodes (#7): HONORED
- HD-2D billboard + world lighting invariants: HONORED — billboard=1 sprite; arena carries WorldEnvironment + DirectionalLight3D
- Conventional-commit messages: HONORED — 4 `feat` + 2 `fix` commits, all scoped `act-player-foundation`

## Docs updated
- `docs/sdd/artifacts/act-player-foundation.yml` — updated (fix-001: XZ walking + 3D arena; fix-002: regenerated sprite assets + temporary idle collapse). No AGENTS.md change required.

## PR
- Target branch: master
- Pushed: yes
- PR URL: https://github.com/AJun01/godot-HD-SleepingIron/pull/33
- Reason (if FAIL or n/a): n/a
