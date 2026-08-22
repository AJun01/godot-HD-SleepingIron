#!/usr/bin/env python3
"""Regenerate assets/ui/architecture_diagram.svg.

Why this exists
---------------
Godot's SVG importer (ThorVG) does NOT rasterize <text> elements, so a
hand-authored SVG full of readable labels imports as empty boxes. This script
converts every label into glyph <path> outlines via fontTools and emits a fully
self-contained SVG (shapes only) that Godot imports correctly.

The diagram's content — nodes (autoloads/services + scenes) and edges
(dependencies) — lives in the NODES / EDGES / ARENA_SERVICES_BUS tables below.
Edit those tables, then run (from the project root):

    python3 tools/architecture_wall/generate_architecture_svg.py

Requires fonttools (dev-only tooling, not a runtime/game dependency; the
committed SVG needs no fonttools at runtime):

    python3 -m pip install fonttools

Fonts are read from the macOS system font folder by default; override
SANS_FONT / SANS_BOLD_FONT / MONO_FONT if you regenerate on another OS.
"""

from __future__ import annotations

import os

try:
    from fontTools.ttLib import TTFont
    from fontTools.pens.svgPathPen import SVGPathPen
    from fontTools.pens.transformPen import TransformPen
    from fontTools.misc.transform import Transform
except ImportError as exc:  # pragma: no cover - setup hint only
    raise SystemExit(
        "fonttools is required: python3 -m pip install fonttools"
    ) from exc

OUT_PATH = os.path.join(
    os.path.dirname(__file__), "..", "..", "assets", "ui", "architecture_diagram.svg"
)

CANVAS_W = 1920
CANVAS_H = 1080

# ---- Fonts (macOS defaults; override for other OSes) ----------------------
SANS_FONT = "/System/Library/Fonts/Supplemental/Arial.ttf"
SANS_BOLD_FONT = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
MONO_FONT = "/System/Library/Fonts/Supplemental/Courier New.ttf"

# ---- Colors ---------------------------------------------------------------
BG = "#0b0e14"
EDGE = "#8b93a7"
TITLE_FG = "#eef2f7"
SUBTITLE_FG = "#9fb0c8"
PATH_FG = "#7f8ea6"
LABEL_FG = "#aab3c5"

KIND_STYLE = {
    # kind: (fill, stroke)
    "scene": ("#14301f", "#2f8f6a"),
    "service": ("#14283f", "#4a90d9"),
    "bus": ("#2a2110", "#d9a441"),
}

# ---- Diagram content (hand-maintained) ------------------------------------
# Each node: (x, y, w, h, kind, title, subtitle, path)
NODES = [
    (100, 140, 210, 90, "scene", "boot", "main scene", "scenes/boot.tscn"),
    (430, 140, 250, 90, "service", "GameFlow",
     "stage machine (BOOT -> ARENA)", "scripts/autoload/game_flow.gd"),
    (800, 140, 250, 90, "service", "SceneRouter",
     "fade + scene swap", "scripts/autoload/scene_router.gd"),
    (1170, 140, 360, 90, "scene", "arena",
     "six-zone dev hub", "scenes/act/arena.tscn"),
    (1640, 140, 250, 90, "scene", "player",
     "CharacterBody3D", "scenes/actors/player.tscn"),
    (100, 400, 950, 90, "bus", "EventBus",
     "autoload signal bus (no logic)", "scripts/autoload/event_bus.gd"),
    (100, 660, 300, 90, "service", "DialogueService",
     "dialogue bar", "scripts/autoload/dialogue_service.gd"),
    (480, 660, 300, 90, "service", "ObjectiveHud",
     "objective label", "scripts/autoload/objective_hud.gd"),
    (860, 660, 300, 90, "service", "SaveService",
     "JSON save/restore", "scripts/autoload/save_service.gd"),
]

# Signals carried by the EventBus (rendered as an extra line on the bus node).
BUS_SIGNALS = "stage_changed | game_state_changed | transition_started | transition_finished"

