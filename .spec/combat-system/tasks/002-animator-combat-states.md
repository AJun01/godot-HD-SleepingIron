# Task 002: Animator combat states + phase tracking

## Goal
Extend `player_animator.gd` (the Gold Standard) **additively** with the seven
combat states (`attack_1/2/3`, `attack_air`, `hit`, `dodge`, `death`), per-attack
wind-up/active/recovery phase tracking, a `play_combat_state()` entry point, and
`state_changed`/`phase_changed` signals. The existing five-state mapping and
preview mode must keep their exact behavior (scope invariant).

## Affected files

**Modified**
- `scripts/world/player_animator.gd`

## Acceptance criteria

### Headless gates
- [ ] `gdlint .` reports **0 problems**.
- [ ] `godot --headless --editor --path . --quit-after 10` runs with **no**
      `ERROR:`, `SCRIPT ERROR`, `Parse Error`, `Failed loading`.
- [ ] `godot --headless --path . --quit-after 5 scenes/act/arena.tscn` runs clean
      (the animation-preview zone still loads and the existing preview path is
      unaffected).
- [ ] `godot --headless --path . --quit-after 5 scenes/boot.tscn` runs clean.

### Observable / code-level
- [ ] The existing five states (`idle/run/jump/fall/land`) map exactly as before:
      `_desired_state()` logic, `land` hold, `landed` handling, and
      `play_preview`/`stop_preview` are byte-equivalent in behavior.
- [ ] Seven new `STATE_*` constants and four `PHASE_*` constants
      (`none/wind_up/active/recovery`) exist.
- [ ] `play_combat_state(state: StringName)` starts a combat one-shot; combat
      states are held by `_process` (not remapped by `_apply_desired_state()`)
      and return to `idle` in `_on_animation_finished()`.
- [ ] While in an attack state, the phase is recomputed each `_process` frame
      from `sprite.frame` vs. the state's `HitWindow` interval (read via the
      `preload`ed `CombatConfig`); `dodge/hit/death` report `PHASE_NONE`.
- [ ] Public accessors `get_state()`, `get_phase()`, `get_frame_progress()`,
      `is_cancel_window_open()` exist and are null-safe when `sprite`/config are
      unavailable.
- [ ] `state_changed(state)` and `phase_changed(state, phase)` signals emit on
      transition.

## Implementation notes
- Config is `const COMBAT_CONFIG: CombatConfig =
  preload("res://resources/combat_config.tres")`, matching `player.gd`'s
  `PLAYER_CONFIG` pattern (see `design.md` §2 "DI style"). Guard phase tracking
  so a null `sprite` or a missing window degrades to `PHASE_NONE`.
- Phase boundaries come **only** from the `HitWindow` `start_frame`/`end_frame`
  (`design.md` §3.2); the animator ignores `damage`/`knockback`.
- Cancel window (`design.md` §3.3): open only in an attack state in `recovery`
  when recovery progress `>= cancel_recovery_threshold` (default `0.6`).
  Recovery progress = `(frame - end_frame) / (frame_count - 1 - end_frame)`.
- Keep `_apply_state()` the single place that sets `_current_state` + plays the
  sprite; emit `state_changed` there.
- `play_combat_state` is not called by anything in this task (combat arrives in
  task 003), so this task is verified by compilation + preserved invariants.

## Constraints (AGENTS.md)
- Additive change only — do not rewrite `_desired_state()` or preview mode.
- Static typing on every new field/parameter/return (rule 1); `StringName` for
  state/phase constants (rule 7); comments explain *why* (rule 8).
- No new scene-tree mutations from signal callbacks in this task.

## Commit
`feat(combat): 扩展 player_animator 增加战斗状态与阶段追踪`

## Implementation log
<!-- Developer appends: what was done, gate results, any deviation. -->

- Extended `scripts/world/player_animator.gd` additively: seven combat `STATE_*`
  constants, four `PHASE_*` constants, `state_changed`/`phase_changed` signals,
  `play_combat_state()`, per-frame hit-window phase tracking, and null-safe
  accessors `get_state`/`get_phase`/`get_frame_progress`/`is_cancel_window_open`.
  The five-state mapping and preview mode were preserved behaviorally.
- Gates: `gdlint .` → 0 problems; headless editor run clean (no ERROR / SCRIPT
  ERROR / Parse Error / Failed loading); `scenes/act/arena.tscn` and
  `scenes/boot.tscn` smoke tests clean.
