# fix-002 — Parameterize HUD test health values via @export

## Context files (read for understanding — do not modify)
- scripts/autoload/objective_hud.gd — offending file (commit `c8b5b5d`). `TEST_HEALTH_MAX` / `TEST_HEALTH_VALUE` are hardcoded smoke-test constants; the values must come from the caller instead.
- scripts/dev/ui_hud_trigger.gd — offending file (commit `c8b5b5d`). Its `MODE_HEALTH` branch calls `ObjectiveHud.show_test_health_bar()`; it must carry the values as `@export` tunables and pass them through the direct call path.

## Reference files (STRICT STYLE MATCH)
- scripts/autoload/objective_hud.gd — the lazily-built `CanvasLayer` + `ProgressBar` pattern to preserve (deferred-instantiation safety).
- AGENTS.md — GDScript rule #4 (tunables in `Resource`/`@export`, never hardcoded) + rule #5 (`call_deferred` for tree mutation from signal callbacks) + rule #1 (static typing).

## Required Skills
- godot-sdd (headless validation)

## Files to create/modify (suggested)
- scripts/autoload/objective_hud.gd — modify (drop `TEST_HEALTH_MAX`/`TEST_HEALTH_VALUE`; parameterize `show_test_health_bar(max_value: float, current_value: float)` and `_show_test_health_bar`)
- scripts/dev/ui_hud_trigger.gd — modify (add `@export` `test_health_max: float = 100.0` / `test_health_value: float = 72.0`; pass them to `ObjectiveHud.show_test_health_bar`)

## Description
GitHub AI review issue **#45 (low)**: *"scripts/autoload/objective_hud.gd — TEST_HEALTH_MAX/TEST_HEALTH_VALUE are hardcoded smoke-test constants. Per AGENTS.md rule 4, the test values should come from the caller: change `show_test_health_bar()` to accept max/current parameters (e.g. `show_test_health_bar(max_value: float, current_value: float)`) and update the UI/HUD zone trigger (scripts/dev/ui_hud_trigger.gd) to carry them as @export tunables (default 100/72) passed through the EventBus/DialogueService-free direct call path. Preserve the existing deferred-instantiation safety."*

Remove the `TEST_HEALTH_MAX` / `TEST_HEALTH_VALUE` constants. Change the public `show_test_health_bar()` to `show_test_health_bar(max_value: float, current_value: float)` and thread the two values through `_show_test_health_bar(max_value: float, current_value: float)`, which sets `bar.max_value` (before `bar.value`, so the value is not clamped by a stale max) then `bar.value`, then makes the bar visible. Preserve the existing deferred-instantiation safety: the first show still defers `_show_test_health_bar` via `call_deferred` when `_bar == null`, because it may run from a physics signal callback. In `ui_hud_trigger.gd`, add two `@export` tunables (`test_health_max: float = 100.0`, `test_health_value: float = 72.0`) and pass them through the existing direct `ObjectiveHud.show_test_health_bar(...)` call (no EventBus/DialogueService involved). Defaults 100/72 keep the rendered bar identical to today.

## Acceptance
- [ ] `grep -n "TEST_HEALTH_MAX\|TEST_HEALTH_VALUE" scripts/autoload/objective_hud.gd` returns no matches; the smoke-test constants are gone.
- [ ] `show_test_health_bar(max_value: float, current_value: float)` applies the passed max/current to the `ProgressBar` (max set before value); the first show still goes through `call_deferred` (deferred-instantiation safety preserved).
- [ ] `scripts/dev/ui_hud_trigger.gd` declares `@export` `test_health_max: float = 100.0` and `test_health_value: float = 72.0` and passes both through the direct `ObjectiveHud.show_test_health_bar(...)` call in `MODE_HEALTH`.
- [ ] With default tunables the bar renders 100 max / 72 current (visually unchanged); changing the tunables in the scene updates the bar.
- [ ] `gdlint .` reports 0 problems.
- [ ] `godot --headless --editor --path . --quit-after 10` is clean; `godot --headless --path . --quit-after 5 scenes/act/arena.tscn` is clean (no `ERROR:`/`SCRIPT ERROR`/`Parse Error`/`Failed loading`).

## Needs tests
no

---

## Implementation log (filled by dev after successful commit)
- Commit: 19739bab45587d021d652f74d0a47bdf9abdfc23 — fix(arena-dev-hub): parameterize HUD test health values via @export
- Files modified:
  - scripts/autoload/objective_hud.gd (modified)
  - scripts/dev/ui_hud_trigger.gd (modified)
- Tests added: none required
- Context & Reference files read:
  - scripts/autoload/objective_hud.gd
  - scripts/dev/ui_hud_trigger.gd
  - AGENTS.md
- Notes: none
