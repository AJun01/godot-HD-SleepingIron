"""
Godot 4.7 SpriteFrames text-format generator (.tres).

All output is pure text. No Godot installation required to generate files.
Vendored from FrameRonin-MCP lib/godot_format.py (see VENDOR.md); the tscn /
tileset / project.godot generators are out of scope and not vendored.
"""

import secrets
import string


# ── Helpers ───────────────────────────────────────────────────────────────

def _fmt(v: float) -> str:
    """Format a number for Godot: integer if whole, else float."""
    if isinstance(v, int):
        return str(v)
    if isinstance(v, float):
        if v == int(v):
            return str(int(v))
        return f"{v:.1f}"
    return str(v)


_UID_ALPHABET = string.ascii_lowercase + string.digits


def generate_uid() -> str:
    """Generate a Godot-compatible random uid: uid://<12-char lowercase base-36 token>.

    Uses only lowercase [a-z0-9]; upstream's secrets.token_urlsafe leaks '-'/'_',
    which Godot's uid parser rejects.
    """
    tok = "".join(secrets.choice(_UID_ALPHABET) for _ in range(12))
    return f"uid://{tok}"


# ── Godot value types ─────────────────────────────────────────────────────

def StringName(name: str) -> dict:
    return {"_gd": "StringName", "name": name}


def SubResource(rid: str) -> dict:
    return {"_gd": "SubResource", "id": str(rid)}


# ── Property serialization ─────────────────────────────────────────────────

def _serialize_value(v) -> str:
    """Serialize a single Python value to Godot text format."""
    if v is None:
        return "null"
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, int):
        return str(v)
    if isinstance(v, float):
        return _fmt(v)
    if isinstance(v, str):
        escaped = v.replace("\\", "\\\\").replace('"', '\\"')
        return f'"{escaped}"'
    if isinstance(v, dict):
        gt = v.get("_gd")
        if gt == "StringName":
            return f'&"{v["name"]}"'
        if gt == "SubResource":
            return f'SubResource("{v["id"]}")'
        return _serialize_dict(v)
    if isinstance(v, (list, tuple)):
        items = ", ".join(_serialize_value(i) for i in v)
        return f"[{items}]"
    return str(v)


def _serialize_dict(d: dict) -> str:
    """Serialize a dict as a Godot dictionary literal."""
    parts = []
    for k, val in d.items():
        if k.startswith("_"):
            continue
        parts.append(f'"{k}": {_serialize_value(val)}')
    return "{" + ", ".join(parts) + "}"


# ── SpriteFrames .tres ─────────────────────────────────────────────────────

def generate_sprite_frames_tres(
    spritesheet_path: str,
    cell_width: int,
    cell_height: int,
    rows: int,
    columns: int,
    animations: list[dict] | None = None,
    uid: str | None = None,
) -> str:
    """
    Generate a SpriteFrames .tres resource from a spritesheet.

    Each referenced cell becomes an AtlasTexture sub-resource; only cells actually
    referenced by an animation get one (blank cells are skipped).
    animations: [{"name": "idle", "row": 0, "speed": 10.0, "loop": True,
                  "columns": [0, 1, 2, 3]}, ...]
    where "columns" is the row's list of non-blank column indices (drives the
    per-animation frame count). If None, auto-generates one idle animation per row.
    uid: optional pinned resource uid (default: a fresh random uid). Callers that
    must keep an existing uid stable across regenerations pass it explicitly.
    """
    uid = uid or generate_uid()

    lines = []
    lines.append(f'[gd_resource type="SpriteFrames" format=3 uid="{uid}"]')
    lines.append("")

    # ExtResource for the spritesheet
    lines.append(f'[ext_resource type="Texture2D" path="res://{spritesheet_path}" id="spritesheet"]')
    lines.append("")

    # Auto-generate one idle animation per row when none supplied.
    if not animations:
        animations = []
        for row in range(rows):
            direction = ["down", "left", "right", "up"][row] if row < 4 else f"row{row}"
            animations.append({
                "name": f"idle_{direction}",
                "row": row,
                "speed": 5.0,
                "loop": True,
                "columns": list(range(columns)),
            })

    # Assign one AtlasTexture per referenced (row, col); blanks get none.
    atlas_ids: dict[tuple[int, int], str] = {}
    for anim in animations:
        row = anim.get("row", 0)
        cols = anim.get("columns")
        if cols is None:
            cols = list(range(columns))
        for col in cols:
            if (row, col) not in atlas_ids:
                atlas_ids[(row, col)] = f"atlas_{len(atlas_ids)}"

    for (row, col), atlas_id in atlas_ids.items():
        x, y = col * cell_width, row * cell_height
        lines.append(f'[sub_resource type="AtlasTexture" id="{atlas_id}"]')
        lines.append('atlas = ExtResource("spritesheet")')
        lines.append(f"region = Rect2({x}, {y}, {cell_width}, {cell_height})")
        lines.append("filter_clip = true")
        lines.append("")

    # Resource section
    lines.append("[resource]")
    anim_entries = []
    for anim in animations:
        name = anim["name"]
        row = anim.get("row", 0)
        speed = anim.get("speed", 5.0)
        loop = anim.get("loop", True)
        cols = anim.get("columns", list(range(columns)))

        frames_json = []
        for col in cols:
            frames_json.append({
                "duration": 1.0,
                "texture": SubResource(atlas_ids[(row, col)]),
            })

        anim_json = {
            "frames": frames_json,
            "loop": loop,
            "name": StringName(name),
            "speed": speed,
        }
        anim_entries.append(_serialize_dict(anim_json))

    lines.append(f"animations = [{', '.join(anim_entries)}]")
    return "\n".join(lines) + "\n"
