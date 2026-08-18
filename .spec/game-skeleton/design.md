# Design: Game Skeleton

## Existing conventions honored
- Source of truth: AGENTS.md
- Language & framework: GDScript, Godot 4.7 stable, Forward Plus renderer, Jolt Physics (AGENTS.md "Project identity")
- Folder structure pattern: scenes/ grouped by area (world/, ui/), scripts/ with autoloads in scripts/autoload/, assets/ subfolders, docs/ (AGENTS.md "Directory conventions")
- Naming conventions: snake_case.gd / snake_case.tscn files; PascalCase node names and classes; class_name only for globally registered classes (AGENTS.md "GDScript rules" #7)
- State / data-flow pattern: central GameFlow autoload state machine (single progression entry), EventBus typed signals, @export dependency injection, Resource files for tunables (AGENTS.md "Architecture law (user-mandated)")
- Testing setup: none declared (no unit-test framework in AGENTS.md)
- Specific rules being honored:
  - Full static typing everywhere (AGENTS.md "GDScript rules" #1)
  - Signals for decoupling, no get_node("../../...") (#2)
  - Composition over inheritance (#3)
  - Tunables in Resource files or @export (#4)
  - call_deferred for scene-tree mutation from signal/physics callbacks (#5)
  - Explicit collision layers and masks (#6)
  - Comments explain "why" in English (#8)
  - 3D world carries lighting; sprites billboard (#85–90 "HD-2D visual invariants")
  - SVG placeholders under assets/placeholders/, registered with status: placeholder (#94–106)
  - Headless validation gate (#51–61, and godot-sdd SKILL.md)

## Technical approach
The game boots into a minimal boot scene (the configured main scene), which immediately hands control to the central `GameFlow` autoload state machine — the single entry for all linear progression. `GameFlow` owns the ordered stage sequence (menu → chapter) read from a `FlowConfig` Resource and never lets a scene advance itself. Every stage change flows through the `SceneRouter` autoload, which runs a full-screen fade via a lazily-created CanvasLayer overlay and swaps scenes with `call_deferred`, refusing any request while a transition is in flight. Cross-cutting events (state changes, transition start/finish) travel over typed `EventBus` signals. The main menu is a Godot Control scene whose buttons only call `GameFlow` methods; the chapter scene is a lit 3D world (DirectionalLight3D + WorldEnvironment) holding a billboarded placeholder player (CharacterBody3D + Sprite3D) that moves in 8 directions via InputMap actions and is followed by a Camera3D follow component. All tunables (stage paths, fade duration/color, movement speed/acceleration) live in `.tres` Resource files or `@export`. All art is self-authored SVG placeholders registered in the artifact registry with `status: placeholder`. Quit semantics: the menu "Quit" button exits the application via `GameFlow.request_quit()`; from the chapter, `ui_cancel` requests `GameFlow.request_quit_to_menu()` — both close the loop with no dead ends.

## Modules / components touched
- GameFlow (autoload) — central linear state machine; owns progression and guards every request against its current state
- SceneRouter (autoload) — scene routing + fade transition with an in-progress guard
- EventBus (autoload) — typed signals for decoupled cross-scene events
- FlowConfig / FlowStage (Resource) — ordered stage definitions (id + scene path)
- TransitionConfig (Resource) — fade duration + color tunables
- PlayerConfig (Resource) — movement speed / acceleration / friction tunables
- Boot scene — minimal entry that starts the flow
- Main menu scene — New Game / Quit controls calling GameFlow
- Chapter scene — HD-2D lit world: ground, billboarded player + environment prop, camera follow
- Player component — CharacterBody3D + billboarded Sprite3D, 8-direction InputMap movement
- Camera follow component — Camera3D tracking an @export target with smoothing
- Artifact registry — docs/sdd/artifacts YAML listing scenes + placeholder SVGs

## Patterns / abstractions
- Autoload service layer (small single-responsibility singletons) — reused, mandated by Architecture law
- Central state machine as single progression entry — new, mandated by Architecture law
- EventBus typed signals at coupling boundaries — mandated by AGENTS.md rule #2
- Resource-driven tunables — mandated by AGENTS.md rule #4
- Composition via child scenes/components + @export DI — mandated by rule #3 and Architecture law
- SceneRouter transition guard — new (required by the "transition in progress ignores duplicates" criterion)

## Trade-offs
- Chose a dedicated boot scene as the main scene (over pointing the main scene at the menu) so the very first screen change also flows through GameFlow + SceneRouter — one uniform progression entry per the Architecture law.
- Chose a Resource-backed ordered stage list (FlowConfig) over hardcoded menu/chapter paths so future stages (combat, dialogue) are additive without rewriting the state machine, per "modular + extensible".
- Chose @export/Resource tunables over constants, per AGENTS.md rule #4.
- Chose a small camera-follow component over hard-parenting the Camera3D to the player, for later camera bounds/cutscenes while staying minimal.
- Chose a project-root `resources/` directory for `.tres` data files; AGENTS.md defines no Resource directory (see Gaps).

## Out of scope (technical)
- Dialogue content/system, combat, inventory, save/load, audio — hooks only or absent.
- Final UI/art/audio assets and main-menu visual design — SVG placeholders only.
- No unit-test framework added (none declared in AGENTS.md).
- No free-roam or world-map systems (linear game).

## Gaps for human attention
- AGENTS.md "Directory conventions" does not define where Resource data files (`.tres`) live. I chose a project-root `resources/` directory (idiomatic Godot) for FlowConfig/TransitionConfig/PlayerConfig. Please confirm or redirect, since it sets where all future tunable data lives.
