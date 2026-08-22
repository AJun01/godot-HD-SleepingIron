# Fix 003: Arena training-zone text legibility

## Status

pending

## Context

Playtest: the training arena's text is too big and overlapping ("满屏的字互相叠
在一起看不清楚"). Located in:

- `scenes/dev/zone_pillar.tscn` — the shared `ZonePillar` `Label3D`
  (`font_size=40`, `outline_size=8`, `pixel_size=0.005`) used by all six arena
  pillars.
- `scenes/act/arena.tscn` — the two `StatusLabel` nodes
  (AnimationPreviewZone and CombatRange, `font_size=48`, `outline_size=8`,
  `pixel_size=0.005`).
- `ZonePillar` composes `title` + `responsibility` + one line per `res://` path;
  the long path lines are the main overlap offender.

## Design decisions

1. **Font/outline sizes (uniform): `font_size = 22`, `outline_size = 3`,
   `pixel_size` unchanged (`0.005`).** Inside the suggested range; it yields a
   ~45–55% smaller on-screen text block (pillar height ≈ 22×0.005 = 0.11 units
   vs 40×0.005 = 0.20; status ≈ 0.11 vs 48×0.005 = 0.24) and a thinner outline
   so adjacent glyphs stop bleeding together.
2. **Drop the `paths` list from the 3D label.** Pillar text becomes `title` +
   `responsibility` only. Justification (learning-project pragmatism): the paths
   are the longest lines and the primary overlap cause; the file references
   already live in `docs/sdd/artifacts/combat-system.yml` and `design.md`, so the
   dev zone keeps only what a player needs ("what this zone does"), not the code
   map. `zone_pillar.gd` keeps its `paths` `@export` (no code change — an empty
   array is already handled), so paths can be re-enabled later without touching
   code.
3. **Deterministic, static values only.** No per-frame scaling logic; UI art and
   dynamic values stay separate (AGENTS.md HD-2D invariant).

## Affected files

**Modified**
- `scenes/dev/zone_pillar.tscn` — `Label3D`: `font_size` 40 → 22,
  `outline_size` 8 → 3 (covers all six pillars at once, shared scene).
- `scenes/act/arena.tscn` — the two `StatusLabel` nodes: `font_size` 48 → 22,
  `outline_size` 8 → 3; remove the `paths = PackedStringArray(...)` line from
  each of the six `ZonePillar` instances.

**Unchanged** (must stay legible)
- `scenes/actors/target_dummy.tscn` dummy `HealthBar` — two billboard mesh quads
  (no text), size/position untouched; it stays legible.
- `combat_range_zone.gd` / `animation_preview_zone.gd` — they only set status
  text strings; no font logic, so no code change.

## Implementation

1. `zone_pillar.tscn`: set `font_size = 22`, `outline_size = 3` on the
   `Label3D` (keep `pixel_size = 0.005`, `billboard = 1`, `fixed_size = true`,
   and both alignment values).
2. `arena.tscn`: set `font_size = 22`, `outline_size = 3` on both `StatusLabel`
   nodes (currently lines ~209-210 and ~271-272).
3. `arena.tscn`: delete the six `paths = PackedStringArray(...)` lines from the
   `ZonePillar` instances under MovementZone / AnimationPreviewZone /
   CombatRange / UiHudZone / SaveLoadZone / AudioZone. Leave `title` and
   `responsibility` as-is.

## Acceptance criteria

### Headless gates

- [ ] `gdlint .` reports **0 problems**.
- [ ] `godot --headless --editor --path . --quit-after 10` runs with **no**
      `ERROR:`, `SCRIPT ERROR`, `Parse Error`, `Failed loading`.
- [ ] `godot --headless --path . --quit-after 5 scenes/act/arena.tscn` runs
      clean (same grep criteria).
- [ ] `godot --headless --path . --quit-after 5 scenes/boot.tscn` runs clean
      (same grep criteria).

### Observable / deterministic

- [ ] All six pillars render as `title` + `responsibility` at `font_size=22` /
      `outline_size=3`, small and non-overlapping (deterministic size math:
      block height ≈ 0.11 world units vs the previous 0.20; ~45% smaller).
- [ ] Both status labels render at `font_size=22` / `outline_size=3`, small and
      non-overlapping (≈0.11 vs previous 0.24; ~54% smaller).
- [ ] The dummy `HealthBar` (mesh quads, no text) is untouched and stays legible;
      the smaller combat-range status text no longer crowds it.
- [ ] No per-frame scaling logic introduced; all values are static `.tscn`
      properties.
- [ ] Visual confirmation of actual on-screen non-overlap is a follow-up
      screenshot pass (out of scope for the headless gate).

## Constraints (AGENTS.md)

- UI art stays separate from dynamic values (Labels/ProgressBar) — only Label3D
  properties change; no numbers baked into art.
- Deterministic: no runtime/per-frame font scaling.

## Commit

`fix(arena): 缩小训练场立柱与状态标签字号，移除路径行避免文字重叠`

## Implementation log

<!-- Developer appends: what was done, gate results, any deviation. -->
