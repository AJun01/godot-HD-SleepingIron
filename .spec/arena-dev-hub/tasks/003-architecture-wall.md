# 003 — Central architecture wall (SVG + regeneration doc)

## Context files (read for understanding — do not modify)
- project.godot — the autoload list (nodes of the diagram) + scene/layer inventory
- scripts/autoload/event_bus.gd — the coupling backbone (edges)
- scripts/autoload/game_flow.gd — the stage machine (boot→arena edge)
- scripts/autoload/scene_router.gd — scene routing (edge)
- scenes/act/arena.tscn — the scene node the wall lives in

## Reference files (STRICT STYLE MATCH)
- docs/sdd/artifacts/act-player-foundation.yml — artifact registry YAML structure to imitate
- AGENTS.md — HD-2D invariants (texture legibility) + "UI art separate from dynamic values"

## Required Skills
- godot-sdd (non-code artifact registry)

## Files to create/modify (suggested)
- assets/ui/architecture_diagram.svg — create (maintained diagram: nodes = autoloads/services/scenes, edges = dependencies)
- scenes/act/arena.tscn — modify (central wall plane textured with the imported SVG)
- docs/architecture-wall.md — create (diagram content + regeneration workflow)
- docs/sdd/artifacts/arena-dev-hub.yml — modify (register the SVG + wall)

## Description
Author a hand-maintained SVG diagram of the code architecture — nodes are the autoloads/services (EventBus, SceneRouter, GameFlow, DialogueService, ObjectiveHud, SaveService) and the scenes (boot, arena, player), edges are their dependencies (boot → GameFlow → SceneRouter → arena; arena → player; zones → services). Store it in `assets/ui/architecture_diagram.svg` so Godot imports it as a Texture2D. Add a large plane in the arena textured with that import (unshaded/emissive material so the text stays legible under arena lighting) as the central architecture wall. Document the diagram's content and the manual regeneration workflow in `docs/architecture-wall.md` (edit the SVG → Godot reimports → verify the wall). Register the SVG and wall in the artifact registry. Follow design.md.

## Acceptance
- [ ] `assets/ui/architecture_diagram.svg` exists, is maintained in-repo, with nodes = autoloads/services/scenes and edges = dependencies.
- [ ] The arena has a central wall plane whose albedo texture is the imported architecture SVG.
- [ ] `docs/architecture-wall.md` documents the regeneration step (script or manual instruction).
- [ ] `gdlint .` reports 0 problems.
- [ ] `godot --headless --editor --path . --quit-after 10` is clean (SVG imports cleanly); `godot --headless --path . --quit-after 5 scenes/act/arena.tscn` is clean.
- [ ] `docs/sdd/artifacts/arena-dev-hub.yml` registers the SVG + wall.

## Needs tests
no

---

## Implementation log (filled by dev after successful commit)
- Commit: 99d7c889c33e8b9f0f808b21cbafdd815011c102 — feat(arena-dev-hub): 添加中央架构墙（架构图 SVG + 再生成文档）
- Files modified:
  - assets/ui/architecture_diagram.svg (created)
  - assets/ui/architecture_diagram.svg.import (created)
  - docs/architecture-wall.md (created)
  - docs/sdd/artifacts/arena-dev-hub.yml (modified)
  - scenes/act/arena.tscn (modified)
  - tools/architecture_wall/generate_architecture_svg.py (created)
- Tests added: none required
- Context & Reference files read:
  - project.godot
  - scripts/autoload/event_bus.gd
  - scripts/autoload/game_flow.gd
  - scripts/autoload/scene_router.gd
  - scenes/act/arena.tscn
  - docs/sdd/artifacts/act-player-foundation.yml
  - AGENTS.md
- Notes: Godot's SVG importer (ThorVG) does not rasterize <text> elements (verified empirically + Godot issue #77893), so a plain hand-authored SVG imports blank. The diagram's labels are therefore baked to glyph <path> outlines by a small generator (tools/architecture_wall/generate_architecture_svg.py, fonttools dev-only dep) — a necessary deviation from design.md's "hand-maintained SVG over code-gen script" note, which assumed SVG text renders. assets/ui/architecture_diagram.svg.import is Godot-generated import metadata tracked per godot-sdd convention. Also read (not in task lists): scripts/boot.gd, scenes/boot.tscn, scenes/actors/player.tscn, scripts/autoload/dialogue_service.gd, scripts/autoload/objective_hud.gd, scenes/dev/zone_pillar.tscn, scripts/dev/zone_pillar.gd, scripts/world/side_view_camera.gd, .gitignore.