# Each edge: (points, label, label_pos, label_anchor)
EDGES = [
    ([(310, 185), (430, 185)], "start_flow()", (370, 176), "middle"),
    ([(680, 185), (800, 185)], "transition_to()", (740, 176), "middle"),
    ([(1050, 185), (1170, 185)], "change_scene()", (1110, 176), "middle"),
    ([(1530, 185), (1640, 185)], "instantiates", (1585, 176), "middle"),
    ([(555, 230), (555, 400)], "emits", (565, 315), "start"),
    ([(925, 230), (925, 400)], "emits", (935, 315), "start"),
    ([(250, 660), (250, 490)], "listens", (260, 575), "start"),
    ([(630, 660), (630, 490)], "listens", (640, 575), "start"),
]

# arena -> services bus (zones drive their services). Trunk drops from the
# arena node, a rail runs below the services row, and three drops rise into
# each service's bottom edge.
ARENA_TRUNK = [(1350, 230), (1350, 790)]
ARENA_RAIL = [(1350, 790), (250, 790)]
ARENA_DROPS = [(250, 750), (630, 750), (1010, 750)]
ARENA_LABEL = ("zones drive services", (1360, 520), "start")

TITLE = "Sleeping Iron HD-2D - Code Architecture"
SUBTITLE = "arena-dev-hub | nodes = autoloads/services + scenes | edges = dependencies"
LEGEND = [
    ("scene", "scene"),
    ("service", "autoload service"),
    ("bus", "signal bus"),
]

# ---- Text -> path ---------------------------------------------------------
_FONT_CACHE: dict[str, TTFont] = {}


def _font(path: str) -> TTFont:
    font = _FONT_CACHE.get(path)
    if font is None:
        font = TTFont(path)
        _FONT_CACHE[path] = font
    return font


def _advances(text: str, font: TTFont) -> list[float]:
    cmap = font.getBestCmap()
    hmtx = font["hmtx"]
    widths: list[float] = []
    for ch in text:
        name = cmap.get(ord(ch)) or ".notdef"
        widths.append(hmtx[name][0])
    return widths


def text_path(
    text: str,
    font_path: str,
    size: float,
    color: str,
    x: float,
    y: float,
    anchor: str = "start",
) -> str:
    """Render ``text`` as glyph outlines, baseline at (x, y)."""
    font = _font(font_path)
    upem = font["head"].unitsPerEm
    scale = size / upem
    gs = font.getGlyphSet()
    cmap = font.getBestCmap()
    advances = _advances(text, font)
    total = sum(advances) * scale
    if anchor == "middle":
        x0 = -total / 2.0
    elif anchor == "end":
        x0 = -total
    else:
        x0 = 0.0

    pen = SVGPathPen(gs)
    cursor = x0
    for ch, advance in zip(text, advances):
        name = cmap.get(ord(ch)) or ".notdef"
        transform = Transform(scale, 0, 0, -scale, cursor, 0)
        gs[name].draw(TransformPen(pen, transform))
        cursor += advance * scale
    d = pen.getCommands()
    return f'<g transform="translate({x:.2f},{y:.2f})"><path fill="{color}" d="{d}"/></g>'


# ---- Shape helpers --------------------------------------------------------
def _arrowhead(ex: float, ey: float, dx: float, dy: float, color: str) -> str:
    import math

    norm = math.hypot(dx, dy)
    ux, uy = dx / norm, dy / norm
    px, py = -uy, ux
    size = 10.0
    half = 4.5
    tip = (ex, ey)
    bx = ex - ux * size
    by = ey - uy * size
    c1 = (bx + px * half, by + py * half)
    c2 = (bx - px * half, by - py * half)
    return (
        f'<polygon points="{tip[0]:.2f},{tip[1]:.2f} '
        f'{c1[0]:.2f},{c1[1]:.2f} {c2[0]:.2f},{c2[1]:.2f}" fill="{color}"/>'
    )


