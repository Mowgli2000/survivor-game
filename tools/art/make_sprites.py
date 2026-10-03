"""Draws the game's characters and enemies as smooth cartoon SVG frames.

Style (docs/superpowers/specs/2026-10-03-passe-artistique-cartoon-design.md):
chibi proportions (big head, small body, stubby limbs), thick dark outline,
flat fill + one soft shadow + one highlight, one neon accent per character.
Every sprite faces right; the game mirrors it.

Each sprite is a small rig (shadow, legs, body, arms, head, accessories) posed
per frame: "idle" (6 frames, breathing) and "walk" (8 frames, legs and arms
swinging, bounce). Flyers only have "walk" (wing flaps).
Output: assets_src/drawn/<id>/<anim>_<i>.svg, then tools/bake_sprites.ps1
rasterizes them into the atlas.
Usage: python tools/art/make_sprites.py
"""
import math
import os

ROOT = os.path.join(os.path.dirname(__file__), "..", "..", "assets_src", "drawn")
SIZE = 256
GROUND = 236  # feet line
INK = "#1b1026"
STROKE = 7

ANIMS = {"idle": 6, "walk": 8}
FLY_ANIMS = {"walk": 6}


# --------------------------------------------------------------------------- colors

def _rgb(hex_color):
    h = hex_color.lstrip("#")
    return [int(h[i:i + 2], 16) for i in (0, 2, 4)]


def _hex(rgb):
    return "#" + "".join("%02x" % max(0, min(255, int(round(c)))) for c in rgb)


def shade(hex_color, amount):
    """amount < 0 darkens toward ink-violet, > 0 lightens toward white."""
    r = _rgb(hex_color)
    if amount < 0:
        target = [40, 20, 60]
        t = -amount
    else:
        target = [255, 255, 255]
        t = amount
    return _hex([c + (tc - c) * t for c, tc in zip(r, target)])


# --------------------------------------------------------------------------- primitives

class Svg:
    def __init__(self):
        self.defs = []
        self.parts = []
        self._id = 0

    def uid(self, prefix):
        self._id += 1
        return "%s%d" % (prefix, self._id)

    def add(self, s):
        self.parts.append(s)

    def text(self):
        return ('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">\n'
                '<defs>%s</defs>\n%s\n</svg>\n' % (SIZE, SIZE, SIZE, SIZE, "".join(self.defs), "\n".join(self.parts)))


def outline(width=STROKE):
    return 'stroke="%s" stroke-width="%s" stroke-linejoin="round" stroke-linecap="round"' % (INK, width)


def shaded(svg, shape, color, light=(0.35, -0.45), shadow=True, highlight=True, width=STROKE):
    """A filled shape with a soft lower shadow and an upper highlight, clipped
    to the shape, then outlined. `shape` is an SVG element without fill/stroke
    attributes, e.g. '<ellipse cx=".." cy=".." rx=".." ry=".."/>'."""
    cid = svg.uid("c")
    inner = shape.replace("/>", " />")
    svg.defs.append('<clipPath id="%s">%s</clipPath>' % (cid, inner))
    out = [shape.replace("/>", ' fill="%s"/>' % color)]
    if shadow:
        out.append('<g clip-path="url(#%s)"><rect x="0" y="0" width="%d" height="%d" fill="%s" opacity="0.0"/>'
                   '%s</g>' % (cid, SIZE, SIZE, color, _shadow_band(shape, shade(color, -0.35))))
    if highlight:
        out.append('<g clip-path="url(#%s)">%s</g>' % (cid, _highlight(shape)))
    out.append(shape.replace("/>", ' fill="none" %s/>' % outline(width)))
    return "\n".join(out)


def _bbox(shape):
    """Rough bounding box of the primitives used here (ellipse, rect, circle, path via data-box)."""
    import re
    def num(name):
        m = re.search(r'\b%s="([-\d.]+)"' % name, shape)
        return float(m.group(1)) if m else None
    if shape.startswith("<ellipse") or shape.startswith("<circle"):
        cx, cy = num("cx"), num("cy")
        rx = num("rx") if num("rx") is not None else num("r")
        ry = num("ry") if num("ry") is not None else num("r")
        return cx - rx, cy - ry, cx + rx, cy + ry
    if shape.startswith("<rect"):
        x, y, w, h = num("x"), num("y"), num("width"), num("height")
        return x, y, x + w, y + h
    m = re.search(r'data-box="([-\d.]+) ([-\d.]+) ([-\d.]+) ([-\d.]+)"', shape)
    if m:
        return tuple(float(v) for v in m.groups())
    return 0, 0, SIZE, SIZE


def _shadow_band(shape, color):
    x0, y0, x1, y1 = _bbox(shape)
    w, h = x1 - x0, y1 - y0
    # Big ellipse offset down-left: covers the lower-left part of the shape.
    return '<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="%s"/>' % (
        x0 + w * 0.38, y1 + h * 0.18, w * 0.75, h * 0.55, color)


