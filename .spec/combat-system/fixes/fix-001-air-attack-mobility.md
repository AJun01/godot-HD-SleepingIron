# Fix 001: Air attack mobility (attack_air must not lock movement)

## Status

pending

## Context

Playtest bug: an airborne `attack_air` suddenly stops the player mid-air before
falling. Root cause is in `scripts/world/player_combat.gd`
`_start_air_attack()`: it calls `_lock_movement()`, which sets
`player.movement_locked = true`. `player.gd` `_apply_horizontal_velocity()`
then ignores input and decays horizontal velocity toward zero at the `friction`
rate, killing air momentum.

This reverses the earlier Q2 decision **for the air case only** (design.md §3.4
"Q2 movement lock" and scope.md "Movement lock (Q2)"): ground attacks keep the
movement lock; `attack_air` keeps full air-movement input response + momentum.
Gravity is unchanged.

## Design change

`attack_air` is a standalone airborne strike: the player keeps responding to air
movement input and retains horizontal momentum while the animation plays;
gravity still runs so the player falls and can land mid-animation. Ground
attacks (`attack_1/2/3`) keep their movement lock (unchanged).

## Affected files

**Modified**
- `scripts/world/player_combat.gd` — `_start_air_attack()` must NOT call
  `_lock_movement()`.

No change to `player.gd`, `player_animator.gd`, or any Resource.

## Implementation

In `_start_air_attack()` (currently `player_combat.gd`, ~line 245):

1. Remove the `_lock_movement()` call.
2. Update the doc-comment: the air attack is standalone, does **not** lock
   movement, keeps full air input + momentum, and gravity still runs so the
   strike falls.

Reference (current code):

```
func _start_air_attack() -> void:
    combo_step = 0
    chain_timer = 0.0
    animator.play_combat_state(PlayerAnimator.STATE_ATTACK_AIR)
    _lock_movement()   # <-- remove this line
```

Nothing else is required. `_update_combo_chain()` already clears
`movement_locked` when an attack one-shot ends (`player.movement_locked = false`),
which becomes a harmless no-op for the air case. Because `_start_air_attack()`
is only reached from a non-combat state (`_try_attack()` returns early when
`_is_combat_state(state)`), `movement_locked` is already `false` at that point,
so simply not locking is correct and complete.

## Design reference updates (Q2 air-case reversal)

- design.md §3.4 "Q2 movement lock", first bullet: now **ground attacks
  (`attack_1/2/3`) set `player.movement_locked`**; `attack_air` does **not**
  lock (it keeps air movement + momentum; gravity still runs). The dodge and
  `hit`/`death` bullets are unchanged.
- design.md §5.3 decision table, row "Airborne, not in a combat state, ATTACK":
  change `lock movement` → `no lock (keep air movement + momentum)`.
- design.md §6 `movement_locked` doc-comment: drop `attack_air` from the list
  (`attack_1/2/3` only).
- scope.md "Movement lock (Q2)" bullet 2 is superseded for the air case (not
  edited here — noted for the docs pass).

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

- [ ] Airborne `attack_air` while holding a direction keeps moving horizontally
      (input still drives `velocity.x/z`; no friction decay to zero).
- [ ] Airborne `attack_air` retains horizontal momentum and the player lands
      while the animation is still playing.
- [ ] Gravity unchanged: the player still falls during `attack_air`.
- [ ] Ground attacks `attack_1/2/3` still lock movement (no regression).

## Constraints (AGENTS.md)

- Static typing unchanged; no new fields/signals; no hardcoded values.
- One-way dependency and collision layers untouched.

## Commit

`fix(combat): attack_air 不再锁定移动，空中保留输入与动量`

## Implementation log

<!-- Developer appends: what was done, gate results, any deviation. -->
