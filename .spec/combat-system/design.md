# Design: Combat System

> Design of record for the `combat-system` feature. Derived from
> `.spec/combat-system/intake.md` (authoritative) and `scope.md`, and from the
> inspected Gold Standard `scripts/world/player_animator.gd` plus its supporting
> references. Where scope.md left a concrete number or naming decision to the
> Tech Lead, the decision is recorded here under "Design decisions".

## 1. Overview

Wire a **minimal closed combat loop** into the player so the `attack_1/2/3`
ground combo, `attack_air`, `dodge`, and the `hit`/`death` states can be
exercised against the arena's three target dummies. Attacks are driven by the
animation state machine with **wind-up → active (hit window) → recovery**
phases; hit windows live in Resource files (frame interval + damage +
knockback). The dummies become hittable targets (hit-flash, billboard health
bar, death, 2 s auto-reset). Everything is composable, tunable, and extensible —
a learning project, so no framework, no EventBus, no god script.

## 2. Component architecture

Three-layer split (confirmed in intake Q7), one-way dependency:

```
Player (physics)          <- reads-  PlayerAnimator (animation)
  ^                                   ^
  | writes public lock                | reads state/phase/frame
  | fields only                       |
  +--------- PlayerCombat (logic) ----+
              |  spawns/positions a hit Area3D
              v
        Hurtbox (dummy)  ->  TargetDummy
```

- **`PlayerAnimator`** (`scripts/world/player_animator.gd`, Gold Standard) is
  the *animation layer*. It is extended **additively** with the combat states and
  per-attack phase tracking. It still reads `player` one-way (velocity,
  `is_on_floor()`, `facing`). The existing five-state mapping
  (`idle/run/jump/fall/land`) and the preview mode are unchanged (scope
  invariant).
- **`PlayerCombat`** (`scripts/world/player_combat.gd`, new) is the *logic
  layer*. It owns the attack input buffer, combo progression, hit-window
  evaluation + hit `Area3D` generation, and dodge displacement/invincibility/
  cooldown. It reads the animator's public state/phase/frame progress and writes
  **only** the player's public lock fields. It never references the animator
  from the player, and the player never references either component (one-way).
- **`Player`** (`scripts/world/player.gd`) gains **only** a minimal public
  movement-lock interface (two fields, default unlocked/zero — see §6). No
  reverse references; no reference to the animator or combat component.

### Dependency direction (hard invariant)
`PlayerAnimator` → `Player` (read only) · `PlayerCombat` → `PlayerAnimator`
(read only) · `PlayerCombat` → `Player` (writes two public fields only) ·
`PlayerCombat` → `Hurtbox` (via the hit `Area3D`) · `TargetDummy` → `Hurtbox`
(via a typed signal). No reverse references, no `get_node("../../...")`.

### DI style
Node references use `@export` + defensive `NodePath` fallback (exactly the
Gold Standard / `animation_preview_zone.gd` pattern). Config values are
preloaded as `const` Resources, mirroring `player.gd`'s
`const PLAYER_CONFIG = preload("res://resources/player_config.tres")` pattern.
There is **no** new EventBus signal and no autoload change — the closed loop is
wired by direct DI through the hit `Area3D` (§7), which is all this feature
needs.

## 3. State machine design

### 3.1 Full state set
Existing five physics-derived states plus seven combat states:

| State | Type | Driven by | Held until |
|-------|------|-----------|------------|
| `idle` | physics | mapping | remapped each frame |
| `run` | physics | mapping | remapped each frame |
| `jump` | physics | mapping (hysteresis) | remapped each frame |
| `fall` | physics | mapping | remapped each frame |
| `land` | physics one-shot | `landed` signal | `animation_finished` |
| `attack_1` | combat one-shot | `PlayerCombat` | `animation_finished` or cancel |
| `attack_2` | combat one-shot | `PlayerCombat` | `animation_finished` or cancel |
| `attack_3` | combat one-shot | `PlayerCombat` | `animation_finished` |
| `attack_air` | combat one-shot | `PlayerCombat` | `animation_finished` |
| `hit` | combat one-shot | preview only (Q3) | `animation_finished` |
| `dodge` | combat one-shot | `PlayerCombat` | `animation_finished` |
| `death` | combat one-shot | preview only (Q3) | `animation_finished` |

`hit`/`death` are **states only** (Q3): no trigger source, no player HP. They
are playable via the existing preview path (`play_preview`) and, like every
combat one-shot, return to `idle` on `animation_finished`.

