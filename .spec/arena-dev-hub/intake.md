# Intake: Arena Dev Hub (test-facility arena + content cleanup + architecture visualization)

## PR target branch
master

## Raw prompt
"先把之前的所有场景删除清理掉，以arena为主进行微调和开发，在所有游戏系统测试完毕之前没有开发产品内容的必要。毕竟这个项目也是学习为主。把arena顺便也改造成测试场地，每个游戏系统在里面都有自己的测试区域，然后带可视化代码架构解释" — plus the user's immediate context: the ACT player foundation (feature act-player-foundation, PR #33) is complete and verified; the project shifts to systems-first development on a dev-hub arena.

## Clarifications (Q&A)

### Q1 — Branch baseline:
**User answered:** merge PR #33 first, then this feature branches from master. (Human merge; the Orchestrator must not merge.)

### Q2 — Deletion list (confirmed):
DELETE: scenes/world/chapter_ending.tscn, chapter_field.tscn, chapter_home.tscn, chapter_return.tscn, chapter_town.tscn; scenes/ui/main_menu.tscn; scripts/ui/main_menu.gd; scripts/ui/chapter_ending.gd; scripts/world/stage.gd; scripts/world/stage_exit.gd; scripts/world/interactable.gd; scripts/world/camera_follow.gd; scripts/config/flow_stage.gd; resources/flow_config.tres; resources/dialogue/{ina,master,uma_defa,wine_shop}.tres; assets/placeholders: placeholder_npc_defa.svg, placeholder_npc_ina.svg, placeholder_npc_mother.svg, placeholder_npc_uma.svg, placeholder_npc_wine_shop_owner.svg, placeholder_prop_home.svg, placeholder_prop_wine_cart.svg, placeholder_prop_wine_shop.svg, placeholder_ground.svg, placeholder_menu_bg.svg, placeholder_env_prop.svg, placeholder_player.svg (and their .import files).
KEEP (systems): EventBus, SceneRouter, GameFlow (reconfigured single-stage boot→arena), DialogueService (system body), ObjectiveHud (HUD test zone), player/player_animator/side_view_camera, scenes/boot.tscn, scenes/act/arena.tscn, scenes/dev/sprite_anim_preview.tscn, scripts/dev/sprite_anim_preview.gd, resources/player_config.tres, resources/theme.tres, resources/transition_config.tres, scripts/config/dialogue_data.gd + transition_config.gd.

### Q3 — Test zones (all six for v1):
movement/jump zone (platforms/steps/long runway) · animation preview zone (play any of the 12 animations) · combat target range (target dummies only; attack system not yet built) · UI/HUD zone (health bar/dialogue tests) · save/load zone (trigger points) · audio zone (sfx triggers).

### Q4 — Architecture visualization:
Zone pillars (Label3D per zone: system name + one-line responsibility + related file paths) AND a central architecture wall (a large plane textured with an architecture-diagram SVG that the agent maintains alongside code changes). Interactive overlay deferred.

### Q5 — Boot flow:
GameFlow kept (AGENTS.md architecture law: linear stage state machine), reconfigured to a single stage boot→arena. EventBus/SceneRouter untouched.

## Confirmed feature behavior

- **Inputs:** none new. Existing movement/jump controls; zone-specific triggers use the existing interact action or proximity.
- **Outputs:**
  - Deleted content files per Q2; boot→arena single-stage flow; no chapter scenes reachable.
  - Arena rebuilt as a test facility with 6 labeled zones, each a physically distinct area with its own test props; zone pillars (Label3D) stating system name + responsibility + key file paths.
  - Central architecture wall: a big plane with a generated architecture SVG (nodes = autoloads/services/scenes, edges = dependencies; maintained in-repo, regenerated when architecture changes).
  - Animation preview zone: control to play each of the 12 animations (idle/run/jump/fall/land/attack_1/2/3/attack_air/hit/dodge/death) on the player character, plus flip facing toggle.
  - Combat range: inert target dummies (static props) — no combat logic yet.
  - UI/HUD zone: triggers to show/hide a test health bar and a test dialogue box through the existing ObjectiveHud/DialogueService systems (system-level smoke tests only).
  - Save/load zone: two trigger points exercising a minimal save/load service (save position/state, load restores it) — if no save system exists yet, this zone introduces the minimal service per AGENTS.md modularity rules.
  - Audio zone: sfx triggers (placeholder beeps are acceptable; AGENTS.md placeholder policy applies).
- **Edge cases handled:** booting with missing/deleted scenes must not error (single-stage flow); zones must remain individually usable after scene reload; architecture SVG regeneration is a documented maintenance step (script or manual instruction).
- **Out of scope (explicit):** chapter/product content re-creation; combat gameplay (attacks/hit/hurt/dodge/death wiring); full save system design; audio content production; interactive architecture overlay; NPC AI.

## Reference Files (confirmed by user)
- `scenes/act/arena.tscn` — the arena scene being transformed into the dev hub.
- `scripts/world/side_view_camera.gd` + `scenes/actors/player.tscn` + `scripts/world/player.gd` / `player_animator.gd` — the ACT foundation the hub exercises.
- `scripts/autoload/game_flow.gd` + `scripts/config/flow_config.gd` — single-stage reconfiguration target.
- `scripts/autoload/dialogue_service.gd`, `objective_hud.gd` — systems the UI/HUD zone smoke-tests.
- `scenes/dev/sprite_anim_preview.tscn` — pattern source for the animation preview zone.

## Architecture constraints (confirmed)
- AGENTS.md: static typing, EventBus signals, composition, tunables in Resources, call_deferred for scene-tree mutations from physics/signal callbacks, explicit collision layers/masks, snake_case files.
- HD-2D invariants: billboarded sprites, 3D world lighting, nearest-neighbor filtering.
- GameFlow remains the central linear stage machine (single stage now); SceneRouter/EventBus remain the coupling backbone.
- Zone components must be small single-responsibility composables (no god-scripts); zones communicate via EventBus where needed.
- Godot 4.7 headless gates: gdlint 0 problems, headless editor import clean, boot + arena smokes clean.

## Reuse (do NOT recreate)
- Existing autoloads and the ACT player foundation; the vendored pipeline tooling (tools/art_pipeline/) if any asset generation is needed.
- ObjectiveHud/DialogueService for the UI zone; SceneRouter for any in-arena teleport between zones.

## Unverified assumptions (RISK)
- Save system: whether to introduce a minimal save/load service in this feature or defer the zone to a later save-system feature — Tech Lead should propose the minimal version (a tiny service + two trigger points), consistent with the "systems first, learning-first" direction.
- Architecture wall SVG regeneration workflow (manual instruction vs script) — Tech Lead decides, document in docs/.
- Zone layout/physical design freedom granted to the Tech Lead (flat ground + distinct areas, DNF-style camera already elevated).
- Audio zone uses placeholder beep SFX per the AGENTS.md placeholder policy.
