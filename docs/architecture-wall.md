# Architecture Wall (arena-dev-hub)

A large central wall plane in the dev-hub arena (`scenes/act/arena.tscn`, node
`ArchitectureWall`) textured with the hand-maintained code-architecture diagram
at `assets/ui/architecture_diagram.svg`. The plane is 16×9 world units, stands
on the ground at the arena's back edge (`transform` origin `(0, 4.5, -7.5)`),
and uses an **unshaded** `StandardMaterial3D` (`shading_mode = 0`) so the
diagram stays at full brightness and remains legible under the arena's
DirectionalLight + environment. The wall casts no shadow (`cast_shadow = 0`) so
it never darkens the play area.

## Diagram content

**Nodes** — the autoloads/services and the scenes that make up the current
system:

| Node | Kind | Path |
|------|------|------|
| boot | scene | `scenes/boot.tscn` |
| GameFlow | autoload service | `scripts/autoload/game_flow.gd` |
| SceneRouter | autoload service | `scripts/autoload/scene_router.gd` |
| arena | scene | `scenes/act/arena.tscn` |
| player | scene | `scenes/actors/player.tscn` |
| EventBus | signal bus | `scripts/autoload/event_bus.gd` |
| DialogueService | autoload service | `scripts/autoload/dialogue_service.gd` |
| ObjectiveHud | autoload service | `scripts/autoload/objective_hud.gd` |
| SaveService | autoload service | `scripts/autoload/save_service.gd` |

**Edges** — the dependencies between them:

- `boot -> GameFlow` (`GameFlow.start_flow()`)
- `GameFlow -> SceneRouter` (`SceneRouter.transition_to()`)
- `SceneRouter -> arena` (`change_scene_to_file`)
- `arena -> player` (the arena instantiates the player)
- `GameFlow -> EventBus` (emits `stage_changed`, `game_state_changed`)
- `SceneRouter -> EventBus` (emits `transition_started`, `transition_finished`)
- `DialogueService -> EventBus` (listens to `transition_started`)
- `ObjectiveHud -> EventBus` (listens to `stage_changed`)
- `arena (zones) -> services` (UI/HUD zone drives DialogueService + ObjectiveHud;
  save/load zone drives SaveService)

## Why the SVG contains no `<text>` elements

Godot's SVG importer (ThorVG) does **not** rasterize SVG `<text>` elements, so a
plain hand-authored SVG of labels imports as empty boxes. To keep the diagram a
single, Godot-importable asset, every label is baked to glyph `<path>` outlines
by the generator below. The committed `assets/ui/architecture_diagram.svg` is
shapes-only and therefore imports as a normal `Texture2D`.

## Regeneration workflow (script)

The diagram's content lives in the `NODES`, `EDGES`, and `ARENA_*` tables at the
top of `tools/architecture_wall/generate_architecture_svg.py`. To update the
diagram after an architecture change:

1. Edit the `NODES` / `EDGES` / `ARENA_*` tables (and `TITLE` / `SUBTITLE` if
   needed) in `tools/architecture_wall/generate_architecture_svg.py`.
2. Install the dev-only dependency (only needed to regenerate, never at runtime):
   `python3 -m pip install fonttools`.
3. From the project root run:
   `python3 tools/architecture_wall/generate_architecture_svg.py`.
4. Let Godot reimport the changed SVG:
   `godot --headless --editor --path . --quit-after 10` (or open the editor).
5. Verify the scene still loads and the wall shows the updated diagram:
   `godot --headless --path . --quit-after 5 scenes/act/arena.tscn`.

## Manual instruction (no script)

The script is the only supported way to change labels — the SVG is glyph-path
data, not editable text, and hand-editing paths is error-prone. If `fonttools`
is unavailable, change the `NODES`/`EDGES` tables anyway and run the script on a
machine that has it; the regenerated SVG is committed, so other machines only
need the SVG, not `fonttools`.

## Invariants

- Keep the SVG canvas at 1920×1080 (16:9) to match the wall plane's 16×9 aspect,
  so the texture is never stretched.
- Add/remove nodes and edges here whenever an autoload, scene, or dependency
  changes — this diagram is a maintenance burden by design (see
  `design.md` "Gaps for human attention").