### 3.2 Phase decomposition (attack states only)
Each of `attack_1/2/3` and `attack_air` is decomposed into three phases, driven
by the current sprite frame against the `HitWindow` frame interval (§4):

- **wind_up** — frames `[0, start_frame)`.
- **active** (hit window) — frames `[start_frame, end_frame]` inclusive.
- **recovery** — frames `(end_frame, last_frame]`.

`dodge`, `hit`, and `death` have no hit window; their phase is `PHASE_NONE`.
The animator exposes `get_phase() -> StringName` and emits `state_changed` /
`phase_changed` signals; the phase is recomputed each `_process` frame while in
an attack state from `sprite.frame` (0-based index) vs. the state's `HitWindow`.

### 3.3 Q1 combo rhythm
All timings are `CombatConfig` tunables (§4):

- **Cancel window**: the next combo step may cancel the current one once the
  recovery phase is `>= cancel_recovery_threshold` (default `0.6`) complete.
- **Input buffer**: `0.15 s` (`input_buffer_time`); **at most one** buffered
  press, no queuing (a single buffer slot, §5.2).
- **Chain timeout**: after an attack one-shot finishes with no follow-up, the
  animator returns to `idle` immediately (the animation is over); the *combo*
  keeps its current step for `0.4 s` (`chain_timeout`), so a follow-up press
  inside that window continues the combo. After `0.4 s` the combo resets to step
  0 (a fresh press starts `attack_1`).

> Interpretation note: "return to idle 0.4 s after recovery ends" is read as
> "the animation returns to idle at one-shot end; the *combo chain window*
> (ability to continue) lasts 0.4 s". Visually the character is briefly idle
> during that window — this is the DNF-style lenient rhythm the user accepted.

### 3.4 Q2 movement lock
- Ground attacks (`attack_1/2/3`) and `attack_air` set `player.movement_locked`
  → movement input is ignored and horizontal velocity decays to zero at the
  existing `friction` rate (smooth stop; gravity continues, so `attack_air`
  still falls).
- `dodge` carries its own displacement (§5.4): it writes the player's
  `movement_override`, it does **not** use the movement lock.
- `hit`/`death` set no lock in this feature (no trigger source; the lock is
  applied later by the future enemy-AI feature).

## 4. Resource design (all tunables — rule 4)

### 4.1 `HitWindow` (`scripts/config/hit_window.gd`, `class_name HitWindow`)
One instance per attack (`attack_1/2/3/attack_air`); stored in
`resources/hit_windows/*.tres`. Fields:

| Field | Type | Default | Meaning |
|-------|------|---------|---------|
| `start_frame` | `int` | `2` | first active frame (inclusive, 0-based) |
| `end_frame` | `int` | `3` | last active frame (inclusive) |
| `damage` | `float` | per attack | damage dealt once per dummy per active window |
| `knockback` | `Vector3` | `Vector3.ZERO` | reserved; static dummy ignores it (see §7) |

The active window `[start_frame, end_frame]` is the **single source of truth**
for the phase boundaries: the animator reads only these two fields (phase
tracking); `PlayerCombat` reads `damage`/`knockback` (and the same interval) to
drive the hit. Default damage (RISK note: Tech Lead defaults, all tunable):

| Attack | damage |
|--------|--------|
| `attack_1` | `35` |
| `attack_2` | `40` |
| `attack_3` | `50` |
| `attack_air` | `40` |

With dummy HP 100/60/30 (§8): the 100 HP dummy dies on the 3rd combo hit, the
60 HP dummy on the 2nd, the 30 HP dummy on the 1st — each combo step is
exercised by at least one dummy.

### 4.2 `CombatConfig` (`scripts/config/combat_config.gd`, `class_name CombatConfig`)
One instance `resources/combat_config.tres`. Holds player-side tunables + the
four `HitWindow` references:

| Field | Type | Default | Meaning |
|-------|------|---------|---------|
| `input_buffer_time` | `float` | `0.15` | attack/dodge input buffer (s) |
| `chain_timeout` | `float` | `0.4` | post-attack combo chain window (s) |
| `cancel_recovery_threshold` | `float` | `0.6` | recovery progress to unlock cancel |
| `dodge_speed` | `float` | `12.0` | dodge horizontal speed (units/s) |
| `dodge_duration` | `float` | `0.3` | dodge + invincibility duration (s) |
| `dodge_cooldown` | `float` | `0.5` | post-dodge cooldown (s) |
| `hit_box_size` | `Vector3` | `(1.0, 1.6, 0.8)` | hit Area3D box size |
| `hit_box_offset` | `Vector3` | `(0.7, 0.0, 0.0)` | hit box center in front (facing applied) |
| `attack_1_window` | `HitWindow` | — | ref to `resources/hit_windows/attack_1.tres` |
| `attack_2_window` | `HitWindow` | — | ref |
| `attack_3_window` | `HitWindow` | — | ref |
| `attack_air_window` | `HitWindow` | — | ref |

