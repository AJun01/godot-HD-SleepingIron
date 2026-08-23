# Fix 006: Combat-range status text — depth-align to the pillar plane and center the dummy health bar

## Status

pending

## Context

A vision-model QA pass after fix-005 identified two residual issues, both
visual-only (no runtime logic is wrong):

1. **The CombatRange `StatusLabel` still overlaps the "Combat Range" pillar
   title.** fix-005 moved the label to `(0, 3.6, 0)` on the assumption that a
   higher world `y` is enough to separate it from the title at world
   `(0, 2.4, -7)`. That assumption is wrong under the side-view camera
   (`scripts/world/side_view_camera.gd`): the camera sits elevated and pitched
   down, so a point's **screen** vertical position is governed by the projection
   ratio `(cam_y − world_y) / (cam_z − world_z)`, not by world `y` alone. At
   `(0, 3.6, 0)` the label ratio is `(6.7 − 3.6) / (14 − 0) ≈ 0.221`, almost
   identical to the title's `(6.7 − 2.4) / (14 + 7) ≈ 0.205`. The depth
   difference (z = 0 vs z = −7) cancels the y offset, so the two texts land at
   nearly the same screen height.

2. **The dummy health bar hangs to the right of the dummy instead of centered.**
   In `scenes/actors/target_dummy.tscn`, `QuadMesh_bar` has
   `center_offset = Vector3(1, 0, 0)`. With `size = Vector2(2, 0.3)` this shifts
   the quad's vertices to span **x ∈ [0, 2]** relative to the dummy center (the
   `HealthBar`/`Fill` node origins sit at the dummy's x = 0). The shared
   2×0.3 quad — and therefore the X-scaled fill — grows rightward from the dummy
   center, leaving the bar off-center.

This fix makes two static value edits: put the label on the **same depth plane
as the pillar** (`z = -7`) and higher (`y = 4.2`), and re-center the shared bar
quad by zeroing its `center_offset`. No runtime logic changes.

## Design decisions

### DD1 — Move the CombatRange `StatusLabel` to `(0, 4.2, -7)` (pillar depth plane)

Within `Zones/CombatRange`, the `ZonePillar` is at local `(0, 0, -7)` and its
title `Label3D` (inside `scenes/dev/zone_pillar.tscn`) is at local `(0, 2.4, 0)`,
so the title sits at world `(0, 2.4, -7)`. The `StatusLabel` is currently at
local `(0, 3.6, 0)`. Move it to local `(0, 4.2, -7)`.

Reference camera (elevated + pitched-down side view, see DD1 note): `cam_y =
6.7`, `cam_z = 14`. Projection ratio `(cam_y − world_y) / (cam_z − world_z)`:

| element | world (x, y, z) | ratio | screen height |
|---------|-----------------|-------|---------------|
| `StatusLabel` (fixed) | (0, 4.2, −7) | (6.7 − 4.2) / (14 + 7) = 2.5 / 21 ≈ **0.119** | highest |
| pillar title "Combat Range" | (0, 2.4, −7) | (6.7 − 2.4) / (14 + 7) = 4.3 / 21 ≈ **0.205** | middle |
| dummy health bars (z = −2) | (0, 2.7, −2) | (6.7 − 2.7) / (14 + 2) = 4.0 / 16 = **0.250** | lowest |
| `StatusLabel` (pre-fix, y 3.6 / z 0) | (0, 3.6, 0) | (6.7 − 3.6) / (14 − 0) = 3.1 / 14 ≈ 0.221 | ~title |

Lower ratio = higher on screen. `0.119 < 0.205 < 0.250`, so the notification
renders **clearly above the title, which is above the dummy bars** — the exact
inverse of the pre-fix ordering where the label (≈0.221) and title (≈0.205) were
near-identical.

> **DD1 note — why this is deterministic, not just numeric.** Because the label
> now shares the title's depth plane (`z = −7`), both use the *same* denominator
> `(cam_z + 7)`, so label-vs-title ordering reduces to `y` alone: `4.2 > 2.4`
> guarantees the label is above the title for **any** camera above the play
> plane and in front of the pillar. The separation no longer depends on the
> camera's exact elevation/depth (the strict ordering also holds under the
> scene's serialized `vertical_offset = 5.5` / `z_distance = 12.0`), which is
> what the previous y-only move failed to deliver.

**Frustum check.** The camera has a −25° pitch and Godot's default 75° vertical
FOV (half-angle 37.5°). The title (ratio 0.205) is already read on-screen by the
vision model, so any point closer to screen center is also in frame. The label
(ratio 0.119) is `atan(2.5/21) ≈ 6.8°` below horizontal → ≈18.2° above the
camera's forward axis, comfortably inside the ±37.5° half-FOV and *closer to
center* than the title's ≈13.4°. The label is billboarded, so there is no
orientation clipping.

Keep every other `StatusLabel` property unchanged: `billboard = 1`,
`fixed_size = true`, `pixel_size = 0.005`, `font_size = 16`, `outline_size = 2`,
`width = 110`, `autowrap_mode = 2`, `horizontal_alignment = 1`,
`vertical_alignment = 1`. The two status strings
(`HINT_TEXT` = `"Attack (J) · Pad resets"`, `RESET_TEXT` = `"Dummies reset!"`)
from fix-005 are untouched.

### DD2 — Center the dummy health bar: `QuadMesh_bar.center_offset` → `(0, 0, 0)`

