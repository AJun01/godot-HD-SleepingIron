# Intake: Game Skeleton

## PR target branch
master (origin/master; remote https://github.com/AJun01/godot-HD-SleepingIron.git was empty,
master pushed and became the default branch)

## Raw prompt
"开始搭骨架吧，这个游戏不是开放世界，但是是线性的。所有specs必须按照模块化+可拓展性的代码设计"

## Clarifications (Q&A)

### Q1 — Feature behavior: skeleton scope
**Recommended:** Full runnable vertical slice: boot → main menu (placeholder UI) → chapter
scene (HD-2D empty world: 3D lighting + ground + placeholder player with 8-direction movement
+ camera follow) → scene transitions with fade, proving the linear flow loop.
**User answered:** A — full skeleton as recommended.

### Q2 — Feature behavior: core gameplay shape
**Recommended:** Narrative adventure first (movement + interaction + dialogue interface left
as hooks); mecha combat plugs in later as a separate module.
**User answered:** A — narrative adventure primarily, combat left as interface.

### Q3 — PR target branch
**Recommended:** Local feature branch, merge back to master after verify.
**User answered:** Custom — configure remote https://github.com/AJun01/godot-HD-SleepingIron.git
and run the full PR flow. (Remote added; origin/master is the default branch.)

### Q4 — Architecture fit
**Recommended:** Central GameFlow state machine (single entry for linear progression) +
autoload service layer (EventBus, SceneRouter — small single-responsibility singletons) +
scene node composition + Resource-driven data.
**User answered:** A — confirmed pattern.

## Confirmed feature behavior

- **Inputs:** player input (keyboard/gamepad via Godot InputMap) on the chapter scene;
  menu selection input on the main menu.
- **Outputs:** boot flow reaches a working main menu; choosing "New Game" transitions to the
  chapter scene with a fade; player placeholder moves in 8 directions with camera follow;
  quitting returns to the menu cleanly; headless validation passes.
- **Edge cases handled:** scene transition interruption (transition in progress ignores
  duplicate requests); missing main scene configured (set `application/run/main_scene`);
  input before transition completes (blocked by GameFlow state).
- **Out of scope:** dialogue content/system, combat, inventory, save/load, audio, story
  content, real art assets (SVG placeholders only, per AGENTS.md policy).

## Reference Files (confirmed by user)

- none — greenfield repository; recorded as RISK (no gold-standard code to match).

## Architecture constraints (confirmed)

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

## Unverified assumptions (RISK)

- Main menu navigation model (keyboard-only vs mouse) — assumed keyboard-first with
  mouse optional; final UI belongs to the user's later art pass.
- Chapter scene placeholder geometry is free-form; no art references exist yet.
- No remote existed at intake time; PR flow enabled mid-intake per user Q3 answer.
