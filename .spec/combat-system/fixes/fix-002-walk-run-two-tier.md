# Fix 002: DNF-style walk/run two-tier movement

## Status

pending

## Context

New feature (confirmed, not a bug): DNF-style two-tier movement.

- Hold a direction key = WALK (slow).
- Double-tap the same direction quickly = RUN (fast).
- Releasing movement input returns to walk.

All speeds/timings are `PlayerConfig` tunables (AGENTS.md rule 4). Must not
break: jump buffer, combat movement lock, dodge movement override, and the
`DialogueService` input gate.

## Design decisions

1. **Speed fields.** Keep the existing `move_speed = 7.0` as the **RUN tier**
   (the task's "run_speed" is realized by `move_speed`; no rename). Add
   `walk_speed: float = 3.5` (half of run — a clearly slower DNF-style walk)
   and `double_tap_window: float = 0.25` (s).
   *Why keep `move_speed` instead of renaming it to `run_speed`:* `move_speed`
   is referenced in exactly three places (`player_config.gd`,
   `player_config.tres`, `player.gd:79`); keeping it preserves the existing
   7.0 default and avoids `.tres` re-serialization churn for zero behavioral
   gain. The existing defaults `7.0 / 60.0 / 70.0 / 22.0 / 8.5` all keep
   working unchanged.
2. **No walk animation asset.** The run animation is reused for both tiers;
   `player_animator.gd` `_desired_state()` already maps any non-zero horizontal
   velocity to `STATE_RUN`, so it stays byte-for-byte unchanged (documented as
   intentional — walk and run share the run sprite).

## Affected files

**Modified**
- `scripts/config/player_config.gd` — add `walk_speed` + `double_tap_window`;
  update the `move_speed` doc-comment to say it is the RUN tier.
- `resources/player_config.tres` — add `walk_speed = 3.5`,
  `double_tap_window = 0.25`; keep `move_speed = 7.0`.
- `scripts/world/player.gd` — double-tap detection in `_unhandled_input`, a
  `_run_active` tier flag, tier-aware target speed in
  `_apply_horizontal_velocity`, and reset-to-walk on zero input.

**Unchanged** (must not regress)
- `player_animator.gd` (velocity mapping), jump buffer/cut, combat lock,
  dodge override.

## Implementation

### PlayerConfig (`scripts/config/player_config.gd`)

Add two typed `@export`s (AGENTS.md rule 1) and amend the `move_speed` comment:

```
## Horizontal speed (units/s) at full input deflection in the RUN tier
## (double-tap). Existing 7.0 default unchanged.
@export var move_speed: float = 7.0

## Horizontal speed (units/s) at full input deflection in the WALK tier
## (hold a direction). Lower than move_speed for DNF-style two-tier movement.
@export var walk_speed: float = 3.5

## Window (s) in which a second press of the SAME direction key upgrades
## movement to the RUN tier.
@export var double_tap_window: float = 0.25
```

`resources/player_config.tres` additions (order does not matter):

```
walk_speed = 3.5
double_tap_window = 0.25
```

### Player (`scripts/world/player.gd`)

New typed state (top-level, next to the existing lock/override fields):

```
var _run_active: bool = false
var _last_dir_key: Vector2 = Vector2.ZERO
var _last_dir_press_ms: int = 0
```

1. **Double-tap detection** in `_unhandled_input`, right after the existing
   `DialogueService.is_open()` gate, and echo-filtered:

```
func _unhandled_input(event: InputEvent) -> void:
    if DialogueService.is_open():
        return
    _track_double_tap(event)
    if event.is_action_pressed(&"jump") and not event.is_echo():
        ...
```

```
func _track_double_tap(event: InputEvent) -> void:
    if event.is_echo():
        return
    var dir: Vector2 = _direction_for_event(event)
    if dir == Vector2.ZERO:
        return
    var now_ms: int = Time.get_ticks_msec()
    var window_ms: int = int(PLAYER_CONFIG.double_tap_window * 1000.0)
    if dir == _last_dir_key and now_ms - _last_dir_press_ms <= window_ms:
        _run_active = true
    _last_dir_key = dir
    _last_dir_press_ms = now_ms
```

`_direction_for_event(event)` maps a fresh press of `move_left` / `move_right` /
`move_up` / `move_down` to a unit `Vector2` (`(-1,0)` / `(1,0)` / `(0,-1)` /
`(0,1)`), and returns `Vector2.ZERO` otherwise. Use
`event.is_action_pressed(action)` so released keys are ignored.

2. **Reset to walk on zero input** — at the top of `_physics_process`, right
   after `_read_movement_input()`:

```
var direction: Vector2 = _read_movement_input()
if direction == Vector2.ZERO:
    _run_active = false
    _last_dir_key = Vector2.ZERO
```

This implements "release + re-hold = walk again" (a fresh press after any zero
input starts as walk, and only a same-direction double-tap re-arms run). It also
resets while a dialogue is open (input reads zero).

3. **Tier-aware target speed** in `_apply_horizontal_velocity` — only the normal
   branch changes (the `movement_override` and `movement_locked` branches stay
   first, so they still win):

```
if direction != Vector2.ZERO:
    var speed: float = PLAYER_CONFIG.move_speed if _run_active else PLAYER_CONFIG.walk_speed
    var target: Vector2 = direction * speed
    velocity.x = move_toward(velocity.x, target.x, PLAYER_CONFIG.acceleration * delta)
    velocity.z = move_toward(velocity.z, target.y, PLAYER_CONFIG.acceleration * delta)
```

## Interaction guarantees

- **Combat lock still wins:** `_apply_horizontal_velocity` checks
  `movement_override`, then `movement_locked`, then the normal branch — walk/run
  only affects the normal branch, so lock/override are unaffected.
- **Dodge override still wins:** same ordering; the override returns early.
- **Jump unchanged:** jump buffer + jump-cut code is untouched.
- **Dialogue gate:** `_read_movement_input` returns zero → run resets; the
  double-tap tracker returns early while dialogue is open.
- **Opposite-direction double-tap:** tapping the opposite key re-arms run; the
  actual movement direction comes from `_read_movement_input()` (the held keys),
  so running flips to the opposite direction. A single re-hold is always walk.

## Edge cases

- Diagonal input stays normalized (existing `limit_length(1.0)`), so neither tier
  is √2 faster diagonally.
- Key repeat (echo) never false-triggers run (echo filtered).
- Double-tap while already running is a no-op (stays run).

## Acceptance criteria

### Headless gates

- [ ] `gdlint .` reports **0 problems**.
- [ ] `godot --headless --editor --path . --quit-after 10` runs with **no**
      `ERROR:`, `SCRIPT ERROR`, `Parse Error`, `Failed loading`.
- [ ] `godot --headless --path . --quit-after 5 scenes/act/arena.tscn` runs
      clean (same grep criteria).
- [ ] `godot --headless --path . --quit-after 5 scenes/boot.tscn` runs clean
      (same grep criteria).

### Observable

- [ ] Hold a direction = walk speed (`3.5`); double-tap the same direction = run
      speed (`7.0`).
- [ ] Release + re-hold the same direction = walk again (run tier cleared).
- [ ] Double-tapping the opposite direction switches run to that direction.
- [ ] Jump buffer, combat movement lock, dodge override, and the dialogue gate
      behave exactly as before.

## Constraints (AGENTS.md)

- Static typing on every new field/param/return (rule 1); all values are
  Resource tunables (rule 4); comments in English (rule 8).

## Commit

`feat(combat): DNF 式两档移动（走/跑）与双击跑动窗口`

## Implementation log

- Implemented DNF-style walk/run two-tier movement per this fix. Added
  `walk_speed = 3.5` + `double_tap_window = 0.25` to `PlayerConfig` and
  `resources/player_config.tres`; `move_speed = 7.0` remains the RUN tier.
  `player.gd` gains echo-filtered per-direction double-tap tracking in
  `_unhandled_input`, resets run on zero input in `_physics_process`, and a
  tier-aware target speed in `_apply_horizontal_velocity` (combat lock / dodge
  override branches kept first and unchanged). No walk animation asset exists,
  so the run sprite is reused for both tiers (`player_animator.gd` untouched).
- Gates: `gdlint .` 0 problems; headless editor + `scenes/act/arena.tscn` +
  `scenes/boot.tscn` all clean (no ERROR/SCRIPT ERROR/Parse Error/Failed
  loading). No `.import` noise was produced, so nothing needed excluding.