def _highlight(shape):
    x0, y0, x1, y1 = _bbox(shape)
    w, h = x1 - x0, y1 - y0
    return '<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="#ffffff" opacity="0.32"/>' % (
        x0 + w * 0.66, y0 + h * 0.26, w * 0.2, h * 0.12)


def ellipse(cx, cy, rx, ry):
    return '<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f"/>' % (cx, cy, rx, ry)


def rrect(x, y, w, h, r):
    return '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="%.1f"/>' % (x, y, w, h, r)


def path(d, box):
    return '<path d="%s" data-box="%.1f %.1f %.1f %.1f"/>' % (d, *box)


def group(content, tx=0.0, ty=0.0, rot=0.0, cx=0.0, cy=0.0, sx=1.0, sy=1.0):
    t = "translate(%.2f %.2f)" % (tx, ty)
    if rot:
        t += " rotate(%.2f %.2f %.2f)" % (rot, cx, cy)
    if sx != 1.0 or sy != 1.0:
        t += " translate(%.2f %.2f) scale(%.3f %.3f) translate(%.2f %.2f)" % (cx, cy, sx, sy, -cx, -cy)
    return '<g transform="%s">\n%s\n</g>' % (t, content)


def ground_shadow(svg, rx=58, ry=12):
    svg.add('<ellipse cx="128" cy="%d" rx="%d" ry="%d" fill="#000000" opacity="0.28"/>' % (GROUND, rx, ry))


# --------------------------------------------------------------------------- poses

def pose(anim, i, frames):
    """Common motion values for a frame."""
    t = i / frames
    if anim == "idle":
        breath = math.sin(t * math.tau)
        return {"bob": breath * 2.5, "squash": 1.0 + breath * 0.025, "leg": 0.0, "arm": breath * 4.0,
                "t": t, "walking": False}
    swing = math.sin(t * math.tau)
    return {"bob": -abs(math.sin(t * math.tau)) * 6.0, "squash": 1.0, "leg": swing * 26.0, "arm": -swing * 30.0,
            "t": t, "walking": True}


# --------------------------------------------------------------------------- biped rig

def biped(svg, p, look):
    """Chibi biped. `look` keys: skin, top, top2, legs, accent, scale (body size),
    head_r, and optional callables: back(svg, p), head_back(svg, hx, hy),
    head_front(svg, hx, hy), face(svg, hx, hy), body_front(svg, bx, by),
    front_hand(svg, x, y) replacing the front hand."""
    s = look.get("scale", 1.0)
    ground_shadow(svg, 52 * s, 11 * s)
    hip_y = GROUND - 30 * s
    bob = p["bob"]
    # Back leg, back arm, (back items), body, front leg, front arm, head.
    leg_w, leg_h = 22 * s, 34 * s

    def leg(angle, x, color):
        content = shaded(svg, rrect(x - leg_w / 2, hip_y - 4, leg_w, leg_h, 9 * s), color)
        foot = shaded(svg, ellipse(x + 5 * s, hip_y + leg_h - 4, 15 * s, 8 * s), shade(color, -0.25),
                      highlight=False)
        return group(content + "\n" + foot, rot=angle, cx=x, cy=hip_y)

    svg.add(leg(-p["leg"], 116, shade(look["legs"], -0.15)))
    if "back" in look:
        look["back"](svg, p, bob)
    body_w, body_h = 74 * s * look.get("body_width", 1.0), 58 * s
    bx, by = 128, hip_y - body_h / 2 + 6 + bob
    # Back arm.
    arm_len = 34 * s
    shoulder_y = by - body_h * 0.18
    svg.add(group(shaded(svg, rrect(128 - 30 * s - 9 * s, shoulder_y, 18 * s, arm_len, 9 * s),
                         shade(look["top"], -0.2)), rot=p["arm"], cx=128 - 30 * s, cy=shoulder_y + 4))
    svg.add(leg(p["leg"], 142, look["legs"]))
    body = shaded(svg, rrect(bx - body_w / 2, by - body_h / 2, body_w, body_h, 26 * s), look["top"])
    svg.add(group(body, sx=1.0 / p["squash"] ** 0.5, sy=p["squash"], cx=bx, cy=by + body_h / 2))
    if "body_front" in look:
        look["body_front"](svg, bx, by, s)
    # Front arm (+ hand item).
    arm = shaded(svg, rrect(128 + 26 * s - 9 * s, shoulder_y, 18 * s, arm_len, 9 * s), look["top2"])
    hand = shaded(svg, ellipse(128 + 26 * s, shoulder_y + arm_len, 10 * s, 10 * s), look["skin"], highlight=False)
    extra = look["front_hand"](svg, 128 + 26 * s, shoulder_y + arm_len) if "front_hand" in look else ""
    svg.add(group(arm + "\n" + hand + "\n" + extra, rot=-p["arm"] * 0.8, cx=128 + 26 * s, cy=shoulder_y + 4))
    # Head.
    hr = look.get("head_r", 54) * s
    hx, hy = 132, by - body_h / 2 - hr * 0.78 + bob * 0.6
    if "head_back" in look:
        look["head_back"](svg, hx, hy, hr)
    svg.add(shaded(svg, ellipse(hx, hy, hr, hr * 0.92), look.get("head_color", look["skin"])))
    if "face" in look:
        look["face"](svg, hx, hy, hr)
    else:
        eyes(svg, hx, hy, hr)
    if "head_front" in look:
        look["head_front"](svg, hx, hy, hr)