Dodge invincibility spans the full `dodge_duration` (Q4 "full invincibility");
no separate invincibility timer. Dummy HP/flash/reset live on the self-contained
`TargetDummy` (§8), **not** in `CombatConfig` — the dummy must not depend on the
player's combat config (scope "self-contained component").

## 5. `PlayerCombat` design (`scripts/world/player_combat.gd`)

`class_name PlayerCombat extends Node3D`. Child of the player scene, wired via
`@export` DI to `player: Player` and `animator: PlayerAnimator` (with
`NodePath` fallbacks). Config is `const COMBAT_CONFIG: CombatConfig =
preload("res://resources/combat_config.tres")`. All logic runs in
`_physics_process(delta)` and polls the animator's cached state/phase (the
animator updates it in `_process`); the ≤1-physics-tick read lag and the
≤1-tick write lag for `movement_override` are acceptable for a 6-frame window
and are documented, not hidden.

### 5.1 Input handling
`_unhandled_input` handles `attack` and `dodge`, gated identically to movement/
jump: `if DialogueService.is_open(): return` (dialogue-open parity). Presses set
the buffer slot (§5.2); immediate cancel is handled in §5.3.

### 5.2 Buffer (single slot, at most one press)
`_buffered_action: Action { NONE, ATTACK, DODGE }` + `_buffer_timer`. A press
sets the slot only if it is empty, and starts `input_buffer_time`. If the slot
is full, the press is dropped (no queuing). The timer ticks down; an expired,
unconsumed buffer is dropped.

### 5.3 Combo progression (decision table, evaluated each physics frame)
`combo_step: int` — `0` = none, `1..3` = `attack_1..3`. `chain_timer` counts
down after an attack ends.

| Situation | Result |
|-----------|--------|
| Grounded, `combo_step == 0`, ATTACK buffered or pressed | start `attack_1`, `combo_step = 1`, lock movement |
| In `attack_1`/`attack_2`, cancel window open, ATTACK buffered | advance step → play next attack, clear buffer |
| In `attack_1`/`attack_2`, cancel window open, ATTACK pressed (immediate) | advance step immediately, do not buffer |
| In `attack_3`, cancel window open, ATTACK | ignore (no step 4) |
| Attack ended, `chain_timer > 0`, `combo_step in {1,2}`, ATTACK | advance step → play next attack |
| Attack ended, `chain_timer` expired | `combo_step = 0` (fresh press restarts) |
| Airborne, not in a combat state, ATTACK | play `attack_air`, `combo_step = 0`, lock movement |
| In `attack_air`, ATTACK | ignore (standalone, never a ground step) |
| In `dodge`/`hit`/`death`, ATTACK | buffered per §5.2 (consumed later if valid) |
| DODGE buffered, not in a combat state, cooldown ready | start dodge (§5.4), clear buffer |
| DODGE pressed during an attack | buffered once; fires when the attack ends |
| DODGE pressed during `dodge`/cooldown | ignored |

When an attack one-shot ends and `combo_step < 3`, combat starts `chain_timer =
chain_timeout`; on expiry `combo_step = 0`. Starting a dodge or `attack_air`
resets `combo_step = 0`.

### 5.4 Dodge (Q4)
On dodge start: `combo_step = 0`, `_dodge_timer = dodge_duration`, record
`_dodge_direction = player.facing`, set `_invincible = true`. Each frame while
`_dodge_timer > 0`: `player.movement_override =
Vector2(_dodge_direction * dodge_speed, 0.0)` (X = displacement, Z = 0; gravity
still runs so an airborne dodge falls). On end: clear `movement_override`,
`_invincible = false`, `_dodge_cooldown_timer = dodge_cooldown`. Expose
`is_invincible() -> bool` (future damage sources check it; nothing damages the
player in this feature).

### 5.5 Hit window evaluation + hit `Area3D`
A persistent `HitArea` (`Area3D`, layer 4 / mask 5) is a scene child of the
`Combat` node (§7). Combat polls the animator each frame:

