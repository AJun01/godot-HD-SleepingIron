# fix-002 — Vendor frame pipeline + despeckle + collapse idle to a single frame

## Context files (read for understanding — do not modify)
- assets/sprites/player/player_frames.tres — offending asset commit `6568d9c`; current 12-animation × 6-frame structure + fixed UID `uid://2k97uge7sf4w` to preserve
- assets/sprites/player/player_left_frames.tres — left spare; fixed UID `uid://a2tle527t5pf` to preserve
- tools/art_pipeline/godot_format.py — `generate_sprite_frames_tres` used to re-emit the `.tres` (loop flags, AtlasTexture regions)
- tools/art_pipeline/VENDOR.md — vendoring provenance pattern to follow for the new script
- docs/character-sprite-mapping.md — 12-row sheet contract (row order, loop flags, feet-to-bottom invariant)

## Reference files (STRICT STYLE MATCH)
- tools/art_pipeline/process_character_sheet.py — Gold Standard CLI structure (argparse, `--project-root`, `res://` path computation, `save_image`)
- tools/art_pipeline/godot_format.py — Gold Standard `.tres` serialization (StringName/AtlasTexture output the current files already use)
- AGENTS.md — "HD-2D visual invariants" (source aspect ratio, nearest-neighbor, transparency) as the Gold Standard

## Required Skills
- godot-sdd (headless validation; non-code asset artifact registration)

## Files to create/modify (suggested)
- tools/art_pipeline/frames_v1_user_process.py — create (vendored + improved version of `/tmp/frames_v1_user_process.py`: checkerboard matting + island/line cleanup + **NEW despeckle** + **NEW idle-collapse** + `.tres` emission with pinned UIDs)
- assets/sprites/player/frames/ — modify (regenerate 72 right-facing `<action>_NNN.png` per-frame outputs)
- assets/sprites/player/player_sheet.png — modify (regenerate right-facing 1536×3072 composed sheet)
- assets/sprites/player/player_left_sheet.png — modify (regenerate mirrored sheet)
- assets/sprites/player/player_frames.tres — modify (regenerate; preserve UID `uid://2k97uge7sf4w`, 12 animations × 6 frames)
- assets/sprites/player/player_left_frames.tres — modify (regenerate; preserve UID `uid://a2tle527t5pf`)
- docs/sdd/artifacts/act-player-foundation.yml — modify (register regenerated sprite assets; note idle row is a temporary single-frame collapse)

## Description
**Failing acceptance criteria (verbatim playtest intent — authoritative):**

> 2. "目前的每一帧没扣图干净，导致还有很多黑点" — the matted sprite frames still contain black specks/dots (matting leftovers visible in-engine).
> 3. "人物禁止[静止]状态可能存在每一帧不对称导致一直抖动（关于这点你先把每帧处理成同一帧，我之后会准备新的发呆时动画素材）" — the idle animation's frames are asymmetric, causing constant jitter; for now collapse the idle row to one duplicated frame (the user will supply new idle art later).

The sprites were last regenerated in asset commit `6568d9c` (checkerboard-residue cleanup) and still ship black specks and an asymmetric 6-frame idle. Fix by re-running the frame-processing pipeline against the user's hand-cropped inputs, with two additions.

**Input.** 72 hand-cropped frames, 485×480 RGBA with baked checkerboard, at `/Users/aj/Desktop/素材/art/frames-v1/{0,1,2_frames,3,4,5_frames,6,7,8_frames,9,10,11_frames}` (18 `frame_NNN.png` per folder). Reference logic is `/tmp/frames_v1_user_process.py` (Pillow + NumPy; runs via `/Users/aj/projects/porfolios/FrameRonin-MCP/.venv/bin/python` or `uv run --with pillow --with numpy`). Vendor an improved copy as `tools/art_pipeline/frames_v1_user_process.py` (follow the `VENDOR.md` provenance pattern) so regeneration is reproducible in-repo.

**Despeckle rule (exact, run after matting and after the 256×256 resize).** Identify "dark" opaque pixels as `dark = (max(R,G,B) < 80) and (alpha > 0)`. Find 4-connected components of dark pixels. For each component compute `area` (pixel count) and `perimeter_transparent_fraction` = (pixels in the component that have ≥1 transparent 4-neighbor) / `area`. Set a component fully transparent (alpha = 0, RGB = 0) **iff `area < 25` AND `perimeter_transparent_fraction >= 0.5`**. This removes small near-black specks floating in transparency while preserving eyes and fine dark details *inside* the silhouette (enclosed by opaque body pixels → near-zero perimeter-transparent fraction). Do not touch the existing structural line-clear or the 1 px erosion steps; despeckle is an additional pass after them.

**Idle collapse (exact).** After cleaning, for the `idle` action (row 0) take ONE neutral frame — default `idle_000`, the first cleaned idle frame (the Orchestrator may substitute a vision-chosen most-centered frame) — and write it into all 6 idle cells: the per-frame outputs `idle_000…idle_005.png` are identical, and all 6 cells of row 0 in BOTH composed sheets (right and mirrored left) are that same frame. Record in the commit + registry that idle art is temporary.