def eyes(svg, hx, hy, hr, color="#ffffff", pupil=INK, glow=None, angry=False, y_off=0.08):
    """Two big cartoon eyes looking right."""
    for k, (dx, size) in enumerate(((0.12, 0.2), (0.5, 0.17))):
        ex, ey = hx + hr * dx, hy + hr * y_off
        rx, ry = hr * size * 0.8, hr * size
        svg.add('<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="%s" %s/>' % (ex, ey, rx, ry, color, outline(4)))
        svg.add('<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="%s"/>' % (ex + rx * 0.3, ey + ry * 0.1, rx * 0.55, ry * 0.62, glow or pupil))
        svg.add('<circle cx="%.1f" cy="%.1f" r="%.1f" fill="#ffffff"/>' % (ex + rx * 0.45, ey - ry * 0.3, rx * 0.25))
        if angry:
            svg.add('<path d="M %.1f %.1f L %.1f %.1f" %s/>' % (ex - rx * 1.1, ey - ry * 1.25 - (4 if k == 0 else 0),
                                                              ex + rx * 1.1, ey - ry * 0.85, outline(6)))


def mouth(svg, hx, hy, hr, kind="smile"):
    x, y = hx + hr * 0.32, hy + hr * 0.5
    if kind == "smile":
        svg.add('<path d="M %.1f %.1f q %.1f %.1f %.1f 0" fill="none" %s/>' % (x - 8, y, 8, 7, 16, outline(4)))
    elif kind == "grin":
        svg.add('<path d="M %.1f %.1f q %.1f %.1f %.1f 0 z" fill="#ffffff" %s/>' % (x - 12, y - 2, 12, 14, 24, outline(4)))
    elif kind == "flat":
        svg.add('<path d="M %.1f %.1f h 14" %s/>' % (x - 6, y, outline(4)))


# --------------------------------------------------------------------------- playable characters

def drifter(svg, p):
    cyan = "#33e6ff"

    def back(svg, p, bob):
        wave = math.sin(p["t"] * math.tau * 2) * 6
        svg.add(shaded(svg, path("M 104 %.1f q -30 %.1f -50 %.1f l 6 14 q 26 0 50 -8 z" % (150 + bob, -4 + wave, 8 + wave),
                                  (50, 140, 110, 175)), cyan, highlight=False))

    def head_front(svg, hx, hy, hr):
        # Hood rim and neon visor.
        svg.add(shaded(svg, path("M %.1f %.1f q %.1f %.1f %.1f 0 l 0 %.1f q %.1f %.1f %.1f 0 z" % (
            hx - hr, hy - hr * 0.05, hr, -hr * 1.35, hr * 2, -hr * 0.0, -hr, -hr * 1.0, -hr * 2),
            (hx - hr, hy - hr * 0.95, hx + hr, hy)), "#2a3550"))
        svg.add('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="%.1f" fill="%s" opacity="0.92" %s/>' % (
            hx - hr * 0.15, hy - hr * 0.12, hr * 1.05, hr * 0.38, hr * 0.18, cyan, outline(5)))
        svg.add('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="3" fill="#ffffff" opacity="0.7"/>' % (
            hx + hr * 0.2, hy - hr * 0.06, hr * 0.5, hr * 0.08))
        mouth(svg, hx, hy, hr, "smile")

    biped(svg, p, {"skin": "#ffd7b5", "top": "#2a3550", "top2": "#334166", "legs": "#1f2840", "accent": cyan,
                   "back": back, "head_front": head_front, "face": lambda *a: None})