- window opened (phase becomes `active` in an attack state) → clear the
  per-window hit set, set current `damage`/`knockback` from the state's
  `HitWindow`, set `_window_active = true`.
- window closed (phase leaves `active`) → `_window_active = false`.
- on `HitArea.area_entered(area)`: if `_window_active` and `area is Hurtbox` and
  `area` not already in the per-window set → add it and call
  `area.receive_hit(damage, knockback)` (each dummy hit at most once per active
  window).

`HitArea` is repositioned to
`Vector3(player.facing * hit_box_offset.x, hit_box_offset.y, hit_box_offset.z)`
and its `CollisionShape3D` box resized from `hit_box_size` in `_ready`. It stays
in the tree and always monitors; the `_window_active` gate prevents hits outside
the active window (no `add_child`/`free` at runtime → no `call_deferred` needed
for hit-window toggling).

## 6. Player movement-lock interface (`scripts/world/player.gd`)

Two public fields, default `false` / `Vector2.ZERO` so pre-combat movement is
byte-for-byte unchanged (scope invariant):

```gdscript
## Combat-set lock: while true, movement input is ignored and horizontal
## velocity decays toward zero (attack_1/2/3, attack_air).
var movement_locked: bool = false

## Combat-set override: while non-zero, this is the horizontal velocity
## (dodge carries its own movement); gravity still runs.
var movement_override: Vector2 = Vector2.ZERO
```

`_apply_horizontal_velocity` gains two branches before the normal accel/friction
path: (1) `movement_override != Vector2.ZERO` → set `velocity.x/z` to it and
return; (2) `movement_locked` → apply friction toward zero and return. No other
change to `player.gd`. No `class_name` change, no new signals.

## 7. Hit detection design (collision layers)

| Layer | Name | Owner | Mask | Meaning |
|-------|------|-------|------|---------|
| 1 | `world` | solids (ground, walls, dummy body) | 2 | unchanged |
| 2 | `player` | `Player` body | 1 | unchanged |
| 3 | `interaction` | dev-zone pads | 2 | unchanged |
| **4** | `hitbox` | player `HitArea` | **5** | attack hit area |
| **5** | `hurtbox` | dummy `Hurtbox` | **4** | damage receiver |

Layers 1/2/3 are **never repurposed** (scope invariant). New layer names
`hitbox`/`hurtbox` are added to `project.godot` `[layer_names]` (metadata only).

- **Hit area** (`HitArea`): `Area3D` child of `Combat`, layer 4 / mask 5,
  persistent `CollisionShape3D` (box). PlayerCombat connects its
  `area_entered`; it drives damage (typed `area is Hurtbox` check).
- **Hurtbox** (`scripts/world/hurtbox.gd`, `class_name Hurtbox`): thin receiver,
  `Area3D` child of the dummy, layer 5 / mask 4. It has **no** dependency on
  `TargetDummy` or `PlayerCombat`; it exposes:
  `signal hit_received(damage: float, knockback: Vector3)` and
  `func receive_hit(damage, knockback): hit_received.emit(...)`. This keeps the
  coupling one-way (hitbox → hurtbox → dummy via signal) and stays a *thin
  forwarder*, not a general damageable framework (scope out-of-scope).
- `knockback` is delivered in the hit payload but the static dummy ignores it
  (a `StaticBody3D` cannot move, and dummy positions are an arena invariant).
  It is retained as a Resource tunable so a future dynamic damage receiver can
  use it without a schema change.

## 8. `TargetDummy` design (`scripts/world/target_dummy.gd`)

`class_name TargetDummy extends StaticBody3D`. Self-contained component shared
by the three dummies. `@export` tunables (rule 4): `max_hp: float = 100.0`,
`reset_delay: float = 2.0`, `hit_flash_duration: float = 0.12`,
`hit_flash_color: Color = Color(1, 0.25, 0.25)`. The three arena instances set
`max_hp = 100 / 60 / 30`.

- **Hit-flash**: on `take_damage`, set `Sprite3D.modulate = hit_flash_color`,
  then a `Tween` lerps modulate back to `Color.WHITE` over `hit_flash_duration`.
- **Billboard health bar**: built in the dummy scene as two billboarded
  `MeshInstance3D` quads (dark background, red fill) with
  `billboard_mode = ENABLED` on their materials; the fill quad's `scale.x`
  tracks `hp / max_hp` (left-anchored). Dynamic bar → no numbers baked into art
  (AGENTS.md HD-2D invariant).
