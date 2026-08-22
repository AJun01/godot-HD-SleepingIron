# fix-004b — Salt-and-pepper despeckle for jump frames (comprehensive all-frame cleanup)

## Context files (read for understanding — do not modify)
- tools/art_pipeline/frames_v1_user_process.py — offending asset commit `67de694`; `despeckle()` (lines 261-294) removes only *isolated* near-black components (`area < 25` AND `perimeter_transparent_fraction >= 0.5`), which cannot catch specks attached to the silhouette via anti-aliased bridges
- assets/sprites/player/player_sheet.png — current right sheet; the jump row (row 2) still carries attached specks the isolated-component rule misses
- assets/sprites/player/player_frames.tres — fixed UID `uid://2k97uge7sf4w` + 12×6 structure + loop flags to preserve on re-emit
- docs/character-sprite-mapping.md — 12-row sheet contract (row order, loop flags, feet-to-bottom invariant)
- docs/sdd/artifacts/act-player-foundation.yml — registry invariant line 72 records the current despeckle rule and must be extended

## Reference files (STRICT STYLE MATCH)
- tools/art_pipeline/process_character_sheet.py — Gold Standard CLI structure (argparse, `--project-root`, `res://` path computation, `save_image`)
- tools/art_pipeline/godot_format.py — Gold Standard `.tres` serialization (`generate_sprite_frames_tres`, StringName/AtlasTexture output)
- AGENTS.md — "HD-2D visual invariants" (source aspect ratio, nearest-neighbor, transparency, no resampling) as the Gold Standard

## Required Skills
- godot-sdd (headless validation; non-code asset artifact registration)

## Files to create/modify (suggested)
- tools/art_pipeline/frames_v1_user_process.py — modify (add a salt-and-pepper pass after the existing `despeckle()`; run it in `main()`; report per-action removal counts)
- assets/sprites/player/frames/ — modify (regenerate 72 right-facing `<action>_NNN.png` per-frame outputs)
- assets/sprites/player/player_sheet.png — modify (regenerate right-facing 1536×3072 composed sheet)
- assets/sprites/player/player_left_sheet.png — modify (regenerate mirrored sheet)
- assets/sprites/player/player_frames.tres — modify (regenerate; preserve UID `uid://2k97uge7sf4w`, 12 animations × 6 frames, loop flags)
- assets/sprites/player/player_left_frames.tres — modify (regenerate; preserve UID `uid://a2tle527t5pf`)
- docs/sdd/artifacts/act-player-foundation.yml — modify (extend the despeckle invariant to cover the new salt-and-pepper pass)

## Description
**Failing acceptance criterion (verbatim playtest intent — authoritative):**

> 2. "目前静止的时候人物贴图是干净了，但是跳跃还有很多不干净的点，请全面清理" — the idle row is clean after the last fix, but the JUMP frames (and possibly others) still contain dirty specks. A comprehensive cleanup of ALL frames is required.

The current despeckle (fix-002, commit `67de694`) removes only *isolated* dark components below a small size; it is insufficient because specks can be **attached to the silhouette via anti-aliased bridges**, so they are part of the main component and never match `area < 25`. Add a salt-and-pepper removal pass that erodes attached specks pixel-by-pixel while preserving real outlines and enclosed dark details (eyes).

**Salt-and-pepper pass (exact; developer may refine only the numpy mechanics, not the semantics).** Add a new function after `despeckle()` and call it in `main()` on the already-despeckled 256×256 frame (immediately after `despeckled, removed = despeckle(clean256)`), before the frame is appended:

