# 003 — Minimal dialogue system (DialogueService)

## Context files (read for understanding — do not modify)
- scripts/autoload/event_bus.gd — `transition_started` signal the service listens to (close on transition)
- scripts/autoload/scene_router.gd — lazily-created CanvasLayer overlay pattern to imitate for the bar
- scripts/world/player.gd — movement code that will consult `DialogueService.is_open()` (integration point; do not modify here)
- .gdlintrc — lint rules (max-line-length 100, static typing, class/var naming) the new script must satisfy

## Reference files (STRICT STYLE MATCH)
- scripts/autoload/game_flow.gd — autoload service style: class docstring, typed private members, guarded public methods
- scripts/autoload/scene_router.gd — runtime CanvasLayer + Control creation pattern
- AGENTS.md — GDScript rules #1/#4/#5/#8 and "UI art separate from dynamic values"

## Required Skills
- godot-sdd (autoload + UI headless validation)

## Files to create/modify (suggested)
- scripts/config/dialogue_data.gd — create (`class_name DialogueData extends Resource`; `speaker: String`, `lines: Array[String]`)
- scripts/autoload/dialogue_service.gd — create (autoload owning the dialogue bar + line-advance state machine)
- project.godot — modify (register `DialogueService` autoload; add `advance` input action: Enter + Space + joypad A)

## Description
Implement the minimal dialogue service that a future full dialogue system can replace without
touching stages: `DialogueData` is the data contract (ordered lines + optional speaker), and
`DialogueService` is the only consumer. `DialogueService.play(dialogue)` shows a dialogue bar
(CanvasLayer + Panel + Label, created lazily like SceneRouter's overlay), advances exactly one line
per `advance` press (no key-echo/hold repeat), closes after the last line, and is `await`-able so the
caller knows when the beat finished. Expose `is_open()`. Listen to `EventBus.transition_started` and
force-close (hide the bar, unblock any in-flight `play()`) so quitting mid-dialogue never leaves a
stuck bar. The bar inherits the project theme from task 001, so Chinese renders. Consume the opening
press via `set_input_as_handled()` where needed so the press that opens a dialogue never also advances
its first line. Follow `design.md`.

## Acceptance
- [ ] `DialogueData` is a typed Resource with `speaker` + `lines`; dialogue content lives in Resources, not in the service or scenes (scope AC #5, #8).
- [ ] `DialogueService.play(dialogue)` advances exactly one line per `advance` press, with no echo/held repeat, and closes after the final line (scope AC #6).
- [ ] `is_open()` is true only while a dialogue is active; the opening press does not also advance the first line (scope AC #6).
- [ ] `DialogueService` listens to `transition_started` and force-closes the bar + unblocks `play()` (scope AC #13).
- [ ] The bar is a dynamic Label (no baked text) and inherits the CJK theme from task 001 (scope AC #5).
- [ ] `godot --headless --editor --path . --quit-after 10` and `godot --headless --path . --quit-after 5 scenes/boot.tscn` are clean.
- [ ] `gdlint .` reports 0 problems.

## Needs tests
no

---

## Implementation log (filled by dev after successful commit)
- Commit: 6be02f6 — feat(chapter-1-demo): 新增可等待的最小对话系统（DialogueService）
- Files modified:
  - project.godot (modified)
  - scripts/autoload/dialogue_service.gd (created)
  - scripts/autoload/dialogue_service.gd.uid (created)
  - scripts/config/dialogue_data.gd (created)
  - scripts/config/dialogue_data.gd.uid (created)
- Tests added: none required
- Context & Reference files read:
  - scripts/autoload/event_bus.gd
  - scripts/autoload/scene_router.gd
  - scripts/world/player.gd
  - .gdlintrc
  - scripts/autoload/game_flow.gd
  - AGENTS.md
- Notes: .uid files are Godot-generated UID sidecars (tracked convention in this repo). Also read scope.md (for AC #5/#6/#8/#13 referenced by the task) and existing config/style files (flow_stage.gd, flow_config.gd, transition_config.gd, boot.gd, project.godot, resources/theme.tres, resources/flow_config.tres) to match local style.
