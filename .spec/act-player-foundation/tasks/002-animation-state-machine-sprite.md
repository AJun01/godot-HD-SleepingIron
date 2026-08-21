# 002 — Animation state machine + AnimatedSprite3D

## Context files (read for understanding — do not modify)
- assets/sprites/player/player_frames.tres — animation names + loop flags (idle/run/fall loop; jump/land one-shot)
- docs/character-sprite-mapping.md — "feet aligned to the cell bottom" invariant (drives the feet-bottom anchor)
- scripts/world/player.gd — public contract the animator reads (`facing`, `landed` signal, `is_on_floor()`, `velocity`)
- design.md — five-state machine semantics (idle/run/jump/fall/land; land one-shot → idle)

## Reference files (STRICT STYLE MATCH)
- scenes/dev/sprite_anim_preview.tscn — Gold Standard SpriteFrames + AnimatedSprite wiring (adapted to AnimatedSprite3D)
- scripts/world/camera_follow.gd — `@export` Node + NodePath defensive-resolution pattern to mirror for the animator's references
- AGENTS.md — HD-2D billboard invariant + composition-over-inheritance

## Required Skills
- godot-sdd (headless validation; sprite invariants, billboard, nearest-neighbor)

## Files to create/modify (suggested)
- scripts/world/player_animator.gd — create (five-state SM component: reads player state, drives AnimatedSprite3D animation + flip_h, land one-shot → idle)
- scenes/actors/player.tscn — modify (replace Sprite3D with AnimatedSprite3D: player_frames.tres, animation "idle", billboard=1, centered, feet-bottom offset; add Animator child wired via @export)

## Description
Add the composable animation state machine as a child Node3D in the player scene. It holds typed references
to the player and the AnimatedSprite3D via `@export` (with NodePath fallback resolution, mirroring the
camera-follow pattern), connects to the player's `landed` signal, and each render frame maps player state to
an animation: grounded + no X velocity → idle, grounded + moving → run, airborne ascending → jump, airborne
descending → fall, freshly landed → land (one-shot, then back to idle via `animation_finished`). It sets
flip_h from `player.facing` (right sheet mirrored; left sheet unused) and only restarts playback on state
change so one-shots are not retriggered every frame. Replace the placeholder Sprite3D with a billboarded
AnimatedSprite3D defaulting to "idle", anchored feet-to-bottom: `centered = true`, `pixel_size = 0.01`
(256 px → 2.56 m), node offset `(0, 0.28, 0)` so feet sit at the capsule bottom (Y = −1.0). Keep explicit
collision layers/masks on the body untouched. Follow design.md for the global pattern.

## Acceptance
- [ ] `gdlint .` reports 0 problems.
- [ ] `godot --headless --editor --path . --quit-after 10` is clean.
- [ ] `godot --headless --path . --quit-after 5 scenes/actors/player.tscn` is clean.
- [ ] Player renders via an AnimatedSprite3D (billboard) defaulting to "idle"; the placeholder Sprite3D is gone.
- [ ] idle plays grounded with no input; run plays grounded while moving; jump plays ascending; fall plays descending.
- [ ] land plays once on landing and returns to idle.
- [ ] Facing is a flip_h mirror of the right-facing sheet driven by the input X sign; the left sheet is not used.
- [ ] Sprite feet align with the capsule bottom (no sinking into the floor).

## Needs tests
no

---

## Implementation log (filled by dev after successful commit)
- Commit: 8e6f906 — feat(act-player-foundation): animation state machine + AnimatedSprite3D
- Files modified:
  - scripts/world/player_animator.gd (created)
  - scripts/world/player_animator.gd.uid (created)
  - scenes/actors/player.tscn (modified)
- Tests added: none required
- Context & Reference files read:
  - assets/sprites/player/player_frames.tres
  - docs/character-sprite-mapping.md
  - scripts/world/player.gd
  - design.md
  - scenes/dev/sprite_anim_preview.tscn
  - scripts/world/camera_follow.gd
  - AGENTS.md
- Notes: `scripts/world/player_animator.gd.uid` is the Godot-generated UID file for the new script (tracked in-repo, consistent with existing `*.gd.uid` files). gdlint was not installed; ran `gdlint .` via a temporary gdtoolkit 4.5.0 venv (0 problems).
