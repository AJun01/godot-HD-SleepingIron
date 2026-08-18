# Review round 2 — Dismissals (GitHub issues #8–#12)

Second AI-review pass on PR #2 opened five findings (#8–#12). All five are
opinions / design choices / false positives, not genuine defects. No fix task
is created. Rationale below, keyed to the issue and the current code.

---

## #8 — "状态机解耦违规" (interactable.gd:54 calls `GameFlow.request_advance_stage()`)

**Verdict: dismiss (design choice, architecture law already satisfied).**

The Architecture law ("state transitions happen only inside GameFlow") is
satisfied, because a *request* is not a *transition*. `interactable.gd:54`
calls the guarded public method `GameFlow.request_advance_stage()`; that method
validates the current state (`if _state != State.CHAPTER: return`) and then
delegates to the private `_transition_to_stage()` / `_set_state()`. The actual
state mutation (`_state`, `_current_stage_index`) happens **only inside
GameFlow** — no scene script can reach those private fields, and the only
public entry points are the guarded `request_*` methods. This is precisely the
established skeleton pattern (`main_menu.gd` → `GameFlow.request_new_game()`),
and `design.md` codified it: "central state machine as the single progression
entry — reused, extended with `request_advance_stage()` (no scene
self-advances)" and Trade-off #3 (autoload-direct calls are the established
pattern over an EventBus relay).

Routing the request through an EventBus signal (`stage_advance_requested`)
would **not** change ownership — GameFlow would still be the component that
mutates state — it would only add an indirection hop and discard the
synchronous state guard that the guarded method provides. That is a stylistic
preference, not a correctness or architecture defect.

**Code change warranted: none.** `game_flow.gd:2–5` already documents this
exact contract in its header docstring ("Scenes never advance themselves; they
only call the `request_*` methods below, each guarded by the current state so
duplicate or out-of-sequence transitions are impossible"). No clarifying
docstring is needed because the clarification already exists at the point the
reviewer would look.

---

## #11 — "状态推进耦合" (stage_exit.gd:29 calls `GameFlow.request_advance_stage()`)

**Verdict: dismiss — same rationale as #8.**

`stage_exit.gd:29` issues the same guarded request via
`GameFlow.request_advance_stage()`; the state transition itself runs inside
GameFlow. The guard is duplicated at the call site (`SceneRouter.is_transitioning()`
re-checked after `call_deferred`, `stage_exit.gd:27-28`), but the authoritative
state guard is still inside GameFlow's method, so out-of-sequence or duplicate
transitions remain impossible regardless of caller. The EventBus-relay
suggestion is the same non-defect style preference as #8.

**Code change warranted: none.**

---

## #9 — "对话播放失败静默" (play() returns false when `_is_open`, "caller ignores it")

**Verdict: dismiss (false positive).**

The premise is factually wrong on two counts:

1. The caller does **not** ignore the result. `interactable.gd:52–53` captures
   `var completed: bool = await DialogueService.play(dialogue)` and uses it to
   gate the advance (`if completed and advance_stage_on_complete`). This is the
   completion contract added in fix-002/fix-003.
2. The "already-open → silent failure" path is **unreachable** from this
   caller: `interactable.gd:43` already short-circuits on
   `DialogueService.is_open()` before ever calling `play()`. So `play()` is
   never invoked while the dialogue bar is open. The `_is_open → return false`
   branch in `play()` is a defensive guard for hypothetical future callers, not
   a reachable failure path.

There is also no silent-failure UX: `interact` (E) and `advance`
(Enter/Space) are distinct actions (design Trade-off #7). While the bar is
open, re-pressing E is a correct no-op — the open bar is itself the visible
state, and line advance belongs to the advance key. No warning print or queue
is warranted; adding one would be scope expansion with no user-visible value.

**Code change warranted: none.**

---

## #10 — "自动返回延迟待确认" (`chapter_ending.auto_return_delay = 3.0`)

**Verdict: dismiss (pacing tunable, not story content).**

`auto_return_delay` is a Resource-driven **pacing/UX tunable** — how many
seconds the "Chapter 1 DEMO complete" message stays on screen before returning
to the menu. It is not story content, so the "no invented lore" rule (AGENTS.md
source-material rule + Role boundary) does not apply: that rule governs
characters, dialogue, and events, not UI timing. The novel would never specify
an ending-screen display duration.

The value correctly lives on `FlowStage` (`flow_stage.gd:25`, `@export var
auto_return_delay: float = 0.0`) and is set in `flow_config.tres:47`, honoring
AGENTS.md GDScript rule #4 ("tunables live in Resource files or `@export`").
Changing it to 0 or deleting it would regress the acceptance criterion
"final beat → fade → 'Chapter 1 DEMO complete' → auto-return to menu"
(`verify.md` line 34).

**Code change warranted: none.**

---

## #12 — "输入处理顺序" (`dialogue_service.gd:100–104`, `_unhandled_input`)

**Verdict: dismiss — the issue's own text concludes no change needed ("无需修改").**

`_unhandled_input` is the correct phase here and is already gated by `_is_open`
(`dialogue_service.gd:78`), so it cannot consume or conflict with the advance
key while the dialogue is closed. `_unhandled_input` (vs `_input`) is
deliberate: it lets other nodes (e.g. the player, the stage) consume the press
first, and only claims it when a dialogue is genuinely open. Moving to
`_input` would risk consuming the advance press before other handlers and
change input priority for no behavioral benefit.

**Code change warranted: none.**