def ronin_pc(svg, p):
    magenta = "#ff40c8"

    def back(svg, p, bob):
        # Katana across the back.
        svg.add(group('<rect x="60" y="120" width="120" height="10" rx="5" fill="#e8e8f4" %s/>'
                      '<rect x="150" y="116" width="38" height="18" rx="6" fill="#3a2440" %s/>' % (outline(5), outline(5)),
                      ty=bob, rot=-32, cx=128, cy=150))

    def body_front(svg, bx, by, s):
        svg.add('<path d="M %.1f %.1f l 14 22 l 14 -22" fill="#ffffff" %s/>' % (bx - 6, by - 26 * s, outline(4)))
        svg.add('<rect x="%.1f" y="%.1f" width="%.1f" height="12" rx="4" fill="#3a2440" %s/>' % (
            bx - 37 * s, by + 4, 74 * s, outline(4)))

    def head_back(svg, hx, hy, hr):
        svg.add(shaded(svg, ellipse(hx - hr * 0.35, hy - hr * 0.95, hr * 0.3, hr * 0.26), "#251733"))

    def head_front(svg, hx, hy, hr):
        svg.add(shaded(svg, path("M %.1f %.1f q %.1f %.1f %.1f %.1f q %.1f %.1f %.1f %.1f z" % (
            hx - hr, hy, hr * 0.2, -hr * 1.2, hr * 1.5, -hr * 0.8, hr * 0.4, hr * 0.2, hr * 0.5, hr * 0.4),
            (hx - hr, hy - hr, hx + hr, hy)), "#251733", highlight=True))
        svg.add('<rect x="%.1f" y="%.1f" width="%.1f" height="9" rx="4" fill="%s" %s/>' % (
            hx - hr * 0.9, hy - hr * 0.42, hr * 1.7, magenta, outline(4)))
        eyes(svg, hx, hy, hr, angry=True, y_off=0.12)
        mouth(svg, hx, hy, hr, "flat")

    biped(svg, p, {"skin": "#ffd2b0", "top": magenta, "top2": shade(magenta, 0.1), "legs": "#3a2440", "accent": magenta,
                   "back": back, "body_front": body_front, "head_back": head_back, "head_front": head_front,
                   "face": lambda *a: None})


def gunslinger(svg, p):
    green = "#4dff73"
    poncho = "#3c8a4a"

    def body_front(svg, bx, by, s):
        svg.add(shaded(svg, path("M %.1f %.1f L %.1f %.1f L %.1f %.1f z" % (
            bx - 46 * s, by - 18, bx + 46 * s, by - 18, bx, by + 34 * s), (bx - 46 * s, by - 18, bx + 46 * s, by + 34 * s)),
            poncho))
        for k in range(3):
            svg.add('<path d="M %.1f %.1f h 12" stroke="%s" stroke-width="5" stroke-linecap="round"/>' % (
                bx - 20 + k * 14, by - 6 + k * 6, green))

    def head_front(svg, hx, hy, hr):
        eyes(svg, hx, hy, hr, y_off=0.0)
        svg.add(shaded(svg, path("M %.1f %.1f q %.1f %.1f %.1f 0 l 0 %.1f q %.1f %.1f %.1f 0 z" % (
            hx - hr * 0.7, hy + hr * 0.3, hr * 0.85, hr * 0.5, hr * 1.7, hr * 0.15, -hr * 0.85, hr * 0.55, -hr * 1.7),
            (hx - hr * 0.7, hy + hr * 0.25, hx + hr, hy + hr * 0.9)), "#d94040", highlight=False))
        svg.add(shaded(svg, ellipse(hx, hy - hr * 0.62, hr * 1.45, hr * 0.28), "#6b4a2e"))
        svg.add(shaded(svg, rrect(hx - hr * 0.62, hy - hr * 1.32, hr * 1.24, hr * 0.78, hr * 0.3), "#7a5636"))
        svg.add('<rect x="%.1f" y="%.1f" width="%.1f" height="8" fill="%s"/>' % (hx - hr * 0.62, hy - hr * 0.8, hr * 1.24, green))

    def front_hand(svg, x, y):
        return ('<g transform="rotate(-80 %.1f %.1f)"><rect x="%.1f" y="%.1f" width="34" height="13" rx="4" fill="#d9d9e6" %s/>'
                '<rect x="%.1f" y="%.1f" width="10" height="18" rx="3" fill="#6b4a2e" %s/></g>' % (
                    x, y, x - 4, y - 6, outline(4), x - 2, y + 2, outline(4)))

    biped(svg, p, {"skin": "#e8b48c", "top": poncho, "top2": shade(poncho, 0.1), "legs": "#4a3a2a", "accent": green,
                   "body_front": body_front, "head_front": head_front, "face": lambda *a: None})


def merchant(svg, p):
    gold = "#ffd24d"

    def back(svg, p, bob):
        for k, (dx, dy, w) in enumerate(((62, 108, 44), (66, 72, 38), (70, 44, 30))):
            svg.add(group(shaded(svg, rrect(dx, dy, w, w * 0.8, 6), "#a8743e" if k % 2 == 0 else "#c28a4c"), ty=bob))
            svg.add(group('<path d="M %d %d l %d %d" %s/>' % (dx + 4, dy + 4, w - 8, w * 0.8 - 8, outline(3)), ty=bob))

    def body_front(svg, bx, by, s):
        svg.add('<rect x="%.1f" y="%.1f" width="%.1f" height="10" rx="4" fill="%s" %s/>' % (
            bx - 42 * s, by + 2, 84 * s, gold, outline(4)))
        svg.add('<circle cx="%.1f" cy="%.1f" r="9" fill="%s" %s/>' % (bx + 14, by + 7, "#fff1a8", outline(4)))

    def head_front(svg, hx, hy, hr):
        eyes(svg, hx, hy, hr, y_off=0.12)
        mouth(svg, hx, hy, hr, "grin")
        svg.add(shaded(svg, ellipse(hx - hr * 0.05, hy - hr * 0.6, hr * 1.1, hr * 0.32), "#8a5a2a"))
        svg.add(shaded(svg, ellipse(hx - hr * 0.05, hy - hr * 0.86, hr * 0.62, hr * 0.42), gold))
        svg.add('<circle cx="%.1f" cy="%.1f" r="7" fill="#ff5a3c" %s/>' % (hx - hr * 0.05, hy - hr * 1.25, outline(4)))

    biped(svg, p, {"skin": "#ffd2b0", "top": "#c9973a", "top2": shade("#c9973a", 0.1), "legs": "#6b4a2e",
                   "accent": gold, "back": back, "body_front": body_front, "head_front": head_front,
                   "face": lambda *a: None, "body_width": 1.18})


