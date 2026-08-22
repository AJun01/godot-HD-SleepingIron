# Verify: Combat System

## Status

Status: PASS

## Summary

Verified the `combat-system` feature end-to-end against `scope.md` / `design.md` /
`tasks.index.md` (tasks 001–006). All six tasks are implemented in six
conventional-commit commits; the full gate suite (gdlint + headless editor +
boot/arena smoke runs) is clean; a 33-assertion headless functional probe
confirmed the combat range is playable — combo + hit windows verifiable against
dummies (dummies take damage, die, and reset).

## Acceptance criteria

### Headless gates (scope.md / task 006)

- [x] `gdlint .` reports 0 problems — `Success: no problems found` (run as
  `/Users/aj/.local/bin/gdlint .`; `gdlint` is installed but not on this shell's
  PATH).
- [x] `godot --headless --editor --path . --quit-after 10` — exit 0; grep for
  `ERROR:` / `SCRIPT ERROR` / `Parse Error` / `Failed loading` is empty.
- [x] `godot --headless --path . --quit-after 5 scenes/boot.tscn` — exit 0; grep
  empty.
- [x] `godot --headless --path . --quit-after 5 scenes/act/arena.tscn` — exit 0;
  grep empty.

### Gameplay-observable criteria (scope.md §Acceptance criteria)

- [x] Ground combo `attack_1 → attack_2 → attack_3` — `PlayerCombat.combo_step`
  0..3 + cancel-window advancement (`_advance_combo`, `is_cancel_window_open`),
  0.15 s single-slot buffer, 0.4 s `chain_timeout` (`player_combat.gd:220-263`,
  `player_animator.gd:199-218`). Probe: `play_combat_state` holds `attack_1`,
  phase reaches `active`, returns to `idle` on `animation_finished`.
- [x] `attack_air` fires airborne, never a ground step —
  `_try_attack`/`_start_air_attack` reset `combo_step=0` and play
  `STATE_ATTACK_AIR` (`player_combat.gd:184-188,245-251`).
- [x] Dodge displacement + full invincibility + 0.5 s cooldown — `_start_dodge`
  records facing, `_dodge_timer=dodge_duration`, `_invincible=true`;
  `_update_dodge` writes `movement_override`; `_end_dodge` sets
  `dodge_cooldown` (`player_combat.gd:266-293`). Probe confirmed
  `is_invincible()` true at start, false after `dodge_duration`.
- [x] Dummies flash on hit, health bar decrements, die at 0 HP, auto-reset 2 s —
  `target_dummy.gd` hit-flash Tween, `scale.x` fill tracking `hp/max_hp`,
  `_enter_dead_state` (hurtbox disabled + bar hidden), `reset()` + `reset_delay`
  timer. Probe: HP 100→65→25→0 on 35/40/50 dmg, dead guard, `reset()`, and
  auto-reset. Three dummies use max HP 100/60/30 (`arena.tscn:292,296,300`).
- [x] `hit`/`death` playable via the animator preview path only (no trigger
  source) — `STATE_HIT`/`STATE_DEATH` are combat one-shots returned to `idle` on
  finish; `play_preview`/`stop_preview` preserved.
- [x] Existing five-state mapping + preview mode unchanged — verified by diff:
  `_desired_state()`, `play_preview`, `stop_preview`, `_on_player_landed` are
  byte-equivalent; the `_process` hold branch is an additive `_is_combat_state`
  guard plus a no-op `_update_phase()` for non-attack states.
- [x] Movement/jump feel unchanged — `resources/player_config.tres` still
  `move_speed=7.0, acceleration=60.0, friction=70.0, gravity=22.0,
  jump_velocity=8.5, jump_buffer_time=0.1, jump_cut_factor=0.5`; the new
  `movement_locked`/`movement_override` default `false`/`Vector2.ZERO`.
- [x] Combat inputs inert while a dialogue is open —
  `player_combat.gd:80` returns early on `DialogueService.is_open()` (same gate
  as movement/jump).

## Functional probe (headless, temporary `--script`-style run)

Ran a temporary scene `res://_verify_probe.tscn` (deleted afterwards) via
`godot --headless --path . --quit-after 1200 res://_verify_probe.tscn` → exit 0,
**33/33 checks PASS**:

- Config mapping: `attack_1/2/3/air` damage `35/40/50/40`, hit-window interval
  `[2,3]` inclusive.
- Arena wiring: three `TargetDummy` instances, `max_hp 100/60/30`, body layer
  1/mask 2, hurtbox layer 5/mask 4, X positions -5/0/5.
- `PlayerCombat` DI: `player`/`animator`/`hit_area` resolved; `HitArea` layer
  4/mask 5.
- Dummy chain: 100→65→25→0 (35/40/50 dmg), dead guard, `reset()`, auto-reset.
- Hit-window delivery once-per-window with config damage (window open/close +
  `_on_hit_area_entered`).
- Animator→combat integration: `play_combat_state(attack_1)` holds the state,
  phase reaches `active` → `PlayerCombat` opens its hit window, one-shot returns
  to `idle`, window closes.
