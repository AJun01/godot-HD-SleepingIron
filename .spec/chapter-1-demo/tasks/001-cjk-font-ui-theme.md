# 001 — CJK font + global UI theme

## Context files (read for understanding — do not modify)
- AGENTS.md — "Directory conventions" (`assets/fonts/`), "Validation" (headless gate), "Role boundary & art placeholder policy"
- scope.md — "Unverified assumptions (RISK)" (CJK coverage risk; OFL Noto Sans SC in `assets/fonts/`)
- docs/sdd/artifacts/game-skeleton.yml — artifact-registry format to imitate

## Reference files (STRICT STYLE MATCH)
- docs/sdd/artifacts/game-skeleton.yml — registry entry shape (`path`, `type`, `role`, `status`, `invariants`, `validation`)
- AGENTS.md — directory conventions + validation commands to honor

## Required Skills
- godot-sdd (font/theme import + headless validation; register non-code artifact)

## Files to create/modify (suggested)
- assets/fonts/noto_sans_sc.ttf — create (vendored OFL Noto Sans SC; normalize the upstream filename to this snake_case path)
- assets/fonts/OFL.txt — create (OFL license text bundled alongside the font)
- resources/theme.tres — create (Theme resource with `default_font` = the bundled font)
- project.godot — modify (`[gui] theme/custom` = `res://resources/theme.tres`)
- docs/sdd/artifacts/chapter-1-demo.yml — create (registry: font + theme entries, `status: placeholder`)

## Description
Bundle an OFL-licensed CJK font so Chinese dialogue and objective text render (no tofu glyphs).
Download/copy Noto Sans SC (OFL) into `assets/fonts/`, keep its OFL license text alongside, and
create a `Theme` resource whose `default_font` is that font. Wire the theme as the project-wide
default via `project.godot` (`gui/theme/custom`) so the dialogue bar, objective HUD, and any future
Chinese UI inherit CJK coverage from one place. Register the font and theme in the feature's
artifact registry with `status: placeholder`. Follow `design.md` for the global pattern; this is the
shared foundation that later dialogue/HUD tasks inherit — no .gd logic in this task.

## Acceptance
- [ ] `assets/fonts/noto_sans_sc.ttf` exists (OFL Noto Sans SC) and `assets/fonts/OFL.txt` ships the license (scope AC #5).
- [ ] `resources/theme.tres` sets `default_font` to the bundled font; `project.godot` sets `gui/theme/custom` to it (scope AC #5).
- [ ] `godot --headless --editor --path . --quit-after 10` is clean — font imports without error.
- [ ] `godot --headless --path . --quit-after 5 scenes/boot.tscn` is clean (no ERROR / SCRIPT ERROR / Parse Error / Failed loading).
- [ ] `gdlint .` reports 0 problems.
- [ ] Registry `docs/sdd/artifacts/chapter-1-demo.yml` lists the font + theme entries with `status: placeholder` (scope AC #15).

## Needs tests
no

---

## Implementation log (filled by dev after successful commit)
- Commit: e034ebae129346644feb2b7a0b9e9d9278ab947e — feat(chapter-1-demo): 内置 Noto Sans SC 中文字体并接入全局 UI 主题
- Files modified:
  - assets/fonts/noto_sans_sc.ttf (created)
  - assets/fonts/noto_sans_sc.ttf.import (created)
  - assets/fonts/OFL.txt (created)
  - resources/theme.tres (created)
  - project.godot (modified)
  - docs/sdd/artifacts/chapter-1-demo.yml (created)
- Tests added: none required
- Context & Reference files read:
  - AGENTS.md
  - scope.md
  - docs/sdd/artifacts/game-skeleton.yml
- Notes: Font sourced from google/fonts `ofl/notosanssc/NotoSansSC[wght].ttf` (genuine TrueType) rather than the noto-cjk OTF suggested in the task, so the `.ttf` extension matches the actual format (the OTF is CFF; renaming it to `.ttf` would mislabel it). `assets/fonts/noto_sans_sc.ttf.import` is the Godot-generated import sidecar, tracked per godot-sdd SKILL.md. The first headless editor run logged a transient "No loader found" for the font because the theme loads before the font's first import; the committed `.import` sidecar makes subsequent runs clean (verified clean on re-run).
