# Tasks: Game Skeleton

Project has tests: no
Test tool: none

| ID  | Title                              | Status  |
|-----|------------------------------------|---------|
| 001 | Autoload service layer + config    | done (fa229bc) |
| 002 | Placeholder assets + registry      | done (caca192) |
| 003 | Main menu scene                    | done (72d7a13) |
| 004 | Chapter world + player + camera    | done (f62fc24) |
| 005 | Boot scene + main scene wiring     | done (17464b9) |

Tasks run in ID order. The Orchestrator executes them one at a time. The order IS the dependency.

## Fixes

| Fix ID  | Title                                             | Triggered by failure in    | Files (suggested)                                              | Status        |
|---------|---------------------------------------------------|----------------------------|----------------------------------------------------------------|---------------|
| fix-001 | Reconcile chapter stage path to canonical chapter.tscn | Verifier cycle 1 (task 004) | resources/flow_config.tres, docs/sdd/artifacts/game-skeleton.yml | done (2134436) |