def _polyline(points: list[tuple[float, float]], color: str, arrow: bool) -> str:
    pts = " ".join(f"{x:.2f},{y:.2f}" for x, y in points)
    out = [f'<polyline points="{pts}" fill="none" stroke="{color}" stroke-width="2"/>']
    if arrow and len(points) >= 2:
        (x1, y1), (x2, y2) = points[-2], points[-1]
        out.append(_arrowhead(x2, y2, x2 - x1, y2 - y1, color))
    return "\n".join(out)


def _node(x: float, y: float, w: float, h: float, kind: str, title: str,
          subtitle: str, path: str, signals: str) -> list[str]:
    fill, stroke = KIND_STYLE[kind]
    out = [
        f'<rect x="{x:.2f}" y="{y:.2f}" width="{w:.2f}" height="{h:.2f}" '
        f'rx="8" fill="{fill}" stroke="{stroke}" stroke-width="2"/>',
        text_path(title, SANS_BOLD_FONT, 17, TITLE_FG, x + 16, y + 30),
        text_path(subtitle, SANS_FONT, 12, SUBTITLE_FG, x + 16, y + 56),
    ]
    if kind == "bus":
        out.append(text_path(signals, SANS_FONT, 12, SUBTITLE_FG, x + 16, y + 70))
        out.append(text_path(path, MONO_FONT, 11, PATH_FG, x + 16, y + 84))
    else:
        out.append(text_path(path, MONO_FONT, 11, PATH_FG, x + 16, y + 78))
    return out


def main() -> None:
    parts: list[str] = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{CANVAS_W}" '
        f'height="{CANVAS_H}" viewBox="0 0 {CANVAS_W} {CANVAS_H}">',
        f'<rect width="{CANVAS_W}" height="{CANVAS_H}" fill="{BG}"/>',
        text_path(TITLE, SANS_BOLD_FONT, 30, TITLE_FG, CANVAS_W / 2, 46, "middle"),
        text_path(SUBTITLE, SANS_FONT, 15, SUBTITLE_FG, CANVAS_W / 2, 74, "middle"),
    ]

    # Legend.
    lx = 40
    for kind, label in LEGEND:
        fill, stroke = KIND_STYLE[kind]
        parts.append(
            f'<rect x="{lx}" y="88" width="16" height="16" rx="3" '
            f'fill="{fill}" stroke="{stroke}" stroke-width="1"/>'
        )
        parts.append(text_path(label, SANS_FONT, 13, SUBTITLE_FG, lx + 24, 101))
        lx += 24 + _text_width(label, SANS_FONT, 13) + 28

    # Nodes.
    for x, y, w, h, kind, title, subtitle, path in NODES:
        signals = BUS_SIGNALS if kind == "bus" else ""
        parts.extend(_node(x, y, w, h, kind, title, subtitle, path, signals))

    # Edges.
    for points, label, label_pos, anchor in EDGES:
        parts.append(_polyline(points, EDGE, arrow=True))
        parts.append(text_path(label, SANS_FONT, 12, LABEL_FG,
                               label_pos[0], label_pos[1], anchor))

    # arena -> services bus.
    parts.append(_polyline(ARENA_TRUNK, EDGE, arrow=False))
    parts.append(_polyline(ARENA_RAIL, EDGE, arrow=False))
    for drop_x, drop_y in ARENA_DROPS:
        parts.append(_polyline([(drop_x, 790), (drop_x, drop_y)], EDGE, arrow=True))
    parts.append(text_path(ARENA_LABEL[0], SANS_FONT, 12, LABEL_FG,
                           ARENA_LABEL[1][0], ARENA_LABEL[1][1], ARENA_LABEL[2]))

    parts.append("</svg>")

    out_dir = os.path.dirname(OUT_PATH)
    os.makedirs(out_dir, exist_ok=True)
    with open(OUT_PATH, "w", encoding="utf-8") as handle:
        handle.write("\n".join(parts) + "\n")
    print(f"wrote {OUT_PATH}")


def _text_width(text: str, font_path: str, size: float) -> float:
    font = _font(font_path)
    return sum(_advances(text, font)) * (size / font["head"].unitsPerEm)


if __name__ == "__main__":
    main()
