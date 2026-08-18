# Tasks: Chapter 1 Demo

Project has tests: no
Test tool: none

| ID  | Title                                            | Status  |
|-----|--------------------------------------------------|---------|
| 001 | CJK font + global UI theme                       | done (e034eba) |
| 002 | Four-stage progression (FlowConfig + GameFlow)   | done (57667f7) |
| 003 | Minimal dialogue system (DialogueService)        | done (6be02f6) |
| 004 | Interaction + stage-exit components              | done (95ddb7b) |
| 005 | Objective HUD service                            | done (014e3bb) |
| 006 | Chapter placeholders + dialogue content          | done (1c4d218) |
| 007 | Player extraction + stage scaffold + home stage  | done (54cb02d) |
| 008 | Remaining stages + ending screen                 | done (9aef0b6) |

Tasks run in ID order. The Orchestrator executes them one at a time. The order IS the dependency.

## Fixes

| Fix ID  | Title                                              | Linked issue | Status  |
|---------|----------------------------------------------------|--------------|---------|
| fix-001 | Move ending auto-return timing into GameFlow       | #3           | done (6442bcd) |
| fix-002 | DialogueService.play() returns completion status   | #5           | done (1fc4be2) |
| fix-003 | Interactable advances only on normal completion    | #4           | done (3ab088d) |
