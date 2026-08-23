# Scope: Combat System

> Spec of record for the `combat-system` feature. Derived exclusively from
> `intake.md` (authoritative) and the Gold Standard / reference code inspected
> during Init. Anything not captured in intake.md is out of scope.

## Goal and scope

Wire a **minimal closed combat loop** into the player so it can be exercised
against the arena target dummies: the `attack_1/2/3` ground combo, `attack_air`,
`dodge`, and the `hit`/`death` states. Attacks are driven by the animation state
machine with **wind-up / hit-window (active) / recovery** phases; hit windows
live in Resource files (frame intervals + damage + knockback). The arena's three
inert target dummies become hittable targets (hit feedback, health bar, death,
auto-reset) so the combo is testable. This is learning-first and extensible: the
combat system is a **minimal closed loop only**; future work adds enemy AI and a
systematic damage-receiver framework on top of it.

### Out of scope (explicit)

- **Player HP** and any player damage/death logic — `hit`/`death` are states only.
- **Damage sources** beyond the player's own combo hit windows (no enemy attacks).
- **Enemy AI** and any NPC combat behavior.
- A **systematic damage-receiver framework** — the target dummy is a self-contained
  component, not a general `Hurtbox`/`Damageable` abstraction.
- **Combat SFX/VFX** (hit-stop, camera shake, particles, sounds) — placeholder art
  only where an asset is strictly required, per AGENTS.md placeholder policy.
- **Save data** for combat state (dummy HP, combo progress) — nothing persists.
- Final art/audio — always the human developer's job (AGENTS.md role boundary).

## Confirmed feature behavior

### Inputs
- New `attack` input action: advances the ground combo (`attack_1 → attack_2 →
  attack_3`) on the ground, or triggers `attack_air` when airborne.
- New `dodge` input action: rolling dash, usable grounded and airborne.
- Existing movement/jump inputs and their feel are **unchanged**.
- Input gating: combat inputs are inert while `DialogueService.is_open()` (same gate
  as movement/jump). Combat inputs use the `_unhandled_input`/buffered pattern
  already established by the jump buffer in `player.gd`.

### Combo rhythm (Q1 — DNF-style lenient)
- Each ground step can be canceled into the next step during the **recovery tail**
  (animation progress >= 60%).
- **0.15s** input buffer on the attack key; **at most one** buffered press, no queuing.
- Return to idle **0.4s** after recovery ends with no follow-up (combo chain timeout).
- All timings are Resource tunables, never hardcoded.

### Movement lock (Q2)
- Ground attacks (`attack_1/2/3`) fully lock X/Z movement.
- `attack_air` locks movement input and decays horizontal momentum to 0 while
  gravity continues.
- Dodge carries its own displacement (its own movement, not player input movement).

### Hit / death (Q3)
- `hit` and `death` enter the state machine as **states only**: playable via preview
  mode, returning to idle when finished. No player HP, no damage source.

### Dodge (Q4)
- Rolling dash **displacement** (speed × duration, tunable) + **full invincibility** +
  **0.5s** cooldown; usable grounded and airborne. All parameters in a Resource.

### Target dummy (Q5)
- Three dummies share one `TargetDummy` component: **hit-flash** (modulate pulse),
  **billboard health bar**, and **death** behavior; **auto-reset to full HP 2s after
  death**. HP / damage / knockback are Resource tunables. Dummies use different max
  HP (e.g. **100 / 60 / 30**) to exercise combo damage.

### Edge cases (from intake)
- Attack pressed while airborne → `attack_air` (no ground-combo step).
- Attack pressed mid-dodge or mid-hit → buffered per Q1 rules, or ignored per state.
- Dodge pressed during an attack → ignored until recovery ends (buffered once).
- Dummy killed mid-combo → later hits do nothing until it resets.
- Dialogue open → combat inputs inert (same gate as movement/jump).
- Combo chain timeout → return to idle.

## Affected files

### New
- `scripts/world/player_combat.gd` — `PlayerCombat`, the composable logic layer:
  owns the attack input buffer, combo progression, hit-window Resource evaluation,
  hit `Area3D` generation, and dodge displacement + invincibility. Reads the
  animator's state; writes only the player's public lock fields/methods.
- `scripts/world/target_dummy.gd` — `TargetDummy` component: hurtbox detection,
  hit-flash, billboard health bar, death, and auto-reset (shared by all three dummies).
