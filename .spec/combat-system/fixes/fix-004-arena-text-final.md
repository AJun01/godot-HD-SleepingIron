# Fix 004: Arena text — final minimal, non-overlapping pass

## Status

pending

## Context

A vision-model QA pass reviewed two real arena screenshots (player near the combat
range) after fix-003 (`font_size = 22` / `outline_size = 3`, `paths` dropped). The
zone text is still unacceptable:

1. **Pillar labels still read as one overlapping jumble.** Each pillar still renders
   `title` + `responsibility` in the same size, and several pillars are on screen at
   once, so their multi-line labels collide into an unreadable white mass in the
   center/upper third.
2. **Long titles clip at the screen edges** (e.g. "Animation Preview").
3. **The dummy health bar reads as a thin faint red sliver**, easy to miss.
4. *(Out of scope)* Overall darkness / camera framing — lighting and camera are
   **not** touched by this fix.

Fix-003 shrank the fonts but kept the two-line (`title` + `responsibility`)
composition and left the text width unbounded. The residual problems are (a) too much
text per pillar, (b) unbounded width, and (c) an under-thick health bar.

## Design decisions

### DD1 — Title-only pillars (drop `responsibility` from the rendered label)

Each pillar renders **only the short `title`**. The `responsibility` line is the
second line of the multi-line block and is the main remaining overlap contributor;
removing it leaves one short line per pillar.

- `scripts/dev/zone_pillar.gd` is **unchanged**: `responsibility` stays
  `@export var responsibility: String = ""`, and `_compose_text()` already skips empty
  strings (`if not responsibility.is_empty()`), so an empty value renders nothing and a
  future zone can opt back in by re-setting the export — no code change.
- The six arena instances clear their `responsibility` values by deleting the
  `responsibility = "…"` line (the script default `""` takes over), exactly the way
  fix-003 cleared the `paths` lines.

### DD2 — Concrete sizes: `font_size = 16`, `outline_size = 2`, `pixel_size = 0.005`

`Label3D.fixed_size = true` renders the text at a fixed on-screen resolution regardless
of distance: `font_size` is the on-screen glyph height in pixels and `pixel_size`
converts one pixel to world units (`0.005` units/px). So a line is `font_size` px on
screen and `font_size × pixel_size` world units tall in the scene.

| | on-screen line height | world line height | composed lines | block height |
|---|---|---|---|---|
| current (fix-003) pillar | 22 px | 22 × 0.005 = 0.110 u | title + blank + responsibility + blank = 4 | 0.44 u |
| fix-004 pillar (title only) | 16 px | 16 × 0.005 = 0.080 u | title + trailing blank = 2 | 0.16 u |
| fix-004 longest title, wrapped | 16 px | 0.080 u | 2 text + trailing blank = 3 | 0.24 u |

The title block drops from 0.44 to 0.16 world units (~64% smaller; about a third) for a
single-line title, and to 0.24 units (~45% smaller; about half) for the longest wrapped
title — "roughly half its current height" holds, and on screen the visible text shrinks
from ~44 px (2×22) to 16–32 px. Outline 3 → 2 px keeps a similar halo ratio
(2/16 ≈ 3/22 ≈ 13%) but with less total white mass, so adjacent glyphs stop bleeding
together.

### DD3 — Bounded width + word wrap (no more edge clipping)

