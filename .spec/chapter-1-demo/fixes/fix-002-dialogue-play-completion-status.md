# fix-002 — DialogueService.play() returns normal-vs-forced completion status

## Linked GitHub issue
- #5 — [AI审查] play()提前返回风险

## Failing criterion
> "play() 在 _force_close 时 break 并调用 _close()，但调用方 await 的协程会正常返回，
> 无法区分正常结束与强制关闭。若调用方依赖对话完成后的状态，可能产生逻辑错误。"

`design.md` requires `Interactable` to do "optional stage-advance on completion"; "completion"
must be observable by the caller, but `play()` returns `void`, so a forced close and a normal
finish are indistinguishable to the `await` caller.

## Root cause
`scripts/autoload/dialogue_service.gd` `play()` is `-> void` and has no completion signal. Both a
full run of the line loop and a `_force_close` break fall through to `_close()` and return the
same way, so the sole consumer (`interactable.gd`) cannot tell whether the dialogue finished
normally or was aborted by a transition.

## Context files (read for understanding — do not modify)
- `scripts/autoload/dialogue_service.gd` (introduced in commit `6be02f6`) — the offending `play()`/`_close()`.
- `scripts/world/interactable.gd` (commit `95ddb7b`) — the only `play()` caller, consumes the result in fix-003.

## Reference files (STRICT STYLE MATCH)
- `scripts/autoload/game_flow.gd` — guarded-autoload method style to imitate.

## Files to create/modify (suggested)
- `scripts/autoload/dialogue_service.gd` — modify: `play()` returns `bool` (normal completion = `true`).

## Minimal fix
1. Change `func play(dialogue: DialogueData) -> bool`.
2. Return `false` for the two no-op early exits (`_is_open` already true; `dialogue == null` or
   `dialogue.lines.is_empty()`).
3. Track completion: after the `for` loop (which `break`s on `_force_close`), capture
   `var completed: bool = not _force_close` **before** `_close()` resets `_force_close`, then
   `_close()` and `return completed`.
4. No caller changes yet — `interactable.gd` still discards the value until fix-003; the return
   type change is backward-compatible.

## Acceptance
- [ ] `gdlint .` reports 0 problems.
- [ ] `godot --headless --editor --path . --quit-after 10` — no `ERROR:`, `SCRIPT ERROR`, `Parse Error`, `Failed loading`.
- [ ] `godot --headless --path . --quit-after 5 scenes/world/chapter_home.tscn` — clean.
- [ ] `play()` returns `true` only when every line advanced without a forced close (manual run:
      advance all lines of a non-advancing NPC's dialogue).
- [ ] `play()` returns `false` when force-closed mid-dialogue (manual run: open a dialogue, trigger
      `ui_cancel` → `request_quit_to_menu()` mid-dialogue).
- [ ] `play()` returns `false` for the no-op paths (already open; null/empty `DialogueData`).

## Needs tests
no (project has no test tool; gates are `gdlint .` + Godot headless + the manual repro above)

---

## Implementation log (filled by dev after successful commit)
- Commit: 1fc4be2 — fix(chapter-1-demo): DialogueService.play() 返回完成状态
- Files modified:
  - scripts/autoload/dialogue_service.gd (modified)
- Tests added: none required
- Context & Reference files read:
  - scripts/autoload/dialogue_service.gd
  - scripts/world/interactable.gd
  - scripts/autoload/game_flow.gd
- Notes: none