- `scripts/dev/combat_range_controller.gd` — composable combat-range controller
  following the `animation_preview_zone.gd` dev-zone pattern (Area3D pads on
  interaction layer 3 / mask 2, `call_deferred` mutations, Label3D status); bounded to
  reset/status conveniences within the confirmed behavior. Exact name is the Tech
  Lead's call (e.g. `combat_range_zone.gd`).
- `scripts/config/combat_config.gd` + `resources/combat_config.tres` — `CombatConfig`
  Resource: combo buffer/cancel/window timings, dodge speed/duration/cooldown,
  knockback, dummy HP defaults.
- `scripts/config/hit_window.gd` + `resources/hit_windows/*.tres` — `HitWindow`
  Resource: per-step frame interval (active window) + damage + knockback, one instance
  per `attack_1/2/3` and `attack_air`.
- `docs/sdd/artifacts/combat-system.yml` — non-code artifact registry (godot-sdd
  skill), listing the touched scenes/scripts/assets with invariants + validation
  commands, mirroring `arena-dev-hub.yml`.

### Modified
- `scripts/world/player_animator.gd` — extended into the full combat animation state
  machine (`attack_1/2/3`, `attack_air`, `hit`, `dodge`; animation-driven
  wind-up / hit-window / recovery phases), still reading the player one-way.
- `scripts/world/player.gd` — gains only a **minimal public movement-lock interface**
  (set by components; no reverse references into the animator or combat component).
- `scenes/actors/player.tscn` — add the `PlayerCombat` node and wiring.
- `scenes/act/arena.tscn` — CombatRange dummies become `TargetDummy` components
  (hurtbox + health bar) and gain the combat-range controller wiring.
- `project.godot` — add `attack` and `dodge` input actions.

### Placeholders (only if strictly required)
- New combat placeholder art goes to `assets/placeholders/` and is registered with
  `status: placeholder` in `combat-system.yml`. The existing
  `placeholder_target_dummy.svg` is reused as the dummy base art. No new art is
  anticipated beyond what already exists; hit-flash is a modulate pulse and the health
  bar is a dynamic bar (not baked art), per AGENTS.md HD-2D invariants.

## Invariants (must NOT change)

- **One-way dependency:** the animator reads the player; the player never references
  the animator. The new `PlayerCombat` reads the animator's state and writes only
  public lock fields/methods on the injected player — no reverse references, no
  `get_node("../../...")`.
- **Existing five-state mapping** (`idle`/`run`/`jump`/`fall`/`land`) and the preview
  mode (`play_preview`/`stop_preview`) for the existing animation-preview zone keep
  their exact behavior; the extension is additive (new states + phase signaling), not
  a rewrite.
- **Movement/jump feel:** `PlayerConfig` values `move_speed=7.0`, `acceleration=60.0`,
  `friction=70.0`, `gravity=22.0`, `jump_velocity=8.5` (and the jump-buffer
  0.1s / jump-cut 0.5) are untouched. The lock interface defaults to unlocked so
  pre-combat movement is byte-for-byte unchanged.
