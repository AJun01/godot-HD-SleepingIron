# Design: ACT Player Foundation (side-view movement + camera + animation state machine)

## Existing conventions honored
- Source of truth: AGENTS.md (no CLAUDE.md at the repo root).
- Language & framework: GDScript on Godot 4.7 stable (Forward Plus, Jolt Physics); artifacts written in English.
- Folder structure pattern: `scripts/` grouped by domain (world/, config/, autoload/, dev/); `scenes/` grouped by area (actors/, world/, dev/, ui/); `resources/` holds `.tres` tunables.
- Naming conventions: snake_case files, PascalCase nodes/classes, `class_name` only for globally-registered classes (AGENTS.md GDScript rule #7).
- State / data-flow pattern: tunables live in Resource files; decoupling via `@export` dependency injection and signals; never `get_node("../../...")`.
- Testing setup: none declared (no unit-test tool). Validation = `gdlint` + Godot headless smoke (AGENTS.md "Validation").
- Specific rules being honored:
  - AGENTS.md "GDScript rules": static typing everywhere (#1); composition over inheritance (#3); tunables in Resources (#4); `call_deferred` for scene-tree mutations from physics callbacks (#5); explicit collision layers/masks (#6).
  - AGENTS.md "HD-2D visual invariants": billboarded sprites; 3D world scene carries lighting; nearest-neighbor filtering; original aspect ratio.
  - AGENTS.md "Architecture law": modular, composable, EventBus at coupling boundaries (no new EventBus signals needed this feature).
  - godot-sdd skill: headless validation gates + non-code artifact registry.

## Technical approach
The player character is rebuilt in place as a CharacterBody3D living on the X–Y play plane: horizontal velocity is applied on X only, gravity and jumping act on Y, and Z is pinned to the play plane. All movement and jump-feel numbers come from an extended PlayerConfig resource, with gravity promoted out of the old `@export`. Jumping uses a short input buffer plus a jump-cut so a tap produces a short hop and a hold produces a full jump. A separate composable animator component reads the player's physics state and drives a billboarded AnimatedSprite3D through a five-state machine (idle/run/jump/fall/land) with flip_h facing. A new arena scene carries its own side-view follow camera (X-follow only, fixed Y and Z) and a flat-ground-plus-steps layout, so the foundation is testable in-editor and headless without touching GameFlow, chapter scenes, EventBus, DialogueService, or NPCs.

## Modules / components touched
- PlayerConfig — extended Resource holding move/jump/gravity tunables (gravity promoted from `@export` to Resource).
- Player — CharacterBody3D rewritten in place: X–Y plane movement, jump buffering + jump-cut, facing, landing signal.
- PlayerAnimator — new composable five-state animation machine driving the AnimatedSprite3D.
- AnimatedSprite3D — billboarded player rendering, replacing the placeholder Sprite3D.
- SideViewCamera — arena-owned Camera3D with X-follow smoothing and fixed Y/Z.
- Arena scene — standalone test scene (lighting + ground + steps + player + camera).
- InputMap — new `jump` action.

## Patterns / abstractions
- Reuse the Resource-tunables pattern (PlayerConfig) and the `@export` Node + NodePath defensive-resolution follow pattern already used by the existing camera-follow component.
- The animation state machine is one new small composable component (Node3D) with a one-way dependency on the player; no new abstraction or inheritance beyond that.
- The player gains `class_name Player` so the animator can hold a statically-typed reference (AGENTS.md rule #1).

## Trade-offs
- Chose a one-way dependency (animator reads the player; the player never references the animator) over two-way wiring, keeping the player physics-only and the state machine replaceable.
- Chose fixed absolute camera Y (1.2 m) and Z (10 m behind the play plane) over tracking the player's Y, per scope's "Y fixed / Z fixed"; low arena steps keep the player in frame.
- Chose feet-bottom anchoring with `centered = true` so flip_h mirrors in place without horizontally shifting the character; the exact pixel_size/offset is recorded in the animator task.

## Out of scope (technical)
- Combat animations (attack_1/2/3, attack_air, hit, dodge, death) stay unwired.
- Conversion of chapter scenes to the side-view camera; chapter `.tscn` files and their camera-follow component are untouched.
- Camera bounds/clamping beyond simple X-follow; save system; enemy/combat systems.
- The separate left-facing sprite sheet remains a spare; not used.
- No `ui_cancel` quit handling in the arena; no GameFlow/SceneRouter changes.

## Gaps for human attention
- Rewriting the player scene/script in place means the four chapter scenes that instance it now receive an ACT player locked to the X–Y plane at Z=0. Their Z-laid-out NPCs/interactables become unreachable under the old top-down chapter camera until a later feature converts chapters. This is the intended intermediate state per scope ("chapter conversion out of scope"), but it is a visible behavioral change to chapters even though no chapter `.tscn` file is edited.
