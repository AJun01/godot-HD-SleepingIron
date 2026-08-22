# 001 — Delete chapter/menu content + single-stage GameFlow

## Context files (read for understanding — do not modify)
- .spec/arena-dev-hub/intake.md — Q2 DELETE/KEEP lists (authoritative deletion scope)
- scripts/autoload/game_flow.gd — the state machine being simplified to a single stage
- resources/flow_config.tres — references every deleted scene + flow_stage.gd
- scripts/boot.gd — the main-scene entry that calls GameFlow.start_flow()

## Reference files (STRICT STYLE MATCH)
- scripts/autoload/scene_router.gd — the transition_to() contract GameFlow calls (transition_started/finished signals)
- scripts/autoload/event_bus.gd — the typed signals GameFlow keeps emitting (game_state_changed, stage_changed)
- AGENTS.md — Architecture law (linear stage machine) + gdlint/headless validation gates

## Required Skills
- godot-sdd (headless validation gates)

## Files to create/modify (suggested)
- scripts/autoload/game_flow.gd — modify (single-stage BOOT→ARENA machine, const arena scene path)
- scripts/config/flow_config.gd — delete (references the deleted FlowStage class)
- scripts/config/flow_stage.gd — delete
- resources/flow_config.tres — delete
- scenes/world/chapter_ending.tscn, chapter_field.tscn, chapter_home.tscn, chapter_return.tscn, chapter_town.tscn — delete
- scenes/ui/main_menu.tscn — delete
- scripts/ui/main_menu.gd, scripts/ui/chapter_ending.gd — delete
- scripts/world/stage.gd, stage_exit.gd, interactable.gd, camera_follow.gd — delete
- resources/dialogue/ina.tres, mother.tres, uma_defa.tres, wine_shop.tres — delete
- assets/placeholders/placeholder_npc_defa.svg, placeholder_npc_ina.svg, placeholder_npc_mother.svg, placeholder_npc_uma.svg, placeholder_npc_wine_shop_owner.svg, placeholder_prop_home.svg, placeholder_prop_wine_cart.svg, placeholder_prop_wine_shop.svg, placeholder_ground.svg, placeholder_menu_bg.svg, placeholder_env_prop.svg, placeholder_player.svg — delete (with their `.import` sidecars)

## Description
Delete every file in intake.md Q2's DELETE list (all chapter world/ui scenes, main_menu, their scripts, stage/stage_exit/interactable/camera_follow, flow_stage.gd, flow_config.tres, all four chapter dialogue content `.tres`, and the listed placeholder SVGs), plus each asset's tracked `.import` sidecar. Also remove `scripts/config/flow_config.gd`, which is silent in Q2 but can no longer compile once the FlowStage class it references is deleted. Rewrite `game_flow.gd` as a minimal two-state machine (BOOT → ARENA): `start_flow()` transitions to the single arena stage through SceneRouter, keeping `EventBus.game_state_changed` and `EventBus.stage_changed` (empty objective) emissions so ObjectiveHud and future listeners keep working. After this task, booting lands in the arena and no chapter/menu scene is reachable. Follow design.md.

## Acceptance
- [ ] Every file in Q2's DELETE list (plus its `.import` sidecar) no longer exists; `scripts/config/flow_config.gd` is also removed.
- [ ] No surviving `.gd`/`.tscn`/`.tres` references any deleted path (grep clean).
- [ ] Launching boots directly into the arena; no chapter scene or main menu is reachable.
- [ ] `gdlint .` reports 0 problems.
- [ ] `godot --headless --editor --path . --quit-after 10` is clean (no ERROR / SCRIPT ERROR / Parse Error / Failed loading).
- [ ] `godot --headless --path . --quit-after 5 scenes/boot.tscn` is clean — boots into the arena with the deleted scenes absent.

## Needs tests
no

---

