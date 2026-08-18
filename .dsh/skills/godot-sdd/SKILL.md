---
name: godot-sdd
description: >
  Godot-specific SDD verification conventions. Invoke for Godot feature work to apply
  headless validation commands, register non-code artifacts (scenes, sprites, audio, UI),
  and enforce Godot acceptance criteria. Works alongside the sdd skill: sdd owns the
  lifecycle, godot-sdd owns the engine-level validation rules. Trigger when planning,
  changing, or reviewing a Godot feature, or when a task mentions project.godot, .tscn,
  .tres, .gdshader, or asset pipeline work.
---

# Godot SDD — Engine-Level Validation Rules

Use a spec → implement → verify cycle for every project change. This skill adds the
Godot-specific layer on top of the `sdd` skill's lifecycle: how to validate, what counts
as done, and how non-code assets are tracked.

## Mandatory flow for Godot changes

1. Inspect the repository and locate the scenes, scripts, and resources affected. Do not
   edit until integration points are identified.
2. The spec lives in `.spec/<feature-slug>/scope.md` (full SDD) or the mini-sdd plan.
   A change must state: goal and scope, affected files, invariants that must not change,
   observable acceptance criteria, risks and rollback plan.
3. Implement the minimal change that satisfies the spec. Never change physics layers,
   collisions, sprite proportions, anchor points, or scene compatibility unless the spec
   says so.
4. **Always validate headless from the project root:**
   ```bash
   godot --headless --editor --path . --quit-after 10
   godot --headless --path . --quit-after 5 scenes/<scene-under-test>.tscn
   ```
   Grep for `ERROR:`, `SCRIPT ERROR`, `Parse Error`, `Failed loading` — any match is FAIL.
5. Check the acceptance criteria and report what was verified, which files changed, and any
   limitations.

## Acceptance criteria (a change is done only when ALL hold)

- (a) The scene loads with no errors;
- (b) all scripts compile (headless editor run is clean);
- (c) every referenced resource exists;
- (d) the requested behavior is observable and checkable;
- (e) out-of-scope invariants are untouched.

If a visual reference, a design decision, or an external asset is missing, stop that part of
the implementation and ask the user for the concrete item instead of inventing it.

## Non-code artifact registry

For features that touch assets, register participating artifacts in
`docs/sdd/artifacts/<feature-slug>.yml`:

```yaml
feature: <slug>
artifacts:
  - path: scenes/actors/player.tscn
    type: scene
    role: player character
    invariants: ["collision layer 1", "node names used by @onready"]
    validation: godot --headless --path . --quit-after 5 scenes/actors/player.tscn
  - path: assets/sprites/juster_idle.png
    type: sprite
    role: protagonist idle frame
    invariants: ["source aspect ratio", "nearest-neighbor filtering"]
    validation: visual compare against docs/art/ references
```

Never close a feature with broken references, failed imports, orphan assets, or assets
without acceptance criteria.

## Project-specific rules (Sleeping Iron HD-2D)

- HD-2D layout: 2D sprites (billboarded) inside a lit 3D world. Preserve sprite pivot points,
  transparency, and scales; lighting changes belong to the 3D world scene, not the sprites.
- UI: keep art (SVG/PNG) separate from dynamic values (Labels/ProgressBar). Never bake numbers
  into art, never duplicate or misalign.
- Audio: prefer real external files compatible with Godot (ogg/wav); never synthesize tones
  when the user asked for real effects.
- Version control: `.godot/`, `.DS_Store`, exported builds and APKs are gitignored. `.import`
  files are tracked (consistent import settings).
