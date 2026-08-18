# Design: Chapter 1 Demo

## Existing conventions honored
- Source of truth: AGENTS.md
- Language & framework: GDScript, Godot 4.7 stable, Forward Plus renderer, Jolt Physics (AGENTS.md "Project identity")
- Folder structure pattern: `scenes/` grouped by area (world/, ui/, actors/), `scripts/` with autoloads in `scripts/autoload/`, `assets/` subfolders (incl. `fonts/`), `resources/` for `.tres`, `docs/sdd/artifacts/` for the artifact registry (AGENTS.md "Directory conventions"; `resources/` location precedent from game-skeleton design.md "Gaps for human attention")
- Naming conventions: `snake_case.gd` / `snake_case.tscn` files; PascalCase node names and classes; `class_name` only for globally registered classes (AGENTS.md "GDScript rules" #7)
- State / data-flow pattern: central `GameFlow` autoload state machine as the single progression entry; `EventBus` typed signals at coupling boundaries; `@export` dependency injection; Resource files for tunables/data (AGENTS.md "Architecture law (user-mandated)")
- Testing setup: none declared (no unit-test framework in AGENTS.md). The acceptance gate is the CI validation block: `gdlint .`, `godot --headless --editor --path . --quit-after 10`, `godot --headless --path . --quit-after 5 <scene>` (AGENTS.md "Validation"; godot-sdd SKILL.md)
- Specific rules being honored:
  - Full static typing everywhere (AGENTS.md "GDScript rules" #1)
  - Signals for decoupling; no `get_node("../../...")` (#2)
  - Composition over inheritance; no god-scripts (#3 + Architecture law)
  - Tunables/data in `Resource` files or `@export` (#4)
  - `call_deferred` for scene-tree mutation from signal/physics callbacks (#5)
  - Explicit collision layers and masks on every physics body/area (#6)
  - Comments explain "why" in English (#8)
  - Linear game, single progression entry, no free roam (Architecture law)
  - 3D world carries lighting; sprites billboard toward camera (HD-2D visual invariants)
  - SVG placeholders under `assets/placeholders/` registered with `status: placeholder` (Role boundary & art placeholder policy)
  - Headless + gdlint validation gates (Validation; godot-sdd SKILL.md)

## Technical approach
Selecting "New Game" walks the player through four ordered chapter stages (home front → field road → town → return) before a "Chapter 1 DEMO complete" ending stage auto-returns to the menu. Progression stays owned by `GameFlow`: `FlowConfig` gains the four chapter stage entries plus the menu and an ending entry, each carrying a scene path, a `state` tag (`menu` / `chapter`), and an objective string; `GameFlow` adds a guarded `request_advance_stage()` that a stage calls when its beat completes, and emits a `stage_changed` signal carrying the new objective. Interaction is a composable `Interactable` component (Area3D proximity + interact key) holding a `DialogueData` Resource; it hands that Resource to a `DialogueService` autoload, which owns a dialogue bar and advances line-by-line on the advance key while the player suppresses movement; the walk-only field-road stage instead uses a `StageExit` zone component to advance. An `ObjectiveHud` autoload listens for `stage_changed` and renders the current objective, hiding when the string is empty, so it can never show a stale stage's text. Dialogue and objectives are Chinese and render through a bundled OFL Noto Sans SC font applied as the project-wide default theme. NPCs and stage props are self-authored SVG placeholders registered with `status: placeholder`; each beat is a faithful, compressed excerpt of the novel's chapter-1 lines.

## Modules / components touched
- `GameFlow` (autoload) — central FSM; gains stage-state mapping (via a `state` tag), a guarded `request_advance_stage()`, and `stage_changed` emission
- `SceneRouter` (autoload) — reused as-is; its busy flag is the interaction-during-transition guard
- `EventBus` (autoload) — new typed signal `stage_changed(stage_index, objective)`
- `FlowStage` / `FlowConfig` (Resource) — stage gains `state` + `objective`; config gains the 4 chapter stages + ending entry
- `DialogueData` (Resource) — ordered lines (+ optional speaker) for one beat; the data contract a future full dialogue system consumes
- `DialogueService` (autoload) — owns the dialogue bar UI, line-by-line advance, movement-block contract, and close-on-transition
- `Interactable` (component) — proximity detection + interact key + dialogue trigger + optional stage-advance on completion
- `StageExit` (component) — walk-into-zone advance trigger for the NPC-less field-road stage
- `ObjectiveHud` (autoload) — canvas HUD label bound to the current stage's objective, hidden when empty
- `Player` (component) — extracted into a reusable scene; suppresses movement while dialogue is open
- `Stage` controller — per-stage root that forwards `ui_cancel` to `GameFlow` and is otherwise driven by components
- Ending screen — "Chapter 1 DEMO complete" placeholder that auto-returns to the menu
- UI theme — project-wide `Theme` resource carrying the CJK font
- Artifact registry — `docs/sdd/artifacts/chapter-1-demo.yml` listing font + placeholders + scenes

## Patterns / abstractions
- Autoload service layer (small single-responsibility singletons) — reused, mandated by Architecture law
- Central state machine as the single progression entry — reused, extended with `request_advance_stage()` (no scene self-advances)
- `EventBus` typed signals at coupling boundaries — reused, extended with `stage_changed`
- Resource-driven data/tunables — reused; dialogue content lives in `DialogueData` Resources, never in scenes/scripts
- Composition via child scenes/components + `@export` DI — reused; `Interactable` and `StageExit` are components added to scene nodes
- New abstraction — `DialogueData` as the dialogue swap contract: `Interactable` only ever hands a `DialogueData` to `DialogueService.play()`; a future full dialogue system replaces the consumer (the service) while keeping the `play(DialogueData)` entry point, so stages and `Interactable` are never rewritten (scope "future full dialogue system must be able to replace it without rewriting stages")
- New field (not a new abstraction) — `FlowStage.state` tag, so new chapter stages are added in `FlowConfig` only, never in `GameFlow` code (scope "new stages extend FlowConfig, never code")

## Trade-offs
- Chose a project-wide default UI theme carrying Noto Sans SC over per-label font overrides, because dialogue, objective HUD, and all future Chinese UI need CJK and one theme is the single robust source. Cost: the menu's Latin text also renders in Noto Sans SC — an acceptable cosmetic change.
- Chose `Interactable` calling `DialogueService.play()` directly (over an `EventBus` relay for dialogue) because autoload-direct calls are the established skeleton pattern (menu → `GameFlow`, chapter → `GameFlow`) and the swap boundary is the `play(DialogueData)` contract.
- Chose a dedicated ending `FlowStage` (over an in-scene overlay) so the ending screen follows the same `GameFlow`/`SceneRouter` path and "new stages extend FlowConfig, never code".
- Chose replay-on-reinteract (over skip) for non-advancing NPCs, because re-emitting the same `DialogueData` is trivial and can never softlock; advancing NPCs leave the stage before a re-trigger can happen.
- Chose a walk-into-zone `StageExit` for the field-road stage (which has no required NPC) over adding a worker NPC, keeping the NPC roster to the five named in scope.
- Chose distinct `interact` (E) and `advance` (Enter/Space) InputMap actions so the press that opens a dialogue never also advances its first line; the opening press is consumed via `set_input_as_handled()`.

## Out of scope (technical)
- Combat, inventory, save/load, audio — none added.
- Full branching dialogue system — only the minimal bar + the `DialogueData` swap contract.
- Input remapping / settings UI.
- Final/production art and audio — SVG placeholders only.
- No unit-test framework is added (none declared in AGENTS.md); verification is `gdlint .` + Godot headless + manual run.
- No refactor of `SceneRouter` or the `EventBus`/`GameFlow` state machine beyond the additive `request_advance_stage()` and `stage_changed`.

## Gaps for human attention
- The CJK font binary (Noto Sans SC, OFL) must be obtained and vendored under `assets/fonts/` (plus its OFL license text); the repo currently ships no font. If the implementing agent has no network access, the human must supply the font file before task 001 can proceed. Headless CI is unaffected once the file is present (font import is headless-safe).
- Exact compressed dialogue lines are a faithfulness-sensitive content decision. Task 006 pins the source line ranges in the novel and the "no invented lore" rule, but the human should review the final compressed lines against `docs/source/正文.md` before merge.
