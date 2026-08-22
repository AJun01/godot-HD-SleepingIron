# fix-001 — Rename sfx_trigger `_player` → `_audio_player`

## Context files (read for understanding — do not modify)
- scripts/dev/sfx_trigger.gd — offending file (commit `988783b`). The `var _player: AudioStreamPlayer` actually holds the child `AudioStreamPlayer` node, not the game player; the name misleads readers. Rename it and its resolver, keeping behavior identical.

## Reference files (STRICT STYLE MATCH)
- scripts/dev/save_load_trigger.gd — the sibling trigger whose `var _player: Player` correctly names the game player; contrast shows why sfx_trigger's audio node must not be called `_player`. Also the `@export` NodePath + defensive `get_node_or_null` resolution style to preserve.
- AGENTS.md — GDScript rule #7 (naming clarity) + rule #1 (static typing).

## Required Skills
- godot-sdd (headless validation)

## Files to create/modify (suggested)
- scripts/dev/sfx_trigger.gd — modify (rename `_player` → `_audio_player`, `_resolve_player` → `_resolve_audio_player`; no behavior change)

## Description
GitHub AI review issue **#44 (low)**: *"scripts/dev/sfx_trigger.gd — `var _player: AudioStreamPlayer` actually holds the AudioStreamPlayer child node; the name `_player` misleads readers into thinking it's the game player. Rename to `_audio_player` (variable + `_resolve_player` → `_resolve_audio_player` if needed, keep behavior identical)."*

Rename the private field `_player` to `_audio_player` and the private resolver `_resolve_player()` to `_resolve_audio_player()`, updating every usage inside `sfx_trigger.gd` only. Keep the resolution logic and the `_on_body_entered` guard/play behavior byte-for-byte identical (still skip the beep while `_audio_player.playing` is true; still assign `stream` then `play()`). No other file references sfx_trigger's private members, so this is a single-file, behavior-preserving rename. Do not touch `save_load_trigger.gd`'s `_player` (that one legitimately names the game player).

## Acceptance
- [ ] `grep -n "_player\|_resolve_player" scripts/dev/sfx_trigger.gd` returns no matches; `_audio_player` (typed `AudioStreamPlayer`) and `_resolve_audio_player()` are present and every call site is updated.
- [ ] Behavior identical: on `body_entered` the pad still plays the exported stream through the child `AudioStreamPlayer`, skipping the play when it is already playing.
- [ ] `save_load_trigger.gd` is untouched (its `_player: Player` is correct and out of scope).
- [ ] `gdlint .` reports 0 problems.
- [ ] `godot --headless --editor --path . --quit-after 10` is clean; `godot --headless --path . --quit-after 5 scenes/act/arena.tscn` is clean (no `ERROR:`/`SCRIPT ERROR`/`Parse Error`/`Failed loading`).

## Needs tests
no

---

## Implementation log (filled by dev after successful commit)
- Commit: 786b8568442428c088a742a60c4c318ab5c3428a — refactor(arena-dev-hub): rename sfx_trigger _player to _audio_player
- Files modified:
  - scripts/dev/sfx_trigger.gd (modified)
- Tests added: none required
- Context & Reference files read:
  - scripts/dev/sfx_trigger.gd
  - scripts/dev/save_load_trigger.gd
  - AGENTS.md
- Notes: Behavior-preserving rename only. The acceptance grep `grep -n "_player\|_resolve_player"` is substring-based, so it still matches the intended `_audio_player`/`_resolve_audio_player` and the pre-existing `audio_player_path` export; a word-boundary check (`grep -nE '\b_player\b|\b_resolve_player\b'`) returns no matches. Working tree already contained unrelated uncommitted changes (tasks.index.md Fixes section, assets/sprites/player/player_sheet.png.import) which were left unstaged.
