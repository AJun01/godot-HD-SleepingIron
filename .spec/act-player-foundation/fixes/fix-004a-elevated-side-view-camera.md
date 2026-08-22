# fix-004a — Raise camera to DNF-style elevated side view (height + downward pitch)

## Context files (read for understanding — do not modify)
- scripts/world/side_view_camera.gd — offending commit `a4af8a0`; `vertical_offset = 1.2` (waist height) and identity rotation (horizontal-forward, no downward pitch), which is what the user reports as "too low"
- scenes/act/arena.tscn — the `SideViewCamera` node serializes `vertical_offset = 1.2` / `z_distance = 12.0` (lines 91-96); this override beats the script default, so it must be updated too
- docs/sdd/artifacts/act-player-foundation.yml — registry lines 17, 26-32 record the camera as "Y≈1.2 … horizontal forward … identity rotation"; these must be updated to match

## Reference files (STRICT STYLE MATCH)
- scripts/world/camera_follow.gd — Gold Standard typed `@export` + docstring + `_ready`/`_physics_process` shape (imitate the *structure*; do NOT copy its `look_at` — the side view stays a constant direction)
- scripts/config/player_config.gd — Gold Standard typed `@export` tunable with a "why" docstring
- AGENTS.md — GDScript law (#1 static typing everywhere, #4 tunables in `@export`) as the Gold Standard

## Required Skills
- godot-sdd (headless validation; typed GDScript conventions)

## Files to create/modify (suggested)
- scripts/world/side_view_camera.gd — modify (raise `vertical_offset` default to 5.5, add `@export pitch_degrees`, set a constant `rotation.x`, update the stale "waist-height / rotation never touched" comments)
- scenes/act/arena.tscn — modify (serialize `vertical_offset = 5.5` and `pitch_degrees = -25.0` on the SideViewCamera node)
- docs/sdd/artifacts/act-player-foundation.yml — modify (update the arena camera + `side_view_camera.gd` invariants to describe the elevated pitched view)

## Description
**Failing acceptance criterion (verbatim playtest intent — authoritative):**

> 1. "arena 3D场景倒是改过来了，但是摄像机角度太低了，参考DNF的高度" — the camera is too low. Reference DNF (Dungeon & Fighter)'s camera framing: an ELEVATED side view looking down at the action, not a waist-height horizontal shot.

The current camera (commit `a4af8a0`) pins `vertical_offset = 1.2` and never touches rotation, so it shoots horizontally forward from waist height. Fix by raising the camera and tilting it down, while keeping the locked side-view orientation (constant view direction, no per-frame `look_at`), X-follow smoothing, and fixed Z.

Concrete decisions (do not deviate):

1. **Raise the height.** Change the `vertical_offset` export default from `1.2` to `5.5` (within the report's 5.0–6.0 range), and rewrite its docstring from "waist-height side view" to something like "elevated DNF-style side view, looking down at the action". Keep it an exported tunable so the user can iterate.
2. **Add an exported downward pitch.** Insert a new typed export after `follow_speed`, exact text (tabs, `##` docstring matching the existing style):
   ```
   ## Downward pitch of the camera in degrees (negative = look down). DNF-style
   ## elevated side view: the camera sits high above the play plane and tilts
   ## down at the action instead of shooting horizontally at waist height.
   @export var pitch_degrees: float = -25.0
   ```
3. **Apply the pitch as a constant orientation, not a `look_at`.** In `_physics_process`, immediately after `global_position = Vector3(smoothed_x, vertical_offset, z_distance)`, assign:
   ```
   	rotation = Vector3(deg_to_rad(pitch_degrees), 0.0, 0.0)
   ```
   `rotation.y` and `rotation.z` stay `0.0` (side view, horizontal forward in the X–Z plane). The value is constant every frame — no `look_at`, no smoothing, no dependence on the target. Do NOT add `look_at` (that would break the locked side-view framing). Replace the stale `# Rotation is never touched: the camera keeps identity rotation and looks horizontally forward (-Z)…` comment to describe the new constant DNF pitch.
4. **Update the class docstring** (top of `side_view_camera.gd`) which still says the camera "looks horizontally forward (-Z)" with no mention of pitch — reflect the elevated downward pitch and the DNF reference.
5. **Update the scene override.** In `scenes/act/arena.tscn` change `vertical_offset = 1.2` (line 95) to `vertical_offset = 5.5` and add `pitch_degrees = -25.0` on the `SideViewCamera` node. `z_distance = 12.0` stays (fixed Z is preserved). The baked `transform` position/rotation is overwritten by the script each frame, so no transform edit is required.
6. **Update the registry.** In `docs/sdd/artifacts/act-player-foundation.yml`, the arena invariant (line 17, "camera is a fixed side view (X-follow, Y≈1.2 … horizontal forward)") and the `side_view_camera.gd` invariants (lines 30-31, "vertical_offset 1.2 … identity rotation (horizontal forward)") must describe the elevated height (~5.5) and constant downward pitch (~-25°).

**Working-tree hygiene.** The headless editor import on this machine re-flips `assets/sprites/player/player_sheet.png.import` to lossy s3tc VRAM (`compress/mode=2`, `mipmaps/generate=true`). Revert any such `.import` change before committing (`git checkout -- assets/sprites/player/player_sheet.png.import`) so the pixel-art nearest-neighbor invariant (AGENTS.md "no resampling") is preserved. Commit only the three files above.

## Acceptance
- [ ] REGRESSION (camera too low): the camera's world Y equals `vertical_offset` (≥ 5.0, default 5.5) and `rotation` = `Vector3(deg_to_rad(pitch_degrees), 0, 0)` with `pitch_degrees` default `-25.0` — an elevated view pitched ~25° down at the action; `rotation.y`/`rotation.z` remain 0 and there is no `look_at` call (constant locked side view).
- [ ] `vertical_offset` (default 5.5) and `pitch_degrees` (default -25.0) are statically-typed `@export var`s with "why" docstrings referencing the DNF elevated angle (AGENTS.md rules #1 + #4).
- [ ] X-follow exponential smoothing and fixed Z are unchanged (`z_distance` untouched; no Z following; no change to the smoothing math).
- [ ] `scenes/act/arena.tscn` serializes `vertical_offset = 5.5` and `pitch_degrees = -25.0` on the SideViewCamera node; the scene loads and the camera frames at the new height/pitch.
- [ ] Stale comments ("waist-height", "identity rotation / horizontal forward", "Rotation is never touched") are updated to describe the elevated pitched DNF view.
- [ ] `gdlint .` reports 0 problems.
- [ ] `godot --headless --editor --path . --quit-after 10` is clean (no ERROR / SCRIPT ERROR / Parse Error / Failed loading).
- [ ] `godot --headless --path . --quit-after 5 scenes/act/arena.tscn` (and `scenes/actors/player.tscn`) smoke clean.
- [ ] `docs/sdd/artifacts/act-player-foundation.yml` no longer claims waist-height / identity-rotation framing; it records the elevated (~5.5) height and constant (~-25°) downward pitch.
- [ ] Commit contains only `scripts/world/side_view_camera.gd`, `scenes/act/arena.tscn`, and the registry yml; any stray `player_sheet.png.import` change is reverted.

## Needs tests
no

---

## Implementation log (filled by dev after successful commit)
- Commit: dc906ef — fix(act-player-foundation): 抬高摄像机为 DNF 式高视角（高度 + 下俯角）
- Files modified:
  - scripts/world/side_view_camera.gd (modified)
  - scenes/act/arena.tscn (modified)
  - docs/sdd/artifacts/act-player-foundation.yml (modified)
- Tests added: none required
- Context & Reference files read:
  - scripts/world/side_view_camera.gd
  - scenes/act/arena.tscn
  - docs/sdd/artifacts/act-player-foundation.yml
  - scripts/world/camera_follow.gd
  - scripts/config/player_config.gd
  - AGENTS.md
- Notes: project.godot was already modified in the working tree before this task (run/main_scene=arena) and was left untouched/uncommitted. assets/sprites/player/player_sheet.png.import was re-flipped by the headless editor import and reverted before commit per the task's working-tree hygiene note. tasks.index.md Fixes table has no Status column (prior fix rows are committed by the Verifier), so no status edit was made. gdlint was run via `uvx --python 3.11 --from gdtoolkit==4.* gdlint .` (local gdlint binary not installed).
