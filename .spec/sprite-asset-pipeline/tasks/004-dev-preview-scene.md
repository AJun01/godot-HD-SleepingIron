# 004 — Add the dev sprite-animation preview scene and artifact registry

## Context files (read for understanding — do not modify)
- `assets/sprites/placeholder_character/character_frames.tres` — the produced `.tres` the preview
  must play (its exact animation names).
- `project.godot` — available input actions (`move_left`/`move_right`, `advance`) if the preview
  script uses keys to cycle animations.
- `docs/sdd/artifacts/game-skeleton.yml` — the existing artifact-registry convention to imitate.

## Reference files (STRICT STYLE MATCH)
- `scripts/world/player.gd` — GDScript style: static typing, typed `@export`, docstrings
  (AGENTS.md rule 1/8).
- `scripts/ui/main_menu.gd` — scene-wiring style: typed `@onready`, `_ready` signal connection.
- `scenes/actors/player.tscn` — `.tscn` declaration structure (`ext_resource`/`sub_resource`/`node`
  blocks, format=3).

## Required Skills
- None (scope.md declares no Required Skills).

## Files to create/modify (suggested)
- `scenes/dev/sprite_anim_preview.tscn` — create | dev preview scene (Node2D + AnimatedSprite2D).
- `scripts/dev/sprite_anim_preview.gd` — create | typed script to cycle the 12 animations and toggle
  `flip_h`.
- `docs/sdd/artifacts/sprite-asset-pipeline.yml` — create | registry of every non-code artifact.

## Description
Add the dev preview scene and register the feature's artifacts. Reference `design.md` for the global
pattern. The preview uses the `AnimatedSprite2D` pattern that the now-removed
`scenes/trial_gemini_anim.tscn` established: a `Node2D` root with an `AnimatedSprite2D` child whose
`sprite_frames` is the produced `.tres` `ExtResource`, defaulting to `animation = &"idle"` and
`playing = true`.

The script enables visual verification of all 12 animations: cycle through them (e.g. `move_left`/
`move_right` or `advance`) and toggle `flip_h` to preview the left-facing mirror. Keep it static-typed
and self-contained (no EventBus needed for a dev-only scene).

Finally create `docs/sdd/artifacts/sprite-asset-pipeline.yml` (matching `game-skeleton.yml`) that
registers: the mapping doc, the blank template, the testdata fixtures, the placeholder sheet
(`status: placeholder`), the produced `.tres` + composed sheet, and this preview scene — each with
`type`, `role`, `invariants`, and its `validation` command. Validate headless from the project root
and grep for `ERROR:` / `SCRIPT ERROR` / `Parse Error` / `Failed loading` (any match = FAIL).

## Acceptance
- [ ] `scenes/dev/sprite_anim_preview.tscn` loads and plays the produced `.tres` (AnimatedSprite2D
  pattern), defaulting to `idle`.
- [ ] The preview script cycles through all 12 animations and toggles `flip_h` for left-facing
  mirroring; fully static-typed per AGENTS.md.
- [ ] `docs/sdd/artifacts/sprite-asset-pipeline.yml` registers every non-code artifact (placeholder
  sheet marked `status: placeholder`) with invariants and a validation command, matching
  `game-skeleton.yml` style.
- [ ] `gdlint .` is clean and the headless editor, boot scene, and this preview scene smoke runs are
  clean (no `ERROR:`/`SCRIPT ERROR`/`Parse Error`/`Failed loading`).

## Needs tests
no

---

## Implementation log (filled by dev after successful commit)
- Commit: 8ce3467055b5ca1122112aad8a1548ebef21bab0 — feat(sprite-asset-pipeline): 添加开发者精灵动画预览场景与产物注册表
- Files modified:
  - scenes/dev/sprite_anim_preview.tscn (created)
  - scripts/dev/sprite_anim_preview.gd (created)
  - scripts/dev/sprite_anim_preview.gd.uid (created)
  - docs/sdd/artifacts/sprite-asset-pipeline.yml (modified)
- Tests added: none required
- Context & Reference files read:
  - assets/sprites/placeholder_character/character_frames.tres
  - project.godot
  - docs/sdd/artifacts/game-skeleton.yml
  - scripts/world/player.gd
  - scripts/ui/main_menu.gd
  - scenes/actors/player.tscn
- Notes: sprite-asset-pipeline.yml already existed (committed by 003 with only 3 entries), so it was extended rather than created to register the mapping doc, blank template, testdata fixtures, and preview scene per acceptance. The preview script hardcodes the 12 animation names in map order because SpriteFrames.get_animation_names() returns hash order (observed: attack_1 first), not the documented row order. A Godot-generated .gd.uid file accompanies the new script (project convention: 26 existing .uid files are tracked).
