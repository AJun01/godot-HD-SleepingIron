# AGENTS.md — Sleeping Iron HD-2D

> **Single source of truth for every AI agent working in this repository.**
> The SDD pipeline (`sdd` skill) treats this file as law and fails fast if it is missing.
> Owned by the human developer. Agents never create or modify this file.

## Project identity

- **Sleeping Iron HD-2D** — an HD-2D (Octopath-style: 2D sprites in a lit 3D world) game
  adaptation of the original Chinese sci-fi/mecha novel *SLEEPING IRON* by A.J Liu.
- **Engine:** Godot 4.7 stable. Renderer: Forward Plus. Physics: Jolt Physics.
  Base resolution 1920×1080, `viewport` stretch mode.
- **Source material:** `docs/source/正文.md` — the canonical novel. All story content must stay
  faithful to it; when the novel is silent on a detail, ask the user before inventing lore.

## Directory conventions

```
scenes/           # .tscn files, grouped by area (world/, ui/, actors/, ...)
scripts/          # .gd files; autoloads live in scripts/autoload/
resources/        # .tres data files (configs, tunables, data-driven content)
assets/
  sprites/        # character/environment sprite sheets
  textures/       # 3D-world textures, normal maps
  audio/          # music + sfx
  fonts/          # font files
  shaders/        # .gdshader
  ui/             # UI art
  vfx/            # particles, flipbooks
addons/           # third-party plugins only
docs/             # GDD, templates, design references
.spec/            # SDD artifacts (created per feature by the pipeline, never by hand)
.dsh/skills/      # project skills (SDD pipeline + game-dev skills) — keep in version control
```

## GDScript rules (non-negotiable)

1. **Static typing everywhere.** Every variable, parameter, return type, and `@export` is
   annotated. No `var x = ...` without a type.
2. **Signals for decoupling.** Cross-scene communication goes through an autoload `EventBus`
   (typed signals) or dependency injection via `@export`. Never `get_node("../../...")`.
3. **Composition over inheritance.** Child scenes as components; deep class hierarchies are
   rejected in review.
4. **Tunables live in `Resource` files or `@export`** — never hardcoded gameplay values.
5. **`call_deferred`** for any scene-tree mutation issued from physics or signal callbacks.
6. **Explicit collision layers and masks** on every physics body/area. Defaults are never
   acceptable in production code.
7. **Naming:** files `snake_case.gd` / `snake_case.tscn`; node names and classes `PascalCase`;
   `class_name` only for globally registered classes.
8. **Comments explain "why", not "what".** Code comments in English.

## Validation (must pass before any feature is reported done)

From the project root:

```bash
godot --headless --editor --path . --quit-after 10
godot --headless --path . --quit-after 5 scenes/<main-scene>.tscn
```

Grep the output for `ERROR:`, `SCRIPT ERROR`, `Parse Error`, `Failed loading`. Any of these =
FAIL. Never report a change as complete without a clean headless run.

## SDD pipeline rules

- All feature work runs through the **SDD flow** (`sdd` skill): `.spec/<feature-slug>/` artifacts
  owned by the pipeline's subagents. Small fixes may use `mini-sdd` when the user approves it.
- **Never hand-edit** `scope.md`, `design.md`, task files, or `verify.md`; never delete a
  `.spec/<slug>/` folder mid-flight.
- One task = one commit, conventional-commit message (`feat:`, `fix:`, `refactor:`, `docs:`...).
- The Verifier opens the PR; a human merges. Nothing is auto-merged.
- Git and `gh` (authenticated) are prerequisites for the full flow; headless-only workflows
  degrade gracefully without them.

## Architecture law (user-mandated)

- **This is a linear game, not an open world.** Progression flows through discrete, ordered
  stages (scenes) driven by a central game-flow state machine. No free-roam world map, no
  non-linear exploration systems.
- **Every spec and design must be modular and extensible.** Systems are isolated behind
  small, single-responsibility autoload services or composable components; no monolithic
  scenes, no god-scripts. Future features (combat, inventory, saves, dialogue) must be
  addable without rewriting existing systems. Prefer composition, dependency injection via
  `@export`, `Resource` files for data, and EventBus signals at coupling boundaries.

## HD-2D visual invariants

- Sprite art keeps its source aspect ratio, anchor points, and transparency; no accidental
  resampling. Pixel-art sprites use nearest-neighbor filtering.
- The 3D world scene carries the lighting (DirectionalLight + environment); sprites face the
  camera billboard-style unless the design says otherwise.
- UI art (SVG/PNG) stays separate from dynamic values (Labels/ProgressBar) — never bake numbers
  into art.

## Role boundary & art placeholder policy

- **The AI agent writes code and solves engineering problems only.** Final art, audio, and
  visual design direction belong to the human developer. The agent may write art specs,
  style references, and asset lists, but never produces final production art.
- **Never block a task on missing art.** When a task needs a visual asset that does not
  exist yet, proceed immediately with a simple self-authored **SVG placeholder** (flat
  color + shape + text label describing the intended asset).
- Placeholders live in `assets/placeholders/`, named after their target asset
  (e.g. `placeholder_player_idle.svg`), and are registered in the feature's artifact
  registry with `status: placeholder` so the human can find and swap them for final art.
- A task is NOT considered blocked while a placeholder is in place; swapping a placeholder
  for final art is its own later task, never a reason to stall.

## Language

- **Artifacts** (`.spec/`, docs templates, GDD, code comments): English.
- **User-facing chat and commits**: match the user's language (currently Chinese).
