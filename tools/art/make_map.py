"""Draws the arena art as SVG (same cartoon style as the characters).

- ground.svg: 512x512 seamless tile of neon-dojo rooftop slabs (medium blue-violet,
  never dark: D34).
- decor/<name>.svg: flat floor decals (inside the arena, low contrast, no
  collision) and tall props (only outside the arena, along the border).
Output: assets_src/drawn/map/, rasterized by tools/art/bake_map.gd.
Usage: python tools/art/make_map.py
"""
import math
import os
import random

ROOT = os.path.join(os.path.dirname(__file__), "..", "..", "assets_src", "drawn", "map")
INK = "#1b1026"


def svg(w, h, body):
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">\n%s\n</svg>\n'
            % (w, h, w, h, body))


def line(width=6):
    return 'stroke="%s" stroke-width="%d" stroke-linejoin="round" stroke-linecap="round"' % (INK, width)


# --------------------------------------------------------------------------- ground

def ground():
    rng = random.Random(7)
    size, tile = 512, 128
    parts = ['<rect width="512" height="512" fill="#45436e"/>']
    base = [(0x6d, 0x6b, 0xa3), (0x66, 0x64, 0x9c), (0x72, 0x70, 0xa8), (0x6a, 0x68, 0x9f)]
    for ty in range(0, size, tile):
        # Running bond: every other row shifted by half a slab, wrapped so the tile stays seamless.
        shift = tile // 2 if (ty // tile) % 2 else 0
        for tx in range(-tile, size + tile, tile):
            x = tx + shift
            r, g, b = rng.choice(base)
            jitter = rng.randint(-5, 5)
            color = "#%02x%02x%02x" % (r + jitter, g + jitter, b + jitter)
            for wrap in (0, -size, size):
                xx = x + wrap
                if xx + tile < 0 or xx > size:
                    continue
                parts.append('<rect x="%d" y="%d" width="%d" height="%d" rx="10" fill="%s"/>' % (
                    xx + 4, ty + 4, tile - 8, tile - 8, color))
                # Bevel: light top-left edge, dark bottom-right edge.
                parts.append('<path d="M %d %d h %d M %d %d v %d" stroke="#ffffff" stroke-opacity="0.10" stroke-width="4"/>' % (
                    xx + 12, ty + 8, tile - 24, xx + 8, ty + 12, tile - 24))
                parts.append('<path d="M %d %d h %d M %d %d v %d" stroke="#1b1026" stroke-opacity="0.18" stroke-width="4"/>' % (
                    xx + 12, ty + tile - 8, tile - 24, xx + tile - 8, ty + 12, tile - 24))
    # A few cracks and pebbles (kept away from the tile edges so the tile wraps).
    for _ in range(9):
        x, y = rng.randint(40, 470), rng.randint(40, 470)
        d = "M %d %d" % (x, y)
        for _k in range(3):
            x += rng.randint(-18, 18)
            y += rng.randint(6, 16)
            d += " L %d %d" % (x, y)
        parts.append('<path d="%s" fill="none" stroke="#2c2a4a" stroke-opacity="0.45" stroke-width="3" stroke-linecap="round"/>' % d)
    for _ in range(14):
        x, y = rng.randint(20, 492), rng.randint(20, 492)
        parts.append('<circle cx="%d" cy="%d" r="%d" fill="#8a88c0" fill-opacity="0.35"/>' % (x, y, rng.randint(2, 4)))
    return svg(size, size, "\n".join(parts))


# --------------------------------------------------------------------------- decals (flat, inside)

def decal_manhole():
    body = ['<circle cx="64" cy="64" r="52" fill="#4c4a74" %s/>' % line(5),
            '<circle cx="64" cy="64" r="40" fill="none" stroke="#3a385e" stroke-width="6"/>']
    for k in range(-2, 3):
        body.append('<path d="M %d %d h 56" stroke="#3a385e" stroke-width="5" stroke-linecap="round"/>' % (36, 64 + k * 12))
    return svg(128, 128, "\n".join(body))