`Background` and `Fill` (both children of `HealthBar`, both at local x = 0)
share the single `QuadMesh_bar` sub-resource. One edit to
`center_offset = Vector3(1, 0, 0)` → `Vector3(0, 0, 0)` re-centers both quads:
vertices now span **x ∈ [−1, 1]** around the dummy center instead of [0, 2].

`scripts/world/target_dummy.gd` `_update_health_bar()` is **untouched**: it
still sets `health_bar_fill.scale.x = hp / max_hp`. Scaling about the now-centered
origin makes the fill shrink **symmetrically** around the dummy center — full HP
spans [−1, 1], half HP spans [−0.5, 0.5], empty collapses to a point at the
center. The bar stays centered at every HP value.

> **DD2 note — stale wording, no code change.** The comment in
> `target_dummy.gd` `_update_health_bar()` ("left-anchored … drains right-to-left
> toward the fixed left edge") and the "left-anchored" wording in `design.md` §8
> now describe the *old* anchoring. Both are out of scope for this fix (the
> `.gd` is intentionally untouched; `design.md` is a pipeline artifact that must
> not be hand-edited). The wording can be corrected in a trivial follow-up if
> desired.

## Affected files

**Modified (by the implementing developer; this file only specifies them)**

- `scenes/act/arena.tscn` — `Zones/CombatRange/StatusLabel` transform
  `(0, 3.6, 0)` → `(0, 4.2, -7)`. x/z now `(0, -7)` puts it on the pillar's
  depth plane. `billboard`, `fixed_size`, `pixel_size`, `font_size`,
  `outline_size`, `width`, `autowrap_mode`, and both alignments are unchanged.
  No other zone/label/pillar/dummy transform changes.
- `scenes/actors/target_dummy.tscn` — `QuadMesh_bar` sub-resource
  `center_offset = Vector3(1, 0, 0)` → `Vector3(0, 0, 0)`. `size` stays
  `Vector2(2, 0.3)`; both `Background` and `Fill` keep sharing the mesh; `Fill`'s
  local transform (z = 0.01) is unchanged.

**Unchanged**

- `scripts/world/target_dummy.gd` (fill `scale.x` logic untouched),
  `scripts/dev/combat_range_zone.gd`, `scripts/world/side_view_camera.gd`,
  `scenes/dev/zone_pillar.tscn`, all other zones, dummies, lighting, and camera.

## Acceptance criteria

### Headless gates

- [ ] `gdlint .` reports **0 problems**.
- [ ] `godot --headless --editor --path . --quit-after 10` runs with **no**
      `ERROR:`, `SCRIPT ERROR`, `Parse Error`, `Failed loading`.
- [ ] `godot --headless --path . --quit-after 5 scenes/act/arena.tscn` runs clean
      (same grep criteria).
- [ ] `godot --headless --path . --quit-after 5 scenes/boot.tscn` runs clean (same
      grep criteria).

### Observable / deterministic

- [ ] `Zones/CombatRange/StatusLabel` transform = `(0, 4.2, -7)`; its z matches
      the `ZonePillar` z (`-7`), so label-vs-title ordering depends on `y` alone
      (4.2 > 2.4) and cannot regress to overlap (DD1).
- [ ] Projection ratios are strictly ordered **status 0.119 < title 0.205 <
      dummy bars 0.250**, i.e. the notification is above everything else in the
      zone (DD1).
- [ ] `QuadMesh_bar.center_offset = Vector3(0, 0, 0)`; `Background` and `Fill`
      both render centered on the dummy (vertices x ∈ [−1, 1]), and `Fill`
      `scale.x` now shrinks symmetrically about the dummy center (DD2).
- [ ] No runtime/per-frame positioning or scaling logic introduced; both edits
      are static `.tscn` values; `target_dummy.gd` fill logic is byte-for-byte
      unchanged (DD2).

### Visual

- [ ] A fresh screenshot pass confirms: the CombatRange notification renders
      above the title and the dummy bars with a clear margin, and each dummy
      health bar is centered on its dummy. This is a later verification step,
      not part of this fix.

## Constraints (AGENTS.md)

- UI art stays separate from dynamic values (Label3D / MeshInstance3D quads);
  only two static transforms/mesh values change, no numbers baked into art.
- Deterministic, static values only — no runtime font/position/scaling changes.
- Do not touch lighting or camera; do not hand-edit `design.md`/`scope.md`/
  `verify.md` (pipeline-owned artifacts).

## Commit (implementation)

`fix(arena): 战斗区状态文本对齐立柱深度平面并居中木桩血条`

## Implementation log

- Applied the fix exactly as specified. `scenes/act/arena.tscn` CombatRange
  `StatusLabel` transform `(0, 3.6, 0)` → `(0, 4.2, -7)` (now on the pillar depth
  plane, z = -7; billboard, fixed_size, pixel_size 0.005, font_size 16,
  outline_size 2, width 110, autowrap_mode 2, and both alignments unchanged).
  `scenes/actors/target_dummy.tscn` shared `QuadMesh_bar` sub-resource
  `center_offset = Vector3(1, 0, 0)` → `Vector3(0, 0, 0)` (single sub-resource
  edit re-centers both Background and Fill). No scripts, other nodes, lighting,
  or camera touched.
- Gates: `gdlint .` → 0 problems; headless editor run clean; `scenes/act/arena.tscn`,
  `scenes/actors/target_dummy.tscn`, and `scenes/boot.tscn` runs all clean (no
  `ERROR:` / `SCRIPT ERROR` / `Parse Error` / `Failed loading`). No `.import`
  noise was produced (the three flagged `.import` files stayed unmodified), so
  nothing needed reverting.
