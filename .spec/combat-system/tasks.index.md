# Tasks Index: Combat System

> Ordered implementation tasks for the `combat-system` feature. Each task is one
> logical concern = one commit, and lands the repo in a **green state** (the
> headless gates in `design.md` §14 run clean after every task). Read
> `../design.md` for the full design; each task file is self-contained.

| id | title | summary | status |
|----|-------|---------|--------|
| 001 | Combat input actions + combat config/hit-window Resources | Add `attack`/`dodge` input actions + `hitbox`/`hurtbox` layer names; create `HitWindow` + `CombatConfig` scripts and their `.tres` files | done |
| 002 | Animator combat states + phase tracking | Extend `player_animator.gd` with 7 combat states, wind-up/active/recovery phase tracking, `play_combat_state`, and phase/state signals | done |
| 003 | PlayerCombat component + player lock interface + Hurtbox | Create `player_combat.gd` (buffer/combo/hit-window/dodge) and `hurtbox.gd`; add the two-field movement-lock interface to `player.gd` | done |
| 004 | Player scene wiring | Add the `Combat` node + persistent `HitArea` to `player.tscn`; wire player/animator references | done |
| 005 | Hittable dummy scene + combat-range zone + arena rewiring | Create `target_dummy.gd` + dummy scene; add `combat_range_zone.gd`; replace the 3 inert dummies and update the ZonePillar text | done |
| 006 | Artifact registry + docs + final gate verification | Write `docs/sdd/artifacts/combat-system.yml` and run the full gate suite | done |

## Ordering rationale

- **001 → 002 → 003** build the leaf types first (Resources, then the animator,
  then the combat component) so each script compiles against already-existing
  `class_name`s; `hurtbox.gd` ships with 003 because `player_combat.gd`'s typed
  `area is Hurtbox` check needs the class at compile time.
- **004** wires the scene (the only `player.tscn` edit, one commit) so the
  combat component becomes live; attacks/dodge animate and lock movement even
  though no hurtbox exists yet.
- **005** makes the dummies hittable; the loop closes.
- **006** is documentation + a final clean-gate pass and does not change runtime
  code.

## Fixes

| id | title | summary | status |
|----|-------|---------|--------|
| fix-001 | Air attack mobility | `attack_air` no longer locks movement; keeps air-movement input + momentum (ground attacks keep the lock) | done |
| fix-002 | Walk/run two-tier movement | DNF-style: hold = walk, double-tap = run (`walk_speed` + `double_tap_window` in PlayerConfig) | done |
| fix-003 | Arena text legibility | Smaller, non-overlapping pillars/status labels; paths dropped from the 3D pillar text | done |
| fix-004 | Arena text final pass | Title-only pillars, bounded wrap width, thinner outline, thicker dummy health bar | done |
| fix-005 | Combat range status position | Move CombatRange StatusLabel above title/bars (y ≈ 3.6), shorten hint/reset strings | done |
| fix-006 | Combat status depth alignment | Move CombatRange StatusLabel to (0, 4.2, -7) on the pillar depth plane; center dummy health bar (center_offset 0,0,0) | pending |
