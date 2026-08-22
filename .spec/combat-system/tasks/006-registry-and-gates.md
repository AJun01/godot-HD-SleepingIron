# Task 006: Artifact registry + docs + final gate verification

## Goal
Write the non-code artifact registry for the feature and run the complete
headless + lint gate suite as the final verification pass. No runtime code
changes.

## Affected files

**New**
- `docs/sdd/artifacts/combat-system.yml` — registry mirroring `arena-dev-hub.yml`.

## Acceptance criteria

### Headless gates (full suite, all clean)
- [ ] `gdlint .` reports **0 problems**.
- [ ] `godot --headless --editor --path . --quit-after 10` runs with **no**
      `ERROR:`, `SCRIPT ERROR`, `Parse Error`, `Failed loading`.
- [ ] `godot --headless --path . --quit-after 5 scenes/act/arena.tscn` runs clean.
- [ ] `godot --headless --path . --quit-after 5 scenes/boot.tscn` runs clean.

### Registry completeness
- [ ] Every touched artifact is registered with `type`, `role`, `invariants`, and
      a `validation` command: `player_animator.gd`, `player.gd`,
      `player_combat.gd`, `target_dummy.gd`, `hurtbox.gd`, `combat_range_zone.gd`,
      `combat_config.gd`, `hit_window.gd`, `resources/combat_config.tres`,
      `resources/hit_windows/*.tres`, `scenes/actors/player.tscn`,
      `scenes/actors/target_dummy.tscn`, `scenes/act/arena.tscn`,
      `assets/placeholders/placeholder_target_dummy.svg` (`status: placeholder`).
- [ ] Each scene entry's `invariants` records its explicit collision layers and
      the preserved dummy positions; each script entry records static typing and
      one-way dependency where applicable.
- [ ] No broken/orphan references: the headless editor import run is clean.

## Implementation notes
- Follow `docs/sdd/artifacts/arena-dev-hub.yml` format exactly (godot-sdd skill):
  `feature: combat-system`, an `artifacts:` list, and per-artifact
  `path`/`type`/`role`/`invariants`/`validation`. Mark the reused dummy SVG with
  `status: placeholder`.
- `validation` for scenes uses the arena/boot smoke commands; scripts/resources
  use the headless editor import command (`design.md` §14).
- Update `tasks.index.md` statuses to `done` only after the gates pass; do not
  hand-edit `scope.md` or `design.md` here.

## Constraints (AGENTS.md)
- Artifact registry is English (artifacts language rule). No code changes in this
  task; a failing gate means the offending earlier commit should be reverted
  (scope rollback plan), not patched here.

## Commit
`docs(combat): 注册战斗系统产物清单并完成全量无头与 lint 门禁验证`

## Implementation log
<!-- Developer appends: what was done, gate results, any deviation. -->

- Wrote `docs/sdd/artifacts/combat-system.yml` mirroring `arena-dev-hub.yml`
  shape: `feature: combat-system` + an `artifacts:` list registering every
  touched artifact with `path`/`type`/`role`/`invariants`/`validation`. Covered:
  `project.godot` (attack/dodge input-map entries + hitbox/hurtbox layer names),
  `scripts/config/hit_window.gd` + `scripts/config/combat_config.gd`,
  `resources/combat_config.tres` + the four `resources/hit_windows/*.tres`,
  `scripts/world/player_animator.gd`, `player.gd`, `player_combat.gd`,
  `hurtbox.gd`, `target_dummy.gd`, `scripts/dev/combat_range_zone.gd`,
  `scenes/actors/player.tscn`, `scenes/actors/target_dummy.tscn`,
  `scenes/act/arena.tscn`, and the reused
  `assets/placeholders/placeholder_target_dummy.svg` (`status: placeholder`).
  Scene entries record explicit collision layers + preserved dummy positions
  (x -5/0/5, z -2, max_hp 100/60/30); script entries record static typing and
  the one-way dependency direction.
- No runtime code or scene changes in this task (documentation only).
- Final full gate suite (all clean): `gdlint .` -> 0 problems;
  `godot --headless --editor --path . --quit-after 10` -> no ERROR:/SCRIPT
  ERROR/Parse Error/Failed loading; `godot --headless --path . --quit-after 5
  scenes/boot.tscn` and `scenes/act/arena.tscn` -> both clean (same grep empty).