- **Death**: at `hp <= 0` → dead state: hurtbox stops receiving (disable the
  `Hurtbox` or gate `take_damage`), modulate darkens, health bar hidden. Later
  hits do nothing until reset (scope edge case).
- **Auto-reset**: a `reset_delay` timer (`2 s`) restores full HP, modulate,
  health bar, and re-enables the hurtbox.

`take_damage(damage: float, knockback: Vector3)` is called by the dummy's own
`Hurtbox.hit_received` connection; `knockback` is accepted and ignored (static).

## 9. Input map additions + gating parity

Add to `project.godot` `[input]` (defaults; user can rebind):

| Action | Keyboard | Joypad |
|--------|----------|--------|
| `attack` | `J` (physical `74`) | face button `2` (X / Square) |
| `dodge` | `K` (physical `75`) | face button `1` (B / Circle) |

Keyboard bindings use `physical_keycode` for consistency with the existing
WASD/E bindings; joypad buttons 1/2 are free (button 0 is already used by
jump/interact/advance). Gating parity: `PlayerCombat._unhandled_input` returns
early when `DialogueService.is_open()`, exactly like `player.gd`'s jump gate and
the `_read_movement_input` gate.

## 10. Arena CombatRange wiring

Replace the three inert `StaticBody3D` dummies (positions x = -5 / 0 / 5, z = -2)
with the hittable dummy scene (§8), **keeping their exact positions** and their
collision body (layer 1 / mask 2, `BoxShape3D 0.7×2.2×0.5` at y = +1.1). Each
dummy gains: the `TargetDummy` script, a child `Hurtbox` (Area3D layer 5 /
mask 4, box matching the body), the billboard health bar, and its `max_hp`
(100/60/30). The `ZonePillar` `responsibility` text becomes
`"Hittable target dummies: combo damage, hit-flash, health bars, death + auto-reset"`.

Add `scripts/dev/combat_range_zone.gd` (composable `Node3D`, following
`animation_preview_zone.gd`: `@export` DI + `NodePath` fallbacks, `Area3D` reset
pad on interaction layer 3 / mask 2, `call_deferred` mutation, `Label3D` status).
It holds `@export var dummies: Array[TargetDummy]` and a `reset_pad_path`; walking
on the pad resets all dummies to full HP (`call_deferred`), and the status label
reports a short hint / reset confirmation. Bounded to reset + status conveniences
(scope).

## 11. Artifact registry

`docs/sdd/artifacts/combat-system.yml`, mirroring `arena-dev-hub.yml`, registers
every touched scene/script/resource with `type`, `role`, `invariants`, and a
`validation` command; the reused `placeholder_target_dummy.svg` stays `status:
placeholder`. Populated in the final task so all entries reflect reality.

## 12. Non-goals (mirror scope.md out-of-scope)

- Player HP / player damage / player death logic — `hit`/`death` are states only.
- Damage sources other than the player's own hit windows.
- Enemy AI / NPC combat behavior.
- A systematic damage-receiver framework (the dummy is self-contained; `Hurtbox`
  is a thin forwarder, not an abstraction).
- Combat SFX/VFX (hit-stop, camera shake, particles, sounds).
- Save data for combat state (nothing persists).
- Final art/audio (human developer's job; placeholders only).
- New EventBus signals / autoloads (the closed loop uses direct DI).

## 13. Design decisions worth the Orchestrator's attention

1. **Config is `preload`ed, dummy is self-contained.** `PlayerAnimator` and
   `PlayerCombat` `preload` `combat_config.tres` (the existing `player.gd`
   `PLAYER_CONFIG` pattern) rather than `@export`-wiring the Resource, so the
   animator's phase tracking works before the scene wiring task. Dummy HP/flash/
   reset live on `TargetDummy` `@export`s (not in `CombatConfig`) so the dummy
   has no dependency on player config.
2. **A thin `hurtbox.gd` exists** (not in scope.md's New-file list). It keeps the
   hitbox→hurtbox→dummy coupling one-way and lets `PlayerCombat`'s typed
   `area is Hurtbox` check compile independently of the dummy; it is a forwarder,
   not a general `Damageable` framework.

## 14. Validation gates (every task)

```bash
gdlint .   # 0 problems (config .gdlintrc)
godot --headless --editor --path . --quit-after 10   # no ERROR:/SCRIPT ERROR/Parse Error/Failed loading
godot --headless --path . --quit-after 5 scenes/act/arena.tscn
godot --headless --path . --quit-after 5 scenes/boot.tscn
```
