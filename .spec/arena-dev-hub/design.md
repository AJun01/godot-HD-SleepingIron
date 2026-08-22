# Design: Arena Dev Hub

## Existing conventions honored
- Source of truth: AGENTS.md (no CLAUDE.md at the repo root).
- Language & framework: GDScript on Godot 4.7 stable (Forward Plus, Jolt Physics); artifacts written in English.
- Folder structure pattern: `scripts/` grouped by domain (autoload/, world/, config/, dev/); `scenes/` grouped by area (act/, actors/, dev/, ui/, world/); `resources/` holds `.tres` tunables; `assets/` holds art/audio; `docs/` holds references.
- Naming conventions: snake_case files, PascalCase nodes/classes, `class_name` only for globally-registered classes (AGENTS.md GDScript rule #7).
- State / data-flow pattern: autoload services (EventBus, SceneRouter, GameFlow, DialogueService, ObjectiveHud) + `@export` dependency injection + typed signals; tunables live in Resource files.
- Testing setup: none declared (no unit-test tool). Validation = `gdlint` + Godot headless smoke (AGENTS.md "Validation").
- Specific rules being honored:
  - AGENTS.md "GDScript rules": static typing everywhere (#1); signals/DI, never `get_node("../../...")` (#2); composition over inheritance (#3); tunables in Resources (#4); `call_deferred` for scene-tree mutation from physics/signal callbacks (#5); explicit collision layers/masks (#6); snake_case (#7).
  - AGENTS.md "Architecture law": linear stage machine; modular/composable services; EventBus at coupling boundaries.
  - AGENTS.md "HD-2D visual invariants": billboarded sprites; 3D world scene carries lighting; nearest-neighbor filtering.
  - AGENTS.md "Role boundary & placeholder policy": SVG placeholders under `assets/placeholders/` with `status: placeholder`; placeholder audio is sanctioned here (scope: "placeholder beeps acceptable").
  - godot-sdd skill: headless validation gates + non-code artifact registry (`docs/sdd/artifacts/<slug>.yml`).

## Technical approach
The project is stripped to a single development stage: GameFlow becomes a two-state machine (BOOT → ARENA) that boots directly into the rebuilt arena, and all chapter/menu scenes, scripts, resources, and placeholder assets are deleted so nothing else is reachable. The arena is rebuilt as a flat, lit 3D facility with six physically distinct zones laid out along the walkable plane, each marked by a billboarded Label3D pillar stating the system name, a one-line responsibility, and the key file paths. A central wall plane shows a hand-maintained architecture SVG whose nodes are the autoloads/scenes and whose edges are their dependencies. Each zone is realized with small single-responsibility composables: static props for the movement zone and inert combat dummies, an animator preview mode plus a zone controller for the animation preview, a minimal SaveService autoload plus save/restore triggers, a health-bar extension to ObjectiveHud plus dialogue triggers for the UI/HUD zone, and placeholder-beep SFX triggers for the audio zone. Zones talk only through their services or `@export` DI; no new EventBus signals are required.

## Modules / components touched
- GameFlow — simplified to a single-stage boot→arena state machine (EventBus signals kept).
- FlowConfig / FlowStage — removed along with flow_config.tres (the single-stage flow is no longer data-driven).
- Arena scene — rebuilt into the six-zone test facility (lighting, ground, zones, player, camera).
- ZonePillar — new composable Label3D pillar (title + one-line responsibility + file paths).
- ArchitectureWall — new plane textured with the maintained architecture SVG + regeneration doc.
- PlayerAnimator — extended with a preview mode to play a forced animation.
- AnimationPreviewZone — new composable controller (cycle the 12 animations + flip facing).
- ObjectiveHud — extended with a test health-bar show/hide.
- DialogueService — reused unchanged for the dialogue smoke test.
- SaveService — new minimal autoload (JSON position + facing).
- SaveLoadTrigger / SfxTrigger / UiHudTrigger — new composable Area3D triggers.
- Placeholder assets — target-dummy SVG, architecture SVG, beep WAVs.

## Patterns / abstractions
- Reuse: `@export` DI with NodePath defensive resolution (player_animator / side_view_camera pattern); Area3D trigger on interaction layer 3 detecting player layer 2 (interactable / stage_exit pattern, re-derived after those files are deleted); lazily-built autoload CanvasLayer (ObjectiveHud / DialogueService pattern); Resource tunables; EventBus signals for flow coupling.
- New abstractions: SaveService autoload (no save system exists; scope RISK resolves to "introduce the minimal version"); PlayerAnimator preview mode (previewing the 12 animations must override the physics-derived state machine); ZonePillar and the three trigger composables (small single-responsibility components per the Architecture law). No new EventBus signals.

## Trade-offs
- Chose a single-stage GameFlow (const scene path) over retaining the FlowConfig/FlowStage resource indirection, because the Q2 DELETE list removes flow_stage.gd + flow_config.tres and the hub is one terminal stage; the state machine and EventBus backbone remain so future stages can be re-added.
- Chose a hand-maintained architecture SVG plus manual regeneration instructions over a code-gen script, per the no-overengineering rule and scope's explicit "your call" freedom on the regeneration workflow.
- Chose proximity (body_entered) triggers over interact-press pads, matching the existing StageExit pattern and keeping zone behavior observable in headless/automated smokes without input.
- Chose a minimal SaveService (position + facing as JSON in user://) over deferring to a later feature, resolving the scope RISK toward "systems first, learning-first".

## Out of scope (technical)
- No combat logic — target dummies are inert static props.
- No full save system — only position + facing, no inventory/checkpoint schema.
- No audio content production — placeholder beep WAVs only.
- No interactive architecture overlay — the wall is a static textured plane.
- No new EventBus signals and no new stage content beyond the single arena stage.
- No quit/escape hatch — with no menu stage, exiting is closing the window.

## Gaps for human attention
- Q2 DELETE list names `resources/dialogue/master.tres`, but the repo file is `mother.tres`; the intent is treated as "delete all chapter dialogue content `.tres` files (ina, mother, uma_defa, wine_shop)" because the KEEP list retains only the DialogueData class.
- Q2 DELETE list removes `scripts/config/flow_stage.gd` + `resources/flow_config.tres` but is silent on `scripts/config/flow_config.gd`; since FlowConfig references the deleted FlowStage class, flow_config.gd is removed too (it cannot compile otherwise).
- The architecture SVG is a hand-maintained asset: future autoload/scene additions must be reflected there manually (workflow documented in the architecture-wall doc) — a maintenance burden to keep in mind.
