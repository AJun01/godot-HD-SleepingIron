# Scope: Arena Dev Hub

## Objective
Enable the developer to exercise every game system in a dedicated arena-based test facility with a visual explanation of the code architecture, so that all systems are verified before any product content is developed.

## User stories
- As a developer, I want all previous chapter/product scenes, scripts, resources, and placeholder assets deleted so the project focuses only on the arena and its core systems.
- As a developer, I want the game to boot directly into the arena through a single stage so no chapter or main-menu scene is reachable.
- As a developer, I want the arena to contain six distinct, labeled test zones (movement/jump, animation preview, combat range, UI/HUD, save/load, audio) so each game system has its own isolated test area.
- As a developer, I want each zone marked with a pillar label stating the system name, its one-line responsibility, and the related file paths so I can locate the code behind each system.
- As a developer, I want a central architecture wall showing a diagram of the code structure (services, scenes, and their dependencies) so I can understand the architecture at a glance.
- As a developer, I want to play each of the 12 player animations and toggle facing in the animation preview zone so I can verify the animation system.
- As a developer, I want a combat range with inert target dummies so I can later verify combat targeting without any combat logic yet.
- As a developer, I want triggers to show/hide a test health bar and a test dialogue box in the UI/HUD zone so I can smoke-test the UI systems.
- As a developer, I want two trigger points that save and restore position/state through a minimal save/load service so I can verify save/load behavior.
- As a developer, I want SFX trigger points in the audio zone so I can verify audio playback.

## Acceptance criteria
- [ ] Every file listed in intake.md Q2's DELETE list no longer exists in the repository, and no surviving scene or script references a deleted path.
- [ ] Launching the game boots directly into the arena, with no chapter scene or main menu reachable.
- [ ] The game boots without errors even when the deleted scenes are absent (single-stage boot→arena flow).
- [ ] The arena contains six physically distinct, labeled zones (movement/jump, animation preview, combat range, UI/HUD, save/load, audio), each with its own test props.
- [ ] Each zone remains individually usable after a scene reload.
- [ ] Each zone displays a Label3D pillar stating the system name, a one-line responsibility, and the related file paths.
- [ ] A central wall plane in the arena displays a generated architecture-diagram SVG whose nodes are autoloads/services/scenes and whose edges are dependencies.
- [ ] The architecture SVG is maintained in-repo, and its regeneration step is documented (script or manual instruction).
- [ ] A control in the animation preview zone plays each of the 12 animations (idle, run, jump, fall, land, attack_1, attack_2, attack_3, attack_air, hit, dodge, death) on the player character.
- [ ] A flip-facing toggle in the animation preview zone reverses the player character's facing.
- [ ] The combat range contains inert target dummies as static props, with no combat logic.
- [ ] Triggers in the UI/HUD zone show and hide a test health bar through the existing ObjectiveHud system.
- [ ] Triggers in the UI/HUD zone show and hide a test dialogue box through the existing DialogueService system.
- [ ] Two trigger points exist in the save/load zone: one saves position/state and the other restores it via a minimal save/load service.
- [ ] SFX trigger points in the audio zone play sound (placeholder beeps acceptable).

## External Tools & Design Mocks
- Figma: none
- Other Tools: none

## Reference Files (Gold Standards)
- `scenes/act/arena.tscn` — the arena scene being transformed into the dev hub.
- `scripts/world/side_view_camera.gd` + `scenes/actors/player.tscn` + `scripts/world/player.gd` / `player_animator.gd` — the ACT foundation the hub exercises.
- `scripts/autoload/game_flow.gd` + `scripts/config/flow_config.gd` — single-stage reconfiguration target.
- `scripts/autoload/dialogue_service.gd`, `objective_hud.gd` — systems the UI/HUD zone smoke-tests.
- `scenes/dev/sprite_anim_preview.tscn` — pattern source for the animation preview zone.

## Architecture constraints
- AGENTS.md: static typing, EventBus signals, composition, tunables in Resources, call_deferred for scene-tree mutations from physics/signal callbacks, explicit collision layers/masks, snake_case files.
- HD-2D invariants: billboarded sprites, 3D world lighting, nearest-neighbor filtering.
- GameFlow remains the central linear stage machine (single stage now); SceneRouter/EventBus remain the coupling backbone.
- Zone components must be small single-responsibility composables (no god-scripts); zones communicate via EventBus where needed.
- Godot 4.7 headless gates: gdlint 0 problems, headless editor import clean, boot + arena smokes clean.

## Reuse (do NOT recreate)
- Existing autoloads and the ACT player foundation; the vendored pipeline tooling (tools/art_pipeline/) if any asset generation is needed.
- ObjectiveHud/DialogueService for the UI zone; SceneRouter for any in-arena teleport between zones.

## Out of scope
- Re-creating chapter/product content.
- Combat gameplay (attacks/hit/hurt/dodge/death wiring).
- Full save system design.
- Audio content production.
- Interactive architecture overlay.
- NPC AI.

## Unverified assumptions (RISK)
- Save system: whether to introduce a minimal save/load service in this feature or defer the zone to a later save-system feature — Tech Lead should propose the minimal version (a tiny service + two trigger points), consistent with the "systems first, learning-first" direction.
- Architecture wall SVG regeneration workflow (manual instruction vs script) — Tech Lead decides, document in docs/.
- Zone layout/physical design freedom granted to the Tech Lead (flat ground + distinct areas, DNF-style camera already elevated).
- Audio zone uses placeholder beep SFX per the AGENTS.md placeholder policy.

## Context
The ACT player foundation (feature act-player-foundation, PR #33) is complete and verified, so the project now shifts to a systems-first, learning-first approach. The user wants to delete all previous chapter/product scenes and rebuild the arena as the single development hub where every game system has its own test area. No product content should be developed until all game systems are tested. The arena should also include a visual explanation of the code architecture to support learning.