- For **every opaque pixel** (`alpha > 0`) with **luminance < 100**, if **more than 5 of its 8 neighbors are transparent** (`alpha == 0`), set it transparent (`alpha = 0`, `RGB = 0`).
- Luminance = `0.299*R + 0.587*G + 0.114*B` (Rec.601 luma).
- **Iterate the sweep 3 times** (report's 2–3), recomputing opacity each pass so bridges erode first and then the now-detached speck pixels follow.
- Count transparent neighbors over the full 8-neighborhood (3×3 minus center). Implement via a shifted-sum of the `(alpha == 0)` boolean array (or a padded 3×3 convolution); if using `np.roll`, zero the wrapped border after each shift exactly like the existing 1px-erosion edge handling in `clean_frame()` (lines 246-254) so the image edges do not wrap.

Semantics rationale (keep this in the docstring): outline pixels have several opaque interior neighbors (≤5 transparent) so they survive; enclosed dark details (eyes) have ~0 transparent neighbors and survive; attached specks and their AA bridges have 6–8 transparent neighbors and are removed.

**Self-check.** Accumulate and print per-frame removal counts, and print a per-action summary (so the jump/attack rows demonstrably reduce). After the final sweep, assert/verify that no pixel still matches the rule (`luminance < 100` AND `> 5` transparent 8-neighbors AND opaque) and print the residual count (should be 0). Keep the existing `despeckle()` self-check output as well.

**Keep the existing pipeline behavior.** The checkerboard matting, label/divider/ground-line cleanup, 1px erosion, 256×256 resize, existing `despeckle()`, 12-action classification, right+mirrored-left sheet composition, and `.tres` emission (pinned UIDs, loop flags, `speed=10.0`) are unchanged. **Idle collapse is preserved** — after cleaning, row 0 is still collapsed to one frame (`idle_000…idle_005.png` byte-identical).

**Regeneration + commit.** Re-run the full pipeline against the hand-cropped inputs at `/Users/aj/Desktop/素材/art/frames-v1/{0,1,2_frames,3,4,5_frames,6,7,8_frames,9,10,11_frames}` via `uv run --with pillow --with numpy python tools/art_pipeline/frames_v1_user_process.py` from the project root, then the pipeline CLI `tools/art_pipeline/process_character_sheet.py` for `.tres` emission (the vendored script emits both `.tres` itself with pinned UIDs). Regenerate `assets/sprites/player/` (right+left sheets, all 72 frame PNGs, both `.tres`), keep the idle-collapse behavior, and commit.

**Working-tree hygiene.** The headless editor import on this machine re-flips `assets/sprites/player/player_sheet.png.import` to lossy s3tc VRAM (`compress/mode=2`, `mipmaps/generate=true`). Revert that `.import` change before committing (`git checkout -- assets/sprites/player/player_sheet.png.import`) so the pixel-art nearest-neighbor invariant (AGENTS.md "no resampling") is preserved.

**Vision QC is the Orchestrator's acceptance gate — NOT the developer's.** The developer must NOT claim final visual acceptance. After the developer commits the deterministic regeneration + mechanical gates below, the Orchestrator runs a vision QC pass over the regenerated frames to confirm specks are gone and outlines/eyes survived. State this deferral explicitly in the Implementation log `Notes`.

## Acceptance
- [ ] REGRESSION (jump/attached specks): `frames_v1_user_process.py` implements the salt-and-pepper pass (opaque + Rec.601 luma < 100 + more than 5 of 8 neighbors transparent → transparent, iterated 3 times) and runs it on every frame after `despeckle()`; the self-check reports per-action removal and asserts 0 residual matching pixels after the final sweep.
- [ ] Existing despeckle rule (`area < 25` AND `perimeter_transparent_fraction >= 0.5`) still runs first and is unchanged; idle row (row 0) stays clean — no regression.
- [ ] Idle collapse preserved: `idle_000…idle_005.png` are byte-identical after regeneration.
- [ ] `assets/sprites/player/player_frames.tres` / `player_left_frames.tres` keep UIDs `uid://2k97uge7sf4w` / `uid://a2tle527t5pf`, 12 animations × 6 frames, and correct loop flags; `player.tscn` still resolves them.
- [ ] The two sheets are 1536×3072 RGBA, feet aligned to the cell bottom, blank cells transparent, nearest-neighbor preserved (no resampling).
- [ ] Script is reproducible: `uv run --with pillow --with numpy python tools/art_pipeline/frames_v1_user_process.py --src "<frames-v1 dir>" --project-root .` runs end-to-end (Pillow + NumPy only).
- [ ] `godot --headless --editor --path . --quit-after 10` is clean (no ERROR / SCRIPT ERROR / Parse Error / Failed loading), regenerating the `.import` sidecars.
- [ ] `godot --headless --path . --quit-after 5 scenes/actors/player.tscn` and `scenes/dev/sprite_anim_preview.tscn` smoke clean.
- [ ] `docs/sdd/artifacts/act-player-foundation.yml` extends the `frames/` despeckle invariant to include the salt-and-pepper pass (and keeps the idle single-frame-collapse note).
- [ ] No stray lossy `player_sheet.png.import` (s3tc/mipmap) change is committed.
- [ ] Vision QC is NOT self-certified by the developer; the Implementation log `Notes` defers visual confirmation (specks gone, outlines/eyes preserved) to the Orchestrator's vision pass.

## Needs tests
no

---

## Implementation log (filled by dev after successful commit)
- Commit: 89e203acaa695dfbdd8a7b7fd0398a1f62caf4e9 — fix(act-player-foundation): 全面清理贴图噪点：新增盐椒去斑扫描并重新生成全部帧
- Files modified:
  - tools/art_pipeline/frames_v1_user_process.py (modified)
  - assets/sprites/player/player_sheet.png (modified)
  - assets/sprites/player/player_left_sheet.png (modified)
  - docs/sdd/artifacts/act-player-foundation.yml (modified)
  - assets/sprites/player/frames/attack_1_000.png (modified)
  - assets/sprites/player/frames/attack_1_001.png (modified)
  - assets/sprites/player/frames/attack_1_002.png (modified)
  - assets/sprites/player/frames/attack_1_003.png (modified)
  - assets/sprites/player/frames/attack_1_004.png (modified)
  - assets/sprites/player/frames/attack_2_000.png (modified)
  - assets/sprites/player/frames/attack_2_001.png (modified)
  - assets/sprites/player/frames/attack_2_002.png (modified)
  - assets/sprites/player/frames/attack_2_003.png (modified)
  - assets/sprites/player/frames/attack_2_004.png (modified)
  - assets/sprites/player/frames/attack_2_005.png (modified)
  - assets/sprites/player/frames/attack_3_000.png (modified)
  - assets/sprites/player/frames/attack_3_001.png (modified)
  - assets/sprites/player/frames/attack_3_002.png (modified)
  - assets/sprites/player/frames/attack_3_003.png (modified)
  - assets/sprites/player/frames/attack_3_004.png (modified)
  - assets/sprites/player/frames/attack_3_005.png (modified)
  - assets/sprites/player/frames/attack_air_001.png (modified)
  - assets/sprites/player/frames/attack_air_002.png (modified)
  - assets/sprites/player/frames/attack_air_003.png (modified)
  - assets/sprites/player/frames/attack_air_004.png (modified)
  - assets/sprites/player/frames/death_000.png (modified)
  - assets/sprites/player/frames/death_001.png (modified)
  - assets/sprites/player/frames/death_002.png (modified)
  - assets/sprites/player/frames/death_003.png (modified)
  - assets/sprites/player/frames/death_004.png (modified)
  - assets/sprites/player/frames/dodge_000.png (modified)
  - assets/sprites/player/frames/dodge_001.png (modified)
  - assets/sprites/player/frames/dodge_002.png (modified)
  - assets/sprites/player/frames/dodge_003.png (modified)
  - assets/sprites/player/frames/dodge_005.png (modified)
  - assets/sprites/player/frames/fall_001.png (modified)
  - assets/sprites/player/frames/fall_002.png (modified)
  - assets/sprites/player/frames/fall_004.png (modified)
  - assets/sprites/player/frames/hit_000.png (modified)
  - assets/sprites/player/frames/hit_002.png (modified)
  - assets/sprites/player/frames/hit_003.png (modified)
  - assets/sprites/player/frames/hit_004.png (modified)
  - assets/sprites/player/frames/hit_005.png (modified)
  - assets/sprites/player/frames/jump_000.png (modified)
  - assets/sprites/player/frames/jump_002.png (modified)
  - assets/sprites/player/frames/jump_005.png (modified)
  - assets/sprites/player/frames/land_000.png (modified)
  - assets/sprites/player/frames/land_002.png (modified)
  - assets/sprites/player/frames/land_004.png (modified)
  - assets/sprites/player/frames/land_005.png (modified)
  - assets/sprites/player/frames/run_002.png (modified)
  - assets/sprites/player/frames/run_003.png (modified)
  - assets/sprites/player/frames/run_004.png (modified)
  - assets/sprites/player/frames/run_005.png (modified)
- Tests added: none required
- Context & Reference files read:
  - tools/art_pipeline/frames_v1_user_process.py
  - assets/sprites/player/player_sheet.png
  - assets/sprites/player/player_frames.tres
  - docs/character-sprite-mapping.md
  - docs/sdd/artifacts/act-player-foundation.yml
  - tools/art_pipeline/process_character_sheet.py
  - tools/art_pipeline/godot_format.py
  - AGENTS.md
- Notes:
  - Vision QC is NOT self-certified by this developer: confirmation that specks are gone and outlines/eyes survived is deferred to the Orchestrator's vision pass.
  - Both .tres files were regenerated but came out byte-identical to HEAD (UIDs `uid://2k97uge7sf4w` / `uid://a2tle527t5pf`, 12×6 structure, loop flags, speed=10.0 all unchanged), so git records no diff for them — they are intentionally absent from this commit.
  - No stray lossy `.import` flip occurred this run: `player_sheet.png.import` stayed `compress/mode=0` / `mipmaps/generate=false` (nearest-neighbor preserved), so no revert was needed.
  - Also read (not modified): tools/art_pipeline/image_utils.py, assets/sprites/player/player_left_frames.tres, assets/sprites/player/player_sheet.png.import.
  - Self-check: per-action salt-and-pepper removal printed (jump 7 px, attack_2 33 px, attack_3 118 px, …), residual after final sweep = 0; idle row byte-identical.
