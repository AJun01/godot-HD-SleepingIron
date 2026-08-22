# 001 — Player movement + jump on the X–Y play plane

## Context files (read for understanding — do not modify)
- AGENTS.md — GDScript rules (static typing, composition, call_deferred, explicit collision layers/masks), HD-2D invariants
- design.md — global pattern (X–Y play plane, jump buffering + jump-cut, config-driven feel)
- scripts/autoload/dialogue_service.gd — `is_open()` input-lock gate the player must keep honoring
- project.godot — existing InputMap action shape (`move_left`/`move_right`/`advance`) that the new `jump` action mirrors

## Reference files (STRICT STYLE MATCH)
- scripts/world/player.gd — current script being rewritten in place (DialogueService gate, move_toward friction, docstring style)
- scripts/config/player_config.gd — Resource tunables pattern being extended
- AGENTS.md — GDScript law as the Gold Standard

## Required Skills
- godot-sdd (headless validation; typed GDScript + resource conventions)

## Files to create/modify (suggested)
- scripts/world/player.gd — modify (rewrite in place: `class_name Player`, X–Y plane movement, gravity/jump from PlayerConfig, jump buffer + jump-cut, `facing`, `landed` signal)
- scripts/config/player_config.gd — modify (add `gravity`, `jump_velocity`, `jump_buffer_time`, `jump_cut_factor`; retune move_speed/acceleration/friction)
- resources/player_config.tres — modify (write 7.0 / 60.0 / 70.0 / 22.0 / 8.5 / 0.1 / 0.5)
- project.godot — modify (add `jump` action: Space + gamepad A)

## Description
Rewrite the player in place as a CharacterBody3D constrained to the X–Y play plane. Horizontal motion
reads `move_left`/`move_right` (move_up/move_down ignored); Z is pinned to 0. Gravity and jump come from
PlayerConfig, so the `@export var gravity` is removed from the script. Implement jump buffering (a press
shortly before landing fires on landing; window = `jump_buffer_time`) and jump-cut (releasing jump during
ascent multiplies upward velocity by `jump_cut_factor`, applied once per jump). Expose `facing` (sign of the
last non-zero horizontal input, +1 right / -1 left) and a `landed` signal for the animator (task 002), and
keep the `DialogueService.is_open()` input lock on both movement and jump. Add the `jump` InputMap action
(Space + gamepad A) to project.godot. Give player.gd `class_name Player` so later components can hold a
statically-typed reference. Follow design.md for the global pattern.

## Acceptance
- [ ] `gdlint .` reports 0 problems.
- [ ] `godot --headless --editor --path . --quit-after 10` is clean (no ERROR / SCRIPT ERROR / Parse Error / Failed loading).
- [ ] `godot --headless --path . --quit-after 5 scenes/actors/player.tscn` is clean.
- [ ] move_left moves along −X and move_right along +X; move_up/move_down have no effect; Z stays fixed at 0.
- [ ] Jumping starts only on the floor; an air press does nothing unless within `jump_buffer_time`; a buffered press fires on landing.
- [ ] Releasing jump during ascent cuts the ascent short (shorter jump than a held jump).
- [ ] move_speed/acceleration/friction/gravity/jump_velocity are read from PlayerConfig (7.0/60/70/22/8.5); no gravity `@export` remains on the player script.
- [ ] The `jump` action is triggered by Space and gamepad A.

## Needs tests
no

---

## Implementation log (filled by dev after successful commit)
- Commit: fc0e2e54943f63aafd85f3c6e9b5efd75c6417b4 — feat(act-player-foundation): player movement + jump on the X-Y play plane
- Files modified:
  - scripts/world/player.gd (modified)
  - scripts/config/player_config.gd (modified)
  - resources/player_config.tres (modified)
  - project.godot (modified)
- Tests added: none required
- Context & Reference files read:
  - AGENTS.md
  - design.md
  - scripts/autoload/dialogue_service.gd
  - project.godot
  - scripts/world/player.gd
  - scripts/config/player_config.gd
- Notes: none — no files modified outside the suggested list. Validation used gdtoolkit 4.5.0 (gdlint/gdformat) from a temporary venv since gdlint is not installed system-wide; additionally read scenes/actors/player.tscn (acceptance scene), scope.md, .gdlintrc, and .github/workflows/code_review_ci.yml for validation context.
