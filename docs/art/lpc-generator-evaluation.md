# LPC Character Generator — Evaluation & Rejection

- **Status:** rejected (reference only, never production art)
- **Date:** 2026-02-21
- **Scope:** evaluation of the [Universal LPC Spritesheet Character Generator](https://liberatedpixelcup.github.io/Universal-LPC-Spritesheet-Character-Generator/) as a character-art source for Sleeping Iron HD-2D.

## Decision

Use the generator **only for quick style exploration**. It is not a production art
source for this project, for three structural reasons:

1. **Animation coverage is fragmentary.** The library was assembled piecemeal by
   dozens of authors over 10+ years. Newer animation slots (`idle`, `run`,
   `jump`, `climb`, `combat`) were retro-fitted by only a few authors, so most
   clothing categories are silently missing them. The concrete failure observed:
   two characters render **naked on run frames** because their torso items have
   no `run` frames while `legs`/`shoes` do.
2. **Style mismatch.** Fantasy tunics/aprons vs. the sci-fi/mecha setting of
   SLEEPING IRON.
3. **License risk.** CC-BY-SA 3.0 / GPL 3.0 share-alike spreads to derivative
   art and requires shipping `CREDITS.csv` with the game (see the upstream
   [README](https://raw.githubusercontent.com/LiberatedPixelCup/Universal-LPC-Spritesheet-Character-Generator/master/README.md)).

## Why the four candidate URLs failed

Two independent defects, verified by replicating the deployed app's resolution
logic (`sources/state/hash.ts` + `sources/state/resolve-hash-param.ts`):

1. **State lives in the URL hash, not the query string.** The deployed bundle
   only reads `window.location.search` for `?debug=`. `?body=...` is ignored.
2. **Wrong keys and value format.** Correct format:

   ```
   #?sex=<bodytype>&<type_name>=<Item_Name>_<variant|recolor>
   ```

   - Body type key is `sex` (legacy-compatible; `bodyType` also accepted),
     lowercase: `male|female|teen|child|muscular|pregnant`.
   - Keys are item `type_name`s (104 total). There is no `body_type`, `torso`,
     `feet`, `headwear`, or any `*_color` key.
   - Color is a suffix of the value, not a parameter:
     `legs=Pants_brown`, `hair=Plain_dark_brown`.
   - Names are display names with spaces replaced by `_`; matching is
     case-insensitive; recolor-only items use `Name_recolor` and
     variant+recolor items use `Name_variant|recolor`.
   - `sex` must precede item params in practical use, because items are
     gated by body type (a mismatched param resolves but never renders).

Example mapping of the failed keys:

| wrong | correct |
|---|---|
| `?body_type=Male` | `#?sex=male` |
| `body=light` | `body=Body_color_light` |
| `torso=tunic` | `clothes=Tunic_tan` (female-only item) |
| `feet=boots` | `shoes=Basic_Boots_brown` |
| `headwear=glasses` | `facial_eyes=Glasses` |
| `hair_color=brown` | part of `hair=..._dark_brown` |
| `belt=pouch` | no "pouch" exists; closest is `belt=Leather_Belt_brown` |

## Verified coverage data

Snapshot taken from the production bundles on 2026-02-21:

- 104 `type_name`s, 657 items; **489 (74%) include `run`**.
- `clothes` (torso): only 22/35 have `run`; **0 items at all for `muscular`**.
- Categories with **zero `run` coverage**: `apron` (0/4), `jacket` (0/6),
  `vest` (0/4), `belt` (0/8), `backpack` (0/4), `cape` (0/2), `dress` (0/4),
  `weapon` (0/40), plus `arms` (0/1) and `shield` (2/9).
- Full-coverage categories: `head` (45/45), `hat` (50/50),
  `facial_eyes` (14/14), `hair` (89/91), `shoes` (11/12).

### `run` coverage and body-type availability by type_name (curated)

Columns: `male | female | teen | child | muscular | pregnant` = number of items
available to that body type; `run` = how many of the category's items include
run frames.

| type_name | items | run | male | female | teen | child | muscular | pregnant |
|---|---|---|---|---|---|---|---|---|
| `apron` | 4 | 0 | 1 | 4 | 2 | 0 | 0 | 1 |
| `armour` | 3 | 3 | 3 | 3 | 3 | 0 | 0 | 0 |
| `arms` | 1 | 0 | 1 | 1 | 1 | 0 | 1 | 1 |
| `backpack` | 4 | 0 | 4 | 4 | 0 | 0 | 4 | 4 |
| `belt` | 8 | 0 | 7 | 7 | 7 | 0 | 0 | 0 |
| `body` | 3 | 1 | 3 | 3 | 3 | 1 | 1 | 1 |
| `bracers` | 1 | 1 | 1 | 1 | 1 | 0 | 1 | 1 |
| `cape` | 2 | 0 | 2 | 2 | 2 | 0 | 2 | 2 |
| `clothes` | 35 | 22 | 28 | 29 | 22 | 1 | **0** | 4 |
| `dress` | 4 | 0 | 0 | 4 | 2 | 0 | 0 | 0 |
| `facial_eyes` | 14 | 14 | 14 | 14 | 14 | 14 | 14 | 14 |
| `gloves` | 1 | 1 | 1 | 1 | 1 | 0 | 1 | 1 |
| `hair` | 91 | 89 | 89 | 89 | 89 | 12 | 89 | 89 |
| `hat` | 50 | 50 | 50 | 50 | 50 | 0 | 50 | 50 |
| `head` | 45 | 45 | 32 | 32 | 32 | 13 | 32 | 32 |
| `jacket` | 6 | 0 | 6 | 1 | 1 | 0 | 0 | 0 |
| `legs` | 21 | 13 | 15 | 17 | 17 | 2 | 6 | 13 |
| `overalls` | 2 | 2 | 2 | 2 | 2 | 0 | 1 | 1 |
| `shield` | 9 | 2 | 9 | 9 | 3 | 0 | 9 | 9 |
| `shoes` | 12 | 11 | 12 | 12 | 12 | 0 | 12 | 12 |
| `shoulders` | 4 | 3 | 4 | 4 | 4 | 0 | 4 | 4 |
| `sleeves` | 5 | 5 | 5 | 5 | 5 | 0 | 0 | 0 |
| `vest` | 4 | 0 | 2 | 2 | 0 | 0 | 0 | 0 |
| `weapon` | 40 | 0 | 40 | 40 | 21 | 0 | 40 | 40 |

Key traps confirmed by this data:

- **`muscular` has zero `clothes` items** — the body type can only be
  bare-chested or wear `overalls`/`shoulders`/`cape`/`bauldron`.
- `vest` is `male`-only; `tunic`/`apron full`/`dress` are `female`-only;
  most jackets are `male`-only (only `tabard` accepts teen).
- Hair palette has no plain `brown` — use `light_brown`/`dark_brown`/`chestnut`.

### Reproduction

The numbers above were produced by downloading the deployed bundles
(`index.html` + `assets/{main,item-metadata,index-metadata}-*.js`), evaluating
`item-metadata`/`index-metadata`, and re-implementing
`resolveHashParamFromHashMatch` from
[`sources/state/resolve-hash-param.ts`](https://github.com/LiberatedPixelCup/Universal-LPC-Spritesheet-Character-Generator/blob/master/sources/state/resolve-hash-param.ts)
(plus body-type gating from `item.required`). Any future re-check can follow the
same recipe: the app ships its own parser, so its source of truth is the
bundles, not documentation.

## Practical use that remains valid

- The generator's animation filter (left column) hides items without the
  selected animation slot — useful if anyone re-uses LPC as a temporary base.
- LPC is fine as a **style/color reference** only. Production art follows
  `docs/art/sprite-pipeline-technical-spec.md` (Route A: 3D→2D bake).
