# Intake: Chapter 1 Demo

## PR target branch
master (origin/master; remote https://github.com/AJun01/godot-HD-SleepingIron.git exists;
branch protection ruleset requires the two CI checks to pass before merge)

## Raw prompt
"我们只用做第一章demo就行，然后可以开下一个specs了"

## Clarifications (Q&A)

### Q1 — Feature behavior: story scope
**Recommended:** Full compressed chapter: wake-up → leave home → field road → meet Ina
(get blue soda) → buy wine → way back meets Uma/Defa (giant statue glow talk) → home
(drop wine) → the three set off → fade out.
**User answered:** A — full compressed chapter.

### Q2 — Architecture fit: scene structure
**Recommended:** Multi-stage linear flow: home front / field road / town / way back as 4
stages driven by FlowConfig + SceneRouter, proving the linear skeleton; later chapters add
stages the same way.
**User answered:** A — multi-stage linear flow.

### Q3 — Feature behavior: interaction/dialogue minimal system
**Recommended:** E-key interaction points + dialogue bar with line-by-line advance + objective
HUD. Dialogue lines taken (compressed) from the original novel text. Foundation for a future
full dialogue system.
**User answered:** A — minimal interaction + dialogue + HUD.

### Q4 — Feature behavior: demo ending
**Recommended:** After the "three set off" beat: fade out → "Chapter 1 DEMO complete"
placeholder screen → auto return to main menu.
**User answered:** A — ending placeholder screen + return to main menu.

## Confirmed feature behavior

- **Inputs:** keyboard/gamepad movement (existing 8-direction from skeleton); E/interact key
  near interactables; dialogue advance key; menu selection (existing).
- **Outputs:** boot → menu → New Game enters stage 1 (home front); player walks through 4
  linear stages; NPC interactions play dialogue (Ina soda, wine shop owner, Uma/Defa trio
  scene, mother wake-up call optionally); objective HUD updates per stage; final beat fades
  to a "Chapter 1 DEMO complete" placeholder screen and returns to the main menu.
- **Edge cases handled:** interaction during scene transition is impossible (GameFlow state
  gate + SceneRouter busy flag); dialogue blocks movement and input queues one advance at a
  time; re-triggering a completed interaction replays or skips per design (no softlock);
  objective HUD must never show stale text after a stage change; quitting to menu mid-stage
  and re-entering is safe (skeleton FlowConfig already handles menu ↔ chapter).
- **Out of scope:** combat, inventory, save/load, audio, full branching dialogue system,
  real art assets (SVG placeholders only), story content beyond chapter 1.

## Reference Files (confirmed by user)

- `scripts/autoload/game_flow.gd` — GameFlow FSM: the ONLY place state transitions happen.
- `scripts/autoload/scene_router.gd` — fade transition + busy flag + call_deferred swap.
- `scripts/autoload/event_bus.gd` — typed signals pattern for cross-scene communication.
- `resources/flow_config.tres` + `resources/transition_config.tres` + `resources/player_config.tres`
  — Resource-driven tunables; new stages extend FlowConfig, never code.
- `scenes/world/chapter.tscn` + `scripts/world/player.gd` + `scripts/world/camera_follow.gd`
  — HD-2D stage composition, billboarded placeholder player, camera follow.
- `assets/placeholders/*.svg` + `docs/sdd/artifacts/game-skeleton.yml` — placeholder policy
  and artifact registry format.
- `docs/source/正文.md` lines 17–140 — canonical story text for chapter 1 (lines 80–131 cover
  the wine-shop/return-home/trio beats; compressed dialogue must stay faithful).

## Architecture constraints (confirmed)

- **Linear game:** 4 stages via FlowConfig; GameFlow remains the single progression entry.
- **Modular + extensible:** interaction + dialogue + objective-HUD are separate small
  systems (autoload services or composable components), designed so a future full dialogue
  system can replace the minimal one without rewriting stages; no god-scripts.
- **HD-2D:** world stages carry 3D lighting; NPCs/player are billboarded placeholder sprites.
- **Placeholders:** new NPCs (Ina, wine shop owner, Uma, Defa, mother) and stage props use
  self-authored SVG placeholders in `assets/placeholders/`, registered in
  `docs/sdd/artifacts/chapter-1-demo.yml` with `status: placeholder`.
- **GDScript law + CI gates:** full static typing, gdlint clean, godot headless clean
  (both enforced locally and by the new CI/branch protection).

## Reuse (do NOT recreate)

- Skeleton autoloads, configs, placeholder convention, and validation gates — extend, never
  rewrite. Existing `scenes/world/chapter.tscn` becomes (or is replaced by) the first of the
  4 chapter stages; FlowConfig gains the 4 stage entries.

## Unverified assumptions (RISK)

- Chinese dialogue rendering: Godot 4 default theme font lacks full CJK coverage. The design
  must bundle an OFL-licensed CJK font (e.g. Noto Sans SC) in `assets/fonts/`; headless CI
  must still pass. (Risk if a suitable font is not added: tofu glyphs on dialogue.)
- Stage boundaries and exact beat placement (home/field/town/return) are free-form — no art
  or level-design references exist yet; placeholders define geometry.
- Interaction key mapping (E + advance) assumed; final remap belongs to the settings feature.
- Novel text is compressed for demo pacing; exact line compression is a tech-lead/dev decision
  constrained by faithfulness (no invented lore).
