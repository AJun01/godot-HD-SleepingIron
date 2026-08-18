# 003 — Main menu scene

## Context files (read for understanding — do not modify)
- AGENTS.md — "HD-2D visual invariants" (UI art separate from dynamic values), naming rules
- design.md — menu buttons must only call GameFlow, never self-advance
- scripts/autoload/game_flow.gd — the exact methods to call (request_new_game, request_quit)

## Reference files (STRICT STYLE MATCH)
- AGENTS.md — GDScript law + UI-art/dynamic-value separation standard

## Required Skills
- godot-sdd (scene-level headless validation)

## Files to create/modify (suggested)
- scenes/ui/main_menu.tscn — create (Control + VBox with New Game / Quit buttons + title label + placeholder bg)
- scripts/ui/main_menu.gd — create (button signal wiring to GameFlow)

## Description
Build the working main menu: a Godot Control scene with a title label, a "New Game" button, and a
"Quit" button. Buttons are the only progression triggers and they call `GameFlow.request_new_game()`
and `GameFlow.request_quit()` respectively — the scene never manages progression itself. Keyboard
navigation comes free from Godot focus/`ui_*` actions (keyboard-first, mouse optional, per the
intake RISK note). Keep UI art (placeholder background) separate from dynamic values (Labels/Buttons
carry the text). Follow design.md for the global pattern.

## Acceptance
- [ ] `godot --headless --editor --path . --quit-after 10` is clean.
- [ ] `godot --headless --path . --quit-after 5 scenes/ui/main_menu.tscn` is clean (no ERROR / SCRIPT ERROR / Parse Error / Failed loading).
- [ ] Menu shows "New Game" and "Quit" controls; "New Game" calls GameFlow.request_new_game(); "Quit" calls GameFlow.request_quit().
- [ ] No numeric/dynamic values baked into art; label/button text is dynamic, placeholder background is separate.
- [ ] Scene uses composition (child Control nodes) and typed signal connections; no get_node("../../...").

## Needs tests
no

---

## Implementation log (filled by dev after successful commit)
- Commit: 72d7a13 — feat(game-skeleton): 添加主菜单场景与按钮接线
- Files modified:
  - scenes/ui/main_menu.tscn (created)
  - scripts/ui/main_menu.gd (created)
  - scripts/ui/main_menu.gd.uid (created)
- Tests added: none required
- Context & Reference files read:
  - AGENTS.md (context + reference)
  - design.md (context)
  - scripts/autoload/game_flow.gd (context)
- Notes: `scripts/ui/main_menu.gd.uid` is the Godot-generated UID companion file (auto-emitted by the headless editor scan), committed alongside the script per repo convention. Also read for wiring context: scripts/autoload/scene_router.gd, scripts/autoload/event_bus.gd, resources/flow_config.tres, resources/transition_config.tres, scripts/config/*.gd, project.godot, docs/sdd/artifacts/game-skeleton.yml, assets/placeholders/placeholder_menu_bg.svg, .spec/game-skeleton/scope.md.
