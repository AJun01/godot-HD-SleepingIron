# Character Sprite Pipeline — Technical Spec (Route A: 3D → 2D Bake)

- **Status:** proposal — pending human sign-off on the decision list below
- **Date:** 2026-02-21
- **Rationale:** see `docs/art/lpc-generator-evaluation.md` (LPC rejected). The
  chosen route renders rigged 3D models to orthographic frame sequences, which
  fits the HD-2D mecha setting: hard-surface designs, any direction count, any
  animation, cheap re-renders after animation changes.

This document is the **contract** both ends must satisfy:

1. **Blender side** (human authoring): what to render and how to name it.
2. **Godot side** (engine integration): how frames become `Sprite3D` animations
   in the existing world scenes.

Anything marked **[DECISION]** is pending the human (art direction is human-owned
per AGENTS.md). Everything else is a proposal to react to.

## 1. Canonical sprite contract

| property | proposal | notes |
|---|---|---|
| canvas height (body) | **64 px** [DECISION] | head-only overlays/portraits may use a separate scale |
| directions | 4 drawn (down/up/left/right) + right mirrored from left [DECISION] | scope requires 8-direction *movement*; drawing 4 halves the authoring cost (standard HD-2D practice) |
| animation set v1 | `idle` (4 frames), `walk` (6 frames) [DECISION] | `run`/`interact`/`emote` deferred; linear game, no combat yet |
| fps | 8 fps [DECISION] | 8 fps is readable at 64 px and keeps bake sizes small |
| pivot | ground-center of each frame | atlas cell width/2 horizontal, bottom edge vertical |
| atlas layout | grid: rows = animations, columns = directions, uniform cell size | metadata JSON (below) is authoritative |
| naming | `snake_case`: `<char>_<anim>_<dir>_<frame>.png` or one atlas + `<char>.json` | per AGENTS.md naming rule 7 |
| transparent background | required | never bake a backdrop color |

### Atlas metadata JSON (contract)

```json
{
  "version": 1,
  "character": "just",
  "cell": { "width": 64, "height": 64 },
  "directions": ["down", "left", "up", "right"],
  "mirror": { "right_from": "left" },
  "animations": {
    "idle": { "row": 0, "frames": 4, "fps": 8 },
    "walk": { "row": 1, "frames": 6, "fps": 8 }
  }
}
```

The engine integration reads this JSON; a validator script must reject sheets
that violate it (see SDD step below).

## 2. Blender export contract

- **Camera:** orthographic; pitch **[DECISION]** (HD-2D typically ~35°; test
  30°–45° against the world camera); yaw steps 0/90/180/270 for the 4 drawn
  directions.
- **Lighting:** neutral rig light (key + soft fill) so frames match the
  in-engine `DirectionalLight3D` + environment look; no colored gels.
- **Frame naming/export:** one render pass per (animation × direction);
  deterministic filenames; no post-processing that adds non-pixel-scale
  artifacts.
- **Resolution strategy [DECISION]:** bake at native pixel size (crisp but
  alias-prone), or bake at 2–4× and nearest-downsample in a scripted pass
  (recommended; keeps outlines stable across cameras).
- **Tools (reference):** [spriteinator](https://github.com/Duckonaut/spriteinator)
  (free Blender addon, batch sprite export), [Auto Spritesheet Pro](https://superhivemarket.com/products/auto-spritesheet-pro)
  (paid automation). Authoring otherwise: Blender + any rig.

## 3. Godot integration (verified against this repo, Godot 4.7.1)

Measured `Sprite3D` defaults on 2026-02-21 via headless probe — several defaults
are wrong for pixel art and **must be set explicitly**, they cannot be assumed:

| property | engine default (measured) | required for this pipeline |
|---|---|---|
| `texture_filter` | 3 = LINEAR_WITH_MIPMAPS | **0 = NEAREST** (pixel art) |
| `alpha_cut` | 0 = DISABLED | **1 = DISCARD** (kills halo fringing on billboards) |
| `billboard` | 0 = DISABLED | **1 = ENABLED** (already set in `scenes/actors/player.tscn`) |
| `shaded` | false | keep false (world light already carries HD-2D look) |
| `pixel_size` | 0.01 m/px | **`world_height_m / sprite_pixel_height`** |

- **`pixel_size` formula:** player capsule is 2.0 m tall
  (`scenes/actors/player.tscn`), so a 64-px body ⇒ `pixel_size = 2.0 / 64 = 0.03125`.
  This keeps sprites to real-world scale without per-scene fudging.
- **`project.godot` note:** `textures/canvas_textures/default_texture_filter=0`
  affects `CanvasItem` only; `Sprite3D` reads the per-sprite material filter,
  so the NEAREST setting above is not redundant.
- **Documentation drift (flagged for the human):** AGENTS.md says stretch mode
  `viewport`, but `project.godot` currently has `canvas_items` + `expand`
  (4K/Retina commit `41d3c49`). AGENTS.md is human-owned; please reconcile.
- **Runtime node:** replace `Sprite3D` with `AnimatedSprite3D` +
  `SpriteFrames` built from the atlas by an importer (SDD step), or keep
  `Sprite3D` + `AtlasTexture` with a small animation controller — importer
  design is part of the SDD scope, not this contract.
- Import references: [Aseprite Wizard](https://godotengine.org/asset-library/asset/713),
  [Importality](https://github.com/Joymagine/godot-4-importality) if hand-drawn
  work ever joins the pipeline; the Route A bake uses the JSON contract above.

## 4. Decision list for the human

1. Body canvas height: 64 px? (or 48 / 96)
2. 4 drawn directions + mirror, or true 8 directions?
3. v1 animation set: `idle` + `walk` only — acceptable for the linear demo?
4. 8 fps?
5. Bake resolution: native pixel vs 2–4× + nearest-downsample?
6. Ortho camera pitch (start ~35°)?
7. Character roster for production art (see the name-mapping note below).

**Name-mapping note (novel canon, `docs/source/正文.md`):** 阿特 = 贾斯特
(Just); 丁娜 = mother; 伊娜 = Ina; 乌玛 = Uma (big build); 德法 = Defa
(small build, round glasses). "Kaelen" and "Elara's Apprentice" do not appear
in the novel and must not become production characters without the human's
explicit approval (AGENTS.md: ask before inventing lore).

## 5. Next step (SDD)

Proposed feature slug `character-sprite-pipeline`, scope:

1. Atlas metadata validator script (enforces §1 contract) + sample atlas.
2. Godot importer/controller: `SpriteFrames` builder or `AtlasTexture` player,
   with NEAREST / alpha-cut / billboard defaults from §3.
3. Replace `placeholder_player.svg` usage with the animated player character;
   keep SVGs registered as placeholders until final art lands.
4. Docs + artifact registry entries per `godot-sdd` conventions.

Run through the SDD flow (`/sdd`) on human approval.
