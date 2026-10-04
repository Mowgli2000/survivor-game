"""Hayate, ninja hero: smooth manga/cartoon vector sprite, drawn shape by shape.

Unlike make_sprites.py (generic rigs), every outline here is placed by hand for
this character (3 heads tall, 3/4 view facing right). Cut-out animation: parts
(head, hair, headband tails, arms, hakama legs, feet) move as rigid pieces.
Cel shading: flat base + a hard shadow crescent (copy shifted toward the light,
clipped to the shape) + hand-placed highlights; thick dark outline.

Output: assets_src/drawn/hayate/idle_0..5.svg, walk_0..7.svg (512 x 512),
then tools/bake_sprites.ps1. Usage: python tools/art/hayate.py
"""
import math
import os

ROOT = os.path.join(os.path.dirname(__file__), "..", "..", "assets_src", "drawn", "hayate")
SIZE = 512
INK = "#1a1024"
STROKE = 8

C = {
    "skin": "#f3c39c", "skin_sh": "#d98f72", "blush": "#f29a8f",
    "hair": "#2a2238", "hair_sh": "#161122", "hair_hl": "#5b4d7a",
    "red": "#e23a4a", "red_sh": "#9c1f33", "red_hl": "#ff8a86",
    "gi": "#353a56", "gi_sh": "#21243a", "gi_hl": "#59618a",
    "hakama": "#283457", "hakama_sh": "#18203a", "hakama_hl": "#425487",
    "wrap": "#efe4d0", "wrap_sh": "#c2b096",
    "metal": "#9aa1b9", "metal_sh": "#5f6580", "metal_hl": "#e1e6f2",
    "gold": "#f0bf4c", "gold_sh": "#a8771f",
    "sheath": "#6a2236", "sheath_sh": "#3f1220",
    "glove": "#2b2638", "glove_sh": "#17131f",
    "eye": "#3ff0ff", "eye_dark": "#0f6f9a", "white": "#ffffff",
}
LIGHT = (-0.55, -1.0)  # direction toward the light (top left)


# --------------------------------------------------------------------------- paths

def smooth(pts, closed=True):
    """Path through points. A point (x, y, 'c') is a sharp corner; others are smooth
    (Catmull-Rom between neighbours)."""
    n = len(pts)
    P = [(p[0], p[1]) for p in pts]
    corner = [len(p) > 2 for p in pts]

    def tangent(i):
        if corner[i]:
            return (0.0, 0.0)
        a = P[(i - 1) % n]
        b = P[(i + 1) % n]
        return ((b[0] - a[0]) / 6.0, (b[1] - a[1]) / 6.0)

    d = "M%.1f %.1f" % P[0]
    last = n if closed else n - 1
    for i in range(last):
        j = (i + 1) % n
        t0 = tangent(i)
        t1 = tangent(j)
        c1 = (P[i][0] + t0[0], P[i][1] + t0[1])
        c2 = (P[j][0] - t1[0], P[j][1] - t1[1])
        d += "C%.1f %.1f %.1f %.1f %.1f %.1f" % (c1[0], c1[1], c2[0], c2[1], P[j][0], P[j][1])
    return d + ("Z" if closed else "")


def ribbon(spine, w0, w1, notch=True):
    """Closed shape around a centerline, width tapering from w0 to w1, swallow-tail end."""
    left = []
    right = []
    n = len(spine)
    for i in range(n):
        a = spine[max(0, i - 1)]
        b = spine[min(n - 1, i + 1)]
        dx, dy = b[0] - a[0], b[1] - a[1]
        l = math.hypot(dx, dy) or 1.0
        nx, ny = -dy / l, dx / l
        w = (w0 + (w1 - w0) * i / (n - 1)) / 2
        left.append((spine[i][0] + nx * w, spine[i][1] + ny * w))
        right.append((spine[i][0] - nx * w, spine[i][1] - ny * w))
    tip = spine[-1]
    pts = [p for p in left]
    if notch:
        a = spine[-2]
        dx, dy = tip[0] - a[0], tip[1] - a[1]
        l = math.hypot(dx, dy) or 1.0
        pts[-1] = (pts[-1][0], pts[-1][1], "c")
        pts.append((tip[0] - dx / l * w1 * 0.9, tip[1] - dy / l * w1 * 0.9, "c"))
        right[-1] = (right[-1][0], right[-1][1], "c")
    return pts + right[::-1]