- Dodge: `is_invincible()` true on start, false after `dodge_duration`.

## Gate results (exact outputs)

| Gate | Command | Result |
|------|---------|--------|
| Lint | `/Users/aj/.local/bin/gdlint .` | `Success: no problems found` (0 problems) |
| Editor import | `godot --headless --editor --path . --quit-after 10` | exit 0; error grep empty |
| Boot smoke | `godot --headless --path . --quit-after 5 scenes/boot.tscn` | exit 0; error grep empty |
| Arena smoke | `godot --headless --path . --quit-after 5 scenes/act/arena.tscn` | exit 0; error grep empty |
| Functional probe | `godot --headless --path . --quit-after 1200 res://_verify_probe.tscn` | exit 0; 33/33 PASS |

## Git hygiene

- Six commits, one task = one commit, conventional Chinese messages:
  - `daffbb6` `feat(combat): 添加 attack/dodge 输入与战斗配置、命中窗口资源`
  - `0d63340` `feat(combat): 扩展 player_animator 增加战斗状态与阶段追踪`
  - `bdf8b3d` `feat(combat): 新增 PlayerCombat 组件、Hurtbox 接收器与玩家移动锁定接口`
  - `8d87d78` `feat(combat): 在 player.tscn 接入 Combat 节点与攻击命中区域`
  - `d384661` `feat(combat): 将竞技场假人替换为可命中的 TargetDummy 并接入战斗范围控制器`
  - `52030f9` `docs(combat): 注册战斗系统产物清单并完成全量无头与 lint 门禁验证`
- No unrelated changes: each commit's file list is scoped to its task
  (`git show --stat` verified).
- Minor deviation (cosmetic only): `tasks/004-player-wiring.md` was not included
  in its implementation commit `8d87d78` (which changed only
  `scenes/actors/player.tscn`); the task file itself is complete and is committed
  now with the verify/docs commit. Implementation code is correct and unaffected.
- Working tree ends clean after the verify/docs commit (spec artifacts were
  untracked and are committed here).

## Convention compliance (AGENTS.md)

- Static typing everywhere: HONORED — every new/modified script is fully
  annotated (`player_animator.gd`, `player_combat.gd`, `player.gd`, `hurtbox.gd`,
  `target_dummy.gd`, `combat_range_zone.gd`, `hit_window.gd`, `combat_config.gd`).
- Signals/DI, never `get_node("../../...")`: HONORED — `@export` + defensive
  `NodePath` fallbacks throughout; `Hurtbox.hit_received` typed signal keeps the
  hitbox→hurtbox→dummy coupling one-way.
- Composition over inheritance: HONORED — small single-responsibility
  composables (`PlayerAnimator`, `PlayerCombat`, `Hurtbox`, `TargetDummy`,
  `combat_range_zone`); no god script.
- Tunables in Resources / `@export`: HONORED — `CombatConfig`/`HitWindow`/dummy
  HP/flash/reset are all Resource or `@export` values; no hardcoded gameplay
  values in scripts.
- `call_deferred` for tree mutation from signal callbacks: HONORED —
  `target_dummy.gd:87` (`_apply_hit_feedback.call_deferred()`) and
  `combat_range_zone.gd:59` (`_reset_dummies.call_deferred()`).
- Explicit collision layers/masks: HONORED — player body 2/1, `HitArea` 4/5,
  dummy body 1/2, `Hurtbox` 5/4, reset pad 3/2; `project.godot` layer names
  `hitbox=4`/`hurtbox=5`; layers 1/2/3 never repurposed.
- Naming: HONORED — snake_case files, PascalCase nodes/classes, `class_name` only
  for the globally-registered classes (`Player`, `PlayerAnimator`, `PlayerCombat`,
  `Hurtbox`, `TargetDummy`, `CombatConfig`, `HitWindow`).
- HD-2D invariants: HONORED — billboarded `Sprite3D`/`Label3D`/health-bar quads;
  placeholder dummy SVG reused, no numbers baked into the health bar (dynamic
  fill).
- Invariants preserved: five-state mapping + preview mode additive-only (diff
  verified); `PlayerConfig` values untouched; collision layers 1/2/3 meanings
  unchanged.

## Limitations

- `hit`/`death` are states only — verified via the animator preview/one-shot
  path; no player HP or damage source exists by design (scope Q3, out of scope).
- The hit-window *logic* (phase → window open/close → config damage delivery
  once-per-window → dummy damage/death/reset) is verified deterministically;
  the final per-frame physics *overlap* between the positioned `HitArea` and a
  dummy `Hurtbox` during a live animation is exercised by the arena smoke run +
  matching layers 4/5, not by a deterministic headless overlap assertion.
- Visual polish is placeholder-level by design (dummy = reused SVG placeholder,
  health bar = two billboard quads, hit-flash = modulate pulse) — final art is
  the human developer's job per AGENTS.md.

## PR

- Target branch: master
- PR opened: yes (see session report)
