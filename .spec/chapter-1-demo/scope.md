# Scope: Chapter 1 Demo

## Objective
Enable the player to play through the full compressed Chapter 1 (wake-up → leave home → field road → town → buy wine → return home → the three set off) as a linear demo so that the core progression loop and HD-2D presentation are experienced and validated end-to-end.

## User stories
- As a player, I want to start a New Game from the main menu so that I enter Chapter 1's first stage.
- As a player, I want to walk through the four linear chapter stages so that I progress from waking up at home through leaving, the field road, town, and the return home in a fixed order.
- As a player, I want to interact with NPCs (mother, Ina, wine-shop owner, Uma/Defa) so that their story beats play as faithful, compressed dialogue.
- As a player, I want an objective HUD that reflects the current stage so that I always know my current goal.
- As a player, I want the demo to end with a fade to a "Chapter 1 DEMO complete" screen that returns to the main menu so that the demo has a clear, non-blocking ending.

## Acceptance criteria
- [ ] Selecting "New Game" from the main menu presents Chapter 1 Stage 1 (home front).
- [ ] The player moves in 8 directions with both keyboard and gamepad throughout the demo.
- [ ] The player progresses through the 4 stages in fixed order (home front → field road → town → return); out-of-order or skipped stages are impossible.
- [ ] Pressing the interact key (E) near an interactable NPC triggers that NPC's dialogue.
- [ ] Dialogue displays legible Chinese characters (no tofu/blank glyphs).
- [ ] Dialogue advances line-by-line: one advance-key press advances exactly one line.
- [ ] While dialogue is open, movement input is ignored.
- [ ] Interacting with Ina plays the blue-soda beat; the wine-shop owner plays the buy-wine beat; Uma/Defa play the giant-statue-glow trio beat; the mother plays the wake-up beat where included.
- [ ] Dialogue text stays faithful to the novel (compressed, no invented lore).
- [ ] The objective HUD always matches the current stage and updates immediately on stage change — it never shows the previous stage's objective.
- [ ] Attempting to interact during a scene transition is rejected without corrupting state or crashing.
- [ ] Re-triggering a completed interaction either replays or skips without softlocking.
- [ ] Quitting to the main menu mid-stage and re-entering the chapter is safe (no stuck/blocked state).
- [ ] After the final beat (the three set off), the game fades out to a "Chapter 1 DEMO complete" placeholder screen, then automatically returns to the main menu.
- [ ] All new visual assets are SVG placeholders registered in the artifact registry (no final art required).

## External Tools & Design Mocks
- Figma: none
- Other Tools: none

## Reference Files (Gold Standards)
- `scripts/autoload/game_flow.gd` — GameFlow FSM: the ONLY place state transitions happen.
- `scripts/autoload/scene_router.gd` — fade transition + busy flag + call_deferred swap.
- `scripts/autoload/event_bus.gd` — typed signals pattern for cross-scene communication.
- `resources/flow_config.tres` + `resources/transition_config.tres` + `resources/player_config.tres` — Resource-driven tunables; new stages extend FlowConfig, never code.
- `scenes/world/chapter.tscn` + `scripts/world/player.gd` + `scripts/world/camera_follow.gd` — HD-2D stage composition, billboarded placeholder player, camera follow.
- `assets/placeholders/*.svg` + `docs/sdd/artifacts/game-skeleton.yml` — placeholder policy and artifact registry format.
- `docs/source/正文.md` lines 17–140 — canonical story text for chapter 1 (lines 80–131 cover the wine-shop/return-home/trio beats; compressed dialogue must stay faithful).

## Architecture constraints
- **Linear game:** 4 stages via FlowConfig; GameFlow remains the single progression entry.
- **Modular + extensible:** interaction + dialogue + objective-HUD are separate small systems (autoload services or composable components), designed so a future full dialogue system can replace the minimal one without rewriting stages; no god-scripts.
- **HD-2D:** world stages carry 3D lighting; NPCs/player are billboarded placeholder sprites.
- **Placeholders:** new NPCs (Ina, wine shop owner, Uma, Defa, mother) and stage props use self-authored SVG placeholders in `assets/placeholders/`, registered in `docs/sdd/artifacts/chapter-1-demo.yml` with `status: placeholder`.
- **GDScript law + CI gates:** full static typing, gdlint clean, godot headless clean (both enforced locally and by the new CI/branch protection).

## Reuse (do NOT recreate)
- Skeleton autoloads, configs, placeholder convention, and validation gates — extend, never rewrite. Existing `scenes/world/chapter.tscn` becomes (or is replaced by) the first of the 4 chapter stages; FlowConfig gains the 4 stage entries.

## Out of scope
- Combat.
- Inventory.
- Save/load.
- Audio (music and SFX).
- Full branching dialogue system.
- Final/production art assets (SVG placeholders only).
- Story content beyond chapter 1.
- Input remapping / settings (belongs to a future settings feature).

## Unverified assumptions (RISK)
- Chinese dialogue rendering: Godot 4 default theme font lacks full CJK coverage. The design must bundle an OFL-licensed CJK font (e.g. Noto Sans SC) in `assets/fonts/`; headless CI must still pass. (Risk if a suitable font is not added: tofu glyphs on dialogue.)
- Stage boundaries and exact beat placement (home/field/town/return) are free-form — no art or level-design references exist yet; placeholders define geometry.
- Interaction key mapping (E + advance) assumed; final remap belongs to the settings feature.
- Novel text is compressed for demo pacing; exact line compression is a tech-lead/dev decision constrained by faithfulness (no invented lore).

## Context
Sleeping Iron HD-2D is a linear, stage-driven game adapted from the novel *SLEEPING IRON*. This demo delivers the full compressed first chapter so the core progression loop — menu into an ordered sequence of stages, NPC dialogue, and an objective HUD — can be experienced and validated end-to-end before later chapters (combat, inventory, saves, dialogue) are added. It establishes the reference implementation for how future chapters add stages and systems without rewriting the existing skeleton.
