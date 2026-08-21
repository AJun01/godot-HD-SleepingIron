# Scope: ACT Player Foundation (side-view movement + camera + animation state machine)

## Objective
Enable the player to control their character across a side-view action plane with responsive movement, jumping, and readable animation so that the rebuilt player foundation is testable in Godot and ready for future ACT combat features.

## User stories
- As a player, I want to move left and right on a side-view plane so that I can traverse the arena.
- As a player, I want to jump with responsive buffering and jump-cut so that the controls feel like a polished ACT game.
- As a player, I want the character sprite to animate through idle / run / jump / fall / land states and face my movement direction so that motion reads clearly.
- As a player, I want the camera to follow me horizontally from a locked side-view angle so that I can always see the play plane.
- As a developer, I want a bootable arena test scene so that I can validate the player foundation in-editor and headless.

## Acceptance criteria
- [ ] Pressing move_left moves the character along negative X and faces it left (sprite mirrored); move_right moves it along positive X and faces it right.
- [ ] The character moves only in the X (horizontal) and Y (vertical, via gravity/jump) plane; its Z position stays fixed on the play plane.
- [ ] move_up and move_down have no effect on the character.
- [ ] When grounded and receiving no horizontal input, the character stands still and plays the idle animation.
- [ ] The `jump` action is triggered by Space and gamepad A.
- [ ] Jumping only starts when the character is on the floor; pressing jump in the air does not produce a jump unless within the jump-buffer window.
- [ ] A jump pressed shortly before landing is buffered and fires on landing (exact window tunable).
- [ ] Releasing jump during ascent cuts the ascent short (jump-cut), producing a lower jump than a held jump.
- [ ] While grounded and moving, the run animation plays; while ascending, jump plays; while descending, fall plays.
- [ ] After landing, a one-shot land animation plays once and returns to idle.
- [ ] Facing is a horizontal mirror (flip_h) of the right-facing sheet driven by the input X sign; the separate left-facing frames are not used.
- [ ] The player renders via an AnimatedSprite3D billboard (default animation "idle"), replacing the placeholder Sprite3D.
- [ ] The arena camera is a fixed side-view: horizontal forward (no top-down look), X follows the player with framerate-independent smoothing, Y fixed near waist height (~1.2 m), Z fixed behind the play plane.
- [ ] The new arena scene (flat ground + steps) is reachable in-editor and boots headless for validation; the existing GameFlow / chapter flow is unchanged.
- [ ] Movement and jump feel are driven by tunables in PlayerConfig: move_speed 7.0, acceleration 60, friction 70, gravity 22, jump_velocity 8.5; gravity no longer lives as an @export on the player script.

## External Tools & Design Mocks
- Figma: none
- Other Tools: none

## Reference Files (Gold Standards)
- `scenes/actors/player.tscn` — current player scene; node structure rewritten in place.
- `scripts/world/player.gd` — current player script; rewritten in place, same path (references stay valid).
- `resources/player_config.tres` + `scripts/config/player_config.gd` — Gold Standard for tunables-in-Resource pattern; extend, don't replace.
- `scripts/world/camera_follow.gd` — current camera behavior; the arena's new camera is a side-view follow component (chapter cameras remain as-is).
- `scenes/dev/sprite_anim_preview.tscn` — Gold Standard for AnimatedSprite2D + SpriteFrames wiring pattern (arena uses AnimatedSprite3D billboard instead).

## Architecture constraints
- AGENTS.md rules: static typing everywhere; signals via EventBus only; composition over inheritance (animation state machine = small composable component, not a god-script); tunables in Resources; call_deferred for scene-tree mutations from physics callbacks; explicit collision layers/masks; snake_case files.
- HD-2D invariants: sprites billboard-style, 3D world carries lighting, nearest-neighbor filtering (global), original aspect ratio.
- GameFlow/SceneRouter/DialogueService/EventBus untouched.
- Godot 4.7 headless validation gates (editor import + scene smoke, gdlint clean).

## Reuse (do NOT recreate)
- `assets/sprites/player/player_frames.tres` (+ left spare) — the animation data.
- `resources/player_config.tres` — extend with new tunables.
- InputMap in `project.godot` — add `jump` action alongside existing actions.
- Existing EventBus signals (game_state_changed etc.) — no new signals needed this feature.

## Out of scope
- Combat actions: attack / hit / dodge / death animations stay unwired.
- Enemy and combat systems.
- Conversion of existing chapter scenes to the side-view camera.
- NPC replacement or repositioning.
- Usage of the separate left-facing sprite sheet.
- Camera bounds / clamping beyond simple X-follow.
- Save system.

## Unverified assumptions (RISK)
- Exact jump buffering window (e.g. 0.1 s) and jump-cut implementation details — Tech Lead decides, tunable-ize where reasonable.
- Arena ground dimensions/layout — Tech Lead proposes (flat stretch + steps); user will iterate on feel later.
- Whether `move_up`/`move_down` should later map to other ACT verbs (e.g. ladder/aim) — left unused, not removed.
- AnimatedSprite3D vertical anchor: feet-bottom anchoring so the sprite aligns with the physics body — Tech Lead must specify exact offset.

## Context
The project has switched design intent to ACT (a side-view action game), so the camera locks to a side view and sprites only need left/right facing. This feature rebuilds the player foundation for ACT — replacing the placeholder sprite and the original skeleton — and is the companion gameplay feature to the earlier `sprite-asset-pipeline` work (assets already in `assets/sprites/player/`). The goal is a testable, responsive movement + animation + camera base inside a new arena scene, without disturbing the existing chapter flow.
