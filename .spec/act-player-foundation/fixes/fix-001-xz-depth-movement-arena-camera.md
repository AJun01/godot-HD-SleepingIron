# fix-001 — Restore XZ depth walking + rebuild arena as 3D walkable ground

## Context files (read for understanding — do not modify)
- AGENTS.md — GDScript rules (static typing, composition, `call_deferred`, explicit collision layers/masks), HD-2D billboard invariants
- scripts/world/player.gd — offending commit `fc0e2e5`; the X–Y pinning (`velocity.z = 0.0`, X-only `_read_horizontal_input`) to reverse
- scripts/world/player_animator.gd — run detection reads `player.velocity.x` only; must become horizontal (XZ) speed
- scenes/act/arena.tscn — offending commit `6fd2e02`; the 2D ground strip (Z depth 4) to rebuild as a 3D walkable floor
- scripts/world/side_view_camera.gd — the follow decision to record (X-follow only, never Z)

## Reference files (STRICT STYLE MATCH)
- scripts/world/camera_follow.gd — Gold Standard follow-component structure (`@export` target + NodePath fallback + exponential smoothing)
- scenes/world/chapter_home.tscn — Gold Standard 3D scene structure (WorldEnvironment + DirectionalLight3D + StaticBody3D ground with explicit layers)
- AGENTS.md — GDScript law + "3D world carries lighting" invariant as the Gold Standard

## Required Skills
- godot-sdd (headless validation; typed GDScript, CharacterBody3D, Camera3D and scene conventions)

## Files to create/modify (suggested)
- scripts/world/player.gd — modify (reverse the Z-lock: read move_up/move_down as Z, apply accel/friction on X and Z, keep gravity/jump on Y + buffer/jump-cut)
- scripts/world/player_animator.gd — modify (run state keyed on horizontal XZ speed, not `velocity.x` only)
- scripts/world/side_view_camera.gd — modify (docstring/comment only — record "camera follows X only, never Z"; no logic change)
- scenes/act/arena.tscn — modify (rebuild as a 3D walkable ground: wide X×Z floor + step/platform obstacles at distinct Z; camera `z_distance` behind the depth range)
- docs/sdd/artifacts/act-player-foundation.yml — modify (update player/arena/camera invariants to XZ walking + 3D arena)

## Description
**Failing acceptance criteria (verbatim playtest intent — authoritative):**

> 1. "HD2D ACT不是类似闯关那种，是可以带上下走的3D场景（这个还是继续参考歧路旅人环境）" — the game is NOT a 2D-plane stage-clearer; it is a 3D scene where the player can also walk up/down in DEPTH (Z), like Octopath Traveler. The camera keeps its locked side-view orientation and sprites stay left/right-facing, but movement must restore XZ walking (move_up/move_down → depth) IN ADDITION to jump (Y).

This **reverses** the original scope acceptance criteria *"The character moves only in the X (horizontal) and Y (vertical, via gravity/jump) plane; its Z position stays fixed on the play plane"* and *"move_up and move_down have no effect on the character"*. `design.md` remains the record of design; only the Z-lock decision is reversed.

