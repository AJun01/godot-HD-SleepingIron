# 006 — Chapter placeholders + dialogue content

## Context files (read for understanding — do not modify)
- docs/source/正文.md — lines 17–140 (canonical chapter-1 text; lines 26–32 mother, 48–65 Ina, 69–83 wine shop, 87–128 Uma/Defa + trio set-off)
- docs/sdd/artifacts/game-skeleton.yml — registry format
- assets/placeholders/placeholder_env_prop.svg — existing placeholder style (flat color + shape + text label)
- scripts/config/dialogue_data.gd — the `DialogueData` resource shape the `.tres` files must instantiate

## Reference files (STRICT STYLE MATCH)
- assets/placeholders/placeholder_player.svg / placeholder_env_prop.svg — flat-color + shape + text-label placeholder style
- docs/sdd/artifacts/game-skeleton.yml — artifact-registry entry shape + `status: placeholder`
- AGENTS.md — "Role boundary & art placeholder policy" (self-authored SVG placeholders, registered)

## Required Skills
- godot-sdd (non-code artifact registry + headless import validation)
- game-narrative-director (faithful, compressed dialogue extraction from the novel)

## Files to create/modify (suggested)
- assets/placeholders/placeholder_npc_mother.svg — create
- assets/placeholders/placeholder_npc_ina.svg — create
- assets/placeholders/placeholder_npc_wine_shop_owner.svg — create
- assets/placeholders/placeholder_npc_uma.svg — create
- assets/placeholders/placeholder_npc_defa.svg — create
- assets/placeholders/placeholder_prop_home.svg — create
- assets/placeholders/placeholder_prop_wine_shop.svg — create
- assets/placeholders/placeholder_prop_wine_cart.svg — create
- resources/dialogue/mother.tres — create (wake-up beat)
- resources/dialogue/ina.tres — create (blue-soda beat)
- resources/dialogue/wine_shop.tres — create (buy-wine beat)
- resources/dialogue/uma_defa.tres — create (giant-statue-glow trio beat)
- docs/sdd/artifacts/chapter-1-demo.yml — modify (add the 8 SVG + 4 dialogue `.tres` entries, `status: placeholder`)

## Description
Create the chapter's content assets. Author eight self-authored SVG placeholders — five NPCs (mother,
Ina, wine-shop owner, Uma, Defa) and three stage props (home, wine shop, wine cart) — each a flat
color + shape + text label naming the intended asset (never final art). Author four `DialogueData`
`.tres` files holding faithful, compressed Chinese lines drawn strictly from the cited 正文.md ranges:
mother = wake-up + "go buy wine" (lines 26–32); Ina = greeting + blue soda (lines 48–65); wine shop =
buy-wine + price/owing beat (lines 69–83); Uma/Defa = giant-statue-glow talk + "let's go see it"
(lines 87–128). Invent no lore; when the novel is silent, compress, never add. Register every new asset
in the artifact registry with `status: placeholder`. Follow `design.md`.

## Acceptance
- [ ] Five NPC + three prop SVG placeholders exist (flat color + shape + text label, transparent or opaque as appropriate) (scope AC #15).
- [ ] Four `DialogueData` `.tres` files load, each with ordered Chinese lines (scope AC #8).
- [ ] Dialogue lines are faithful, compressed excerpts of the cited 正文.md ranges with no invented lore (scope AC #9).
- [ ] `docs/sdd/artifacts/chapter-1-demo.yml` registers every new SVG + dialogue `.tres` with `status: placeholder` (scope AC #15).
- [ ] `godot --headless --editor --path . --quit-after 10` is clean (all SVGs import; all `.tres` load).
- [ ] `gdlint .` reports 0 problems.

## Needs tests
no

---

## Implementation log (filled by dev after successful commit)
- Commit: 1c4d218 — feat(chapter-1-demo): 新增 NPC/场景道具 SVG 占位图与对话数据资源
- Files modified:
  - assets/placeholders/placeholder_npc_mother.svg (created)
  - assets/placeholders/placeholder_npc_mother.svg.import (created)
  - assets/placeholders/placeholder_npc_ina.svg (created)
  - assets/placeholders/placeholder_npc_ina.svg.import (created)
  - assets/placeholders/placeholder_npc_wine_shop_owner.svg (created)
  - assets/placeholders/placeholder_npc_wine_shop_owner.svg.import (created)
  - assets/placeholders/placeholder_npc_uma.svg (created)
  - assets/placeholders/placeholder_npc_uma.svg.import (created)
  - assets/placeholders/placeholder_npc_defa.svg (created)
  - assets/placeholders/placeholder_npc_defa.svg.import (created)
  - assets/placeholders/placeholder_prop_home.svg (created)
  - assets/placeholders/placeholder_prop_home.svg.import (created)
  - assets/placeholders/placeholder_prop_wine_shop.svg (created)
  - assets/placeholders/placeholder_prop_wine_shop.svg.import (created)
  - assets/placeholders/placeholder_prop_wine_cart.svg (created)
  - assets/placeholders/placeholder_prop_wine_cart.svg.import (created)
  - resources/dialogue/mother.tres (created)
  - resources/dialogue/ina.tres (created)
  - resources/dialogue/wine_shop.tres (created)
  - resources/dialogue/uma_defa.tres (created)
  - docs/sdd/artifacts/chapter-1-demo.yml (modified)
- Tests added: none required
- Context & Reference files read:
  - docs/source/正文.md
  - docs/sdd/artifacts/game-skeleton.yml
  - assets/placeholders/placeholder_env_prop.svg
  - assets/placeholders/placeholder_player.svg
  - scripts/config/dialogue_data.gd
  - AGENTS.md
- Notes: >
  SVG labels use the same bitmap-rect text style as the existing placeholders (English labels;
  ThorVG does not rasterize <text>). Dialogue lines carry inline 角色： prefixes and leave the
  DialogueData `speaker` field empty because each beat is a multi-party exchange (single speaker
  field can't represent it); flag for human review per design.md "Gaps for human attention".
  The mother beat uses the novel's literal errand "拿点东西" (lines 26–32) rather than "买酒",
  which only appears in the wine-shop range (line 69); strictly faithful, no invented line. The
  8 `.svg.import` files were generated by the Godot headless editor import and are committed per
  the godot-sdd convention (`.import` files are tracked). Additional files read for understanding
  only (not modified): design.md, scope.md, scripts/autoload/dialogue_service.gd,
  scripts/world/interactable.gd, scripts/config/flow_stage.gd, scripts/config/flow_config.gd.
