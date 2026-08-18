# Verify: Chapter 1 Demo

## Status
PASS

## Acceptance criteria
- [x] New Game from menu presents Chapter 1 Stage 1 (home) — `scripts/ui/main_menu.gd:12` wires `NewGameButton.pressed` → `GameFlow.request_new_game()`; runtime probe confirmed `request_new_game()` lands on `res://scenes/world/chapter_home.tscn` (commit `54cb02d`).
- [x] 8-direction movement, keyboard + gamepad — `scripts/world/player.gd:25` reads `Input.get_vector("move_left","move_right","move_up","move_down")`; every `move_*` action in `project.godot` carries keyboard + joypad button + joypad motion (commit `54cb02d`).
- [x] 4 stages in fixed order, no skip/out-of-order — `resources/flow_config.tres` lists menu(0)→home(1)→field(2)→town(3)→return(4)→ending(5); `scripts/autoload/game_flow.gd:38` `request_advance_stage()` guarded to `State.CHAPTER`, `_transition_to_stage` bounds-checked. Probe INDEX_SEQUENCE `[0,1,2,3,4,5,0]` (commits `57667f7`, `9aef0b6`).
- [x] Interact key (E) near NPC triggers dialogue — `interact` action maps E + joypad A (`project.godot:45-49`); `scripts/world/interactable.gd:40-52` gates on `_player_in_range` (commit `95ddb7b`).
- [x] Legible Chinese (no tofu) — Noto Sans SC (genuine TrueType, 17.7 MB) vendored at `assets/fonts/noto_sans_sc.ttf`, `resources/theme.tres` `default_font`, `project.godot:34` `gui/theme/custom` (commit `e034eba`).
- [x] Line-by-line advance, one press one line, no echo — `scripts/autoload/dialogue_service.gd:50-53` awaits `advance_pressed` per line; `:75` ignores `event.is_echo()` (commit `6be02f6`).
- [x] Movement ignored while dialogue open — `scripts/world/player.gd:23-24` returns `Vector3.ZERO` when `DialogueService.is_open()` (commit `54cb02d`).
- [x] Beats: Ina blue-soda / wine-shop owner buy-wine / Uma-Defa trio / mother wake-up — town scene wires Ina (`ina.tres`, non-advancing) + wine-shop owner (`wine_shop.tres`, `advance_stage_on_complete = true`); return scene wires Uma (`uma_defa.tres`, advancing) + Defa sprite; home wires mother (`mother.tres`, advancing) (commits `1c4d218`, `54cb02d`, `9aef0b6`).
- [x] Dialogue faithful to novel (compressed, no invented lore) — spot-checked all 4 `DialogueData` `.tres` against `docs/source/正文.md` 17–140; every line traces to a compression of the source (no invented lore). See advisory below.
- [x] Objective HUD matches current stage, never stale — `scripts/autoload/objective_hud.gd` updates on `stage_changed` (emitted at fade-start, `game_flow.gd:71`); probe confirmed exact objective per stage and label empty/hidden on menu+ending (commit `014e3bb`).
- [x] Interact during transition rejected without corruption — `scripts/world/interactable.gd:43` guards `SceneRouter.is_transitioning()`; `stage_exit.gd:27` guards the same before advancing (commit `95ddb7b`).
- [x] Re-trigger replays/skips without softlock — non-advancing NPCs replay the same `DialogueData` (`interactable.gd`); advancing NPCs leave the stage before re-trigger (design.md trade-off) (commit `95ddb7b`).
- [x] Quit-to-menu mid-stage safe — `scripts/world/stage.gd:9` forwards `ui_cancel` → `GameFlow.request_quit_to_menu()`; `dialogue_service.gd:65-69` force-closes on `transition_started` (commits `54cb02d`, `6be02f6`).
- [x] Final beat → fade → "Chapter 1 DEMO complete" → auto-return to menu — `scripts/ui/chapter_ending.gd:11-16` timer → `request_quit_to_menu()`; probe confirmed ending → menu auto-return (commit `9aef0b6`).
- [x] New visual assets are registered SVG placeholders — `docs/sdd/artifacts/chapter-1-demo.yml` registers font+theme+8 SVGs+4 dialogue `.tres`+player+5 scenes, all `status: placeholder` (commit `1c4d218`, `e034eba`, `54cb02d`, `9aef0b6`).

