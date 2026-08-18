# 001 — Autoload service layer + config

## Context files (read for understanding — do not modify)
- AGENTS.md — GDScript rules 1–8, Architecture law, Validation gate (the law for this task)
- project.godot — current engine config to extend (no autoloads/main_scene yet)
- .dsh/skills/godot-sdd/SKILL.md — headless validation commands + acceptance rules

## Reference files (STRICT STYLE MATCH)
- AGENTS.md — the only authoritative style/architecture standard (scope.md declares no gold-standard code; greenfield)
- .dsh/skills/godot-sdd/SKILL.md — engine-level validation conventions to mirror

## Required Skills
- godot-sdd (engine validation conventions; referenced throughout AGENTS.md and docs/SDD.md)

## Files to create/modify (suggested)
- project.godot — modify (register autoloads EventBus → SceneRouter → GameFlow; add [input] move actions; add [layer_names])
- scripts/autoload/event_bus.gd — create (typed cross-scene signals)
- scripts/autoload/scene_router.gd — create (fade + deferred scene swap + in-progress guard)
- scripts/autoload/game_flow.gd — create (central linear state machine)
- scripts/config/flow_config.gd — create (FlowStage + FlowConfig Resource classes)
- scripts/config/transition_config.gd — create (TransitionConfig Resource class)
- resources/flow_config.tres — create (ordered stages: menu → chapter)
- resources/transition_config.tres — create (fade duration + color)

## Description
Build the progression plumbing that every later system plugs into: three small autoloads in
dependency order. `EventBus` holds typed signals only (no logic). `SceneRouter` exposes
`transition_to(scene_path) -> bool` (returns false and does nothing if a transition is already
running), runs a full-screen fade through a lazily-created CanvasLayer + ColorRect, and performs
the actual scene swap with `call_deferred` so no scene-tree mutation happens mid-signal.
`GameFlow` is the single state machine (BOOT → MENU → CHAPTER, plus an internal TRANSITIONING
guard), reads its ordered stages from `FlowConfig`, and exposes `start_flow()`,
`request_new_game()`, `request_quit_to_menu()`, and `request_quit()`; every request is rejected
unless it is legal for the current state, so duplicate or out-of-sequence flow changes are
impossible. No scene loads happen in autoload `_ready` (all scene loading is lazy at transition
time). Follow design.md for the global pattern.

## Acceptance
- [ ] project.godot registers autoloads in order: EventBus, SceneRouter, GameFlow.
- [ ] project.godot defines move actions (move_left/move_right/move_up/move_down: keyboard WASD + arrows, gamepad dpad + left stick) and layer names (layer 1 = world, layer 2 = player).
- [ ] `godot --headless --editor --path . --quit-after 10` is clean (grep: no `ERROR:`, `SCRIPT ERROR`, `Parse Error`, `Failed loading`).
- [ ] All three autoloads load without error; SceneRouter exposes `transition_to() -> bool` + `is_transitioning() -> bool`; GameFlow exposes the four request methods.
- [ ] SceneRouter returns false on a duplicate transition request while one is in progress; GameFlow rejects requests illegal for its current state (blocks input-before-transition and out-of-sequence changes).
- [ ] All scripts fully static-typed; snake_case files; PascalCase classes; no get_node("../../..."); English "why" comments.

## Needs tests
no

---

## Implementation log (filled by dev after successful commit)
- Commit: fa229bcd2d62d3080942e00c3c8ca7560e05c2d4 — feat(game-skeleton): 添加自动加载服务层与流程配置
- Files modified:
  - project.godot (modified)
  - scripts/autoload/event_bus.gd (created)
  - scripts/autoload/event_bus.gd.uid (created)
  - scripts/autoload/scene_router.gd (created)
  - scripts/autoload/scene_router.gd.uid (created)
  - scripts/autoload/game_flow.gd (created)
  - scripts/autoload/game_flow.gd.uid (created)
  - scripts/config/flow_config.gd (created)
  - scripts/config/flow_config.gd.uid (created)
  - scripts/config/flow_stage.gd (created)
  - scripts/config/flow_stage.gd.uid (created)
  - scripts/config/transition_config.gd (created)
  - scripts/config/transition_config.gd.uid (created)
  - resources/flow_config.tres (created)
  - resources/transition_config.tres (created)
- Tests added: none required
- Context & Reference files read:
  - AGENTS.md
  - project.godot
  - .dsh/skills/godot-sdd/SKILL.md
- Notes:
  - Validation: `godot --headless --editor --path . --quit-after 10` clean — no `ERROR:`, `SCRIPT ERROR`, `Parse Error`, or `Failed loading` (grep exit 1). Global classes FlowConfig/FlowStage/TransitionConfig registered. Runtime sanity checks also passed: duplicate `transition_to()` returns false; illegal GameFlow requests from BOOT cause zero state changes; deferred scene swap + fade + `transition_finished` all fire.
  - Deviation: added `scripts/config/flow_stage.gd` beyond the suggested list. Godot 4 cannot load a typed `Array[FlowStage]` of an inner class from a `.tres` (verified: "Cannot assign contents of Array[Object]" + empty array), so `FlowStage` is a top-level `class_name` in its own file.
  - Deviation: the three autoload scripts intentionally declare no `class_name` (a `class_name` matching an autoload name is a Parse Error: "Class hides an autoload singleton"). They are referenced by autoload global name; `EventBus.game_state_changed` is `int`-typed to avoid a cross-autoload type dependency.
  - `resources/flow_config.tres` scene paths are placeholders chosen from AGENTS.md conventions: `res://scenes/ui/main_menu.tscn` and `res://scenes/world/chapter_01.tscn`. Scenes are created in later tasks (003/004); confirm these paths match.
  - Godot generated the `*.gd.uid` files during import; they are committed alongside their scripts.