# --------------------------------------------------------------------------- enemies

def grunt(svg, p):
    red = "#e04a4a"

    def head_back(svg, hx, hy, hr):
        for dx in (-0.55, 0.45):
            svg.add(shaded(svg, path("M %.1f %.1f q %.1f %.1f %.1f %.1f z" % (
                hx + hr * dx, hy - hr * 0.72, hr * 0.12, -hr * 0.75, hr * 0.36, hr * 0.02),
                (hx + hr * dx, hy - hr * 1.45, hx + hr * (dx + 0.36), hy - hr * 0.7)), "#fff0d0", highlight=False))

    def face(svg, hx, hy, hr):
        svg.add(shaded(svg, ellipse(hx + hr * 0.3, hy + hr * 0.12, hr * 0.62, hr * 0.55), "#f4f0ea"))
        eyes(svg, hx + hr * 0.02, hy, hr * 0.9, color="#ffe066", pupil=INK, angry=True)
        svg.add('<path d="M %.1f %.1f l 6 8 l 6 -8 l 6 8 l 6 -8" fill="none" %s/>' % (
            hx + hr * 0.1, hy + hr * 0.45, outline(4)))
        svg.add('<path d="M %.1f %.1f q 10 -6 20 0" stroke="%s" stroke-width="5" fill="none"/>' % (
            hx + hr * 0.05, hy - hr * 0.3, red))

    biped(svg, p, {"skin": red, "top": "#7a2a3a", "top2": "#8c3446", "legs": "#4a1c2a", "accent": "#ff5a5a",
                   "head_front": head_back, "face": face, "scale": 0.9})


def shooter(svg, p):
    purple = "#a24dff"

    def face(svg, hx, hy, hr):
        eyes(svg, hx - hr * 0.05, hy - hr * 0.05, hr * 0.85, color="#f0e0ff", glow="#ff3cc8", angry=True)
        svg.add(shaded(svg, path("M %.1f %.1f q %.1f %.1f %.1f %.1f q %.1f %.1f %.1f %.1f z" % (
            hx + hr * 0.6, hy + hr * 0.05, hr * 0.6, hr * 0.02, hr * 0.95, hr * 0.32, -hr * 0.4, hr * 0.15, -hr * 0.95, hr * 0.12),
            (hx + hr * 0.6, hy, hx + hr * 1.55, hy + hr * 0.4)), "#ff5a3c"))

    def head_front(svg, hx, hy, hr):
        svg.add(shaded(svg, path("M %.1f %.1f l %.1f %.1f l %.1f %.1f z" % (
            hx - hr * 0.5, hy - hr * 0.75, hr * 0.5, -hr * 0.55, hr * 0.4, hr * 0.5),
            (hx - hr * 0.5, hy - hr * 1.3, hx + hr * 0.4, hy - hr * 0.75)), "#3a1f5a", highlight=False))

    def front_hand(svg, x, y):
        return ('<g transform="rotate(-20 %.1f %.1f)"><rect x="%.1f" y="%.1f" width="46" height="22" rx="8" fill="#4a3a66" %s/>'
                '<circle cx="%.1f" cy="%.1f" r="8" fill="#ff3cc8" %s/></g>' % (x, y, x - 8, y - 11, outline(4), x + 38, y, outline(3)))

    biped(svg, p, {"skin": "#d9b3ff", "top": purple, "top2": shade(purple, 0.1), "legs": "#3a1f5a", "accent": purple,
                   "face": face, "head_front": head_front, "front_hand": front_hand, "head_r": 48})


def tank(svg, p):
    rust = "#c8643a"

    def body_front(svg, bx, by, s):
        for k in range(3):
            svg.add('<rect x="%.1f" y="%.1f" width="%.1f" height="9" rx="3" fill="%s" %s/>' % (
                bx - 30 * s, by - 18 * s + k * 15 * s, 60 * s, shade(rust, -0.2), outline(3)))
        svg.add('<circle cx="%.1f" cy="%.1f" r="%.1f" fill="#ffb347" %s/>' % (bx + 4, by - 2, 9 * s, outline(4)))

    def face(svg, hx, hy, hr):
        svg.add('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="6" fill="%s" %s/>' % (
            hx - hr * 0.1, hy - hr * 0.1, hr * 1.0, hr * 0.32, INK, outline(4)))
        for dx in (0.15, 0.55):
            svg.add('<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="#ffb347"/>' % (
                hx + hr * dx, hy + hr * 0.06, hr * 0.12, hr * 0.08))

    biped(svg, p, {"skin": "#8a6a5a", "head_color": shade(rust, -0.1), "top": rust, "top2": shade(rust, 0.1),
                   "legs": "#5a3a2a", "accent": "#ff7a3c", "body_front": body_front, "face": face, "scale": 1.15,
                   "head_r": 40, "body_width": 1.35})


