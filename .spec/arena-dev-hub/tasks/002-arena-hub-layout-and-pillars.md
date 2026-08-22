# 002 — Rebuild arena as the six-zone facility + zone pillars

## Context files (read for understanding — do not modify)
- scenes/act/arena.tscn — the current arena being rebuilt into the six-zone facility
- scenes/actors/player.tscn — the player instance and its AnimatedSprite3D wiring to preserve
- scripts/world/side_view_camera.gd — the camera's @export values to keep wired
- project.godot — collision layer names (world=1, player=2, interaction=3)

## Reference files (STRICT STYLE MATCH)
- scenes/actors/player.tscn — explicit collision layer/mask (2/1) + billboarded AnimatedSprite3D pattern
- scripts/world/side_view_camera.gd — @export DI + NodePath defensive-resolution composable style
- AGENTS.md — HD-2D invariants (3D world carries lighting), placeholder policy, explicit collision layers/masks

## Required Skills
- godot-sdd (headless validation; non-code artifact registry)

## Files to create/modify (suggested)
- scenes/act/arena.tscn — modify (rebuild: six physically distinct zones, movement props, combat dummies, six pillars, wall anchor)
- scripts/dev/zone_pillar.gd — create (Label3D pillar: title + responsibility + file paths → text)
- scenes/dev/zone_pillar.tscn — create (reusable billboarded Label3D pillar scene)
- assets/placeholders/placeholder_target_dummy.svg — create (placeholder combat dummy)
- docs/sdd/artifacts/arena-dev-hub.yml — create (register the shell artifacts)

## Description
Rebuild the arena as a large flat walkable ground (StaticBody3D, explicit world layer 1 / mask 2) with six physically distinct zones laid out along X — movement/jump, animation preview, combat range, UI/HUD, save/load, audio — keeping the WorldEnvironment + DirectionalLight3D lighting, the Player instance, and the SideViewCamera. The movement/jump zone gets platforms/steps and a long runway (reuse the existing step boxes plus a longer ground runway); the combat range gets inert target dummies (billboarded placeholder SVG on StaticBody3D — no script, no combat logic). Build the reusable `zone_pillar.tscn` (Node3D + billboarded Label3D) driven by `zone_pillar.gd` with `@export` title/responsibility/paths composed into the label text, and instance one per zone with correct content. Every physics body/area uses explicit collision layers (world=1, player=2, interaction=3) — no defaults. Register the shell artifacts and the dummy placeholder (status: placeholder) in the artifact registry. Follow design.md.

## Acceptance
- [ ] The arena loads clean headless and contains six physically distinct zones, each with its own test props.
- [ ] The movement/jump zone has platforms/steps + a runway; the combat range has inert dummies with no script/logic.
- [ ] Each zone displays a ZonePillar Label3D stating the system name, a one-line responsibility, and the related file paths.
- [ ] Every physics body/area has an explicit collision layer/mask; no defaults.
- [ ] `gdlint .` reports 0 problems.
- [ ] `godot --headless --editor --path . --quit-after 10` is clean; `godot --headless --path . --quit-after 5 scenes/act/arena.tscn` is clean.
- [ ] `docs/sdd/artifacts/arena-dev-hub.yml` registers the shell artifacts + the dummy placeholder (status: placeholder).

## Needs tests
no

---

## Implementation log (filled by dev after successful commit)
- Commit: b64ae4fd847010afaf392117751816b84a34fe3c — feat(arena-dev-hub): 将竞技场重建为六区域测试设施并添加区域立柱
- Files modified:
  - scenes/act/arena.tscn (modified)
  - scenes/dev/zone_pillar.tscn (created)
  - scripts/dev/zone_pillar.gd (created)
  - scripts/dev/zone_pillar.gd.uid (created)
  - assets/placeholders/placeholder_target_dummy.svg (created)
  - assets/placeholders/placeholder_target_dummy.svg.import (created)
  - docs/sdd/artifacts/arena-dev-hub.yml (created)
- Tests added: none required
- Context & Reference files read:
  - scenes/act/arena.tscn
  - scenes/actors/player.tscn
  - scripts/world/side_view_camera.gd
  - project.godot
  - AGENTS.md
- Notes: >
  zone_pillar.gd.uid and placeholder_target_dummy.svg.import are Godot-generated
  companion files (tracked .uid/.import convention) and are committed alongside
  their sources. Save/Load and Audio pillar paths point at design.md-intended
  modules (scripts/autoload/save_service.gd, scripts/dev/save_load_trigger.gd,
  scripts/dev/sfx_trigger.gd, assets/placeholders/placeholder_beep.wav) that are
  created by tasks 004/007 and do not exist yet. Also read design.md, scope.md,
  scripts/world/player.gd, scripts/world/player_animator.gd,
  scripts/dev/sprite_anim_preview.gd, scripts/autoload/game_flow.gd,
  scripts/boot.gd, scenes/boot.tscn, docs/sdd/artifacts/act-player-foundation.yml,
  .gdlintrc, resources/player_config.tres for context/style. Reverted a spurious
  re-import change to assets/sprites/player/player_sheet.png.import produced by
  the headless editor import pass (out of scope; restored committed state).
