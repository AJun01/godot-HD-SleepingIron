# 002 — Placeholder assets + registry

## Context files (read for understanding — do not modify)
- AGENTS.md — "Role boundary & art placeholder policy" (SVG placeholder rules + registry)
- .dsh/skills/godot-sdd/SKILL.md — "Non-code artifact registry" format + project-specific placeholder rules
- design.md — the planned scenes/components these assets serve

## Reference files (STRICT STYLE MATCH)
- AGENTS.md — placeholder naming (`placeholder_*.svg`) and `assets/placeholders/` location
- .dsh/skills/godot-sdd/SKILL.md — artifact registry YAML schema (feature/artifacts/path/type/role/invariants/validation)

## Required Skills
- godot-sdd (artifact registry + import validation)

## Files to create/modify (suggested)
- assets/placeholders/placeholder_player.svg — create (flat color + shape + "PLAYER" label)
- assets/placeholders/placeholder_ground.svg — create (checkered ground albedo; visual motion reference)
- assets/placeholders/placeholder_env_prop.svg — create (billboarded prop, e.g. "PROP" label)
- assets/placeholders/placeholder_menu_bg.svg — create (flat dark menu background + "MENU BG" label)
- docs/sdd/artifacts/game-skeleton.yml — create (register SVGs with status: placeholder, and the 5 planned scenes)

## Description
Author the self-authored SVG placeholders this feature needs and register them in the feature
artifact registry so the human can find and swap them later. Each SVG is a flat color + simple
shape + a text label describing the intended asset — no final art. The registry lists every
placeholder with `status: placeholder` plus the scenes (boot, main menu, chapter) that will use
them, each with role, invariants, and its headless validation command. Follow design.md and the
godot-sdd registry schema; do not block on real art.

## Acceptance
- [ ] Four valid SVGs exist under assets/placeholders/ (flat color + shape + text label each).
- [ ] `godot --headless --editor --path . --quit-after 10` is clean and every SVG imports (no `Failed loading`, no failed-import errors).
- [ ] docs/sdd/artifacts/game-skeleton.yml exists and lists each placeholder with `status: placeholder`, a `role`, and at least one `invariant`.
- [ ] The registry also declares the boot, main-menu, and chapter scenes with type `scene`, role, invariants, and a `godot --headless --path . --quit-after 5 <scene>` validation line.

## Needs tests
no

---

## Implementation log (filled by dev after successful commit)
- Commit: caca192 — feat(game-skeleton): 添加 SVG 占位符资源与产物注册表
- Files modified:
  - assets/placeholders/placeholder_player.svg (created)
  - assets/placeholders/placeholder_player.svg.import (created)
  - assets/placeholders/placeholder_ground.svg (created)
  - assets/placeholders/placeholder_ground.svg.import (created)
  - assets/placeholders/placeholder_env_prop.svg (created)
  - assets/placeholders/placeholder_env_prop.svg.import (created)
  - assets/placeholders/placeholder_menu_bg.svg (created)
  - assets/placeholders/placeholder_menu_bg.svg.import (created)
  - docs/sdd/artifacts/game-skeleton.yml (created)
- Tests added: none required
- Context & Reference files read:
  - AGENTS.md
  - .dsh/skills/godot-sdd/SKILL.md
  - design.md
- Notes:
  - SVG text labels are drawn as bitmap-rect glyphs instead of `<text>` because Godot's
    ThorVG importer does not rasterize `<text>` elements (Godot docs "Importing SVG images
    with text"); this keeps labels visible after import.
  - The chapter scene path in the registry (`scenes/world/chapter_01.tscn`) follows the
    committed `resources/flow_config.tres` stage path; it may differ from task 004's
    suggested `scenes/world/chapter.tscn` — flagged for orchestrator/verifier reconciliation.
  - The task's suggested-files line says "the 5 planned scenes", but the Description and
    Acceptance name only three (boot, main menu, chapter); the registry declares those three.
  - Additional files read (outside the task's Context/Reference lists) to resolve scene paths
    and import conventions: scope.md, intake.md, resources/flow_config.tres, project.godot,
    icon.svg, icon.svg.import, .gitignore.