def ronin_boss(svg, p):
    cyan = "#4df2ff"

    def back(svg, p, bob):
        wave = math.sin(p["t"] * math.tau) * 5
        svg.add(shaded(svg, path("M 100 %.1f q -36 30 -30 %.1f l 40 -10 z" % (140 + bob, 80 + wave),
                                  (66, 135, 110, 225)), "#1c4a5a", highlight=False))

    def face(svg, hx, hy, hr):
        svg.add(shaded(svg, path("M %.1f %.1f q %.1f %.1f %.1f 0 l 0 %.1f q %.1f %.1f %.1f 0 z" % (
            hx - hr * 0.6, hy + hr * 0.02, hr * 0.95, -hr * 0.1, hr * 1.55, hr * 0.42, -hr * 0.8, hr * 0.45, -hr * 1.55),
            (hx - hr * 0.6, hy - hr * 0.1, hx + hr * 0.95, hy + hr * 0.85)), "#2a2f3a"))
        for dx in (0.18, 0.55):
            svg.add('<path d="M %.1f %.1f l %.1f %.1f" stroke="%s" stroke-width="7" stroke-linecap="round"/>' % (
                hx + hr * dx - 6, hy - hr * 0.12, 14, 4, cyan))

    def head_front(svg, hx, hy, hr):
        svg.add(shaded(svg, path("M %.1f %.1f L %.1f %.1f L %.1f %.1f q %.1f %.1f %.1f 0 z" % (
            hx - hr * 1.6, hy - hr * 0.3, hx, hy - hr * 1.3, hx + hr * 1.6, hy - hr * 0.3, -hr * 1.6, hr * 0.25, -hr * 3.2),
            (hx - hr * 1.6, hy - hr * 1.3, hx + hr * 1.6, hy - hr * 0.1)), "#d9b46a"))
        svg.add('<path d="M %.1f %.1f L %.1f %.1f" stroke="%s" stroke-width="4"/>' % (
            hx - hr * 0.8, hy - hr * 0.8, hx + hr * 0.8, hy - hr * 0.8, shade("#d9b46a", -0.3)))

    def front_hand(svg, x, y):
        return ('<g transform="rotate(-60 %.1f %.1f)"><rect x="%.1f" y="%.1f" width="90" height="10" rx="5" fill="#e8f8ff" %s/>'
                '<rect x="%.1f" y="%.1f" width="22" height="14" rx="4" fill="#1c4a5a" %s/></g>' % (
                    x, y, x, y - 5, outline(4), x - 14, y - 7, outline(4)))

    biped(svg, p, {"skin": "#ffd2b0", "top": "#2a7a8c", "top2": "#33909f", "legs": "#1c3a44", "accent": cyan,
                   "back": back, "face": face, "head_front": head_front, "front_hand": front_hand, "scale": 1.1,
                   "head_r": 46})


def shogun(svg, p):
    magenta = "#ff33b8"
    gold = "#ffd24d"

    def body_front(svg, bx, by, s):
        for side in (-1, 1):
            svg.add(shaded(svg, rrect(bx + side * 36 * s - 16 * s, by - 32 * s, 32 * s, 26 * s, 8), shade(magenta, -0.25)))
        for k in range(3):
            svg.add('<rect x="%.1f" y="%.1f" width="%.1f" height="8" rx="3" fill="%s" %s/>' % (
                bx - 28 * s, by - 10 * s + k * 13 * s, 56 * s, gold, outline(3)))

    def face(svg, hx, hy, hr):
        svg.add(shaded(svg, ellipse(hx + hr * 0.25, hy + hr * 0.18, hr * 0.72, hr * 0.62), "#2a1a2f"))
        for dx in (0.05, 0.5):
            svg.add('<path d="M %.1f %.1f l %.1f %.1f" stroke="%s" stroke-width="8" stroke-linecap="round"/>' % (
                hx + hr * dx - 4, hy - hr * 0.02, 16, 6, magenta))
        svg.add('<path d="M %.1f %.1f l 6 7 l 6 -7 l 6 7 l 6 -7 l 6 7" fill="none" stroke="%s" stroke-width="4"/>' % (
            hx + hr * 0.0, hy + hr * 0.45, gold))

    def head_front(svg, hx, hy, hr):
        svg.add(shaded(svg, path("M %.1f %.1f q %.1f %.1f %.1f 0 l %.1f %.1f l %.1f 0 z" % (
            hx - hr * 1.05, hy - hr * 0.2, hr * 1.05, -hr * 1.3, hr * 2.1, hr * 0.15, hr * 0.15, -hr * 2.4),
            (hx - hr * 1.2, hy - hr * 1.0, hx + hr * 1.2, hy)), shade(magenta, -0.3)))
        svg.add(shaded(svg, path("M %.1f %.1f q %.1f %.1f %.1f %.1f q %.1f %.1f %.1f %.1f z" % (
            hx, hy - hr * 0.7, -hr * 0.9, -hr * 0.35, -hr * 0.95, -hr * 1.25, hr * 0.35, hr * 0.7, hr * 0.95, hr * 0.85),
            (hx - hr * 0.95, hy - hr * 1.95, hx, hy - hr * 0.7)), gold))
        svg.add(shaded(svg, path("M %.1f %.1f q %.1f %.1f %.1f %.1f q %.1f %.1f %.1f %.1f z" % (
            hx, hy - hr * 0.7, hr * 0.9, -hr * 0.35, hr * 0.95, -hr * 1.25, -hr * 0.35, hr * 0.7, -hr * 0.95, hr * 0.85),
            (hx, hy - hr * 1.95, hx + hr * 0.95, hy - hr * 0.7)), gold))
        svg.add('<circle cx="%.1f" cy="%.1f" r="%.1f" fill="%s" %s/>' % (hx, hy - hr * 0.72, hr * 0.16, magenta, outline(4)))

    biped(svg, p, {"skin": "#5a3a5a", "head_color": shade(magenta, -0.15), "top": shade(magenta, -0.1),
                   "top2": magenta, "legs": "#3a1a3a", "accent": magenta, "body_front": body_front, "face": face,
                   "head_front": head_front, "scale": 1.2, "head_r": 46, "body_width": 1.25})