def bez(p0, p1, p2, t):
    u = 1 - t
    return (u * u * p0[0] + 2 * u * t * p1[0] + t * t * p2[0], u * u * p0[1] + 2 * u * t * p1[1] + t * t * p2[1])


class Svg:
    def __init__(self):
        self.defs = []
        self.body = []
        self._id = 0

    def uid(self, p):
        self._id += 1
        return "%s%d" % (p, self._id)

    def text(self):
        return ('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">\n<defs>%s</defs>\n%s\n</svg>\n'
                % (SIZE, SIZE, SIZE, SIZE, "".join(self.defs), "\n".join(self.body)))


def part(svg, d, fill, shadow=None, depth=12.0, stroke=STROKE, extra=""):
    """Base + hard cel shadow (shape minus its copy shifted toward the light) + outline.
    `extra`: SVG drawn inside the clip (hand-placed highlights, stripes...)."""
    cid = svg.uid("c")
    svg.defs.append('<clipPath id="%s"><path d="%s"/></clipPath>' % (cid, d))
    out = ['<path d="%s" fill="%s"/>' % (d, fill)]
    if shadow:
        dx, dy = LIGHT[0] * depth, LIGHT[1] * depth
        out.append('<g clip-path="url(#%s)"><path d="%s" fill="%s"/><path d="%s" fill="%s" transform="translate(%.1f %.1f)"/>%s</g>'
                   % (cid, d, shadow, d, fill, dx, dy, extra))
    elif extra:
        out.append('<g clip-path="url(#%s)">%s</g>' % (cid, extra))
    if stroke:
        out.append('<path d="%s" fill="none" stroke="%s" stroke-width="%d" stroke-linejoin="round" stroke-linecap="round"/>' % (d, INK, stroke))
    return "\n".join(out)


def line(pts, color, width, closed=False):
    return '<path d="%s" fill="none" stroke="%s" stroke-width="%.1f" stroke-linecap="round" stroke-linejoin="round"/>' % (
        smooth(pts, closed), color, width)


def g(content, tx=0.0, ty=0.0, rot=0.0, cx=0.0, cy=0.0):
    t = "translate(%.2f %.2f)" % (tx, ty)
    if rot:
        t += " rotate(%.2f %.2f %.2f)" % (rot, cx, cy)
    return '<g transform="%s">\n%s\n</g>' % (t, content)


# --------------------------------------------------------------------------- body parts

def tails(svg, sway, walking):
    """Two headband ribbons flowing back from the knot (178, 112)."""
    out = []
    knot = (176, 114)
    for k in range(2):
        length = 150 - k * 30
        back = 1.0 + (0.25 if walking else 0.0)
        end = (knot[0] - length * back, knot[1] + 70 + k * 40 - (35 if walking else 0) + sway * (14 + k * 6))
        ctrl = (knot[0] - length * 0.5, knot[1] - 10 + sway * 10 + k * 18)
        spine = [bez(knot, ctrl, end, i / 7) for i in range(8)]
        # gentle wave along the ribbon
        spine = [(x, y + math.sin(i * 0.9 + sway * 3 + k) * 4) for i, (x, y) in enumerate(spine)]
        shape = ribbon(spine, 30 - k * 5, 22 - k * 4)
        out.append(part(svg, smooth(shape), C["red"] if k == 0 else C["red_sh"], C["red_sh"] if k == 0 else "#7a1527", depth=7))
    return "\n".join(out[::-1])


