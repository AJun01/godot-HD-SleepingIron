# fix-003 — Add jump/fall hysteresis to stop apex flapping

## Context files (read for understanding — do not modify)
- scripts/world/player_animator.gd — offending commit `8e6f906`; `_desired_state()` airborne mapping (`velocity.y > 0 → jump else fall`) that flaps near the apex
- scripts/world/player.gd — physics contract the animator reads (`velocity.y` sign, `is_on_floor()`, jump_velocity from PlayerConfig)
- scripts/config/player_config.gd — `@export` tunable + docstring style the new threshold imitates (AGENTS.md rule #4)
- scenes/actors/player.tscn — the Animator wiring (`@export player`/`sprite` NodePaths) so the dev sees where the export lives
- AGENTS.md — GDScript rules #1 (static typing everywhere) and #4 (tunables in Resources/@export)

## Reference files (STRICT STYLE MATCH)
- scripts/config/player_config.gd — Gold Standard typed `@export` tunable with a "why" docstring
- scripts/world/camera_follow.gd — Gold Standard `@export` + defensive NodePath resolution (already mirrored by the animator)
- AGENTS.md — GDScript law + tunables rule as the Gold Standard

## Required Skills
- godot-sdd (headless validation; typed GDScript conventions)

## Files to create/modify (suggested)
- scripts/world/player_animator.gd — modify (add `@export jump_fall_threshold` + hysteresis in the airborne branch of `_desired_state()`)

## Description
**Failing criterion (verbatim, GitHub issue #34):** in `scripts/world/player_animator.gd` `_desired_state()`, airborne state maps JUMP when `velocity.y > 0` else FALL, causing jump/fall flapping near the apex where `velocity.y` oscillates around zero. Required fix: hysteresis — once JUMP, only switch to FALL when `velocity.y < -0.5` (threshold as an exported tunable, default -0.5).

The flapping comes from the instantaneous `velocity.y > 0.0` switch: at the jump apex `velocity.y` crosses zero every few frames, so `jump` and `fall` alternate. Fix by latching the JUMP→FALL edge.

Concrete decisions (do not deviate):

1. **Add an exported tunable** to `player_animator.gd`, typed per AGENTS.md rule #1, placed after the existing `@export var sprite_path` block. Exact text (tabs, `##` docstring matching the existing style):
   ```
   ## Downward velocity (m/s) below which the animator switches from jump to fall
   ## while airborne. Hysteresis threshold: near the jump apex velocity.y
   ## oscillates around zero, so switching at exactly 0.0 flaps jump<->fall every
   ## frame; this negative threshold keeps "jump" until the body is truly
   ## descending.
   @export var jump_fall_threshold: float = -0.5
   ```
2. **Rewrite ONLY the airborne branch** of `_desired_state()` — the two lines after the `if player.is_on_floor(): …` block. The grounded block (land/idle/run) is unchanged. Exact replacement:
   ```
   	# Hysteresis on the jump->fall edge: once JUMP, hold JUMP until velocity.y
   	# drops below jump_fall_threshold, so apex oscillation around zero does not
   	# flap between jump and fall every frame.
   	if _current_state == STATE_JUMP:
   		if player.velocity.y < jump_fall_threshold:
   			return STATE_FALL
   		return STATE_JUMP
   	if player.velocity.y > 0.0:
   		return STATE_JUMP
   	return STATE_FALL
   ```
   The result: on the first airborne frame (state still idle/run) `velocity.y > 0` still enters JUMP; while in JUMP the state stays JUMP until `velocity.y < -0.5`, so the apex no longer flaps; FALL remains sticky until landing.
3. **No PlayerConfig change.** The threshold is animation-state logic, not player physics, and the report asks for an "exported tunable", which `@export` satisfies under AGENTS.md rule #4. Do not add it to `resources/player_config.tres` / `scripts/config/player_config.gd`.

**Working-tree hygiene.** The tree currently carries a stray `assets/sprites/player/player_sheet.png.import` modification (s3tc/vram/mipmap flags + `compress/mode=2` + `mipmaps/generate=true` + `detect_3d/compress_to=0`). Revert it before committing — `git checkout -- assets/sprites/player/player_sheet.png.import` — so no lossy VRAM/mipmap change to the pixel-art sheet is committed (AGENTS.md "no resampling, nearest-neighbor" invariant). Commit only `scripts/world/player_animator.gd`.

## Acceptance
- [ ] REGRESSION (apex flap): `_desired_state()` latches the airborne state — once `_current_state == STATE_JUMP`, it returns JUMP until `player.velocity.y < jump_fall_threshold`, and only then FALL. No `velocity.y > 0.0`-only switch remains that could flap jump↔fall at the apex.
- [ ] `jump_fall_threshold` is a statically-typed `@export var` on `player_animator.gd` with default `-0.5` and a "why" docstring (AGENTS.md rules #1 + #4).
- [ ] Normal transitions are unchanged: grounded + no input → idle; grounded + moving → run; landing → land one-shot → idle; the grounded block is untouched.
- [ ] `gdlint .` reports 0 problems.
- [ ] `godot --headless --editor --path . --quit-after 10` is clean (no ERROR / SCRIPT ERROR / Parse Error / Failed loading).
- [ ] `godot --headless --path . --quit-after 5 scenes/boot.tscn`, `scenes/act/arena.tscn`, `scenes/actors/player.tscn` all smoke clean.
- [ ] Only `scripts/world/player_animator.gd` is committed; the stray `assets/sprites/player/player_sheet.png.import` change is reverted and not part of the commit.

## Needs tests
no

---

## Implementation log (filled by dev after successful commit)
- Commit: 7f1ac58 — fix(act-player-foundation): 加入跳跃/下落迟滞以消除顶点抖动
- Files modified:
  - scripts/world/player_animator.gd (modified)
- Tests added: none required
- Context & Reference files read:
  - scripts/world/player_animator.gd
  - scripts/world/player.gd
  - scripts/config/player_config.gd
  - scenes/actors/player.tscn
  - AGENTS.md
  - scripts/world/camera_follow.gd
- Notes: The task's "exact replacement" airborne branch put 7 return statements in `_desired_state()`, exceeding `.gdlintrc` `max-returns: 6` (gdlint flagged line 94). Preserved identical behavior but merged the two JUMP-latch branches into boolean `and`/`or` conditions so the airborne branch has 3 returns (6 total); the grounded block is untouched and gdlint is clean. Reverted the stray `assets/sprites/player/player_sheet.png.import` modification per the task's working-tree hygiene note before committing.
