# Tasks: ACT Player Foundation

Project has tests: no
Test tool: none

| ID  | Title                                          | Status  |
|-----|------------------------------------------------|---------|
| 001 | Player movement + jump on the X–Y play plane   | done (fc0e2e5) |
| 002 | Animation state machine + AnimatedSprite3D     | done (8e6f906) |
| 003 | Side-view follow camera component              | done (a4af8a0) |
| 004 | ACT arena scene + artifact registry + validation | done (6fd2e02) |

Tasks run in ID order. The Orchestrator executes them one at a time. The order IS the dependency.

## Fixes

| Fix ID  | Title                                                  | Triggered by failure in | Files (suggested)                                          |
|---------|--------------------------------------------------------|-------------------------|------------------------------------------------------------|
| fix-001 | Restore XZ depth walking + rebuild arena as 3D ground  | Playtest failure cycle 1 | scripts/world/player.gd, scripts/world/player_animator.gd, scripts/world/side_view_camera.gd, scenes/act/arena.tscn, docs/sdd/artifacts/act-player-foundation.yml |
| fix-002 | Vendor frame pipeline + despeckle + collapse idle row  | Playtest failure cycle 1 | tools/art_pipeline/frames_v1_user_process.py, assets/sprites/player/* (sheets, frames, both .tres), docs/sdd/artifacts/act-player-foundation.yml |
| fix-003 | Add jump/fall hysteresis to stop apex flapping          | Verifier failure cycle 2 | scripts/world/player_animator.gd |
| fix-004a | Raise camera to DNF-style elevated side view (height + pitch) | Playtest failure cycle 3 | scripts/world/side_view_camera.gd, scenes/act/arena.tscn, docs/sdd/artifacts/act-player-foundation.yml |
| fix-004b | Salt-and-pepper despeckle for jump frames (all-frame cleanup) | Playtest failure cycle 3 | tools/art_pipeline/frames_v1_user_process.py, assets/sprites/player/* (sheets, frames, both .tres), docs/sdd/artifacts/act-player-foundation.yml |