Concrete decisions (do not deviate):
1. **Input → motion.** Read `move_left`/`move_right` into X and `move_up`/`move_down` into Z. Mapping: `move_up` → −Z (walk deeper into the scene, away from the camera), `move_down` → +Z (walk toward the camera). Normalize the 2D input vector with `.limit_length(1.0)` so diagonal movement is not √2 faster. Replace `_read_horizontal_input()` with a `Vector2`-returning read gated by the same `DialogueService.is_open()` lock, and apply `move_toward` acceleration/friction to `velocity.x` AND `velocity.z` (both reuse `move_speed`/`acceleration`/`friction`). **Delete `velocity.z = 0.0`** and its "constrain to X–Y plane" comment.
2. **Jump unchanged.** Gravity and jump keep acting on Y only; jump buffering and jump-cut are preserved exactly as-is. No new `PlayerConfig` tunables are required.
3. **Facing stays X-driven.** `_update_facing` keeps reading the X sign only (+1 right / −1 left); moving purely in Z does not flip the sprite (sprites remain left/right-facing billboards per the playtest).
4. **Camera decision (X-follow only).** The camera keeps its locked side-view orientation (identity rotation, horizontal forward) and follows the player **horizontally (X only)**, with Y fixed (`vertical_offset` 1.2) and Z fixed (`z_distance`). It does **NOT** follow Z: following Z would zoom the whole scene as the player walks in depth and destabilize framing. Depth is instead expressed by the player's own Z position under the fixed perspective camera (the Octopath depth cue). `side_view_camera.gd` needs **no logic change** — only update its docstring to state the "never follows Z" decision. In the arena, set `z_distance` so the camera sits behind the deepest walkable Z.
5. **Animator.** `_desired_state()` returns `run` when the horizontal speed `Vector2(velocity.x, velocity.z)` is non-zero (not `velocity.x != 0.0`), so walking purely in depth also plays `run`.
6. **Arena rebuild.** Replace the 2D strip with a 3D walkable ground: a floor box spanning meaningful X and Z depth (top at Y = 0), plus at least two step/platform obstacles placed at **distinct Z** (tops ≈ Y = 0.5 and ≈ Y = 1.0, within jump reach) so depth walking is collidable and testable. Player spawns on the floor at Z within the walkable range. Every physics body keeps explicit collision layers/masks (world = layer 1 / mask 2, player = layer 2 / mask 1). Do not change GameFlow, SceneRouter, DialogueService, EventBus, or any chapter `.tscn`.
7. **Restore boot flow.** The working tree contains stray uncommitted edits from the playtest: `project.godot` (`run/main_scene` → `res://scenes/act/arena.tscn`) and `assets/sprites/player/player_sheet.png.import` (s3tc/vram/mipmap flags). Revert both (`git checkout -- project.godot assets/sprites/player/player_sheet.png.import`) before committing, so `main_scene` returns to `res://scenes/boot.tscn` and the arena stays reachable in-editor only. The `.import` file is regenerated by the headless import pass (and by fix-002's asset regeneration).
8. **Registry.** Update `docs/sdd/artifacts/act-player-foundation.yml` so the player and arena invariants describe XZ walking and the 3D arena (no longer "Z pinned to the play plane").

## Acceptance
- [ ] `gdlint .` reports 0 problems.
- [ ] `godot --headless --editor --path . --quit-after 10` is clean (no ERROR / SCRIPT ERROR / Parse Error / Failed loading).
- [ ] `godot --headless --path . --quit-after 5 scenes/act/arena.tscn` is clean; `scenes/actors/player.tscn` and `scenes/world/chapter_home.tscn` also smoke clean.
- [ ] REGRESSION (reverses the old Z-lock): `move_up` moves the player along −Z and `move_down` along +Z; `move_left`/`move_right` still move along ∓X; all four axes work simultaneously with no diagonal speed-up. `velocity.z` is no longer pinned.
- [ ] Jump still acts on Y only (Space / gamepad A), with jump-buffer and jump-cut behaving exactly as before (regression unchanged).
- [ ] Facing still flips only on the X input sign; moving purely in Z does not flip the sprite.
- [ ] `run` animation plays when moving in any horizontal direction (X or Z), not only along X.
- [ ] Arena ground is a 3D walkable floor with Z depth; the player can walk up/down in depth and collides with step/platform obstacles at distinct Z.
- [ ] Camera keeps identity rotation (side view), follows X only, Y ≈ 1.2 fixed and Z fixed at `z_distance` behind the walkable depth range (never follows Z).
- [ ] `project.godot` `run/main_scene` is `res://scenes/boot.tscn` (boot flow restored; no stray `.import` flag change is committed).
- [ ] `docs/sdd/artifacts/act-player-foundation.yml` describes XZ walking + 3D arena invariants (no "Z pinned to the play plane" wording remains).

## Needs tests
no

---

## Implementation log (filled by dev after successful commit)
- Commit: f40bc15 — fix(act-player-foundation): 恢复 XZ 深度行走并重建竞技场为 3D 可行走地面
- Files modified:
  - scripts/world/player.gd (modified)
  - scripts/world/player_animator.gd (modified)
  - scripts/world/side_view_camera.gd (modified)
  - scenes/act/arena.tscn (modified)
  - docs/sdd/artifacts/act-player-foundation.yml (modified)
- Tests added: none required
- Context & Reference files read:
  - AGENTS.md
  - scripts/world/player.gd
  - scripts/world/player_animator.gd
  - scenes/act/arena.tscn
  - scripts/world/side_view_camera.gd
  - scripts/world/camera_follow.gd
  - scenes/world/chapter_home.tscn
- Notes: Reverted the stray playtest edits to `project.godot` (`run/main_scene` → arena) and `assets/sprites/player/player_sheet.png.import` per the task; both confirmed reverted and excluded from the commit (headless import pass did not re-dirty them). Arena `z_distance` set to 12.0 (behind the +8 walkable Z edge) rather than the script default 10.0. No files touched outside the suggested list.
