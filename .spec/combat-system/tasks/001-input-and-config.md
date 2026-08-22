# Task 001: Combat input actions + combat config/hit-window Resources

## Goal
Add the `attack`/`dodge` input actions and the `hitbox`/`hurtbox` physics layer
names to `project.godot`, and create the `HitWindow` + `CombatConfig` Resource
scripts and their `.tres` files. No runtime behavior changes yet — this task
only adds data and types.

## Affected files

**Modified**
- `project.godot` — add `attack` + `dodge` to `[input]`; add `layer_4="hitbox"`
  and `layer_5="hurtbox"` to `[layer_names]`.

**New**
- `scripts/config/hit_window.gd` — `class_name HitWindow extends Resource`.
- `scripts/config/combat_config.gd` — `class_name CombatConfig extends Resource`.
- `resources/combat_config.tres` — `CombatConfig` instance.
- `resources/hit_windows/attack_1.tres` — `HitWindow` instance.
- `resources/hit_windows/attack_2.tres` — `HitWindow` instance.
- `resources/hit_windows/attack_3.tres` — `HitWindow` instance.
- `resources/hit_windows/attack_air.tres` — `HitWindow` instance.

## Acceptance criteria

### Headless gates
- [ ] `gdlint .` reports **0 problems**.
- [ ] `godot --headless --editor --path . --quit-after 10` runs with **no**
      `ERROR:`, `SCRIPT ERROR`, `Parse Error`, `Failed loading`.
- [ ] `godot --headless --path . --quit-after 5 scenes/boot.tscn` runs clean
      (same grep criteria).

### Observable
- [ ] `project.godot` `[input]` contains `attack` (J, joypad button 2) and
      `dodge` (K, joypad button 1); `[layer_names]` contains layer 4 `hitbox`
      and layer 5 `hurtbox`.
- [ ] `HitWindow` has typed `@export`s: `start_frame: int`, `end_frame: int`,
      `damage: float`, `knockback: Vector3`.
- [ ] `CombatConfig` has typed `@export`s for every field in `design.md` §4.2 and
      references all four `HitWindow` `.tres` files.
- [ ] The four `HitWindow` `.tres` files set `start_frame=2`, `end_frame=3`,
      `knockback=Vector3.ZERO`, and damage `35/40/50/40` (attack_1/2/3/air).

## Implementation notes
- Follow `scripts/config/player_config.gd` as the Resource pattern: typed
  `@export`s only, an English doc-comment explaining *why* on each field
  (AGENTS.md rule 8).
- `combat_config.tres` mirrors `resources/player_config.tres`: declare the four
  hit windows as `ExtResource` entries and assign them to the four window
  fields. Use `[ext_resource type="Script" ...]` pointing at the `.gd` files and
  `script_class="HitWindow"` / `script_class="CombatConfig"` in the resource
  headers.
- Keyboard bindings use `physical_keycode` (74 = J, 75 = K) to match the existing
  WASD/E entries; see `design.md` §9 for the joypad button indices.
- Layer-name additions are metadata only; no scene assigns layers 4/5 yet.

## Constraints (AGENTS.md)
- Static typing on every `@export` (rule 1); no hardcoded gameplay values in
  scripts — defaults live in the `.tres`/`@export` (rule 4).
- `class_name` only for the two globally-registered Resource classes (rule 7).
- Snake_case file names, PascalCase class names.

## Commit
`feat(combat): 添加 attack/dodge 输入与战斗配置、命中窗口资源`

## Implementation log
<!-- Developer appends: what was done, gate results, any deviation. -->

- Added `attack` (J / joypad button 2) and `dodge` (K / joypad button 1) to
  `[input]`, and `layer_4="hitbox"` / `layer_5="hurtbox"` to `[layer_names]`
  in `project.godot`.
- Created `HitWindow` and `CombatConfig` Resource scripts (`scripts/config/`)
  and their `.tres` files: `resources/combat_config.tres` plus four
  `resources/hit_windows/*.tres` (start_frame=2, end_frame=3,
  knockback=Vector3.ZERO, damage 35/40/50/40).
- Gates passed: `gdlint .` → 0 problems; headless editor + `scenes/boot.tscn`
  runs clean (no ERROR/SCRIPT ERROR/Parse Error/Failed loading); explicit
  headless load of `combat_config.tres` confirmed every field and all four
  window references resolve with the expected values.