**Output + `.tres`.** The script writes: (a) 72 right-facing per-frame PNGs to `assets/sprites/player/frames/<action>_NNN.png` (flat layout, matching the current repo), (b) `player_sheet.png` (right, 1536×3072) and `player_left_sheet.png` (mirrored), (c) `player_frames.tres` + `player_left_frames.tres`. Emit both `.tres` via `tools/art_pipeline/godot_format.generate_sprite_frames_tres` with `columns = [0..5]` for every animation and the correct per-row loop flags (idle/run/fall `loop=true`; jump/land/attack_1/attack_2/attack_3/attack_air/hit/dodge/death `loop=false`), and **pin the existing UIDs** (right `uid://2k97uge7sf4w`, left `uid://a2tle527t5pf`) so `player.tscn`'s by-path reference and any cached UID lookups stay valid. `.import` sidecars are regenerated by the headless editor import pass — do not hand-edit them.

**Vision QC is an Orchestrator responsibility.** The developer may not have vision and must NOT self-certify visual quality. After asset regeneration, the Orchestrator runs a vision QC pass (provider deepseek-official / model deepseek-v4-flash-vision-exp) over the regenerated sheets to confirm (a) black specks are gone, (b) eyes/fine interior details survived despeckle, (c) the idle row is a single clean duplicated frame. The developer's task is the deterministic regeneration + mechanical gates below; visual confirmation is deferred to that Orchestrator pass before merge.

## Acceptance
- [ ] REGRESSION (black specks): running the vendored script against the 72 source frames emits sheets whose matted frames contain no isolated near-black components matching the despeckle rule (`area < 25` and `perimeter_transparent_fraction >= 0.5`); the script's own self-check (count of removed dark components per frame) reports the specks removed.
- [ ] REGRESSION (idle jitter): the idle row (row 0) of both composed sheets contains one frame duplicated across all 6 cells; `idle_000…idle_005.png` are byte-identical.
- [ ] `assets/sprites/player/player_frames.tres` and `player_left_frames.tres` keep their existing UIDs (`uid://2k97uge7sf4w` / `uid://a2tle527t5pf`), 12 animations × 6 frames, correct loop flags, and `player.tscn` still resolves them.
- [ ] The two sheets are 1536×3072 RGBA with feet aligned to the cell bottom and blank cells transparent (no resampling; nearest-neighbor preserved).
- [ ] `godot --headless --editor --path . --quit-after 10` is clean (no ERROR / SCRIPT ERROR / Parse Error / Failed loading), which regenerates the `.import` sidecars for the new sheets/frames.
- [ ] `godot --headless --path . --quit-after 5 scenes/actors/player.tscn` and `scenes/dev/sprite_anim_preview.tscn` smoke clean (regenerated `.tres` loads and plays).
- [ ] The script is reproducible: `python tools/art_pipeline/frames_v1_user_process.py --src "<frames-v1 dir>" --project-root .` runs end-to-end with Pillow + NumPy only.
- [ ] `docs/sdd/artifacts/act-player-foundation.yml` registers the regenerated sprite assets and marks the idle row as a temporary single-frame collapse (awaiting new idle art).
- [ ] Vision QC is NOT self-certified by the developer; the task note defers visual confirmation (specks gone, eyes preserved, idle centered) to the Orchestrator's vision pass.

## Needs tests
no

---

## Implementation log (filled by dev after successful commit)
- Commit: 67de694 — fix(act-player-foundation): 重新生成玩家精灵：去黑点 + 待机折叠为单帧（vendored 帧管线）
- Files modified:
  - tools/art_pipeline/frames_v1_user_process.py (created)
  - assets/sprites/player/frames/<action>_NNN.png — all 72 right-facing frame PNGs (modified)
  - assets/sprites/player/player_sheet.png (modified)
  - assets/sprites/player/player_left_sheet.png (modified)
  - docs/sdd/artifacts/act-player-foundation.yml (modified)
- Tests added: none required
- Context & Reference files read:
  - assets/sprites/player/player_frames.tres
  - assets/sprites/player/player_left_frames.tres
  - tools/art_pipeline/godot_format.py
  - tools/art_pipeline/VENDOR.md
  - docs/character-sprite-mapping.md
  - tools/art_pipeline/process_character_sheet.py
  - AGENTS.md
- Notes: The two .tres files were re-emitted by the vendored script via generate_sprite_frames_tres with pinned UIDs (uid://2k97uge7sf4w / uid://a2tle527t5pf) and produced byte-identical output to the committed files (same 12×6 structure, loop flags, speed 10), so git reports no change to them. Extra files read for context: .spec/act-player-foundation/design.md, /tmp/frames_v1_user_process.py (reference logic), tools/art_pipeline/image_utils.py, tools/art_pipeline/character_sheet_map.json, docs/sdd/artifacts/act-player-foundation.yml. Despeckle self-check removed 110 dark components across 72 frames; post-run check confirms 0 residual components matching the despeckle rule. idle_000…idle_005 are byte-identical (sha256 match). Vision QC deferred to Orchestrator per task.
