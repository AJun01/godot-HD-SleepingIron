# Scope: Game Skeleton

## Objective
Enable the player to boot the game, reach a working main menu, start a new game, and move a placeholder character through a linear HD-2D chapter scene so that the linear game-flow loop is proven runnable and extensible.

## User stories
- As a player, I want to launch the game and reach a working main menu so that I have a clear entry point into the linear game.
- As a player, I want to choose "New Game" and transition into a chapter scene with a fade so that the linear menu → chapter flow is demonstrable.
- As a player, I want to move a placeholder character in 8 directions with camera follow so that the movement foundation of the narrative adventure is proven.
- As a player, I want to quit or return to the menu cleanly so that the linear flow loop closes without dead ends.

## Acceptance criteria
- [ ] Launching the project boots into a working main menu.
- [ ] Choosing "New Game" transitions to the chapter scene with a fade.
- [ ] The player placeholder moves in 8 directions with camera follow, driven by keyboard/gamepad via the InputMap.
- [ ] Quitting returns to the menu cleanly.
- [ ] Headless validation runs clean (no `ERROR`, `SCRIPT ERROR`, `Parse Error`, or `Failed loading` in output).
- [ ] A transition in progress ignores duplicate transition requests.
- [ ] Booting resolves the main scene without a missing-main-scene error.
- [ ] Input issued before a transition completes is blocked and does not trigger a duplicate or out-of-sequence flow change.

## External Tools & Design Mocks
- Figma: none
- Other Tools: none

## Reference Files (Gold Standards)
- none — greenfield repository; recorded as RISK (no gold-standard code to match).

## Architecture constraints
- **Linear game:** one central `GameFlow` autoload state machine owns progression
  (menu → chapter → transitions); scenes never self-manage progression.
- **Modular + extensible:** small single-responsibility autoload services (EventBus,
  SceneRouter/Transition, GameFlow), composition via scenes/child nodes, `@export`
  dependency injection, `Resource` files for tunables; combat/inventory/saves/dialogue
  must be addable later without rewriting existing systems.
- **HD-2D:** 2D sprites in a lit 3D world; world scene carries lighting; sprites billboard.
- **Placeholders:** no blocking on art — self-authored SVG placeholders in
  `assets/placeholders/`, registered in the feature artifact registry with
  `status: placeholder`.
- **GDScript law (AGENTS.md):** full static typing, signals for decoupling, composition over
  inheritance, tunables in `@export`/Resource, `call_deferred` for scene-tree mutations from
  physics/signal callbacks, explicit collision layers/masks, snake_case files.
- **Validation gate:** `godot --headless --editor --path . --quit-after 10` and
  `godot --headless --path . --quit-after 5 scenes/<main-scene>.tscn` must be clean
  (no ERROR / SCRIPT ERROR / Parse Error / Failed loading).

## Reuse (do NOT recreate)
- none yet (greenfield).

## Out of scope
- Dialogue content and the dialogue system (hooks only, per Q2).
- Combat and mecha combat (interface left for a later module).
- Inventory, save/load, and audio.
- Story content beyond the skeleton flow.
- Real art/audio assets — SVG placeholders only, per AGENTS.md policy.
- Final UI art and main-menu visual design — belongs to the user's later art pass.

## Unverified assumptions (RISK)
- Main menu navigation model (keyboard-only vs mouse) — assumed keyboard-first with
  mouse optional; final UI belongs to the user's later art pass.
- Chapter scene placeholder geometry is free-form; no art references exist yet.
- No remote existed at intake time; PR flow enabled mid-intake per user Q3 answer.

## Context
Sleeping Iron HD-2D is a linear, narrative-first HD-2D adaptation of the novel *SLEEPING IRON*.
This is the first feature — the skeleton that proves the boot → main menu → chapter → transition
loop and establishes the modular architecture (central GameFlow state machine plus small
single-responsibility autoload services) every later system will plug into.
Combat, inventory, saves, and dialogue are planned future modules that must be addable without
rewriting this foundation. The human developer owns final art and visual direction; the agent
ships engineering plus SVG placeholders only.
