# Task 003: PlayerCombat component + player lock interface + Hurtbox

## Goal
Create `PlayerCombat` (attack buffer, combo progression, hit-window evaluation,
dodge displacement/invincibility/cooldown), the thin `Hurtbox` receiver, and add
the minimal two-field movement-lock interface to `player.gd`. The scene is not
wired yet (task 004), so nothing instantiates `PlayerCombat` here — this task
must leave runtime behavior byte-for-byte unchanged.

## Affected files

**New**
- `scripts/world/player_combat.gd` — `class_name PlayerCombat extends Node3D`.
- `scripts/world/hurtbox.gd` — `class_name Hurtbox extends Area3D`.

**Modified**
- `scripts/world/player.gd` — add `movement_locked: bool` and
  `movement_override: Vector2` (default `false` / `Vector2.ZERO`) and consume
  them in `_apply_horizontal_velocity`.

## Acceptance criteria

### Headless gates
- [ ] `gdlint .` reports **0 problems**.
- [ ] `godot --headless --editor --path . --quit-after 10` runs with **no**
      `ERROR:`, `SCRIPT ERROR`, `Parse Error`, `Failed loading`.
- [ ] `godot --headless --path . --quit-after 5 scenes/act/arena.tscn` runs clean.
- [ ] `godot --headless --path . --quit-after 5 scenes/boot.tscn` runs clean.

### Observable / code-level
- [ ] `player.gd`: with defaults (unlocked, zero override), movement/jump feel is
      unchanged — `PlayerConfig` values and jump-buffer/cut logic untouched.
- [ ] `_apply_horizontal_velocity` branches: override wins → set `velocity.x/z`
      and return; `movement_locked` → friction toward zero and return; else the
      existing accel/friction path.
- [ ] `PlayerCombat` holds `@export player: Player`, `@export animator:
      PlayerAnimator` with `NodePath` fallbacks; `const COMBAT_CONFIG` preloaded.
- [ ] `_unhandled_input` handles `attack`/`dodge` and returns early when
      `DialogueService.is_open()` (gating parity, `design.md` §9).
- [ ] Single buffer slot (`NONE/ATTACK/DODGE` + `input_buffer_time`), combo
      `combo_step 0..3`, `chain_timer`, `dodge_cooldown`, `is_invincible()` all
      implemented per `design.md` §5.
- [ ] Hit-window evaluation: poll `animator.get_phase()`; track window open/close;
      on `HitArea.area_entered(area)`, deliver once per window to `area` when
      `area is Hurtbox` and the window is active.
- [ ] `Hurtbox` exposes `signal hit_received(damage: float, knockback: Vector3)`
      and `receive_hit(...)` re-emitting it; **no** dependency on `TargetDummy`
      or `PlayerCombat`.

## Implementation notes
- `PlayerCombat` runs its logic in `_physics_process(delta)` and polls the
  animator's cached state/phase (`design.md` §5). The ≤1-tick read/write lag is
  acceptable and should be noted in a comment.
- The hit `Area3D` is a scene node wired in task 004; here expose an
  `@export var hit_area: Area3D` (+ `NodePath` fallback) and null-guard its use
  so the script compiles and no-ops before wiring.
- `Hurtbox` is a thin forwarder, not a `Damageable` framework (`design.md` §7).
- Follow the jump-buffer pattern in `player.gd` for the attack/dodge buffer.
- No `add_child`/`free` from signal callbacks: `HitArea` toggling is a flag
  change, not a scene-tree mutation, so no `call_deferred` is required here.

## Constraints (AGENTS.md)
- One-way dependency: combat reads animator + writes only `movement_locked` /
  `movement_override` on the player; no reverse references (rule 2).
- Static typing everywhere (rule 1); `call_deferred` for any scene-tree mutation
  from physics/signal callbacks (rule 5); explicit collision layers 4/5 are wired
  in task 004/005, not hardcoded defaults in this task (rule 6).

## Commit
`feat(combat): 新增 PlayerCombat 组件、Hurtbox 接收器与玩家移动锁定接口`

## Implementation log
<!-- Developer appends: what was done, gate results, any deviation. -->

- Added `scripts/world/player_combat.gd` (`class_name PlayerCombat extends Node3D`):
  single-slot attack/dodge buffer, ground combo `combo_step` 0..3 with
  `chain_timer`, cancel-window advancement, dodge displacement/invincibility/
  cooldown, hit-window evaluation vs a null-guarded `@export hit_area`, typed
  `area is Hurtbox` delivery once per active window. Added `scripts/world/hurtbox.gd`
  (`class_name Hurtbox extends Area3D`) thin forwarder with `hit_received` signal.
  Added `movement_locked` / `movement_override` to `scripts/world/player.gd` and
  consumed them in `_apply_horizontal_velocity` (override wins → lock friction →
  existing path).
- Gates: `gdlint .` 0 problems; headless editor run clean (no ERROR:/SCRIPT
  ERROR/Parse Error/Failed loading); `scenes/act/arena.tscn` and `scenes/boot.tscn`
  smoke tests clean. No deviation.
