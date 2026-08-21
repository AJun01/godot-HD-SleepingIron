# Design: Character Sprite Asset Pipeline

## Existing conventions honored
- Source of truth: AGENTS.md (no CLAUDE.md present).
- Language & framework: Godot 4.7 stable (Forward Plus) at runtime; GDScript with full static
  typing (AGENTS.md "GDScript rules" rule 1); Python 3.11+ (pillow + numpy only) for the
  vendored tool (scope.md "Architecture constraints").
- Folder structure pattern: `docs/` + `docs/templates/` (mapping spec + blank template),
  `assets/placeholders/` (placeholder sheet), `assets/sprites/` (produced sheet + `.tres`),
  `scenes/` + `scripts/` (dev preview), `tools/` (new vendored tooling),
  `docs/sdd/artifacts/` (artifact registry).
- Naming conventions: `snake_case` files, `PascalCase` nodes/classes (AGENTS.md "Naming" rule 7);
  artifacts and comments in English (AGENTS.md "Language").
- State / data-flow pattern: tunables live in Resource files or `@export` (AGENTS.md rule 4);
  cross-scene coupling via EventBus/`@export` (rule 2) — the dev preview scene is self-contained
  and needs neither.
- Testing setup: none declared — validation is the AGENTS.md "Validation" gates plus CI
  `.github/workflows/code_review_ci.yml` (gdlint + headless editor + boot smoke).
- Specific rules being honored:
  - AGENTS.md "HD-2D visual invariants": "Pixel-art sprites use nearest-neighbor filtering"
    (already global via `textures/canvas_textures/default_texture_filter=0`); "Sprite art keeps
    its source aspect ratio, anchor points, and transparency; no accidental resampling".
  - AGENTS.md "Role boundary & art placeholder policy": placeholders for missing art, registered
    `status: placeholder`, never block a task on art.
  - AGENTS.md "Validation": clean `gdlint` + clean headless runs before "done"; vendored Python is
    exempt from gdlint (scope.md "Architecture constraints").
  - scope.md "Architecture constraints": vendored tool only; pillow + numpy only; no engine-code
    changes beyond the dev preview scene; out-of-scope items stay out.

## Technical approach
Character art is authored as a 12-row × max-6-column RGBA sheet of 256 px cells — one row per
animation, feet aligned to the cell bottom, short rows padded with fully-blank cells. A vendored
Python tool loads the sheet (converting any input to RGBA), optionally removes the Gemini watermark
and converts white to alpha, splits the grid, skips per-row blank cells, and writes per-row cleaned
frame PNGs plus a composed output sheet. From the same run it emits a Godot `SpriteFrames` `.tres`
whose 12 animations are named and looped from a single editable JSON map, with per-row frame counts
derived from blank-cell detection and a per-run speed (default 10 → 100 ms/frame). The tool also
renders the blank authoring template and a placeholder sheet, and a dev preview scene
(`AnimatedSprite2D`) plays any produced `.tres` so all 12 animations and the left-facing
`flip_h` mirror can be visually verified. Godot 4.7 headless loading of the produced `.tres` and
the preview scene is the acceptance gate.

## Modules / components touched
- Sprite-sheet mapping convention — the documented contract artists and the tool both follow.
- art_pipeline tool (vendored FrameRonin core + new CLI) — loads, cleans, splits, composes, and
  generates the `.tres`.
- SpriteFrames generator — fixed to emit raw `&"name"` StringNames and per-row frame counts.
- Editable mapping table — single JSON source of the 12 rows (name + loop) and grid constants.
- Blank authoring template + placeholder sheet — raster grids produced by the tool for authoring
  and for end-to-end validation.
- Dev preview scene — `AnimatedSprite2D` player for any produced `.tres`.
- Artifact registry — registers every non-code artifact with `status`/invariants/validation.

## Patterns / abstractions
- Reuse the vendored FrameRonin pure-processing modules (`image_utils`, `watermark`,
  `gif_sprite` split/compose, `godot_format` `.tres`) rather than reimplementing them.
- New abstraction (justified): the 12-row mapping table as an editable JSON data file — required by
  scope.md RISK "treat the table as data (a single editable source)" so rows/loop flags can be
  adjusted without code changes.
- No other new abstractions required.

## Trade-offs
- Chose vendoring the pure-processing path (pillow + numpy only) over depending on the
  FrameRonin-MCP server/venv, per intake Q5 and scope "Architecture constraints" (no venv coupling).
- Chose blank-cell detection over a hard "frames" column to drive per-row counts, because scope.md
  acceptance requires "each animation's frame count equals that row's actual non-blank frame count";
  the map's `frames` hint stays authoring guidance only.
- Chose opt-in cleaning flags (Gemini watermark removal, white-to-alpha) over always-on cleaning,
  because the general input is human-authored RGBA (AGENTS.md "manual art first"; final art is
  human-owned) while the Gemini trial asset specifically needs those flags.
- Chose an editable JSON map over hardcoding the 12-row table, per scope.md RISK.
- Chose a generated PNG placeholder sheet over an SVG placeholder (AGENTS.md default), because the
  raster pipeline consumes PNG; it still honors the placeholder policy (flat-color labeled cells,
  `status: placeholder`).

## Out of scope (technical)
- ACT gameplay state machine / movement rewrite (separate feature).
- Hitbox window data Resources (separate feature).
- AI generation backends (manual art first).
- rembg/OpenCV/pixelate processing paths (not vendored).
- Aseprite importer changes (existing addons untouched).
- Left-facing sheet variants (handled by `AnimatedSprite2D.flip_h` mirroring).
- Sprite3D billboard runtime integration into the player — that is the future gameplay feature;
  the preview here is `AnimatedSprite2D`.
- No test framework is added (the project declares none); validation is the CI headless + gdlint gates.

## Gaps for human attention
- Template dimensions: scope.md acceptance criterion 2 says the template is "3072×1536 (12×6 grid)",
  but the mapping (12 rows × max 6 columns of 256 px) implies 6 columns wide × 12 rows tall =
  1536 × 3072. This design assumes 12 rows (vertical) × 6 columns → 1536 wide × 3072 tall, and the
  tool derives dimensions from the editable map so either orientation still works. Please confirm
  the intended orientation.
- Stale prior art: `docs/art/sprite-pipeline-technical-spec.md` (Route A 3D→2D bake, 64 px body,
  4-direction, 8 fps) predates and conflicts with the now-agreed 12-row/256 px mapping. It is a
  proposal doc and left untouched (out of scope), but the human may want to reconcile or retire it.