def hair_back(svg):
    pts = [(188, 172, "c"), (170, 152), (136, 154, "c"), (158, 128), (114, 112, "c"), (152, 96), (124, 62, "c"),
           (172, 66), (170, 18, "c"), (212, 44), (246, 4, "c"), (264, 42), (306, 10, "c"), (308, 52), (356, 36, "c"),
           (334, 80), (366, 104, "c"), (326, 104), (322, 132, "c"), (300, 96), (240, 84), (196, 104), (190, 140)]
    d = smooth(pts)
    shine = (line([(150, 60), (170, 40), (195, 30)], C["hair_hl"], 7) +
             line([(232, 26), (250, 16)], C["hair_hl"], 6) + line([(290, 32), (306, 22)], C["hair_hl"], 6))
    return part(svg, d, C["hair"], C["hair_sh"], depth=14, extra=shine)


def head(svg):
    face = [(252, 46), (306, 66), (324, 112), (318, 152), (300, 182), (270, 202, "c"), (232, 192), (196, 166),
            (180, 128), (186, 82), (214, 56)]
    ear = smooth([(178, 118), (192, 112), (198, 136), (190, 158), (176, 150), (170, 132)])
    out = [part(svg, ear, C["skin"], C["skin_sh"], depth=6),
           line([(182, 128), (188, 140), (184, 150)], C["skin_sh"], 4)]
    # neck shadow under the chin is part of the neck; the face itself:
    blush = ('<ellipse cx="214" cy="170" rx="16" ry="7" fill="%s" opacity="0.55"/>'
             '<ellipse cx="300" cy="166" rx="10" ry="6" fill="%s" opacity="0.5"/>' % (C["blush"], C["blush"]))
    out.append(part(svg, smooth(face), C["skin"], C["skin_sh"], depth=10, extra=blush))
    return "\n".join(out)


def eyes():
    """Big manga eyes (near = image left, wider; far = narrower), brows, nose, mouth."""
    s = []
    for (cx, cy, w, h, far) in ((228, 146, 44, 46, False), (293, 142, 30, 44, True)):
        x0, x1 = cx - w / 2, cx + w / 2
        sclera = smooth([(x0, cy - 4), (cx - w * 0.1, cy - h * 0.48), (x1, cy - h * 0.38), (x1 - 2, cy + h * 0.3),
                         (cx, cy + h * 0.46), (x0 + 3, cy + h * 0.2)])
        s.append('<path d="%s" fill="#ffffff"/>' % sclera)
        gid = "irisgrad%d" % (1 if far else 0)
        s.append('<defs><linearGradient id="%s" x1="0" y1="0" x2="0" y2="1">'
                 '<stop offset="0" stop-color="%s"/><stop offset="0.55" stop-color="%s"/><stop offset="1" stop-color="#aefcff"/>'
                 '</linearGradient></defs>' % (gid, C["eye_dark"], C["eye"]))
        icx = cx + (3 if far else 5)
        s.append('<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="url(#%s)"/>' % (icx, cy + 3, w * 0.33, h * 0.4, gid))
        s.append('<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="#0b2233"/>' % (icx + 1, cy + 4, w * 0.13, h * 0.2))
        s.append('<circle cx="%.1f" cy="%.1f" r="%.1f" fill="#ffffff"/>' % (icx - w * 0.12, cy - h * 0.1, w * 0.12))
        s.append('<circle cx="%.1f" cy="%.1f" r="%.1f" fill="#ffffff" opacity="0.9"/>' % (icx + w * 0.12, cy + h * 0.2, w * 0.06))
        # thick upper lash (flares at the outer corner), thin lower lash
        lash = [(x0 - 4, cy + 2), (cx - w * 0.1, cy - h * 0.52), (x1 + 6, cy - h * 0.36)]
        s.append(line(lash, INK, 9))
        s.append(line([(x1 - 4, cy + h * 0.32), (cx, cy + h * 0.48)], INK, 3.5))
        s.append('<path d="%s" fill="none" stroke="%s" stroke-width="3"/>' % (sclera, INK))
    # angry brows (over the bangs)
    s.append(line([(200, 112), (226, 116), (250, 126)], INK, 9))
    s.append(line([(282, 122), (300, 112), (314, 110)], INK, 8))
    # nose, mouth
    s.append(line([(276, 168), (281, 174)], C["skin_sh"], 4))
    s.append(line([(256, 186), (268, 188), (278, 184)], INK, 4))
    return "\n".join(s)


