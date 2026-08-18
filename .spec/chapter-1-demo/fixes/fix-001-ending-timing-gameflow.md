# fix-001 — Move ending auto-return timing into GameFlow

## Linked GitHub issue
- #3 — [AI审查] 状态流转绕过GameFlow

## Failing criterion
> "chapter_ending.gd 在 _ready 中创建 SceneTreeTimer 并在超时后直接调用
> GameFlow.request_quit_to_menu()，这属于场景自身驱动状态流转，违反架构法律
> '状态流转只能发生在 GameFlow 内，禁止其他类硬编码状态流转'。"

This violates `AGENTS.md` "Architecture law (user-mandated)" — "Progression flows through
discrete, ordered stages (scenes) driven by a central game-flow state machine" — and
`design.md` "no scene self-advances" / "Progression stays owned by GameFlow". The ending
scene decides *when* the flow advances; that timing is progression scheduling and belongs to
`GameFlow`.

## Root cause
`scripts/ui/chapter_ending.gd` owns a `SceneTreeTimer` in its own `_ready()` and, on timeout,
triggers the return-to-menu through `GameFlow.request_quit_to_menu()`. The scene holds
progression-timing logic instead of being display-only. `GameFlow` has no notion of the
ending stage's auto-return, so the timing is not part of the central state machine.

## Context files (read for understanding — do not modify)
- `scripts/ui/chapter_ending.gd` (introduced in commit `9aef0b6`) — the offending scene-side timer.
- `scripts/autoload/game_flow.gd` (commit `57667f7`) — the state machine that must own the timing.
- `resources/flow_config.tres` (commit `57667f7`) — stage list; ending stage needs the tunable.

## Reference files (STRICT STYLE MATCH)
- `scripts/config/flow_stage.gd` — Resource-field declaration style to imitate for the new tunable.
- `scripts/autoload/game_flow.gd` — existing guarded `request_*`/transition patterns to reuse.

## Files to create/modify (suggested)
- `scripts/config/flow_stage.gd` — modify: add `auto_return_delay` tunable field.
- `scripts/autoload/game_flow.gd` — modify: start/own the auto-return timer when the stage becomes active.
- `resources/flow_config.tres` — modify: set `auto_return_delay = 3.0` on the ending stage.
- `scripts/ui/chapter_ending.gd` — modify: strip timer + progression logic; display-only.

## Minimal fix
1. Add `@export var auto_return_delay: float = 0.0` to `FlowStage` (tunable lives in a Resource,
   AGENTS.md rule #4). `0.0` means "no auto-return"; this keeps "new stages extend FlowConfig,
   never code".
2. In `GameFlow`, when a stage becomes active (in `_on_transition_finished`, after
   `_set_state(_pending_state)`), if the current stage is a chapter stage and its
   `auto_return_delay > 0.0`, cancel any prior auto-return timer and start a one-shot
   `SceneTreeTimer` for `auto_return_delay`; on timeout, re-check that `_current_stage_index`
   still points at that stage and `_state == State.CHAPTER`, then call `request_quit_to_menu()`.
3. Set `auto_return_delay = 3.0` on the `chapter_ending` `FlowStage` in `flow_config.tres`.
4. Reduce `chapter_ending.gd` to display-only: remove `@export return_delay`, `_ready()`, and
   `_on_return_timeout()` (keep the "Chapter 1 DEMO complete" message; it no longer triggers flow).

## Acceptance
- [ ] `gdlint .` reports 0 problems.
- [ ] `godot --headless --editor --path . --quit-after 10` — no `ERROR:`, `SCRIPT ERROR`, `Parse Error`, `Failed loading`.
- [ ] `godot --headless --path . --quit-after 5 scenes/world/chapter_ending.tscn` — clean, no parse/script errors.
- [ ] `chapter_ending.gd` contains no `create_timer`, no `SceneTreeTimer`, and no `GameFlow.` call.
- [ ] Manual run: New Game → reach ending → the message shows ~3s then auto-returns to the main
  menu, with the timer owned by `GameFlow` (regression repro of the original scene-driven behavior).
- [ ] Menu and non-ending chapter stages do NOT auto-advance (`auto_return_delay` defaults to `0.0`).

## Needs tests
no (project has no test tool; gates are `gdlint .` + Godot headless + the manual repro above)

---

## Implementation log (filled by dev after successful commit)
- Commit: 6442bcd — fix(chapter-1-demo): 结局阶段自动返回计时改由 GameFlow 拥有
- Files modified:
  - scripts/config/flow_stage.gd (modified)
  - scripts/autoload/game_flow.gd (modified)
  - resources/flow_config.tres (modified)
  - scripts/ui/chapter_ending.gd (modified)
  - docs/sdd/artifacts/chapter-1-demo.yml (modified)
- Tests added: none required (project declares no test tool; gates are gdlint + Godot headless)
- Context & Reference files read:
  - scripts/ui/chapter_ending.gd
  - scripts/autoload/game_flow.gd
  - resources/flow_config.tres
  - scripts/config/flow_stage.gd
- Notes:
  - `FlowStage.auto_return_delay` defaults to `0.0`, so the menu and the four chapter stages
    keep their behavior unchanged; only the `chapter_ending` stage sets `3.0`.
  - `GameFlow` schedules the timer in `_start_auto_return_if_needed()`, called from
    `_on_transition_finished()` right after `_set_state(_pending_state)`. It cancels any prior
    timer (disconnecting its `timeout`) and, on fire, re-checks that the scheduling stage index
    is still current and `_state == State.CHAPTER` before calling `request_quit_to_menu()`.
  - `chapter_ending.gd` is now display-only: no `create_timer`, no `SceneTreeTimer`, no
    `GameFlow.` call, no `@export`. The "Chapter 1 DEMO complete" message stays in
    `scenes/world/chapter_ending.tscn` (the scene never set `return_delay`, so removing the
    export required no scene change).
  - File touched outside the suggested list: `docs/sdd/artifacts/chapter-1-demo.yml` — its
    registry invariant for `scenes/world/chapter_ending.tscn` still asserted that the Control
    root "calls GameFlow.request_quit_to_menu()", which this fix makes false; the two invariant
    lines were updated to the display-only + `auto_return_delay = 3.0` contract.
  - Validation run: `gdlint .` → "Success: no problems found";
    `godot --headless --editor --path . --quit-after 10` → clean;
    `godot --headless --path . --quit-after 8 scenes/world/chapter_ending.tscn` → clean;
    `godot --headless --path . --quit-after 8 scenes/boot.tscn` (extra check that
    `flow_config.tres` still loads through the real boot path) → clean. No `ERROR:`,
    `SCRIPT ERROR`, `Parse Error`, or `Failed loading` in any run.
  - The manual acceptance item (New Game → ending → ~3s auto-return) needs a human with a
    display; it is not verifiable headlessly.
