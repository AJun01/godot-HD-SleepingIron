# Task 004: Player scene wiring

## Goal
Wire `PlayerCombat` and its persistent hit `Area3D` into `scenes/actors/player.tscn`
so the combat component goes live: attacks/dodge animate, lock movement, and
position the hit area. The arena dummies have no hurtboxes yet, so hits land on
nothing — this task closes animation + movement, not damage.

## Affected files

**Modified**
- `scenes/actors/player.tscn` — add a `Combat` node (script
  `player_combat.gd`) with a child `HitArea` (`Area3D`, layer 4 / mask 5) and a
  `CollisionShape3D` box.

## Acceptance criteria

### Headless gates
- [ ] `gdlint .` reports **0 problems**.
- [ ] `godot --headless --editor --path . --quit-after 10` runs with **no**
      `ERROR:`, `SCRIPT ERROR`, `Parse Error`, `Failed loading`.
- [ ] `godot --headless --path . --quit-after 5 scenes/act/arena.tscn` runs clean.
- [ ] `godot --headless --path . --quit-after 5 scenes/boot.tscn` runs clean.

### Observable
- [ ] `player.tscn` loads clean; the `Combat` node's `player`/`animator`/`hit_area`
      references resolve (no missing-node warnings).
- [ ] Grounded `attack` (J) plays `attack_1 → attack_2 → attack_3` under the Q1
      rhythm (cancel at ≥60% recovery, 0.15 s buffer, 0.4 s chain timeout) and
      locks X/Z movement during each attack.
- [ ] `attack` airborne plays `attack_air` (never a ground step) and decays
      horizontal momentum while gravity continues.
- [ ] `dodge` (K) displaces the player along facing, reports invincibility active
      during the dash (`is_invincible()`), and respects the 0.5 s cooldown,
      grounded and airborne.
- [ ] `HitArea` is on layer 4 / mask 5, resized from `hit_box_size`, positioned at
      `facing * hit_box_offset`, and monitors only during the active window.
- [ ] Movement/jump feel unchanged; combat inputs inert while a dialogue is open.

## Implementation notes
- Add `Combat` as a `Node3D` child of `Player` with `script` =
  `res://scripts/world/player_combat.gd`; set `player = NodePath("..")` and
  `animator = NodePath("../Animator")`, `hit_area = NodePath("HitArea")`
  (defensive fallbacks mirror `player_animator.gd`).
- `HitArea`: `Area3D` child of `Combat`, `collision_layer = 4`,
  `collision_mask = 5`, with a `CollisionShape3D` box; `PlayerCombat` resizes the
  box and repositions the area in `_ready` from `COMBAT_CONFIG` (`design.md` §5.5).
- The `Animator` node needs no new scene refs: config is `preload`ed in code
  (task 002). This keeps the config wiring out of the scene.
- Do not touch the dummies in this task (task 005).

## Constraints (AGENTS.md)
- One-way dependency (animator reads player; combat reads animator; no reverse
  refs) — rule 2. Explicit `collision_layer = 4` / `collision_mask = 5` on
  `HitArea` (rule 6). Snake_case node/file names, PascalCase class names (rule 7).

## Commit
`feat(combat): 在 player.tscn 接入 Combat 节点与攻击命中区域`

## Implementation log
<!-- Developer appends: what was done, gate results, any deviation. -->

- Added `Combat` (Node3D, `player_combat.gd`) to `scenes/actors/player.tscn` with
  `player`/`animator`/`hit_area` `@export` node references (NodePath DI) and a
  persistent child `HitArea` (Area3D layer 4 / mask 5) with a `CollisionShape3D`
  box (`BoxShape3D`, initial size from `hit_box_size`). Existing node names and
  the player layer 2 / mask 1 invariant untouched.
- Gates: `gdlint .` → 0 problems; `godot --headless --editor --path . --quit-after 10`
  clean (no ERROR/SCRIPT ERROR/Parse Error/Failed loading); smoke tests for
  `scenes/actors/player.tscn`, `scenes/act/arena.tscn`, `scenes/boot.tscn` clean.