## Implementation log (filled by dev after successful commit)
- Commit: 0252b8d64e853c6204e68a04c70ccdd6b1a9d478 — refactor(arena-dev-hub): 清理章节/菜单内容并简化 GameFlow 为单场景 boot→arena
- Files modified:
  - scripts/autoload/game_flow.gd (modified)
  - scripts/world/side_view_camera.gd (modified)
  - scripts/world/player_animator.gd (modified)
  - scripts/config/flow_config.gd (deleted)
  - scripts/config/flow_config.gd.uid (deleted)
  - scripts/config/flow_stage.gd (deleted)
  - scripts/config/flow_stage.gd.uid (deleted)
  - resources/flow_config.tres (deleted)
  - scenes/world/chapter_ending.tscn (deleted)
  - scenes/world/chapter_field.tscn (deleted)
  - scenes/world/chapter_home.tscn (deleted)
  - scenes/world/chapter_return.tscn (deleted)
  - scenes/world/chapter_town.tscn (deleted)
  - scenes/ui/main_menu.tscn (deleted)
  - scripts/ui/main_menu.gd (deleted)
  - scripts/ui/main_menu.gd.uid (deleted)
  - scripts/ui/chapter_ending.gd (deleted)
  - scripts/ui/chapter_ending.gd.uid (deleted)
  - scripts/world/stage.gd (deleted)
  - scripts/world/stage.gd.uid (deleted)
  - scripts/world/stage_exit.gd (deleted)
  - scripts/world/stage_exit.gd.uid (deleted)
  - scripts/world/interactable.gd (deleted)
  - scripts/world/interactable.gd.uid (deleted)
  - scripts/world/camera_follow.gd (deleted)
  - scripts/world/camera_follow.gd.uid (deleted)
  - resources/dialogue/ina.tres (deleted)
  - resources/dialogue/mother.tres (deleted)
  - resources/dialogue/uma_defa.tres (deleted)
  - resources/dialogue/wine_shop.tres (deleted)
  - assets/placeholders/placeholder_npc_defa.svg (deleted)
  - assets/placeholders/placeholder_npc_defa.svg.import (deleted)
  - assets/placeholders/placeholder_npc_ina.svg (deleted)
  - assets/placeholders/placeholder_npc_ina.svg.import (deleted)
  - assets/placeholders/placeholder_npc_mother.svg (deleted)
  - assets/placeholders/placeholder_npc_mother.svg.import (deleted)
  - assets/placeholders/placeholder_npc_uma.svg (deleted)
  - assets/placeholders/placeholder_npc_uma.svg.import (deleted)
  - assets/placeholders/placeholder_npc_wine_shop_owner.svg (deleted)
  - assets/placeholders/placeholder_npc_wine_shop_owner.svg.import (deleted)
  - assets/placeholders/placeholder_prop_home.svg (deleted)
  - assets/placeholders/placeholder_prop_home.svg.import (deleted)
  - assets/placeholders/placeholder_prop_wine_cart.svg (deleted)
  - assets/placeholders/placeholder_prop_wine_cart.svg.import (deleted)
  - assets/placeholders/placeholder_prop_wine_shop.svg (deleted)
  - assets/placeholders/placeholder_prop_wine_shop.svg.import (deleted)
  - assets/placeholders/placeholder_ground.svg (deleted)
  - assets/placeholders/placeholder_ground.svg.import (deleted)
  - assets/placeholders/placeholder_menu_bg.svg (deleted)
  - assets/placeholders/placeholder_menu_bg.svg.import (deleted)
  - assets/placeholders/placeholder_env_prop.svg (deleted)
  - assets/placeholders/placeholder_env_prop.svg.import (deleted)
  - assets/placeholders/placeholder_player.svg (deleted)
  - assets/placeholders/placeholder_player.svg.import (deleted)
- Tests added: none required
- Context & Reference files read:
  - .spec/arena-dev-hub/intake.md
  - scripts/autoload/game_flow.gd
  - resources/flow_config.tres
  - scripts/boot.gd
  - scripts/autoload/scene_router.gd
  - scripts/autoload/event_bus.gd
  - AGENTS.md
- Notes: Touched scripts/world/side_view_camera.gd and scripts/world/player_animator.gd (outside the suggested list) only to remove stale comment references to the deleted camera_follow.gd, so the "grep clean" acceptance holds. Deleted each removed .gd script's .gd.uid sidecar and each SVG's .import sidecar for a clean tree. Q2 names resources/dialogue/master.tres but the repo file is mother.tres; per design.md Gaps, deleted mother.tres (no master.tres exists). gdlint is not installed locally, so it was run via `uvx --from "gdtoolkit==4.*" gdlint .` (0 problems), matching CI's gdtoolkit==4.* pin. All headless gates (editor import, boot smoke, arena smoke) passed clean.
