# Tasks: Arena Dev Hub

Project has tests: no
Test tool: none

| ID  | Title                                              | Status  |
|-----|----------------------------------------------------|---------|
| 001 | Delete chapter/menu content + single-stage GameFlow | done (0252b8d64e853c6204e68a04c70ccdd6b1a9d478) |
| 002 | Rebuild arena as the six-zone facility + zone pillars | done (b64ae4fd847010afaf392117751816b84a34fe3c) |
| 003 | Central architecture wall (SVG + regeneration doc)  | done (99d7c889c33e8b9f0f808b21cbafdd815011c102) |
| 004 | Minimal SaveService + save/load trigger points     | done (25d79a5) |
| 005 | Animation preview zone (12 animations + flip facing) | done (6f28921) |
| 006 | UI/HUD zone (test health bar + dialogue smoke tests) | done (c8b5b5d) |
| 007 | Audio zone (placeholder SFX triggers)              | done (988783b) |

Tasks run in ID order. The Orchestrator executes them one at a time. The order IS the dependency.

## Fixes

| Fix ID  | Title                                                          | Triggered by failure in | Files (suggested)                                      |
|---------|----------------------------------------------------------------|-------------------------|--------------------------------------------------------|
| fix-001 | Rename sfx_trigger `_player` → `_audio_player`                  | Review cycle 1 (#44)    | scripts/dev/sfx_trigger.gd                             |
| fix-002 | Parameterize HUD test health values via @export                | Review cycle 1 (#45)    | scripts/autoload/objective_hud.gd, scripts/dev/ui_hud_trigger.gd |
| fix-003 | SaveService save path error reporting + bool return            | Review cycle 1 (#47)    | scripts/autoload/save_service.gd                       |