## Tests
- Project has tests: no (per tasks.index.md) — no test command to run.
- Gates run (project validation block):
  - `/tmp/gdtk/bin/gdlint .` → `Success: no problems found` (exit 0).
  - `godot --headless --editor --path . --quit-after 10` → clean (exit 0, no ERROR/SCRIPT ERROR/Parse Error/Failed loading).
  - Scene runs (boot + 5 stages) → all clean: `scenes/boot.tscn`, `scenes/world/chapter_home.tscn`, `chapter_field.tscn`, `chapter_town.tscn`, `chapter_return.tscn`, `chapter_ending.tscn`.
  - Runtime probe (`--script` SceneTree driving GameFlow): full linear flow menu→home→field→town→return→ending→auto-return-to-menu, 0 failures, exact stage order + exact `stage_changed` objectives, ObjectiveHud label empty/hidden at menu.

## Developer log integrity
- Tasks with filled Implementation log: 8 / 8
- Commit/file mismatches: 0 — each commit's `git show --name-status` matches the logged file list. (Task 007's `chapter.tscn→chapter_home.tscn` and `chapter.gd→stage.gd` are reported by git as renames, consistent with the "deleted/created" log wording.)
- Tasks missing Implementation log: 0
- Context & Reference files read: complete for all 8 tasks (every declared Context/Reference file appears in the read list; no claimed file is missing from the repo).

## Convention compliance (AGENTS.md / CLAUDE.md)
- Static typing everywhere: HONORED (grep found no untyped `var` declarations in `scripts/`).
- Signals for decoupling, no `get_node("../../...")`: HONORED (no matches).
- Composition over inheritance: HONORED (`Interactable`/`StageExit` are Area3D components).
- Tunables in Resource/@export: HONORED (FlowConfig/TransitionConfig/PlayerConfig/DialogueData, `@export` fields).
- `call_deferred` for tree mutation: HONORED (SceneRouter swap, ObjectiveHud first build, StageExit advance).
- Explicit collision layers/masks: HONORED (`interactable.gd`/`stage_exit.gd` set layer 3 / mask 2 in `_ready`).
- Naming (snake_case files, PascalCase classes/nodes, `class_name` only for globals): HONORED.
- English "why" comments: HONORED.
- Conventional commits, one per task: HONORED (8 `feat(chapter-1-demo):` commits).
- HD-2D invariants (3D world carries lighting, billboarded sprites, UI art vs dynamic labels): HONORED.

## Architecture fidelity
- GameFlow remains the only progression entry: HONORED — `SceneRouter.transition_to()` is called only from `game_flow.gd:64`; every other script calls `GameFlow.request_*`.
- DialogueService contract swappable: HONORED — `DialogueData` is the data contract; `DialogueService` is its only consumer; `Interactable` only calls `play(dialogue)`.
- ObjectiveHud never stale: HONORED — driven solely by `stage_changed` at fade-start; hides on empty objective (probe-verified).
- Placeholders + registry complete: HONORED — all 8 SVGs + font + theme + 4 dialogue + 6 scenes registered with `status: placeholder`.
- CJK font theme applied: HONORED — `gui/theme/custom` → `theme.tres` → `noto_sans_sc.ttf`.

## Docs updated
- `docs/sdd/artifacts/chapter-1-demo.yml` — created and extended across tasks (font, theme, placeholders, dialogue, scenes) — required by the feature.
- No AGENTS.md change required (no repo-layout change beyond the documented conventions).

## Advisory (non-blocking)
- **Dialogue faithfulness — human final reading recommended.** All 4 beats trace to compressed excerpts of `docs/source/正文.md` 17–140 with no invented lore, but the beats encode multi-party exchanges as inline `角色：` line prefixes with an empty `speaker` field (flagged by the developer and design.md "Gaps for human attention"). A final human read of the compressed lines is advisory before merge.
- Minor: `docs/sdd/artifacts/game-skeleton.yml` (prior feature registry) still references the deleted `scenes/world/chapter.tscn`; out of scope here, worth a later doc-cleanup task.

## PR
- Target branch: master
- Pushed: yes
- PR URL: https://github.com/AJun01/godot-HD-SleepingIron/pull/2
