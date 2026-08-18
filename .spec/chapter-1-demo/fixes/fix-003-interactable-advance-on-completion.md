# fix-003 — Interactable advances the stage only on normal dialogue completion

## Linked GitHub issue
- #4 — [AI审查] 对话强制关闭后仍推进

## Failing criterion
> "在 _unhandled_input 中 await DialogueService.play(dialogue) 后，未检查对话是否因强制关闭
> （如场景切换）而提前结束。若对话被强制关闭，play() 会提前返回，但 advance_stage_on_complete
> 仍会触发 GameFlow.request_advance_stage()，可能导致在场景切换过程中意外推进流程。"

`design.md` specifies `Interactable` has "optional stage-advance on completion"; the advance must
fire only when the dialogue completed normally, not when it was force-closed.

## Root cause
`scripts/world/interactable.gd` treats any return from `await DialogueService.play(dialogue)` as
"dialogue finished", then advances when `advance_stage_on_complete` is set. It never checks whether
the dialogue ended normally vs. was force-closed by a transition, so a forced close can still
trigger a stage-advance request.

## Context files (read for understanding — do not modify)
- `scripts/world/interactable.gd` (introduced in commit `95ddb7b`) — the offending post-`await` advance.
- `scripts/autoload/dialogue_service.gd` — `play()` now returns `bool` (see fix-002, this task's dependency).

## Reference files (STRICT STYLE MATCH)
- `scripts/world/interactable.gd` — existing typed-`await` + guarded-input style to keep.

## Files to create/modify (suggested)
- `scripts/world/interactable.gd` — modify: capture `play()` result and gate the advance on it.

## Minimal fix
Depends on fix-002 (`play()` returns `bool`).
1. Capture the result: `var completed: bool = await DialogueService.play(dialogue)`.
2. Advance only when it truly finished: `if completed and advance_stage_on_complete: GameFlow.request_advance_stage()`.
3. No other behavior changes (replay-on-reinteract for non-advancing NPCs is unchanged).

## Acceptance
- [ ] `gdlint .` reports 0 problems.
- [ ] `godot --headless --editor --path . --quit-after 10` — no `ERROR:`, `SCRIPT ERROR`, `Parse Error`, `Failed loading`.
- [ ] `godot --headless --path . --quit-after 5 scenes/world/chapter_home.tscn` — clean.
- [ ] Advancing NPC: after the dialogue finishes normally, `GameFlow.request_advance_stage()` fires exactly once.
- [ ] Regression repro: open an advancing NPC's dialogue, force-close it via `ui_cancel` →
      `request_quit_to_menu()`; the stage does NOT advance (no double/out-of-sequence advance).
- [ ] Non-advancing NPC: replay-on-reinteract still works (behavior unchanged).

## Needs tests
no (project has no test tool; gates are `gdlint .` + Godot headless + the manual repro above)

---

## Implementation log (filled by dev after successful commit)
- Commit: 3ab088d — fix(chapter-1-demo): 仅在对话正常结束后推进阶段
- Files modified:
  - scripts/world/interactable.gd (modified)
- Tests added: none required
- Context & Reference files read:
  - scripts/world/interactable.gd
  - scripts/autoload/dialogue_service.gd
- Notes: Matched the suggested file list exactly (one file). `DialogueService.play()` already
  returns `bool` from fix-002 (`true` only when every line advanced without `_force_close`), so
  the fix is the two-line gate from `## Minimal fix`: `var completed: bool = await
  DialogueService.play(dialogue)` plus `if completed and advance_stage_on_complete`. A short
  "why" comment explains that a forced close must not advance mid-transition. Note that a no-op
  call (null/empty `DialogueData` or already open) also returns `false`, which is correct here —
  the `dialogue == null` guard above already returns early, and no dialogue playing means no
  completion to advance on. Non-advancing NPC replay-on-reinteract is untouched.
  Validation: `gdlint .` 0 problems; `godot --headless --editor --path . --quit-after 10` and
  `godot --headless --path . --quit-after 8 scenes/world/chapter_home.tscn` both clean (no
  `ERROR:` / `SCRIPT ERROR` / `Parse Error` / `Failed loading`). The two runtime/manual
  acceptance items (advance fires exactly once; force-close repro does not advance) are code-path
  verified, not executed — they need an interactive session.
