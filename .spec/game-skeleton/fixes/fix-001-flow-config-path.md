# fix-001 — Reconcile chapter stage path to canonical `chapter.tscn`

## Context files (read for understanding — do not modify)
- resources/flow_config.tres — line 14 sets the chapter `FlowStage.scene_path` to the stale `res://scenes/world/chapter_01.tscn` (introduced in commit `fa229bc`, task 001).
- docs/sdd/artifacts/game-skeleton.yml — lines 54 and 61 declare and validate the stale `scenes/world/chapter_01.tscn` (introduced in commit `caca192`, task 002).
- scenes/world/chapter.tscn — the canonical chapter scene (created in commit `f62fc24`, task 004); confirm it is the only scene under `scenes/world/`.
- scripts/autoload/game_flow.gd — how `stage.scene_path` flows into `SceneRouter.transition_to()` (do not modify).

## Reference files (STRICT STYLE MATCH)
- resources/flow_config.tres — correct `.tres` sub-resource shape for a `FlowStage` (`id` + `scene_path`).
- docs/sdd/artifacts/game-skeleton.yml — registry entry shape (`path` / `type` / `role` / `invariants` / `validation`).

## Required Skills
- godot-sdd

## Files to create/modify (suggested)
- resources/flow_config.tres — modify (point the chapter `FlowStage` at `res://scenes/world/chapter.tscn`)
- docs/sdd/artifacts/game-skeleton.yml — modify (registry `path` + `validation` command to `scenes/world/chapter.tscn`)

## Description

Verifier failure — failing acceptance criterion, quoted verbatim from the failure report:

> "`resources/flow_config.tres:14` points the chapter stage at `res://scenes/world/chapter_01.tscn`, which does not exist — the real scene is `scenes/world/chapter.tscn` (task 004). A runtime probe of the exact `change_scene_to_file` call returned `ERROR: Failed loading resource` (err=19), so the New Game → chapter transition (acceptance #2) hangs on a black fade. `docs/sdd/artifacts/game-skeleton.yml:54,61` is stale with the same wrong path."

Root cause: tasks 001/002 referenced the chapter scene by its then-planned name `chapter_01.tscn`, but task 004 actually created it as `chapter.tscn`. `FlowConfig` (and its registry mirror) were never reconciled to the real file, so `GameFlow` hands `SceneRouter` a nonexistent path and the transition dead-ends on the fade.

Minimal fix: reconcile both the `FlowConfig` chapter `scene_path` and the registry's chapter entry (path + validation command) to the canonical `res://scenes/world/chapter.tscn`. No scene/script logic changes; no scope expansion.

## Acceptance
- [ ] `resources/flow_config.tres` chapter `FlowStage.scene_path` is `res://scenes/world/chapter.tscn` (no `chapter_01` reference remains).
- [ ] `docs/sdd/artifacts/game-skeleton.yml` chapter entry `path` is `scenes/world/chapter.tscn` and its `validation` command targets `scenes/world/chapter.tscn` (no `chapter_01` reference remains).
- [ ] Regression — the reported dead-end is gone: `godot --headless --path . --quit-after 5 scenes/world/chapter.tscn` exits 0 with no `Failed loading` / `ERROR:` (the registry's own validation command now resolves to an existing scene).
- [ ] Regression — a runtime probe of `change_scene_to_file("res://scenes/world/chapter.tscn")` returns `err=0` (the exact call that previously returned `err=19` now loads), so New Game → chapter transition no longer hangs on the fade.

## Needs tests
no
(Project has no unit-test framework — `tasks.index.md` "Project has tests: no", AGENTS.md "Testing setup: none declared". The regression is covered by the headless Godot validation commands in Acceptance above.)

---

## Implementation log (filled by dev after successful commit)
- Commit: 2134436 — fix(game-skeleton): reconcile chapter stage path to canonical chapter.tscn
- Files modified:
  - resources/flow_config.tres (modified)
  - docs/sdd/artifacts/game-skeleton.yml (modified)
- Tests added: none required
- Context & Reference files read:
  - resources/flow_config.tres (Context + Reference)
  - docs/sdd/artifacts/game-skeleton.yml (Context + Reference)
  - scenes/world/chapter.tscn (Context)
  - scripts/autoload/game_flow.gd (Context)
- Notes: `scenes/world/chapter.tscn` confirmed as the only scene under `scenes/world/`. Runtime probe `change_scene_to_file("res://scenes/world/chapter.tscn")` returns err=0 (previously err=19). Remaining `chapter_01` references exist only in `.spec/game-skeleton/{tasks,verify.md}` historical artifacts and were intentionally left untouched (spec files are never hand-edited).