def decal_seal(color):
    body = ['<circle cx="80" cy="80" r="66" fill="none" stroke="%s" stroke-opacity="0.5" stroke-width="8"/>' % color,
            '<circle cx="80" cy="80" r="50" fill="none" stroke="%s" stroke-opacity="0.35" stroke-width="4" stroke-dasharray="14 10"/>' % color,
            '<path d="M 56 60 h 48 M 80 48 v 64 M 60 92 q 20 -16 40 0 M 62 76 l 36 0" fill="none" stroke="%s" '
            'stroke-opacity="0.55" stroke-width="7" stroke-linecap="round"/>' % color]
    return svg(160, 160, "\n".join(body))


def decal_puddle():
    return svg(160, 96, '<path d="M 20 52 q 10 -30 50 -32 q 30 -8 56 10 q 26 16 6 34 q -20 18 -60 12 q -44 4 -52 -24 z" '
                        'fill="#5ad6ff" fill-opacity="0.28" stroke="#5ad6ff" stroke-opacity="0.45" stroke-width="4"/>'
                        '<path d="M 52 40 q 20 -8 40 -2" fill="none" stroke="#ffffff" stroke-opacity="0.5" stroke-width="4" stroke-linecap="round"/>')


def decal_grate():
    body = ['<rect x="8" y="8" width="112" height="72" rx="8" fill="#43416a" %s/>' % line(5)]
    for k in range(6):
        body.append('<rect x="%d" y="18" width="8" height="52" rx="3" fill="#2c2a4a"/>' % (22 + k * 16))
    return svg(128, 88, "\n".join(body))


def decal_cable():
    return svg(256, 64, '<path d="M 6 40 q 40 -36 84 -6 q 44 30 84 0 q 40 -30 76 4" fill="none" stroke="%s" stroke-width="12" '
                        'stroke-linecap="round"/><path d="M 6 40 q 40 -36 84 -6 q 44 30 84 0 q 40 -30 76 4" fill="none" '
                        'stroke="#3d3b63" stroke-width="6" stroke-linecap="round"/>' % INK)


# --------------------------------------------------------------------------- props (tall, outside)

def prop_lantern():
    body = ['<ellipse cx="64" cy="232" rx="40" ry="10" fill="#000" opacity="0.3"/>',
            '<rect x="40" y="196" width="48" height="34" rx="6" fill="#8a88a8" %s/>' % line(),
            '<rect x="54" y="140" width="20" height="60" rx="5" fill="#9c9abb" %s/>' % line(),
            '<path d="M 22 140 L 64 116 L 106 140 z" fill="#7a7898" %s/>' % line(),
            '<rect x="38" y="76" width="52" height="44" rx="8" fill="#ffd27a" %s/>' % line(),
            '<rect x="50" y="86" width="28" height="24" rx="5" fill="#fff4c8"/>',
            '<path d="M 18 76 L 64 44 L 110 76 z" fill="#7a7898" %s/>' % line(),
            '<circle cx="64" cy="38" r="9" fill="#9c9abb" %s/>' % line(5),
            '<circle cx="64" cy="98" r="58" fill="#ffd27a" opacity="0.18"/>']
    return svg(128, 248, "\n".join(body))


def prop_tree():
    rng = random.Random(3)
    body = ['<ellipse cx="96" cy="240" rx="60" ry="12" fill="#000" opacity="0.3"/>',
            '<path d="M 86 236 q -6 -60 10 -110 l 14 4 q -12 50 -4 106 z" fill="#6b4256" %s/>' % line(),
            '<path d="M 98 150 q -30 -10 -46 -34" fill="none" %s/>' % line(10),
            '<path d="M 98 150 q -30 -10 -46 -34" fill="none" stroke="#6b4256" stroke-width="4" stroke-linecap="round"/>']
    for cx, cy, r in ((60, 96, 46), (130, 86, 50), (96, 56, 52), (40, 130, 32), (150, 130, 34)):
        body.append('<circle cx="%d" cy="%d" r="%d" fill="#ff9ad5" %s/>' % (cx, cy, r, line()))
        body.append('<circle cx="%d" cy="%d" r="%d" fill="#ffc4e6" opacity="0.7"/>' % (cx + r * 0.25, cy - r * 0.3, r * 0.45))
    for _ in range(10):
        body.append('<circle cx="%d" cy="%d" r="4" fill="#ffffff" opacity="0.8"/>' % (rng.randint(30, 170), rng.randint(30, 160)))
    return svg(192, 256, "\n".join(body))


