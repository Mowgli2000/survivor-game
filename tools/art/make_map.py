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

def decal_puddle():
    return svg(160, 96, '<path d="M 20 52 q 10 -30 50 -32 q 30 -8 56 10 q 26 16 6 34 q -20 18 -60 12 q -44 4 -52 -24 z" '
                        'fill="#5ad6ff" fill-opacity="0.28" stroke="#5ad6ff" stroke-opacity="0.45" stroke-width="4"/>'
                        '<path d="M 52 40 q 20 -8 40 -2" fill="none" stroke="#ffffff" stroke-opacity="0.5" stroke-width="4" stroke-linecap="round"/>')


def decal_grate():
    body = ['<rect x="8" y="8" width="112" height="72" rx="8" fill="#43416a" %s/>' % line(5)]
    for k in range(6):
        body.append('<rect x="%d" y="18" width="8" height="52" rx="3" fill="#2c2a4a"/>' % (22 + k * 16))
    return svg(128, 88, "\n".join(body))


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
    # Crossbow bolt (repeating crossbow): wooden shaft, steel head, fletching; points right.
    return svg(64, 64, '<path d="M 8 26 l 10 6 l -10 6 z M 14 24 l 10 8 l -10 8 z" fill="#e8e4d8" stroke="%s" stroke-width="3" '
                       'stroke-linejoin="round"/><rect x="14" y="29" width="34" height="6" rx="2" fill="#a0703c" stroke="%s" '
                       'stroke-width="3"/><path d="M 46 24 L 62 32 L 46 40 z" fill="#d9dde8" stroke="%s" stroke-width="4" '
                       'stroke-linejoin="round"/>' % (INK, INK, INK))


def proj_missile():
    # Bomb flask (alchemy): orange potion, cork and a lit fuse at the front (right).
    return svg(64, 64, '<circle cx="26" cy="32" r="18" fill="#ff8a2b" stroke="%s" stroke-width="5"/>'
                       '<path d="M 18 24 q 6 -6 14 -4" fill="none" stroke="#ffe0b0" stroke-width="4" stroke-linecap="round"/>'
                       '<rect x="40" y="26" width="10" height="12" rx="2" fill="#c8e6f0" stroke="%s" stroke-width="4"/>'
                       '<rect x="49" y="27" width="6" height="10" rx="2" fill="#b07840" stroke="%s" stroke-width="3"/>'
                       '<path d="M 55 32 q 4 -6 7 -2" fill="none" stroke="%s" stroke-width="3"/>'
                       '<circle cx="61" cy="29" r="3" fill="#ffd24d"/>' % (INK, INK, INK, INK))


def proj_shuriken():
    # Spinning throwing dagger: steel leaf blade, black grip, ring pommel.
    return svg(64, 64, '<path d="M 30 32 L 40 22 Q 58 26 62 32 Q 58 38 40 42 z" fill="#d9dde8" stroke="%s" stroke-width="4" '
                       'stroke-linejoin="round"/><rect x="14" y="28" width="18" height="8" rx="3" fill="#2a2633" stroke="%s" '
                       'stroke-width="3"/><circle cx="10" cy="32" r="5" fill="none" stroke="%s" stroke-width="4"/>' % (INK, INK, INK))


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
    # The other decor pieces are AI art (art_source/ai/decor/ -> tools/art/make_icon.gd --height).
    files = {
        os.path.join(ROOT, "ground.svg"): ground(),
        os.path.join(out, "decal_puddle.svg"): decal_puddle(),
        os.path.join(out, "decal_grate.svg"): decal_grate(),
    }
    for path, text in files.items():
        with open(path, "w", encoding="utf-8") as f:
            f.write(text)
    print("%d map files written to %s" % (len(files), os.path.normpath(ROOT)))


if __name__ == "__main__":
    main()