def bangs(svg):
    pts = [(184, 104), (190, 70), (226, 42), (272, 36), (312, 52), (330, 88), (322, 106, "c"), (316, 142, "c"), (302, 112),
           (290, 146, "c"), (276, 112), (258, 140, "c"), (244, 108), (226, 138, "c"), (214, 106), (196, 132, "c"), (190, 112)]
    shine = line([(214, 64), (236, 50), (262, 46)], C["hair_hl"], 7) + line([(290, 52), (306, 62)], C["hair_hl"], 5)
    return part(svg, smooth(pts), C["hair"], C["hair_sh"], depth=9, extra=shine)


def headband(svg):
    band = smooth([(180, 92, "c"), (250, 78), (326, 74, "c"), (330, 100, "c"), (252, 106), (182, 122, "c")])
    stripe = line([(196, 104), (260, 94), (318, 88)], C["red_sh"], 4)
    plate = smooth([(268, 80, "c"), (300, 76, "c"), (302, 100, "c"), (270, 104, "c")])
    out = [part(svg, band, C["red"], C["red_sh"], depth=6, extra=stripe),
           part(svg, plate, C["metal"], C["metal_sh"], depth=5, stroke=5),
           line([(274, 86), (294, 84)], C["metal_hl"], 3)]
    knot = smooth([(160, 100), (184, 96), (194, 116), (182, 134), (160, 132), (152, 116)])
    out.append(part(svg, knot, C["red"], C["red_sh"], depth=6))
    return "\n".join(out)


def neck(svg):
    d = smooth([(240, 184, "c"), (278, 192, "c"), (280, 222, "c"), (238, 222, "c")])
    shade = '<path d="M236 184 L284 194 L284 206 Q260 204 236 198 Z" fill="%s"/>' % C["skin_sh"]
    return part(svg, d, C["skin"], None, extra=shade)


def torso(svg):
    gi = smooth([(232, 206), (284, 206), (326, 224), (334, 262), (322, 312, "c"), (186, 314, "c"), (176, 262), (184, 226)])
    collar = ('<path d="M234 204 L286 204 L262 252 Z" fill="%s"/>'
              '<path d="M262 252 L246 236 L254 230 Z" fill="%s"/>' % (C["skin"], C["skin_sh"]))
    lapels = line([(226, 212), (248, 238), (262, 256)], C["gi_hl"], 6) + line([(292, 212), (276, 236), (264, 254)], C["gi_hl"], 6)
    folds = line([(210, 282), (226, 292), (244, 292)], C["gi_sh"], 5) + line([(290, 280), (304, 290)], C["gi_sh"], 5)
    return part(svg, gi, C["gi"], C["gi_sh"], depth=16, extra=collar + lapels + folds)


def sash(svg):
    band = smooth([(182, 300, "c"), (324, 298, "c"), (328, 332, "c"), (180, 334, "c")])
    stripes = line([(186, 316), (322, 314)], C["red_sh"], 4)
    knot = smooth([(186, 304), (214, 302), (222, 322), (210, 340), (186, 338), (176, 320)])
    t1 = smooth(ribbon([(196, 334), (190, 356), (180, 378)], 18, 14))
    t2 = smooth(ribbon([(206, 334), (208, 360), (204, 384)], 16, 12))
    return "\n".join([part(svg, band, C["red"], C["red_sh"], depth=7, extra=stripes),
                      part(svg, t2, C["red_sh"], "#7a1527", depth=5), part(svg, t1, C["red"], C["red_sh"], depth=5),
                      part(svg, knot, C["red"], C["red_sh"], depth=6)])


