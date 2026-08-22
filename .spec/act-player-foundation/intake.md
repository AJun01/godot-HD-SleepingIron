# Intake: ACT Player Foundation (side-view movement + camera + animation state machine)

## PR target branch
master

## Raw prompt
"我们现在开始整合到godot里面，替换原有的占位符测试一下了" — followed by a scope correction from the user: the design intent has already switched to ACT (side-view action game). That is why the sprite assets only cover left/right facing (no 8-direction), and the camera view should be locked side-view. Much of the original skeleton must be replaced. This feature rebuilds the player foundation for ACT; it is the companion gameplay feature to the earlier `sprite-asset-pipeline` feature (assets already in `assets/sprites/player/`).

## Clarifications (Q&A)

### Q1 — Play plane & test scene: where does the ACT test run?
**Recommended:** a NEW act test arena scene (flat ground + a few steps); existing chapter scenes are NOT converted this feature (their NPC interactables are laid out along Z and become unreachable under a locked side-view camera).
**User answered:** 新建 ACT 测试场 (as recommended).

### Q2 — Jump input:
**Recommended:** new `jump` InputMap action (Space + gamepad A); move_left/right drive horizontal movement; move_up/down left unused (not removed).
**User answered:** 新增 jump 动作 (as recommended).

### Q3 — Animation state machine scope:
**Recommended:** wire idle / run / jump / fall / land only; attack_1/2/3, attack_air, hit, dodge, death stay unwired until a combat feature exists. SM must be extensible (composition-friendly).
**User answered:** 五态基础 (as recommended).

### Q4 — Facing:
**Recommended:** right sheet + `flip_h` mirror; `player_left_frames.tres` kept as a spare for future asymmetric actions.
**User answered:** flip_h 镜像 (as recommended).

### Q5 — Git logistics before branching:
**User answered:** chore commit dirty tree, then branch. DONE: chore commits made; branch `feature/act-player-foundation` created and clean.

### Q6 — Camera scheme:
**Recommended:** the new arena scene carries its own Camera3D — perspective projection (HD-2D look kept), X-axis follows the player, Y fixed at the player's waist height (~1.2 m), Z fixed 10 m behind the play plane, horizontal forward (no more top-down look_at). Billboarded sprites face it automatically. Existing chapter-scene cameras (camera_follow.gd) untouched this feature.
**User answered:** 侧视锁定 X 跟随 (as recommended).

### Q7 — Movement feel tunables (all in PlayerConfig Resource):
**Recommended:** move_speed 7.0 / acceleration 60 / friction 70 / gravity 22 / jump_velocity 8.5. gravity moves from @export into the Resource. Include jump buffering and jump-cut (release shortens ascent) — ACT feel conventions; exact implementation left to the Tech Lead.
**User answered:** 推荐参数 (as recommended).

### Q8 — Preserved items:
**User answered:** confirm — DialogueService input lock, EventBus, GameFlow, SceneRouter, NPC placeholders, scenes/dev/sprite_anim_preview.tscn untouched; player.gd rewritten in place (references unchanged).

## Confirmed feature behavior

- **Inputs:** move_left/move_right (horizontal), new `jump` action (Space + gamepad A). move_up/move_down unused.
- **Movement:** CharacterBody3D on a 2D play plane — X horizontal, Y vertical (gravity + jump), Z fixed. `is_on_floor()` gates jumping; jump buffering + jump-cut implemented.
- **Animations (SpriteFrames `assets/sprites/player/player_frames.tres`):** idle (no input, grounded), run (moving, grounded), jump (ascending), fall (descending), land (just landed, one-shot → idle). Facing via AnimatedSprite3D.flip_h from input x sign.
- **Rendering:** replace placeholder `Sprite3D` with `AnimatedSprite3D` (billboard = 1), animation "idle" default.
- **Camera:** arena-owned Camera3D, perspective, X-follow, fixed Y≈1.2 m, fixed Z behind play plane, horizontal forward, framerate-independent smoothing.
- **Test scene:** new arena scene (flat ground + steps), reachable in-editor (and bootable headless for validation); GameFlow/chapter flow untouched.
- **Tunables:** PlayerConfig resource gains jump_velocity + gravity (gravity removed from @export); existing move_speed/acceleration/friction retuned (7.0/60/70).
- **Out of scope (explicit):** combat actions (attack/hit/dodge/death animations stay unwired), enemy/combat systems, chapter-scene conversion, NPC replacement, left-sheet usage, camera bounds/clamping beyond simple X-follow, save system.

## Reference Files (confirmed by user)
- `scenes/actors/player.tscn` — current player scene; node structure rewritten in place.
- `scripts/world/player.gd` — current player script; rewritten in place, same path (references stay valid).
- `resources/player_config.tres` + `scripts/config/player_config.gd` — Gold Standard for tunables-in-Resource pattern; extend, don't replace.
- `scripts/world/camera_follow.gd` — current camera behavior; the arena's new camera is a side-view follow component (chapter cameras remain as-is).
- `scenes/dev/sprite_anim_preview.tscn` — Gold Standard for AnimatedSprite2D + SpriteFrames wiring pattern (arena uses AnimatedSprite3D billboard instead).

## Architecture constraints (confirmed)
- AGENTS.md rules: static typing everywhere; signals via EventBus only; composition over inheritance (animation state machine = small composable component, not a god-script); tunables in Resources; call_deferred for scene-tree mutations from physics callbacks; explicit collision layers/masks; snake_case files.
- HD-2D invariants: sprites billboard-style, 3D world carries lighting, nearest-neighbor filtering (global), original aspect ratio.
- GameFlow/SceneRouter/DialogueService/EventBus untouched.
- Godot 4.7 headless validation gates (editor import + scene smoke, gdlint clean).

## Reuse (do NOT recreate)
- `assets/sprites/player/player_frames.tres` (+ left spare) — the animation data.
- `resources/player_config.tres` — extend with new tunables.
- InputMap in `project.godot` — add `jump` action alongside existing actions.
- Existing EventBus signals (game_state_changed etc.) — no new signals needed this feature.

## Unverified assumptions (RISK)
- Exact jump buffering window (e.g. 0.1 s) and jump-cut implementation details — Tech Lead decides, tunable-ize where reasonable.
- Arena ground dimensions/layout — Tech Lead proposes (flat stretch + steps); user will iterate on feel later.
- Whether `move_up`/`move_down` should later map to other ACT verbs (e.g. ladder/aim) — left unused, not removed.
- AnimatedSprite3D vertical anchor: feet-bottom anchoring so the sprite aligns with the physics body — Tech Lead must specify exact offset.
