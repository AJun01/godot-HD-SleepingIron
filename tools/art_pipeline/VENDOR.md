# Vendored code: FrameRonin art pipeline (processing core)

- Upstream repository: <https://github.com/GOODDAYDAY/FrameRonin-MCP>
- Pinned upstream commit: `dc31d2baf9ae32cb3faee6bf84d3456b37993cf7` (`dc31d2b`)
- License: MIT (see `LICENSE` in this directory)
- Vendored on: feature `sprite-asset-pipeline`, task 001

## What was vendored

| Local file | Upstream source | Notes |
|---|---|---|
| `image_utils.py` | `frame_ronin_mcp/lib/image_utils.py` | `load_image`, `save_image`, `resize_image`, `white_to_alpha` only (base64/bytes/crop/nearest-neighbor/info helpers omitted — out of scope) |
| `watermark.py` | `frame_ronin_mcp/lib/watermark.py` | Vendored as-is (`remove_gemini_watermark` + helpers) |
| `godot_format.py` | `frame_ronin_mcp/lib/godot_format.py` | `generate_sprite_frames_tres` + serialization helpers only; tscn/tileset/project.godot generators omitted (out of scope). Local fixes applied (below). |
| `gif_sprite.py` | `frame_ronin_mcp/tools/gif_sprite.py` | `handle_spritesheet_split` + `handle_spritesheet_compose` only; GIF extract/compose omitted (out of scope) |

## Local fixes applied to `godot_format.py`

1. Animation names are serialized as raw Godot StringNames (`"name": &"idle"`) instead of the
   upstream escaped-string form (`"name": "&\"idle\""`), which Godot cannot resolve.
2. Per-animation frame counts are driven by the caller's list of non-blank cell columns instead
   of the upstream hardcoded `columns` count; only referenced cells get an `AtlasTexture`.
3. `generate_uid()` emits lowercase `[a-z0-9]` only (upstream `secrets.token_urlsafe` leaks `-`/`_`,
   which are invalid in Godot resource uids).
