# 004 — ACT arena scene + artifact registry + validation

## Context files (read for understanding — do not modify)
- design.md — arena composition + camera/player wiring + registry requirement
- scenes/world/chapter_home.tscn — ground/lighting/player-instance/camera-wiring pattern to mirror
- scenes/actors/player.tscn — the scene to instance (its nodes and @export wiring)
- scripts/world/side_view_camera.gd — the camera component's exports to wire (target_path, vertical_offset, z_distance)

## Reference files (STRICT STYLE MATCH)
- scenes/world/chapter_home.tscn — Gold Standard scene structure (WorldEnvironment + DirectionalLight3D + StaticBody3D ground with explicit layers)
- AGENTS.md — explicit collision layers/masks + "3D world carries lighting" invariant

## Required Skills
- godot-sdd (headless validation; non-code artifact registry)

## Files to create/modify (suggested)
- scenes/act/arena.tscn — create (Node3D: WorldEnvironment + DirectionalLight3D + ground strip + two steps + Player instance at Z=0 + SideViewCamera instance)
- docs/sdd/artifacts/act-player-foundation.yml — create (register player scene, arena scene, player animator, side-view camera, config resource)

## Description
Assemble the standalone ACT test arena under a new `scenes/act/` area: a lit 3D world (WorldEnvironment +
DirectionalLight3D, mirroring chapter scenes), a flat ground strip along X (top at Y = 0), two step boxes
(tops ≈ Y = 0.5 and ≈ Y = 1.0, within jump reach), the rewritten Player instanced at Z = 0, and the
SideViewCamera wired to the player (X-follow, Y = 1.2, Z = 10, perspective). Every physics body gets explicit
collision layers/masks (world = layer 1, player = layer 2); no defaults. Do not change GameFlow, SceneRouter,
DialogueService, EventBus, or any chapter `.tscn`. Register all participating artifacts in
`docs/sdd/artifacts/act-player-foundation.yml` (player scene, arena scene, player animator, side-view camera,
config resource) with role + invariants + validation. Final validation gates must be clean. Follow design.md.

## Acceptance
- [ ] `gdlint .` reports 0 problems.
- [ ] `godot --headless --editor --path . --quit-after 10` is clean.
- [ ] `godot --headless --path . --quit-after 5 scenes/act/arena.tscn` is clean.
- [ ] `godot --headless --path . --quit-after 5 scenes/world/chapter_home.tscn` is clean (chapter flow unaffected by the in-place player rewrite).
- [ ] Arena has flat ground + steps; the player spawns at Z = 0 and lands on the ground.
- [ ] Arena camera is a fixed side view: X-follow, Y ≈ 1.2 m fixed, Z fixed behind the play plane, perspective, horizontal forward.
- [ ] Every physics body has explicit collision layer/mask; no defaults.
- [ ] `docs/sdd/artifacts/act-player-foundation.yml` registers the participating artifacts.
- [ ] GameFlow / SceneRouter / DialogueService / EventBus and all chapter `.tscn` files are unchanged.

## Needs tests
no

---

## Implementation log (filled by dev after successful commit)
- Commit: 6fd2e02 — feat(act-player-foundation): ACT arena test scene + artifact registry
- Files modified:
  - scenes/act/arena.tscn (created)
  - docs/sdd/artifacts/act-player-foundation.yml (created)
- Tests added: none required
- Context & Reference files read:
  - design.md
  - scenes/world/chapter_home.tscn
  - scenes/actors/player.tscn
  - scripts/world/side_view_camera.gd
  - AGENTS.md
- Notes: gdlint not installed on PATH; ran `uvx --from gdtoolkit gdlint .` (0 problems). Arena ground/steps use flat StandardMaterial3D albedo colors (3D world geometry, not sprite art) so no placeholder art registration was required. Player instanced at Y=1 so its capsule feet rest on the ground top (Y=0), matching chapter_home.tscn.
