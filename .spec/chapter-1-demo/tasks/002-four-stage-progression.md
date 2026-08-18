# 002 — Four-stage progression (FlowConfig + GameFlow)

## Context files (read for understanding — do not modify)
- scripts/autoload/game_flow.gd — current FSM: `_state_for_stage_id`, `_transition_to_stage`, request_* methods, rollback on busy SceneRouter
- scripts/autoload/event_bus.gd — existing typed-signal style to extend
- scripts/autoload/scene_router.gd — `transition_to()` return value + busy flag used by the guard
- scripts/config/flow_stage.gd — `FlowStage` fields (`id`, `scene_path`) to extend
- resources/flow_config.tres — current menu + chapter entries and `.tres` serialization shape

## Reference files (STRICT STYLE MATCH)
- scripts/autoload/game_flow.gd — FSM style, docstring conventions, request_* guards to imitate
- scripts/autoload/event_bus.gd — typed-signal declaration style
- AGENTS.md — "Architecture law": GameFlow is the ONLY progression entry; "new stages extend FlowConfig, never code"

## Required Skills
- godot-sdd (headless validation of `.tres` + autoload changes)

## Files to create/modify (suggested)
- scripts/config/flow_stage.gd — modify (add `state: StringName` + `objective: String` exports with defaults)
- scripts/autoload/game_flow.gd — modify (map state from `stage.state`; add guarded `request_advance_stage()`; emit `stage_changed`)
- scripts/autoload/event_bus.gd — modify (add `signal stage_changed(stage_index: int, objective: String)`)
- resources/flow_config.tres — modify (6 ordered stages: menu, chapter_home, chapter_field, chapter_town, chapter_return, chapter_ending)

## Description
Extend the linear skeleton so the chapter is four ordered stages instead of one. Give `FlowStage` a
`state` tag (`&"menu"` | `&"chapter"`) and an `objective` string; rewrite `FlowConfig` to list, in
order: menu (0), home (1), field road (2), town (3), return (4), ending (5) — each chapter stage and
the ending tagged `state = &"chapter"`, with the stage's objective text (menu and ending objective
empty). In `GameFlow`, derive the target state from `stage.state` (replacing the id match) so future
chapter stages need no code change, add `request_advance_stage()` guarded to `State.CHAPTER` that
transitions to `_current_stage_index + 1` (bounds-checked by the existing `_transition_to_stage`),
and emit `EventBus.stage_changed(stage_index, stage.objective)` only after `SceneRouter.transition_to`
confirms the transition started (so the HUD updates at fade-start and never on a rolled-back request).
Scene paths may point at stage scenes created in later tasks — `FlowConfig` stores them as strings, so
headless boot (menu stage only) stays clean. Follow `design.md`.

## Acceptance
- [ ] `FlowConfig` lists 6 stages in fixed order: menu, chapter_home, chapter_field, chapter_town, chapter_return, chapter_ending (scope AC #3).
- [ ] Each `FlowStage` carries `state` (`&"menu"`/`&"chapter"`) and `objective`; menu + ending objectives are empty (scope AC #3, #10).
- [ ] `GameFlow` maps `stage.state` to `State.MENU`/`State.CHAPTER` (no per-stage id match) and `request_advance_stage()` is a no-op unless `_state == State.CHAPTER` (scope AC #3, #11).
- [ ] `stage_changed(stage_index, objective)` is emitted exactly once per successful transition, carrying the new stage's objective (scope AC #10).
- [ ] `godot --headless --editor --path . --quit-after 10` and `godot --headless --path . --quit-after 5 scenes/boot.tscn` are clean.
- [ ] `gdlint .` reports 0 problems.

## Needs tests
no

---

## Implementation log (filled by dev after successful commit)
- Commit: 57667f78fda1db53d1e01c716671a262e06efab8 — feat(chapter-1-demo): 实现四阶段线性推进与阶段变更信号
- Files modified:
  - resources/flow_config.tres (modified)
  - scripts/autoload/event_bus.gd (modified)
  - scripts/autoload/game_flow.gd (modified)
  - scripts/config/flow_stage.gd (modified)
- Tests added: none required
- Context & Reference files read:
  - scripts/autoload/game_flow.gd
  - scripts/autoload/event_bus.gd
  - scripts/autoload/scene_router.gd
  - scripts/config/flow_stage.gd
  - resources/flow_config.tres
  - AGENTS.md
- Notes: Scene paths for the 4 chapter stages + ending are placeholder strings (scenes/world/chapter_{home,field,town,return,ending}.tscn) pointing at scenes created in later tasks, so headless boot (menu only) stays clean. Objective strings are provisional Chinese text derived from scope.md beats; human should review against docs/source/正文.md before merge. Kept FlowStage.id as the stable identifier; GameFlow now maps stage.state (tag) instead of id. Extra files read for context: scripts/config/flow_config.gd, .spec/chapter-1-demo/scope.md, scenes/boot.tscn + scripts/boot.gd, scenes/ui/main_menu.tscn + scripts/ui/main_menu.gd, resources/transition_config.tres.