def runner(svg, p):
    """Bat drone: round orange body, one big eye, flapping wings (flyer)."""
    orange = "#ff9a3c"
    t = p["t"]
    flap = math.sin(t * math.tau) * 34
    hover = math.sin(t * math.tau) * 6
    ground_shadow(svg, 40, 9)
    cy = 140 + hover
    for side, rot in ((-1, flap), (1, -flap)):
        wing = shaded(svg, path("M 128 %.1f q %.1f -50 %.1f -18 q %.1f 10 %.1f 30 q %.1f -10 %.1f 6 z" % (
            cy, side * 40, side * 82, -side * 10, -side * 16, -side * 22, -side * 44),
            (min(128, 128 + side * 82), cy - 50, max(128, 128 + side * 82), cy + 12)), "#5a2a1f", highlight=False)
        svg.add(group(wing, rot=rot * side * -1, cx=128, cy=cy))
    svg.add(shaded(svg, ellipse(128, cy, 40, 36), orange))
    svg.add('<ellipse cx="140" cy="%.1f" rx="16" ry="18" fill="#ffffff" %s/>' % (cy - 2, outline(4)))
    svg.add('<ellipse cx="145" cy="%.1f" rx="8" ry="10" fill="%s"/>' % (cy, INK))
    svg.add('<circle cx="148" cy="%.1f" r="3" fill="#ffffff"/>' % (cy - 5))
    for dx in (-14, 0):
        svg.add('<path d="M %.1f %.1f l 4 10 l 4 -10" fill="#ffffff" %s/>' % (128 + dx, cy + 26, outline(3)))
    for dx in (-22, -8):
        svg.add('<path d="M %.1f %.1f l -6 -16 l 12 8 z" fill="%s" %s/>' % (128 + dx, cy - 30, orange, outline(4)))


def kamikaze(svg, p):
    """Walking bomb with a lit fuse."""
    t = p["t"]
    hop = -abs(math.sin(t * math.tau)) * 10 if p["walking"] else math.sin(t * math.tau) * 2
    ground_shadow(svg, 40, 10)
    cy = 178 + hop
    for side, k in ((-1, 0), (1, 1)):
        angle = (p["leg"] if k else -p["leg"]) * 0.8
        svg.add(group(shaded(svg, ellipse(128 + side * 18, GROUND - 6, 14, 8), "#3a2a2a", highlight=False),
                      rot=angle, cx=128 + side * 18, cy=GROUND - 30))
    svg.add(shaded(svg, ellipse(128, cy, 48, 46), "#3a3048"))
    svg.add('<rect x="114" y="%.1f" width="28" height="16" rx="5" fill="#7a7a8c" %s/>' % (cy - 58, outline(4)))
    fuse_y = cy - 60
    svg.add('<path d="M 128 %.1f q 6 -18 22 -22" fill="none" stroke="#c8a66a" stroke-width="6" stroke-linecap="round"/>' % fuse_y)
    spark = 10 + math.sin(t * math.tau * 3) * 4
    svg.add('<circle cx="150" cy="%.1f" r="%.1f" fill="#ffd24d" opacity="0.9"/>' % (fuse_y - 22, spark))
    svg.add('<circle cx="150" cy="%.1f" r="%.1f" fill="#ff7a3c"/>' % (fuse_y - 22, spark * 0.5))
    svg.add('<path d="M 96 %.1f q 32 -10 64 0" stroke="#ff9a3c" stroke-width="6" fill="none"/>' % (cy + 14))
    eyes(svg, 124, cy - 6, 40, color="#ffe066", angry=True)


