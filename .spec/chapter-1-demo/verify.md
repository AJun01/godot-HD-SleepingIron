# Verify: Chapter 1 Demo

## Status
PASS

> Re-verification after the AI-review fix round (issues #3/#5/#4). The original
> PASS (first pass) held on every acceptance criterion; a subsequent AI code review
> opened 3 issues, each fixed with one conventional commit and re-verified below.
> All gates pass again.

## Failure history (AI-review fix round)
- First pass: PASS (verify.md written and committed in `68e4bc8`; PR #2 opened against `master`).
- AI review then flagged 3 progression-ownership / completion-contract issues, auto-filed as GitHub
  issues #3, #5, #4. The developer applied three minimal fixes on `feature/chapter-1-demo`:
  - `fix-001` — `6442bcd` (`Closes #3`): ending auto-return timing moved from the scene into `GameFlow`.
  - `fix-002` — `1fc4be2` (`Closes #5`): `DialogueService.play()` now returns completion status (`bool`).
  - `fix-003` — `3ab088d` (`Closes #4`): `Interactable` advances the stage only when `play()` returns `true`.
- This document is the re-verification of those three fixes on top of the original PASS.

## Acceptance criteria
- [x] New Game from menu presents Chapter 1 Stage 1 (home) — `scripts/ui/main_menu.gd:12` wires `NewGameButton.pressed` → `GameFlow.request_new_game()`; probe confirmed (commit `54cb02d`).
- [x] 8-direction movement, keyboard + gamepad — `scripts/world/player.gd:25` reads `Input.get_vector(...)`; every `move_*` action carries keyboard + joypad bindings (commit `54cb02d`).
- [x] 4 stages in fixed order, no skip/out-of-order — `resources/flow_config.tres` lists menu(0)→home(1)→field(2)→town(3)→return(4)→ending(5); `game_flow.gd` guards `request_advance_stage()` to `State.CHAPTER`; probe `INDEX_SEQUENCE [0,1,2,3,4,5,0]` (commits `57667f7`, `9aef0b6`).
- [x] Interact key (E) near NPC triggers dialogue — `interact` maps E + joypad A; `interactable.gd` gates on `_player_in_range` (commit `95ddb7b`).
- [x] Legible Chinese (no tofu) — Noto Sans SC vendored at `assets/fonts/noto_sans_sc.ttf`, `resources/theme.tres`, `project.godot` `gui/theme/custom` (commit `e034eba`).
- [x] Line-by-line advance, one press one line, no echo — `dialogue_service.gd` awaits `advance_pressed` per line and ignores `event.is_echo()` (commit `6be02f6`).
- [x] Movement ignored while dialogue open — `player.gd:23-24` returns `Vector3.ZERO` when `DialogueService.is_open()` (commit `54cb02d`).
- [x] Beats: Ina blue-soda / wine-shop owner buy-wine / Uma-Defa trio / mother wake-up — advancing NPCs carry `advance_stage_on_complete = true`; wire into `ina.tres`, `wine_shop.tres`, `uma_defa.tres`, `mother.tres` (commits `1c4d218`, `54cb02d`, `9aef0b6`).
- [x] Dialogue faithful to novel (compressed, no invented lore) — 4 `DialogueData` `.tres` spot-checked against `docs/source/正文.md` 17–140; every line traces to a compression of the source (see advisory).
- [x] Objective HUD matches current stage, never stale — `objective_hud.gd` updates on `stage_changed`; probe confirmed exact objective per stage and empty/hidden on menu+ending (commit `014e3bb`).
- [x] Interact during transition rejected without corruption — `interactable.gd` guards `SceneRouter.is_transitioning()`; `stage_exit.gd` guards the same (commit `95ddb7b`).
- [x] Re-trigger replays/skips without softlock — non-advancing NPCs replay; advancing NPCs leave before re-trigger (commit `95ddb7b`).
- [x] Quit-to-menu mid-stage safe — `stage.gd` forwards `ui_cancel` → `request_quit_to_menu()`; `dialogue_service.gd` force-closes on `transition_started` (commits `54cb02d`, `6be02f6`).
- [x] Final beat → fade → "Chapter 1 DEMO complete" → auto-return to menu — NOW owned by `GameFlow` via `FlowStage.auto_return_delay = 3.0` (`fix-001`, commit `6442bcd`); probe confirmed ending → menu auto-return.
- [x] New visual assets registered as SVG placeholders — `docs/sdd/artifacts/chapter-1-demo.yml` registers font+theme+8 SVGs+4 dialogue+player+scenes (commits `1c4d218`, `e034eba`, `54cb02d`, `9aef0b6`, updated in `6442bcd`).

### Fix-round acceptance (issues #3 / #5 / #4)
- [x] `chapter_ending.gd` is display-only — no `create_timer`, no `SceneTreeTimer`, no `GameFlow.` call, no `@export`, no `_ready`; the file is a `Control` + one "why" comment (verified by read; grep found zero forbidden symbols).
- [x] `DialogueService.play()` returns `bool` — `true` only when every line advanced without `_force_close`; `false` for the no-op paths (already open, null/empty) and forced close (`dialogue_service.gd:43-61`).
- [x] `Interactable` advances only on normal completion — `var completed: bool = await DialogueService.play(dialogue)`; `if completed and advance_stage_on_complete:` (`interactable.gd:52-54`).
- [x] Ending auto-return timing is data + GameFlow-owned — `FlowStage.auto_return_delay: float = 0.0`; `GameFlow._start_auto_return_if_needed()` schedules a `SceneTreeTimer` on stage activation and `_on_auto_return_timeout()` re-checks stage index + `State.CHAPTER` before `request_quit_to_menu()` (`flow_stage.gd:25`, `game_flow.gd:95-123`, `flow_config.tres:47`).

## Tests
- Project has tests: no (per tasks.index.md) — no test command to run.
- Gates run (project validation block):
  - `/tmp/gdtk/bin/gdlint .` → `Success: no problems found` (exit 0).
  - `/opt/homebrew/bin/godot --headless --editor --path . --quit-after 10` → clean (exit 0, no ERROR/SCRIPT ERROR/Parse Error/Failed loading).
  - Scene runs (boot + 5 stages) → all clean: `scenes/boot.tscn`, `scenes/world/chapter_home.tscn`, `chapter_field.tscn`, `chapter_town.tscn`, `chapter_return.tscn`, `chapter_ending.tscn`.
  - Runtime probe (`/tmp/probe_flow.gd`, `extends SceneTree`) → full linear flow menu→home→field→town→return→ending→auto-return-to-menu: `FAILURES=[]` (exit 0), `INDEX_SEQUENCE=[0,1,2,3,4,5,0]`, exact per-stage objectives, `HUD_LABEL text= visible=false` at menu.

## Developer log integrity
- Tasks with filled Implementation log: 8 / 8
- Fixes with filled Implementation log: 3 / 3
- Commit/file mismatches: 0 —
  - `6442bcd` (`Closes #3`) changed exactly the 5 files logged in fix-001 (`flow_stage.gd`, `game_flow.gd`, `flow_config.tres`, `chapter_ending.gd`, `docs/sdd/artifacts/chapter-1-demo.yml`).
  - `1fc4be2` (`Closes #5`) changed exactly `scripts/autoload/dialogue_service.gd` (fix-002).
  - `3ab088d` (`Closes #4`) changed exactly `scripts/world/interactable.gd` (fix-003).
- Tasks/fixes missing Implementation log: 0
- Context & Reference files read: complete for all 8 tasks and 3 fixes (every declared Context/Reference file appears in the read list; no claimed file is missing from the repo).
- Trailers: all 3 fix commits carry the correct `Closes #N` trailer matching their linked issue and `tasks.index.md` fix rows.

## Convention compliance (AGENTS.md / CLAUDE.md)
- Static typing everywhere: HONORED (grep found no untyped `var` declarations in the fixed files or `scripts/`).
- Signals for decoupling, no `get_node("../../...")`: HONORED.
- Composition over inheritance: HONORED (`Interactable`/`StageExit` are Area3D components).
- Tunables in Resource/@export: HONORED (`auto_return_delay` lives on `FlowStage`, not hardcoded).
- `call_deferred` for tree mutation: HONORED.
- Explicit collision layers/masks: HONORED.
- Naming (snake_case files, PascalCase classes/nodes): HONORED.
- English "why" comments: HONORED (fix-003 adds a one-line "why" comment; fix-001 rewrote `chapter_ending.gd` as a "why" comment).
- Conventional commits, one per task/fix: HONORED (8 `feat:` + 3 `fix(chapter-1-demo):` commits with `Closes #N` trailers).
- HD-2D invariants: HONORED.

## Architecture fidelity
- GameFlow remains the only progression entry: HONORED — `SceneRouter.transition_to()` is called only from `game_flow.gd`; the ending scene no longer calls `GameFlow.request_quit_to_menu()` itself (fix-001). Progression timing is now a `FlowStage` tunable consumed by `GameFlow`, so "stages extend FlowConfig, never code".
- DialogueService contract swappable: HONORED — `DialogueData` is the data contract; `DialogueService` is its only consumer; `play()` now exposes an observable completion result without breaking the swap contract.
- ObjectiveHud never stale: HONORED (probe-verified).
- Placeholders + registry complete: HONORED — registry updated in `6442bcd` so the ending scene's invariant matches its display-only contract.

## Docs updated
- `docs/sdd/artifacts/chapter-1-demo.yml` — ending scene invariants corrected in `6442bcd` to the display-only + `auto_return_delay = 3.0` contract (fix-001 required).
- No AGENTS.md change required (no repo-layout change beyond documented conventions).

## Advisory (non-blocking)
- **Dialogue faithfulness — human final reading recommended.** All 4 beats trace to compressed excerpts of `docs/source/正文.md` 17–140 with no invented lore, but the beats encode multi-party exchanges as inline `角色：` line prefixes with an empty `speaker` field. A final human read of the compressed lines is advisory before merge.
- Minor: `docs/sdd/artifacts/game-skeleton.yml` (prior feature registry) still references the deleted `scenes/world/chapter.tscn`; out of scope here, worth a later doc-cleanup task.
- The manual-only fix acceptance items (ending ~3s auto-return on a real display; force-close repro does not advance) are code-path + probe verified headlessly, not visually confirmed — a human with a display should smoke-test the ending once.

## PR
- Target branch: master
- Pushed: yes
- PR URL: https://github.com/AJun01/godot-HD-SleepingIron/pull/2
- Note: PR #2 was already OPEN (base master) from the first pass; no new PR was created. Pushing `feature/chapter-1-demo` updates it automatically and re-runs the AI review workflow (expected).