- **Collision layers:** `world=1`, `player=2`, `interaction=3` keep their meanings.
  Player body = layer 2 / mask 1; world solids (ground, dummies' physics bodies) =
  layer 1 / mask 2; interaction pads = layer 3 / mask 2. Any new combat hit/hurt
  detection layer must be explicit and must NOT repurpose layers 1/2/3.
- **Pixel-art nearest-neighbor filtering** and source aspect ratio/transparency for
  billboarded sprites (project `default_texture_filter=0`; no resampling).
- **`call_deferred`** for every scene-tree mutation issued from physics/signal
  callbacks.
- **Static typing everywhere** — every variable, parameter, return type, and `@export`
  annotated.
- **No god scripts** — composable components + `@export` DI only; tunables in Resources,
  never hardcoded gameplay values.

## Acceptance criteria

### Headless gates (CI-enforced; all must be clean)
- [ ] `gdlint .` reports **0 problems** (config `.gdlintrc`).
- [ ] `godot --headless --editor --path . --quit-after 10` runs with **no**
  `ERROR:`, `SCRIPT ERROR`, `Parse Error`, or `Failed loading`.
- [ ] `godot --headless --path . --quit-after 5 scenes/act/arena.tscn` runs clean
  (same grep criteria).
- [ ] `godot --headless --path . --quit-after 5 scenes/boot.tscn` runs clean
  (same grep criteria).

### Gameplay-observable criteria
- [ ] Ground combo chains `attack_1 → attack_2 → attack_3` under the Q1 rhythm
  (recovery-tail cancel at >= 60% + 0.15s buffer + 0.4s idle-return timeout).
- [ ] `attack_air` fires when `attack` is pressed airborne; it never starts a ground
  step.
- [ ] Dodge displaces the player, grants full invincibility, and respects the 0.5s
  cooldown, grounded and airborne.
- [ ] Dummies flash on hit, their billboard health bar decrements, they die at 0 HP,
  and auto-reset to full HP 2s after death; the three dummies use different max HP
  (100/60/30).
- [ ] `hit` and `death` are playable via the animator preview path (no trigger source
  in this feature).
- [ ] Existing five-state movement animation and preview mode still behave as before.
- [ ] Movement/jump feel is unchanged (PlayerConfig values preserved).
- [ ] Combat inputs are inert while a dialogue is open.

## Risks and rollback plan

Each stage below is independently revertible (one task = one commit; git revert the
commit that failed).

- **Animator extension breaks the five-state mapping or preview mode** → revert
  `player_animator.gd` to its pre-feature version; the physics mapping and preview
  paths are isolated functions, so a clean revert restores them.
- **`player.gd` lock interface degrades movement/jump feel** → revert `player.gd`;
  the interface is additive (default unlocked), so removing it restores prior feel.
- **`PlayerCombat` wiring breaks the player scene** → revert `player_combat.gd` and
  the `player.tscn` node addition; `player.tscn` returns to the pre-feature serialization.
- **Dummy conversion breaks the arena** → revert `target_dummy.gd` and the CombatRange
  edits in `arena.tscn`; dummies return to inert `StaticBody3D` props.
- **New Resource / config files are broken or orphaned** → remove the offending
  `.tres`/`.gd` and revert the referencing scene/script.
- **Input-map additions conflict** → revert the `[input]` section of `project.godot`.

**Broken-resource detection:** run the headless editor import
(`godot --headless --editor --path . --quit-after 10`) and the arena/boot smoke runs;
grep for `Failed loading`, `ERROR:`, `SCRIPT ERROR`, `Parse Error`. Any match means a
broken or orphaned reference — revert the referencing file before proceeding.

## Reuse (do NOT recreate)

- `player_animator.gd` preview mode — the verification path for `hit`/`death` states.
- `player.gd` jump-buffer pattern — the template for the attack buffer.
- `animation_preview_zone.gd` Area3D-pad + `call_deferred` dev-zone pattern — the
  template for the combat-range controller.
- `player_config.gd` Resource pattern — the template for the new `CombatConfig` /
  `HitWindow` Resources.
- `assets/placeholders/placeholder_target_dummy.svg` — dummy base art (reused, not
  redrawn).
- `event_bus.gd` typed signals — only if combat genuinely needs a cross-scene event;
  the minimal loop should avoid it unless justified.

## Unverified assumptions (RISK)

- Concrete numbers (damage per combo step, dummy max HP 100/60/30, knockback, dodge
  speed/duration/cooldown, combo cancel/buffer/window timings) are **sensible defaults
  chosen by the Tech Lead**; every one must be a Resource tunable, never hardcoded.
- `attack`/`dodge` input-map entries: default bindings are the Tech Lead's call
  (e.g. `attack = J`, `dodge = K`, joypad face buttons), documented in the task so the
  user can rebind.
- `hit`/`death` have **no trigger source** in this feature; verified via preview mode
  only (accepted in Q3).
- Exact collision layer assignment for hit vs. hurt detection is a Tech Lead design
  decision, constrained by the layer invariant above (never repurpose 1/2/3).

## Context

The ACT player foundation (`act-player-foundation`) and the arena dev hub
(`arena-dev-hub`) are complete and verified. The arena already contains a CombatRange
zone with three inert billboarded dummies (`StaticBody3D`, layer 1 / mask 2, no
script) and a ZonePillar labeled "Inert target dummies … (no logic)". This feature
turns that placeholder zone into a working combat test range while preserving every
HD-2D and architecture invariant established by those features. The Gold Standard for
composition, one-way dependency, and preview mode is
`scripts/world/player_animator.gd`.
