# Task 005: Hittable dummy scene + combat-range zone + arena rewiring

## Goal
Turn the three inert arena dummies into hittable `TargetDummy` components (hit
flash, billboard health bar, death, 2 s auto-reset), add the combat-range zone
controller, and rewire the arena `CombatRange` (keep dummy positions, update the
ZonePillar text). This closes the combat loop.

## Affected files

**New**
- `scripts/world/target_dummy.gd` — `class_name TargetDummy extends StaticBody3D`.
- `scripts/dev/combat_range_zone.gd` — composable `Node3D` zone controller.
- `scenes/actors/target_dummy.tscn` — reusable hittable dummy scene (body layer 1
  / mask 2 + `Hurtbox` layer 5 / mask 4 + billboard health bar + `Sprite3D`).

**Modified**
- `scenes/act/arena.tscn` — replace the three inert `StaticBody3D` dummies with
  `target_dummy.tscn` instances (positions x = -5 / 0 / 5, z = -2, max_hp
  100 / 60 / 30); add the `CombatRange` controller wiring; update the ZonePillar.

## Acceptance criteria

### Headless gates
- [ ] `gdlint .` reports **0 problems**.
- [ ] `godot --headless --editor --path . --quit-after 10` runs with **no**
      `ERROR:`, `SCRIPT ERROR`, `Parse Error`, `Failed loading`.
- [ ] `godot --headless --path . --quit-after 5 scenes/act/arena.tscn` runs clean.
- [ ] `godot --headless --path . --quit-after 5 scenes/boot.tscn` runs clean.

### Observable
- [ ] The three dummies keep their exact positions and their physics body
      (layer 1 / mask 2, `BoxShape3D 0.7×2.2×0.5` at y = +1.1).
- [ ] Hitting a dummy during the active window flashes its sprite (modulate
      pulse) and decrements its billboard health bar once per attack.
- [ ] Dummies die at 0 HP (hurtbox stops receiving), and auto-reset to full HP
      2 s after death; 100 / 60 / 30 HP dummies die on the 3rd / 2nd / 1st combo
      hit respectively.
- [ ] A killed dummy ignores later hits until it resets.
- [ ] The combat-range reset pad (interaction layer 3 / mask 2) resets all three
      dummies to full HP (deferred from the pad signal); the status `Label3D`
      shows a short hint / reset confirmation.
- [ ] ZonePillar `responsibility` now reads `"Hittable target dummies: combo
      damage, hit-flash, health bars, death + auto-reset"`.
- [ ] No placeholder art is baked into the health bar (dynamic fill, not numbers).

## Implementation notes
- `TargetDummy` `@export` tunables per `design.md` §8: `max_hp=100`,
  `reset_delay=2.0`, `hit_flash_duration=0.12`, `hit_flash_color=Color(1,0.25,0.25)`;
  connect its child `Hurtbox.hit_received` to `take_damage`. The hit flash uses a
  `Tween`; the health bar fill is a billboarded `MeshInstance3D` quad whose
  `scale.x` tracks `hp/max_hp`.
- `combat_range_zone.gd` mirrors `animation_preview_zone.gd`: `@export` DI +
  `NodePath` fallbacks, an `Area3D` reset pad (layer 3 / mask 2), and
  `call_deferred` for the reset mutation from the pad signal (rule 5). Expose
  `@export var dummies: Array[TargetDummy]` (wired in the scene).
- Reuse `assets/placeholders/placeholder_target_dummy.svg` for the dummy sprite
  (no new art); it stays registered as a placeholder.
- `knockback` is delivered to `take_damage` and ignored (static body) — comment
  this clearly (rule 8).

## Constraints (AGENTS.md)
- Explicit collision layers: dummy body 1/2, `Hurtbox` 5/4 (rule 6); never
  repurpose layers 1/2/3. `call_deferred` for scene-tree mutations from pad
  signals (rule 5). Static typing (rule 1). Composition, no god scripts (rule 3).

## Commit
`feat(combat): 将竞技场假人替换为可命中的 TargetDummy 并接入战斗范围控制器`

## Implementation log
<!-- Developer appends: what was done, gate results, any deviation. -->

- Added `scripts/world/target_dummy.gd` (`class_name TargetDummy extends
  StaticBody3D`): `@export` HP/flash/reset tunables, Hurtbox `hit_received` ->
  `take_damage` (knockback accepted and ignored, commented), deferred hit-flash
  (Tween modulate pulse), billboard health-bar fill whose `scale.x` tracks
  `hp/max_hp`, darkened dead state (hurtbox disabled + bar hidden), and a 2 s
  auto-reset + public `reset()`. Added `scenes/actors/target_dummy.tscn` (body
  layer 1/mask 2, `Hurtbox` layer 5/mask 4, `Sprite3D` on the existing
  `placeholder_target_dummy.svg`, two billboarded `QuadMesh` health-bar quads).
- Added `scripts/dev/combat_range_zone.gd` (composable `Node3D`, mirrors
  `animation_preview_zone.gd`): `@export var dummies: Array[TargetDummy]`,
  `reset_pad_path` (Area3D layer 3/mask 2), `Label3D` status, `call_deferred`
  reset from `body_entered`.
- Rewired `scenes/act/arena.tscn` CombatRange: the three inert `StaticBody3D`
  dummies are now `target_dummy.tscn` instances at the same positions (x -5/0/5,
  z -2, `max_hp` 100/60/30), the `CombatRange` node gained the zone controller
  (dummies wired via `node_paths=PackedStringArray("dummies")`), a `ResetPad`
  and `StatusLabel`, and the ZonePillar now reads
  `"Hittable target dummies: combo damage, hit-flash, health bars, death + auto-reset"`.
- Gates: `gdlint .` -> 0 problems; `godot --headless --editor --path . --quit-after 10`
  clean (no ERROR/SCRIPT ERROR/Parse Error/Failed loading); smoke tests for
  `scenes/act/arena.tscn`, `scenes/boot.tscn`, `scenes/actors/target_dummy.tscn`
  clean. Headless script checks confirmed 3 wired dummies (positions/layers/HP),
  HP 100 -> 65 -> 25 -> 0 on 35/40/50 damage, dead guard, `reset()`, and the 2 s
  auto-reset.