def charger(svg, p):
    """Robot boar on four stubby legs, horn and tusks."""
    red = "#e6463c"
    t = p["t"]
    bob = -abs(math.sin(t * math.tau)) * 5 if p["walking"] else math.sin(t * math.tau) * 1.5
    ground_shadow(svg, 70, 12)
    body_y = 176 + bob
    for k, x in enumerate((92, 112, 146, 166)):
        swing = p["leg"] * (1 if k % 2 == 0 else -1) * 0.8
        color = shade("#5a2a2a", -0.1 if k in (0, 2) else 0.0)
        svg.add(group(shaded(svg, rrect(x - 9, body_y + 10, 18, 40, 8), color, highlight=False), rot=swing, cx=x, cy=body_y + 14))
    svg.add(shaded(svg, ellipse(126, body_y, 64, 40), red))
    for k in range(4):
        svg.add('<path d="M %.1f %.1f l 8 -18 l 8 18 z" fill="#ff7a5a" %s/>' % (92 + k * 16, body_y - 34, outline(4)))
    svg.add(shaded(svg, ellipse(184, body_y + 2, 32, 28), shade(red, -0.1)))
    svg.add(shaded(svg, ellipse(206, body_y + 10, 16, 13), "#ffb0a0", highlight=False))
    svg.add('<path d="M 212 %.1f q 18 -26 8 -40 q -4 22 -18 30 z" fill="#f4f0ea" %s/>' % (body_y - 2, outline(4)))
    svg.add('<path d="M 196 %.1f q 6 14 16 12" fill="none" stroke="#f4f0ea" stroke-width="6" stroke-linecap="round"/>' % (body_y + 16))
    eyes(svg, 182, body_y - 8, 24, color="#ffe066", angry=True)


def spawner(svg, p):
    """Brood mother: glowing egg sac, small head, six legs."""
    green = "#4dff73"
    t = p["t"]
    bob = math.sin(t * math.tau * (2 if p["walking"] else 1)) * 3
    ground_shadow(svg, 74, 13)
    body_y = 160 + bob
    for k in range(3):
        for side in (-1, 1):
            base_x = 128 + (k - 1) * 26
            swing = p["leg"] * (1 if (k + (side > 0)) % 2 == 0 else -1) * 0.6
            d = "M %.1f %.1f q %.1f -40 %.1f 10 q -4 30 %.1f 36" % (base_x, body_y + 10, side * 40, side * 60, side * 0)
            leg = '<path d="%s" fill="none" stroke="%s" stroke-width="16" stroke-linecap="round" stroke-linejoin="round"/>' \
                  '<path d="%s" fill="none" stroke="#2a4a2f" stroke-width="8" stroke-linecap="round" stroke-linejoin="round"/>' % (d, INK, d)
            svg.add(group(leg, rot=swing, cx=base_x, cy=body_y + 10))
    svg.add(shaded(svg, ellipse(116, body_y - 6, 60, 50), "#3f8a4a"))
    for ex, ey, r in ((96, -18, 12), (120, -30, 10), (132, -4, 13), (104, 10, 9)):
        pulse = 0.65 + 0.35 * math.sin(t * math.tau + ex)
        svg.add('<circle cx="%.1f" cy="%.1f" r="%.1f" fill="%s" opacity="%.2f" %s/>' % (
            ex, body_y + ey, r, green, pulse, outline(3)))
    svg.add(shaded(svg, ellipse(176, body_y + 14, 28, 24), "#2f6a38"))
    eyes(svg, 172, body_y + 10, 24, color="#e0ffe6", glow="#ff3c5a", angry=True)


SPRITES = {
    "drifter": (drifter, ANIMS),
    "ronin_pc": (ronin_pc, ANIMS),
    "gunslinger": (gunslinger, ANIMS),
    "merchant": (merchant, ANIMS),
    "grunt": (grunt, ANIMS),
    "runner": (runner, FLY_ANIMS),
    "shooter": (shooter, ANIMS),
    "tank": (tank, ANIMS),
    "kamikaze": (kamikaze, ANIMS),
    "charger": (charger, ANIMS),
    "spawner": (spawner, ANIMS),
    "ronin_boss": (ronin_boss, ANIMS),
    "shogun": (shogun, ANIMS),
}


def main():
    count = 0
    for sprite_id, (draw, anims) in SPRITES.items():
        out = os.path.join(ROOT, sprite_id)
        os.makedirs(out, exist_ok=True)
        for anim, frames in anims.items():
            for i in range(frames):
                svg = Svg()
                draw(svg, pose(anim, i, frames))
                with open(os.path.join(out, "%s_%d.svg" % (anim, i)), "w", encoding="utf-8") as f:
                    f.write(svg.text())
                count += 1
    print("%d frames written to %s" % (count, os.path.normpath(ROOT)))


if __name__ == "__main__":
    main()
