# fix-003 — SaveService save path error reporting + bool return

## Context files (read for understanding — do not modify)
- scripts/autoload/save_service.gd — offending file (commit `25d79a5`). `save_player_state()` silently `return`s when `FileAccess.open` fails; it must `push_error` and return a bool success indicator.
- scripts/dev/save_load_trigger.gd — the caller of `save_player_state`/`load_player_state`; confirms the return-type change does not break its call sites.

## Reference files (STRICT STYLE MATCH)
- scripts/autoload/save_service.gd — the existing statically-typed service + shared key-constants style to keep the change symmetric and minimal.
- AGENTS.md — GDScript rule #1 (static typing) + rule #8 (comments explain "why") + validation gate (headless run must be clean).

## Required Skills
- godot-sdd (headless validation)

## Files to create/modify (suggested)
- scripts/autoload/save_service.gd — modify (`save_player_state` returns `bool` + `push_error` on open failure; `load_player_state` gains matching `push_error` on failure, keeping its empty-Dictionary default)

## Description
GitHub AI review issue **#47 (low)**: *"scripts/autoload/save_service.gd — `save_player_state()` silently returns when FileAccess.open fails. Fix: push_error with a descriptive message and return a bool success indicator from the save path (load path may keep its current empty-default behavior or gain a matching bool per your judgment — prefer symmetric bool returns with push_error on failure)."*

Change `save_player_state(position: Vector3, facing: int)` to `save_player_state(position: Vector3, facing: int) -> bool`: on `FileAccess.open` failure call `push_error("...")` with a descriptive message (naming `SAVE_PATH`) and `return false`; on a successful write `return true`. For the load path, keep `load_player_state() -> Dictionary` returning the empty `{}` default on failure (its existing, caller-checked failure indicator) but add a descriptive `push_error` on each failure branch (open failure, parse-not-Dictionary, decode failure) so load no longer fails silently either — this is the symmetric error reporting the review prefers, without a breaking return-type change to `save_load_trigger.gd` (which reads `var state: Dictionary = SaveService.load_player_state()`). Do not change the JSON shape, key constants, or the caller.

## Acceptance
- [ ] `save_player_state` is annotated `-> bool`; it returns `true` on a successful write and `false` after a descriptive `push_error` when `FileAccess.open(SAVE_PATH, FileAccess.WRITE)` returns null.
- [ ] `load_player_state` keeps `-> Dictionary` with the empty `{}` default on failure, and each failure branch (open / parse / decode) calls `push_error` with a descriptive message.
- [ ] `scripts/dev/save_load_trigger.gd` still compiles and runs unchanged (its `SaveService.save_player_state(...)` and `load_player_state()` call sites are untouched).
- [ ] `grep -n "push_error" scripts/autoload/save_service.gd` shows error reporting on both the save and load failure paths.
- [ ] `gdlint .` reports 0 problems.
- [ ] `godot --headless --editor --path . --quit-after 10` is clean; `godot --headless --path . --quit-after 5 scenes/act/arena.tscn` is clean (no `ERROR:`/`SCRIPT ERROR`/`Parse Error`/`Failed loading`).

## Needs tests
no

---

## Implementation log (filled by dev after successful commit)
- Commit: b441899baa0225046c717b6740f65facec257182 — fix(arena-dev-hub): report save/load errors and return bool from save path
- Files modified:
  - scripts/autoload/save_service.gd (modified)
- Tests added: none required
- Context & Reference files read:
  - scripts/autoload/save_service.gd
  - scripts/dev/save_load_trigger.gd
  - AGENTS.md
- Notes: Pre-existing uncommitted changes (tasks.index.md, assets/sprites/player/player_sheet.png.import, untracked .spec/arena-dev-hub/fixes/) were left unstaged and are not part of this commit.