def sheath(svg):
    d = smooth(ribbon([(300, 322), (200, 372), (96, 424)], 22, 18, notch=False))
    tip = smooth([(92, 412, "c"), (108, 418, "c"), (104, 436, "c"), (86, 434, "c")])
    band = line([(178, 380), (186, 396)], C["gold"], 6)
    return part(svg, d, C["sheath"], C["sheath_sh"], depth=6, extra=band) + "\n" + part(svg, tip, C["gold"], C["gold_sh"], depth=4, stroke=5)


def hilt(svg):
    grip = smooth(ribbon([(304, 316), (338, 294), (372, 272)], 18, 16, notch=False))
    diamonds = "".join(line([(316 + i * 14, 306 - i * 9), (322 + i * 14, 314 - i * 9)], INK, 4) for i in range(4))
    tsuba = '<ellipse cx="302" cy="318" rx="12" ry="20" transform="rotate(-33 302 318)"/>'
    pommel = smooth([(366, 264, "c"), (382, 260, "c"), (384, 276, "c"), (370, 282, "c")])
    out = [part(svg, grip, C["wrap"], C["wrap_sh"], depth=5, extra=diamonds),
           part(svg, pommel, C["gold"], C["gold_sh"], depth=4, stroke=5),
           tsuba.replace("/>", ' fill="%s" stroke="%s" stroke-width="6"/>' % (C["gold"], INK))]
    return "\n".join(out)


def arm(svg, near, angle, fore_angle):
    """Shoulder at the pivot; upper sleeve, wrapped forearm, gloved fist."""
    if near:
        sh = (190, 236)
        upper = [(176, 226), (204, 226), (202, 270), (176, 274)]
    else:
        sh = (318, 238)
        upper = [(306, 228), (334, 232), (338, 272), (312, 274)]
    elbow = (sh[0] - (2 if near else -4), sh[1] + 40)
    fore_end = (elbow[0] + math.sin(math.radians(-fore_angle)) * 46, elbow[1] + math.cos(math.radians(fore_angle)) * 46)
    sleeve = part(svg, smooth(upper), C["gi"], C["gi_sh"], depth=8)
    fore = smooth(ribbon([elbow, ((elbow[0] + fore_end[0]) / 2, (elbow[1] + fore_end[1]) / 2), fore_end], 30, 26, notch=False))
    stripes = "".join(line([(elbow[0] - 16, elbow[1] + 10 + i * 12), (elbow[0] + 16, elbow[1] + 4 + i * 12)], C["wrap_sh"], 4) for i in range(4))
    forearm = part(svg, fore, C["wrap"], C["wrap_sh"], depth=6, extra=stripes)
    fist = smooth([(fore_end[0] - 17, fore_end[1] - 2), (fore_end[0] + 15, fore_end[1] - 4), (fore_end[0] + 18, fore_end[1] + 18),
                   (fore_end[0] - 2, fore_end[1] + 26), (fore_end[0] - 19, fore_end[1] + 14)])
    knuckles = line([(fore_end[0] - 10, fore_end[1] + 10), (fore_end[0] + 10, fore_end[1] + 8)], C["glove_sh"], 3)
    hand = part(svg, fist, C["glove"], C["glove_sh"], depth=6, extra=knuckles)
    out = sleeve + "\n" + forearm + "\n" + hand
    if near:
        pad = smooth([(160, 226), (184, 206), (214, 210), (222, 236), (204, 258), (172, 256)])
        rivets = ('<circle cx="182" cy="230" r="4" fill="%s"/><circle cx="204" cy="226" r="4" fill="%s"/>' % (C["gold"], C["gold"]))
        shine = line([(176, 220), (194, 212)], C["metal_hl"], 5)
        out += "\n" + part(svg, pad, C["metal"], C["metal_sh"], depth=8, extra=rivets + shine)
    return g(out, rot=angle, cx=sh[0], cy=sh[1])


