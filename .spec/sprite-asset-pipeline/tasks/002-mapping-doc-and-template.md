# 002 — Write the sprite-sheet mapping doc and blank template

## Context files (read for understanding — do not modify)
- `tools/art_pipeline/character_sheet_map.json` — the authoritative 12-row table this doc must
  mirror; it is the single editable source of truth.
- `docs/templates/character-sheet.md` — existing `docs/templates/` document style to match.
- `tools/art_pipeline/README.md` — the CLI usage for the `--make-template` mode.

## Reference files (STRICT STYLE MATCH)
- `docs/art/sprite-pipeline-technical-spec.md` — technical-spec markdown style (table-driven
  contract + invariant/decision notes); the new doc supersedes its mapping assumptions.

## Required Skills
- None (scope.md declares no Required Skills).

## Files to create/modify (suggested)
- `docs/character-sprite-mapping.md` — create | the mapping contract (12-row × max-6-col, names,
  loop flags, 256 px cells, feet-to-bottom, blank padding, 100 ms default, Aseprite tags).
- `docs/templates/character-sheet-template.png` — create | blank 12×6 grid rendered by the tool.

## Description
Write the human-facing mapping spec and produce the blank authoring template. Reference `design.md`
for the global pattern. The doc documents the exact convention from intake Q6 and scope.md, and
points at the JSON map as the single editable source (reproducing its table for readers) so rows can
be adjusted without code or doc drift. It must also document the Aseprite-side workflow (one tag per
row, tag name = animation name) as guidance only — not automated in this feature.

Render the template with the tool built in Task 001:
`python tools/art_pipeline/process_character_sheet.py --make-template --output docs/templates/character-sheet-template.png`.
The template is a 12-row × 6-column grid of 256 px cells (6 columns wide × 12 rows tall =
1536 × 3072) with faint grid lines and row labels per the map. Note: scope.md criterion 2 writes
"3072×1536"; this design assumes 12 rows tall (see `design.md` "Gaps for human attention") — produce
1536 × 3072 and record the discrepancy in the commit notes if it persists.

## Acceptance
- [ ] `docs/character-sprite-mapping.md` documents the 12-row × max-6-column mapping, the exact 12
  animation names, per-row loop flags, 256×256 cell size, feet-aligned-to-cell-bottom, blank-cell
  padding, and 100 ms default frame duration (speed 10).
- [ ] The doc names the JSON map as the single editable source and reproduces its table for humans.
- [ ] The doc includes the Aseprite tag-per-row workflow note (documented, not automated).
- [ ] `docs/templates/character-sheet-template.png` exists at 1536×3072 with faint grid lines and
  row labels, and is regenerable via the tool (not hand-drawn).

## Needs tests
no

---

## Implementation log (filled by dev after successful commit)
- Commit: 817b4c6 — docs(sprite-asset-pipeline): 编写精灵表映射文档与空白创作模板
- Files modified:
  - docs/character-sprite-mapping.md (created)
  - docs/templates/character-sheet-template.png (created)
- Tests added: none required
- Context & Reference files read:
  - tools/art_pipeline/character_sheet_map.json
  - docs/templates/character-sheet.md
  - tools/art_pipeline/README.md
  - docs/art/sprite-pipeline-technical-spec.md
- Notes: Rendered the template with `--output-dir docs/templates` (the tool's actual CLI flag)
  instead of the task's literal `--output docs/templates/character-sheet-template.png`, which does not
  exist; it produces the exact required file. Discrepancy persisted and is recorded: scope.md
  criterion 2 writes 3072×1536, but the produced template is 1536×3072 (12 rows vertical × 6 columns)
  per design.md "Gaps for human attention"; the doc's §2 "Orientation note" flags this for the human.
  (Also read design.md, scope.md, and process_character_sheet.py for implementation context.)