def prop_sign(color, text_bars):
    body = ['<ellipse cx="64" cy="240" rx="30" ry="8" fill="#000" opacity="0.3"/>',
            '<rect x="56" y="120" width="16" height="118" rx="4" fill="#4c4a74" %s/>' % line(),
            '<rect x="14" y="20" width="100" height="110" rx="12" fill="#2a2840" %s/>' % line(),
            '<rect x="22" y="28" width="84" height="94" rx="8" fill="none" stroke="%s" stroke-width="6"/>' % color,
            '<rect x="14" y="20" width="100" height="110" rx="12" fill="%s" opacity="0.15"/>' % color]
    for k, w in enumerate(text_bars):
        body.append('<rect x="%d" y="%d" width="%d" height="12" rx="6" fill="%s"/>' % (64 - w // 2, 44 + k * 24, w, color))
    return svg(128, 248, "\n".join(body))


def prop_vending():
    body = ['<ellipse cx="72" cy="244" rx="56" ry="10" fill="#000" opacity="0.3"/>',
            '<rect x="16" y="40" width="112" height="200" rx="12" fill="#e6e4f4" %s/>' % line(),
            '<rect x="28" y="54" width="70" height="120" rx="6" fill="#33e6ff" fill-opacity="0.35" %s/>' % line(5)]
    colors = ["#ff5a8c", "#ffd24d", "#4dff73", "#33e6ff", "#ff9a3c", "#a24dff"]
    for row in range(3):
        for col in range(3):
            body.append('<rect x="%d" y="%d" width="14" height="24" rx="4" fill="%s" %s/>' % (
                36 + col * 21, 64 + row * 36, colors[(row * 3 + col) % len(colors)], line(3)))
    body.append('<rect x="104" y="80" width="14" height="30" rx="4" fill="#4c4a74" %s/>' % line(4))
    body.append('<rect x="34" y="190" width="70" height="26" rx="5" fill="#2a2840" %s/>' % line(4))
    return svg(144, 256, "\n".join(body))


def prop_crates():
    body = ['<ellipse cx="80" cy="186" rx="70" ry="12" fill="#000" opacity="0.3"/>']
    for x, y, w in ((16, 112, 76), (88, 120, 66), (44, 52, 64)):
        body.append('<rect x="%d" y="%d" width="%d" height="%d" rx="6" fill="#b07a46" %s/>' % (x, y, w, w * 0.9, line()))
        body.append('<path d="M %d %d l %d %d M %d %d l %d %d" stroke="%s" stroke-width="4"/>' % (
            x + 6, y + 6, w - 12, w * 0.9 - 12, x + w - 6, y + 6, -(w - 12), w * 0.9 - 12, "#7a5030"))
    return svg(160, 196, "\n".join(body))


# --------------------------------------------------------------------------- projectiles
# 64x64 cells, pointing right, in WeaponData.ProjectileStyle order (1..6). White
# parts are tinted by the projectile color in game (orb, bolt, enemy orb).

def proj_orb():
    return svg(64, 64, '<circle cx="32" cy="32" r="22" fill="#ffffff" stroke="#ffffff" stroke-opacity="0.5" stroke-width="6"/>'
                       '<circle cx="26" cy="26" r="7" fill="#ffffff"/>')


def proj_bolt():
    return svg(64, 64, '<path d="M 4 32 L 22 22 L 60 30 L 60 34 L 22 42 z" fill="#ffffff"/>'
                       '<path d="M 22 30 L 56 32 L 22 34 z" fill="#ffffff" opacity="0.9"/>')


def proj_bullet():
    return svg(64, 64, '<path d="M 10 22 h 30 q 18 0 20 10 q -2 10 -20 10 h -30 z" fill="#ffcc4d" stroke="%s" stroke-width="5" '
                       'stroke-linejoin="round"/><path d="M 14 26 h 24" stroke="#fff4c8" stroke-width="4" stroke-linecap="round"/>'
                       '<rect x="6" y="20" width="10" height="24" rx="3" fill="#c8963a" stroke="%s" stroke-width="5"/>' % (INK, INK))


def proj_missile():
    return svg(64, 64, '<path d="M 4 32 q 6 -10 14 -6 l 0 12 q -8 4 -14 -6 z" fill="#ffd24d"/>'
                       '<path d="M 14 22 h 30 q 16 2 18 10 q -2 8 -18 10 h -30 z" fill="#eeeef6" stroke="%s" stroke-width="5" stroke-linejoin="round"/>'
                       '<path d="M 46 22 q 14 2 16 10 q -2 8 -16 10 z" fill="#ff5a3c" stroke="%s" stroke-width="5" stroke-linejoin="round"/>'
                       '<path d="M 18 22 l -8 -10 h 12 l 8 10 z M 18 42 l -8 10 h 12 l 8 -10 z" fill="#ff5a3c" stroke="%s" '
                       'stroke-width="4" stroke-linejoin="round"/>' % (INK, INK, INK))


def proj_shuriken():
    return svg(64, 64, '<path d="M 32 2 L 38 26 L 62 32 L 38 38 L 32 62 L 26 38 L 2 32 L 26 26 z" fill="#d9d9e6" stroke="%s" '
                       'stroke-width="4" stroke-linejoin="round"/><circle cx="32" cy="32" r="7" fill="#ffffff" stroke="%s" '
                       'stroke-width="4"/>' % (INK, INK))


def proj_enemy_orb():
    return svg(64, 64, '<circle cx="32" cy="32" r="24" fill="#ffffff" stroke="%s" stroke-width="5"/>'
                       '<circle cx="32" cy="32" r="13" fill="#ffffff" opacity="0.6"/><circle cx="25" cy="25" r="6" fill="#ffffff"/>' % INK)


def main():
    proj = os.path.join(ROOT, "..", "projectiles")
    os.makedirs(proj, exist_ok=True)
    for name, draw in (("1_orb", proj_orb), ("2_bolt", proj_bolt), ("3_bullet", proj_bullet),
                       ("4_missile", proj_missile), ("5_shuriken", proj_shuriken), ("6_enemy_orb", proj_enemy_orb)):
        with open(os.path.join(proj, name + ".svg"), "w", encoding="utf-8") as f:
            f.write(draw())
    out = os.path.join(ROOT, "decor")
    os.makedirs(out, exist_ok=True)
    files = {
        os.path.join(ROOT, "ground.svg"): ground(),
        os.path.join(out, "decal_manhole.svg"): decal_manhole(),
        os.path.join(out, "decal_seal_pink.svg"): decal_seal("#ff5ac8"),
        os.path.join(out, "decal_seal_cyan.svg"): decal_seal("#4de6ff"),
        os.path.join(out, "decal_puddle.svg"): decal_puddle(),
        os.path.join(out, "decal_grate.svg"): decal_grate(),
        os.path.join(out, "decal_cable.svg"): decal_cable(),
        os.path.join(out, "prop_lantern.svg"): prop_lantern(),
        os.path.join(out, "prop_tree.svg"): prop_tree(),
        os.path.join(out, "prop_sign_pink.svg"): prop_sign("#ff5ac8", (56, 40, 64)),
        os.path.join(out, "prop_sign_cyan.svg"): prop_sign("#4de6ff", (64, 48)),
        os.path.join(out, "prop_vending.svg"): prop_vending(),
        os.path.join(out, "prop_crates.svg"): prop_crates(),
    }
    for path, text in files.items():
        with open(path, "w", encoding="utf-8") as f:
            f.write(text)
    print("%d map files written to %s" % (len(files), os.path.normpath(ROOT)))


if __name__ == "__main__":
    main()
