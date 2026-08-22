# 007 — Audio zone (placeholder SFX triggers)

## Context files (read for understanding — do not modify)
- scenes/act/arena.tscn — where the audio zone trigger pads are placed
- project.godot — collision layer names (interaction=3, player=2)
- scripts/dev/save_load_trigger.gd — the trigger pattern already established in this feature (to mirror)

## Reference files (STRICT STYLE MATCH)
- scripts/dev/save_load_trigger.gd — Gold Standard Area3D trigger (layer 3/mask 2, body_entered, @export DI)
- AGENTS.md — placeholder policy + static typing

## Required Skills
- godot-sdd (headless validation; non-code artifact registry)

## Files to create/modify (suggested)
- assets/audio/placeholder_beep.wav — create (short placeholder beep)
- assets/audio/placeholder_beep_high.wav — create (second placeholder beep, distinct pitch)
- scripts/dev/sfx_trigger.gd — create (Area3D that plays an AudioStream on body_entered)
- scenes/act/arena.tscn — modify (2–3 SFX trigger pads in the audio zone)
- docs/sdd/artifacts/arena-dev-hub.yml — modify (register the beeps + sfx trigger)

## Description
Author two short placeholder beep WAVs (a low and a high sine beep) in `assets/audio/` as placeholder sfx (status: placeholder; no final audio). Add `sfx_trigger.gd` (Area3D, interaction layer 3, mask 2) with an `@export` `stream: AudioStream` and a child AudioStreamPlayer; on `body_entered`, if not already playing, play the beep. Place 2–3 trigger pads in the audio zone, each wired to a beep. Register the beeps and trigger. Follow design.md.

## Acceptance
- [ ] Placeholder beep WAVs exist in `assets/audio/` and import cleanly.
- [ ] Stepping into each SFX trigger pad plays an audible beep with no errors.
- [ ] SFX triggers use explicit interaction layer 3 / mask 2; no defaults.
- [ ] `gdlint .` reports 0 problems.
- [ ] `godot --headless --editor --path . --quit-after 10` is clean; `godot --headless --path . --quit-after 5 scenes/act/arena.tscn` is clean.
- [ ] `docs/sdd/artifacts/arena-dev-hub.yml` registers the beeps (status: placeholder) + sfx trigger.

## Needs tests
no

---

## Implementation log (filled by dev after successful commit)
- Commit: 988783be42aa8c2f1853841255bf9d3eab6929f4 — feat(arena-dev-hub): add audio zone SFX trigger pads with placeholder beeps
- Files modified:
  - assets/audio/placeholder_beep.wav (created)
  - assets/audio/placeholder_beep.wav.import (created)
  - assets/audio/placeholder_beep_high.wav (created)
  - assets/audio/placeholder_beep_high.wav.import (created)
  - scripts/dev/sfx_trigger.gd (created)
  - scripts/dev/sfx_trigger.gd.uid (created)
  - scenes/act/arena.tscn (modified)
  - docs/sdd/artifacts/arena-dev-hub.yml (modified)
- Tests added: none required
- Context & Reference files read:
  - scenes/act/arena.tscn
  - project.godot
  - scripts/dev/save_load_trigger.gd
  - AGENTS.md
- Notes: Godot generated the `.import` sidecars and `.gd.uid` (tracked per repo convention), hence 8 files vs the 5 suggested. Placed 3 trigger pads (low/high/low) within the "2–3" allowance. Updated the AudioZone pillar `paths` from the pre-existing `res://assets/placeholders/placeholder_beep.wav` (which does not exist — beeps live in `assets/audio/` per this task) to the two real beep paths.