Add `width = 110` and `autowrap_mode = 2` (`TextServer.AUTOWRAP_WORD`) to the pillar
`Label3D`. `width` (in pixels, used for autowrap/fill alignment) only wraps when
`autowrap_mode != AUTOWRAP_OFF`, so **both** properties are required. 110 px is wider
than the longest single word ("Animation" ≈ 85–90 px at `font_size = 16`) so word-wrap
breaks cleanly at spaces, but narrower than the full two-word titles ("Animation
Preview" ≈ 135 px, "Movement / Jump" ≈ 130 px), so those wrap to two short lines instead
of spanning the screen and clipping. Short titles ("Audio", "UI / HUD", "Save / Load",
"Combat Range") stay on one line. (Glyph widths are font-dependent; the exact wrap
points are confirmed in the screenshot pass.)

### DD4 — StatusLabels: same font treatment, keep y ≈ 2.2

Both arena `StatusLabel` nodes (AnimationPreviewZone, CombatRange) get the same
`font_size = 16`, `outline_size = 2`, `pixel_size = 0.005`, `width = 110`,
`autowrap_mode = 2`. Keep their position at **y = 2.2**: the pillar titles sit at
y = 2.4 and z = −7 (7 units behind the play plane) while the status labels sit at
y = 2.2 and z = 0, so the 0.2-unit vertical offset plus the 7-unit depth separation
keeps them from colliding with pillar titles; moving them down would instead risk
colliding with the dummy health bar at y = 2.7 in the combat range.

### DD5 — Thicken the dummy health bar

`scenes/actors/target_dummy.tscn` `QuadMesh_bar`: `size` `Vector2(2, 0.2)` →
`Vector2(2, 0.3)`. Keep `center_offset = Vector3(1, 0, 0)` (left-anchored), the y = 2.7
root position, and both billboard materials. The fill quad's `scale.x = hp / max_hp`
(X-only, `target_dummy.gd:_update_health_bar`) is unaffected because thickness is
geometry (Y), not scale. 0.2 → 0.3 world units makes the red fill a visible bar instead
of a sliver.

## Affected files

**Modified (by the implementing developer; this file only specifies them)**

- `scenes/dev/zone_pillar.tscn` — pillar `Label3D`: `font_size` 22 → 16,
  `outline_size` 3 → 2, add `width = 110` + `autowrap_mode = 2` (keep
  `pixel_size = 0.005`, `billboard = 1`, `fixed_size = true`, and both alignments).
  Covers all six pillars via the shared scene.
- `scenes/act/arena.tscn` — the two `StatusLabel` nodes: same font/width/autowrap
  treatment; delete the six `responsibility = "…"` lines from the `ZonePillar`
  instances (keep `title`).
- `scenes/actors/target_dummy.tscn` — `QuadMesh_bar.size` `Vector2(2, 0.2)` →
  `Vector2(2, 0.3)`.

**Unchanged**

- `scripts/dev/zone_pillar.gd` (DD1), `scripts/dev/combat_range_zone.gd`,
  `scripts/dev/animation_preview_zone.gd`, `scripts/world/target_dummy.gd` — no code
  change.

Cleared `responsibility` strings (recorded for reversibility; a future zone re-enables
by setting the `responsibility` export):

- Movement / Jump — "XZ movement, gravity, jump buffer and jump-cut feel"
- Animation Preview — "Play each of the 12 player animations and flip facing"
- Combat Range — "Hittable target dummies: combo damage, hit-flash, health bars, death + auto-reset"
- UI / HUD — "Show/hide the test health bar and dialogue box"
- Save / Load — "Save and restore player position and facing"
- Audio — "Playback smoke tests via SFX trigger points (placeholder beeps)"

## Implementation

1. `zone_pillar.tscn`: on the `Label3D`, set `font_size = 16`, `outline_size = 2`,
   `width = 110`, `autowrap_mode = 2`; keep `pixel_size = 0.005`, `billboard = 1`,
   `fixed_size = true`, `horizontal_alignment = 1`, `vertical_alignment = 1`.
2. `arena.tscn`: both `StatusLabel` nodes — set `font_size = 16`, `outline_size = 2`,
   `width = 110`, `autowrap_mode = 2`; keep the transform (y = 2.2), `pixel_size`,
   `billboard`, `fixed_size`, and both alignments.
3. `arena.tscn`: delete the six `responsibility = "…"` lines from the `ZonePillar`
   instances (keep `title`). No other instance changes.
4. `target_dummy.tscn`: `QuadMesh_bar` `size = Vector2(2, 0.3)` (was `Vector2(2, 0.2)`).
   Leave `center_offset`, the `HealthBar` transform, and both materials unchanged.

> The compose logic's trailing newline leaves a harmless empty second line when only
> `title` is set; that empty line is already counted in the 2-line block height above
> and needs no code change.

## Acceptance criteria

### Headless gates

- [ ] `gdlint .` reports **0 problems**.
- [ ] `godot --headless --editor --path . --quit-after 10` runs with **no** `ERROR:`,
      `SCRIPT ERROR`, `Parse Error`, `Failed loading`.
- [ ] `godot --headless --path . --quit-after 5 scenes/act/arena.tscn` runs clean
      (same grep criteria).
- [ ] `godot --headless --path . --quit-after 5 scenes/boot.tscn` runs clean (same grep
      criteria).

### Observable / deterministic

- [ ] All six pillars render title-only at `font_size = 16` / `outline_size = 2`;
      block height ≈ 0.16 u (title) or 0.24 u (wrapped title) vs 0.44 u before — roughly
      half or less (DD2 table).
- [ ] `width = 110` + `autowrap_mode = 2` present on every pillar/status label;
      "Animation Preview" and "Movement / Jump" wrap to two lines, no title exceeds
      110 px, so none clips at the screen edges.
- [ ] Both status labels render at `font_size = 16` / `outline_size = 2` at y = 2.2,
      non-colliding with pillar titles (depth separation + 0.2-unit offset, DD4).
- [ ] Dummy `QuadMesh_bar.size = Vector2(2, 0.3)`; fill still scales `scale.x` only;
      position and billboard unchanged.
- [ ] No per-frame scaling/positioning logic introduced; all values are static `.tscn`
      properties.
- [ ] Lighting and camera are untouched (out-of-scope QA finding #4).

### Visual

- [ ] A fresh screenshot pass confirms the text is minimal and non-overlapping and the
      health bar reads as a bar. This is a later verification step, not part of this
      fix.

## Constraints (AGENTS.md)

- UI art stays separate from dynamic values (Labels/ProgressBar); only `Label3D` /
  `QuadMesh` `.tscn` properties change, no numbers baked into art.
- Deterministic, static values only — no runtime/per-frame font scaling.
- Do not touch lighting or camera.

## Commit (implementation)

`fix(arena): 训练场立柱仅显示短标题并设置换行宽度，加粗木桩血条`

## Implementation log

- Applied the fix exactly as specified. `scenes/dev/zone_pillar.tscn` Label3D:
  `font_size` 22 → 16, `outline_size` 3 → 2, added `width = 110` and
  `autowrap_mode = 2` (`pixel_size = 0.005`, `billboard = 1`, `fixed_size = true`,
  and both alignments unchanged). Both arena `StatusLabel` nodes
  (AnimationPreviewZone, CombatRange) got the same font/width/autowrap treatment
  at y = 2.2. Deleted the six `responsibility = "…"` lines from the arena
  `ZonePillar` instances so each pillar renders title-only (script default `""`
  takes over; `zone_pillar.gd` untouched). `scenes/actors/target_dummy.tscn`
  `QuadMesh_bar.size` `Vector2(2, 0.2)` → `Vector2(2, 0.3)` (shared sub-resource,
  so Background and Fill both thicken; `center_offset` and materials unchanged).
  No lighting/camera/script changes.
- Gates: `gdlint .` 0 problems; headless editor plus `scenes/act/arena.tscn`,
  `scenes/actors/target_dummy.tscn`, and `scenes/boot.tscn` all clean (no
  `ERROR:` / `SCRIPT ERROR` / `Parse Error` / `Failed loading`). No `.import`
  noise was produced, so nothing needed reverting.
