# Fix 005: CombatRange status label — move clear of pillar title and dummy bars

## Status

pending

## Context

A vision-model QA pass (round 2, after fix-004) confirmed the decisive text
cleanup worked: pillar titles are short, small, and unclipped, and the thickened
dummy health bars read clearly. One residual issue remains, and it is the only one:

- The **CombatRange `StatusLabel`** (driven by `scripts/dev/combat_range_zone.gd`)
  renders at **y = 2.2** in the zone center, exactly where the "Combat Range"
  pillar title (y = 2.4) and the dummy health bars (y = 2.7) are, so its
  notification text ("Attack the dummies (J). Step on the pad to reset." /
  "Dummies reset to full HP.") overlaps the title and the bars/player.

The notification must move away from the actors — higher, clear of the title and
the bars. This fix only relocates the CombatRange label and shortens its two
status strings; it changes no other zone and no runtime logic.

## Design decisions

### DD1 — Move the CombatRange `StatusLabel` to y = 3.6 (same x/z)

The relevant vertical extents, in world units (Label3D `fixed_size = true` with
`pixel_size = 0.005` makes one line `font_size × pixel_size = 16 × 0.005 = 0.08 u`
tall, per fix-004 DD2):

| element | y (root/center) | block height | occupied band |
|---------|-----------------|--------------|---------------|
| pillar title "Combat Range" (single line + trailing blank) | 2.4 | 0.16 u | 2.32 – 2.48 |
| dummy health bar (`target_dummy.tscn` `HealthBar`, 0.3 u thick) | 2.7 | 0.30 u | 2.55 – 2.85 |
| CombatRange `StatusLabel` (current) | 2.2 | multi-line hint (up to ~4 lines ≈ 0.32 u) | ~2.04 – 2.36 (overlaps title, crowds bars) |
| CombatRange `StatusLabel` (fixed) | **3.6** | ≤2 lines ≈ 0.16 u | 3.52 – 3.68 |

Placing the label at **y = 3.6**, with x and z unchanged (zone center, z = 0),
is 0.9 u above the health-bar center (2.7) and 1.2 u above the title center
(2.4). Even a two-line block centered at 3.6 occupies 3.52 – 3.68, so its bottom
edge stays **≈ 0.67 u above the bar top (2.85)** and **≈ 1.04 u above the title
top (2.48)** — deterministically clear of both, with no dependence on depth
separation or wrap estimates.

Keep every other `StatusLabel` property unchanged: `billboard = 1`,
`fixed_size = true`, `pixel_size = 0.005`, `font_size = 16`, `outline_size = 2`,
`width = 110`, `autowrap_mode = 2`, `horizontal_alignment = 1`,
`vertical_alignment = 1`.

### DD2 — Shorten the two status strings to ≤2 lines at width 110

The current strings are far too long for `width = 110` at `font_size = 16`
(roughly 13–14 characters per line), so they wrap into a tall multi-line block
that crowds the title and bars:

| const | current | length | new | length |
|-------|---------|--------|-----|--------|
| `HINT_TEXT` | `Attack the dummies (J). Step on the pad to reset.` | 52 | `Attack (J) · Pad resets` | 23 |
| `RESET_TEXT` | `Dummies reset to full HP.` | 25 | `Dummies reset!` | 14 |

Both new strings are ≤ ~23 characters, so at 16 px / width 110 they wrap to at
most two lines (the acceptance bound). The hint still conveys both actions
(attack with J, step on the pad to reset); the reset text keeps the reset
confirmation. The strings stay `const` declarations in
`scripts/dev/combat_range_zone.gd`; `_set_status()` and all logic are unchanged.

> If the middle dot (`·`, U+00B7) renders poorly in the default font, use the
> plain-ASCII fallback `Attack (J) | Pad resets` — same intent, same length band.

### DD3 — Leave the AnimationPreviewZone label and all other zones untouched

The `AnimationPreviewZone` `StatusLabel` stays at y = 2.2: it shows a single
short animation name (`idle` / `run` / `attack_1` / …), is not reported as
overlapping, and is out of scope. No other zone, pillar, dummy, or camera/light
property changes.

## Affected files

**Modified (by the implementing developer; this file only specifies them)**

- `scenes/act/arena.tscn` — `Zones/CombatRange/StatusLabel` transform
  `(0, 2.2, 0)` → `(0, 3.6, 0)`. x/z, billboard, fixed_size, pixel_size,
  font_size, outline_size, width, autowrap_mode, and both alignments are
  unchanged. The `AnimationPreviewZone` `StatusLabel` is untouched.
- `scripts/dev/combat_range_zone.gd` — `HINT_TEXT` and `RESET_TEXT` shortened
  per DD2. No logic change.

**Unchanged**

- `scripts/dev/animation_preview_zone.gd`, `scripts/dev/zone_pillar.gd`,
  `scenes/dev/zone_pillar.tscn`, `scenes/actors/target_dummy.tscn`,
  `scripts/world/target_dummy.gd`, all other zones, lighting, camera.

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

- [ ] `Zones/CombatRange/StatusLabel` transform y = 3.6; its ≤2-line block
      (≈ 0.16 u, band 3.52 – 3.68) is deterministically above the title
      (2.32 – 2.48) and the bars (2.55 – 2.85) — the offsets alone guarantee no
      overlap (DD1).
- [ ] `HINT_TEXT` ≤ ~23 chars and `RESET_TEXT` ≤ ~14 chars, so both wrap to at
      most two lines at `font_size = 16` / `width = 110` (DD2).
- [ ] `AnimationPreviewZone` `StatusLabel` stays at y = 2.2; no other zone,
      pillar, dummy, lighting, or camera property changes (DD3).
- [ ] No per-frame positioning/scaling logic introduced; all values are static
      `.tscn` / `const` properties.

### Visual

- [ ] A fresh screenshot pass confirms the CombatRange notification renders
      above the title and bars with no overlap. This is a later verification
      step, not part of this fix.

## Constraints (AGENTS.md)

- UI art stays separate from dynamic values (Label3D); only the label transform
  and two `const` strings change, no numbers baked into art.
- Deterministic, static values only — no runtime/per-frame font or position
  scaling.
- Do not touch lighting or camera (fix-004 out-of-scope QA finding #4 stays out
  of scope).

## Commit (implementation)

`fix(arena): 上移战斗区状态文本避开立柱标题与木桩血条并精简提示语`
