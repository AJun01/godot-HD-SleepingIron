# 007 — Player extraction + stage scaffold + home stage

## Context files (read for understanding — do not modify)
- scripts/world/interactable.gd — component API to wire onto the mother NPC
- scripts/autoload/dialogue_service.gd — `is_open()` the player consults to block movement
- scripts/world/camera_follow.gd — camera component reused per stage
- scripts/world/chapter.gd — `ui_cancel` forward to generalize into the stage controller
- design.md — global pattern (stage composition, progression ownership)

## Reference files (STRICT STYLE MATCH)
- scenes/world/chapter.tscn — HD-2D stage composition (DirectionalLight3D + WorldEnvironment + ground + billboarded sprites + camera)
- scripts/world/player.gd — movement style + typed `@export`/docstring conventions
- AGENTS.md — "HD-2D visual invariants" + explicit collision layers/masks

## Required Skills
- godot-sdd (scene composition headless validation)

## Files to create/modify (suggested)
- scenes/actors/player.tscn — create (extracted player: CharacterBody3D + CollisionShape3D + billboarded Sprite3D)
- scripts/world/player.gd — modify (return zero input direction while `DialogueService.is_open()`)
- scripts/world/stage.gd — create (generic stage controller: forwards `ui_cancel` to `GameFlow.request_quit_to_menu()`)
- scenes/world/chapter_home.tscn — create (stage 1: lighting + ground + player instance + camera + home prop + mother NPC)
- scripts/world/chapter.gd — delete (replaced by `stage.gd`)
- scenes/world/chapter.tscn — delete (replaced by `chapter_home.tscn`)
- docs/sdd/artifacts/chapter-1-demo.yml — modify (register `player.tscn` + `chapter_home.tscn`)

## Description
Establish the reusable stage scaffold and the first vertical slice. Extract the player into a shared
scene so all four stages reuse one movement implementation, and add the movement block: while
`DialogueService.is_open()`, the player reads zero input direction (friction brings it to rest).
Generalize the old chapter controller into `stage.gd` (forwards `ui_cancel` to
`GameFlow.request_quit_to_menu()`; progression stays with `GameFlow`). Build `chapter_home.tscn` as the
first stage: 3D lighting (DirectionalLight3D + WorldEnvironment), ground, the player instance, a
per-stage Camera3D with `camera_follow`, the home prop, and the mother NPC (billboarded
`Sprite3D` using `placeholder_npc_mother.svg`) with an `Interactable` Area3D wired to
`resources/dialogue/mother.tres` and `advance_stage_on_complete = true`. Follow `design.md`.

## Acceptance
- [ ] Player is extracted to `scenes/actors/player.tscn` and reused in `chapter_home.tscn` with 8-direction movement (keyboard + gamepad actions) (scope AC #2).
- [ ] While `DialogueService.is_open()`, the player's movement input is ignored (scope AC #7).
- [ ] `chapter_home.tscn` carries DirectionalLight3D + WorldEnvironment; mother NPC and player sprites are billboarded; explicit layers/masks on all bodies/areas (scope AC — HD-2D invariants + AGENTS.md #6).
- [ ] Selecting New Game from the menu presents Stage 1 (home front) (scope AC #1).
- [ ] Pressing E near the mother plays the wake-up beat; its completion advances to the field-road stage (scope AC #4, #8).
- [ ] `ui_cancel` forwards to `GameFlow.request_quit_to_menu()`; the stage never self-advances progression (scope AC #13).
- [ ] `godot --headless --editor --path . --quit-after 10` and `godot --headless --path . --quit-after 5 scenes/world/chapter_home.tscn` are clean; `gdlint .` reports 0 problems.

## Needs tests
no

---

## Implementation log (filled by dev after successful commit)
- Commit: 54cb02d1cf4633848a6a43d6df56b11832f2eb54 — feat(chapter-1-demo): 抽取玩家复用场景并搭建第一章母家舞台
- Files modified:
  - docs/sdd/artifacts/chapter-1-demo.yml (modified)
  - scenes/actors/player.tscn (created)
  - scenes/world/chapter.tscn (deleted)
  - scenes/world/chapter_home.tscn (created)
  - scripts/world/chapter.gd (deleted)
  - scripts/world/chapter.gd.uid (deleted)
  - scripts/world/stage.gd (created)
  - scripts/world/stage.gd.uid (created)
  - scripts/world/player.gd (modified)
- Tests added: none required
- Context & Reference files read:
  - scripts/world/interactable.gd
  - scripts/autoload/dialogue_service.gd
  - scripts/world/camera_follow.gd
  - scripts/world/chapter.gd
  - design.md
  - scenes/world/chapter.tscn
  - scripts/world/player.gd
  - AGENTS.md
- Notes: stage.gd.uid is the Godot-generated script UID, committed alongside stage.gd (project tracks .gd.uid files). The Interactable Area3D's collision layer/mask are set explicitly in interactable.gd `_ready()` (not duplicated in the .tscn), matching the existing component pattern. docs/sdd/artifacts/game-skeleton.yml (a prior feature's registry) still references the deleted scenes/world/chapter.tscn; left untouched as out of scope for this task.