def leg(svg, near, rot, lift, dx):
    hip = (222, 330) if near else (286, 330)
    if near:
        d = smooth([(186, 326, "c"), (256, 326, "c"), (252, 452, "c"), (214, 458), (164, 452, "c"), (172, 400)])
        pleats = line([(214, 340), (206, 450)], C["hakama_sh"], 5) + line([(236, 340), (236, 450)], C["hakama_sh"], 4)
        foot_c = (208, 470)
    else:
        d = smooth([(254, 326, "c"), (320, 326, "c"), (334, 400), (346, 450, "c"), (300, 458), (258, 452, "c")])
        pleats = line([(288, 340), (296, 450)], C["hakama_sh"], 5) + line([(310, 340), (322, 448)], C["hakama_hl"], 4)
        foot_c = (304, 470)
    hem = line([(170, 448), (250, 448)] if near else [(262, 448), (342, 446)], C["hakama_hl"], 4)
    cloth = part(svg, d, C["hakama"], C["hakama_sh"], depth=14, extra=pleats + hem)
    fx, fy = foot_c
    tabi = smooth([(fx - 26, fy - 18, "c"), (fx + 18, fy - 18), (fx + 34, fy + 2), (fx + 30, fy + 18, "c"), (fx - 28, fy + 18, "c")])
    split = line([(fx + 14, fy - 4), (fx + 18, fy + 14)], C["glove_sh"], 3)
    sole = '<path d="M%.1f %.1f H%.1f" stroke="%s" stroke-width="6"/>' % (fx - 26, fy + 14, fx + 28, C["wrap_sh"])
    foot = g(part(svg, tabi, C["glove"], C["glove_sh"], depth=6, extra=split + sole), tx=dx, ty=-lift)
    return foot + "\n" + g(cloth, tx=dx * 0.5, ty=-lift * 0.5, rot=rot, cx=hip[0], cy=hip[1])


# --------------------------------------------------------------------------- frames

def frame(anim, i, n):
    t = i / n
    svg = Svg()
    walking = anim == "walk"
    if walking:
        s = math.sin(t * math.tau)
        c = math.cos(t * math.tau)
        bob = -abs(c) * 6 + 3
        legs = ((-s * 7, max(0.0, c) * 10, s * 16), (s * 7, max(0.0, -c) * 10, -s * 16))
        arms = (s * 16, -s * 16)
        sway = 0.6 + math.sin(t * math.tau * 2) * 0.4
        head_tilt = 2.0
    else:
        b = math.sin(t * math.tau)
        bob = b * 3
        legs = ((0, 0, 0), (0, 0, 0))
        arms = (b * 3, -b * 3)
        sway = math.sin(t * math.tau) * 0.5
        head_tilt = b * 1.2

    svg.body.append('<ellipse cx="256" cy="490" rx="118" ry="16" fill="#000000" opacity="0.28"/>')
    upper_back = [tails(svg, sway, walking), sheath(svg), arm(svg, False, arms[1], 12)]
    svg.body.append(g("\n".join(upper_back), ty=bob))
    # legs: far leg first
    svg.body.append(leg(svg, False, legs[1][0], legs[1][1], legs[1][2]))
    svg.body.append(leg(svg, True, legs[0][0], legs[0][1], legs[0][2]))
    head_group = "\n".join([hair_back(svg), head(svg), eyes(), bangs(svg), headband(svg)])
    upper = [neck(svg), torso(svg), sash(svg), hilt(svg),
             g(head_group, rot=head_tilt, cx=256, cy=200),
             arm(svg, True, arms[0], -10)]
    svg.body.append(g("\n".join(upper), ty=bob))
    return svg.text()


def main():
    os.makedirs(ROOT, exist_ok=True)
    for anim, n in (("idle", 6), ("walk", 8)):
        for i in range(n):
            with open(os.path.join(ROOT, "%s_%d.svg" % (anim, i)), "w", encoding="utf-8", newline="\n") as f:
                f.write(frame(anim, i, n))
    print("hayate: 6 idle + 8 walk frames -> %s" % os.path.abspath(ROOT))


if __name__ == "__main__":
    main()
