"""Bakes the painted effects chosen among the candidates of tools/art/gen_vfx.py.
Sheets (art on black): assets/vfx/<name>.png, premultiplied alpha (alpha = brightest channel x boost,
so dark parts of the art darken the floor) + data/vfx/<name>.tres (EffectSheet).
Cells (projectile bodies): the black is keyed to alpha, written to assets_src/drawn/projectiles/NN_<style>.png
and art_source/ai/projectiles/ (then tools/art/bake_map.gd cuts the strip assets/sprites/projectiles.png).
Usage: python tools/art/bake_vfx.py [name ...]   (picks below; no name: all picked jobs)"""
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "art_tests/vfx"
SRC_HD = ROOT / "art_tests/vfx_hd"
HD_CELL = 384

# name: (candidate 1|2, boost, scale, forward, duration)
SHEETS = {
    "explosion_star": (2, 1.6, 2.4, 0.0, 0.38),
    "rapier_slash": (2, 1.8, 2.0, 0.0, 0.16),
    "flame_slash": (1, 1.8, 2.3, 0.12, 0.15),
    "star_impact": (2, 1.5, 2.2, 0.0, 0.22),
    "steel_slash": (2, 1.8, 2.3, 0.12, 0.22),
    "fang_slash": (2, 1.8, 2.3, 0.12, 0.18),
    "thrust": (1, 1.8, 2.0, 0.0, 0.15),
    "axe_slash": (2, 1.8, 2.3, 0.12, 0.15),
    "scythe_slash": (2, 1.8, 2.4, 0.12, 0.15),
    "hammer_smash": (2, 1.6, 1.5, 0.55, 0.36),
    "runic_slash": (2, 1.8, 2.3, 0.12, 0.15),
    "impact_generic": (2, 1.5, 2.2, 0.0, 0.15),
    "impact_fire": (2, 1.5, 2.2, 0.0, 0.2),
    "impact_frost": (2, 1.5, 2.2, 0.0, 0.2),
    "impact_lightning": (2, 1.5, 2.2, 0.0, 0.15),
    "explosion_fire": (2, 1.6, 2.4, 0.0, 0.35),
    "explosion_frost": (2, 1.6, 2.4, 0.0, 0.35),
    "explosion_blast": (2, 1.6, 2.4, 0.0, 0.35),
}
# Third pass (tools/art/gen_vfx_hd.py, art_tests/vfx_hd): 4 columns, 3 rows (12 frames) or 4 rows (16 frames, square image).
# These names replace the ones above. name: (candidate 1|2, boost, scale, forward, duration)
SHEETS_HD = {
    "frost_shards": (3, 1.7, 1.1, 0.5, 0.3),
    "steel_slash": (3, 1.8, 2.2, 0.0, 0.22),
    "fang_slash": (1, 1.8, 2.2, 0.0, 0.18),
    "hammer_smash": (3, 1.6, 2.2, 0.0, 0.36),
    "impact_generic": (1, 1.5, 2.2, 0.0, 0.15),
    "impact_sling": (3, 1.5, 2.2, 0.0, 0.16),
    "impact_fire": (1, 1.5, 2.2, 0.0, 0.2),
    "impact_frost": (1, 1.5, 2.2, 0.0, 0.2),
    "impact_lightning": (2, 1.5, 2.2, 0.0, 0.15),
    "star_impact": (1, 1.5, 2.2, 0.0, 0.22),
    "explosion_fire": (3, 1.6, 2.4, 0.0, 0.35),
    "explosion_frost": (3, 1.6, 2.4, 0.0, 0.35),
    "explosion_blast": (3, 1.6, 2.4, 0.0, 0.35),
    "explosion_star": (1, 1.6, 2.4, 0.0, 0.38),
    "flame_wave": (1, 1.8, 2.4, 0.0, 0.3),
    "iaido_line": (3, 1.8, 1.3, 0.0, 0.22),
    "rapier_slash": (2, 1.8, 1.3, 0.0, 0.16),
    "axe_slam": (4, 1.6, 2.4, 0.0, 0.32),
    "scythe_blade": (1, 1.8, 2.2, 0.0, 0.36),
    "rune_sigil": (4, 1.6, 1.9, 0.0, 0.38),
    "rapier_prick": (1, 1.8, 2.0, 0.0, 0.15),
    "spear_pierce": (1, 1.8, 1.3, 0.0, 0.16),
    # fifth pass (2026-10-11): painted beams, chain bolt and meteor
    "crystal_beam": (1, 1.7, 1.0, 0.0, 0.16),
    "frost_beam": (2, 1.7, 1.0, 0.0, 0.18),
    "storm_arc": (1, 1.5, 1.0, 0.0, 0.16),
    "meteor_fall": (2, 2.6, 1.0, 0.0, 0.5),
    "meteor_impact": (1, 3.0, 2.4, 0.0, 0.38),
    "fire_puddle": (3, 1.6, 2.4, 0.0, 0.5),
    # sixth pass (2026-10-11): one unique explosion per explosive weapon
    "explosion_bomb": (3, 1.6, 2.4, 0.0, 0.35),
    "explosion_flask": (1, 1.6, 2.4, 0.0, 0.35),
    "explosion_cannon": (1, 1.6, 2.4, 0.0, 0.35),
    # Demon Knight attacks (tools/art/gen_vfx_knight.py, 2026-10-16)
    "toon_iron_fx1": (1, 1.3, 2.2, 0.0, 0.45),
    "toon_iron_fx2": (1, 1.3, 2.2, 0.0, 0.4),
    "toon_iron_fx3": (1, 1.3, 2.2, 0.0, 0.45),
    "toon_iron_fx4": (1, 1.3, 2.2, 0.0, 0.45),
    "toon_iron_fx5": (1, 1.3, 2.2, 0.0, 0.4),
    "toon_silver_fx1": (1, 1.3, 2.2, 0.0, 0.45),
    "toon_silver_fx2": (1, 1.3, 2.2, 0.0, 0.4),
    "toon_silver_fx3": (1, 1.3, 2.2, 0.0, 0.45),
    "toon_silver_fx4": (1, 1.3, 2.2, 0.0, 0.45),
    "toon_silver_fx5": (1, 1.3, 2.2, 0.0, 0.4),
    "toon_gold_fx1": (1, 1.3, 2.2, 0.0, 0.45),
    "toon_gold_fx2": (1, 1.3, 2.2, 0.0, 0.4),
    "toon_gold_fx3": (1, 1.3, 2.2, 0.0, 0.45),
    "toon_gold_fx4": (1, 1.3, 2.2, 0.0, 0.45),
    "toon_gold_fx5": (1, 1.3, 2.2, 0.0, 0.4),
    "toon_obsidian_fx1": (1, 1.3, 2.2, 0.0, 0.45),
    "toon_obsidian_fx2": (1, 1.3, 2.2, 0.0, 0.4),
    "toon_obsidian_fx3": (1, 1.3, 2.2, 0.0, 0.45),
    "toon_obsidian_fx4": (1, 1.3, 2.2, 0.0, 0.45),
    "toon_obsidian_fx5": (3, 1.3, 2.2, 0.0, 0.4),
    "toon_astral_fx1": (1, 1.3, 2.2, 0.0, 0.45),
    "toon_astral_fx2": (1, 1.3, 2.2, 0.0, 0.4),
    "toon_astral_fx3": (1, 1.3, 2.2, 0.0, 0.45),
    "toon_astral_fx4": (1, 1.3, 2.2, 0.0, 0.45),
    "toon_astral_fx5": (1, 1.3, 2.2, 0.0, 0.4),
    "knighttd_blade": (1, 1.3, 2.2, 0.0, 0.35),
    "knighttd_step": (1, 1.3, 2.2, 0.0, 0.35),
    "knighttd_flame": (1, 1.3, 2.2, 0.0, 0.45),
    "toon_gold_wings": (1, 1.3, 2.2, 0.0, 0.4),
    "toon_iron_ring": (1, 1.3, 2.2, 0.0, 0.45),
    "toon_astral_ring": (1, 1.3, 2.2, 0.0, 0.45),
    "toon_gold_chain": (1, 1.3, 1.0, 0.0, 0.4),
    "toon_obsidian_web": (1, 1.3, 1.0, 0.0, 0.4),
    "toon_silver_wave": (1, 1.3, 1.0, 0.0, 0.4),
    "knighttd_strip": (1, 1.3, 1.0, 0.0, 0.4),
    "knightt_cross": (1, 1.3, 1.7, 0.0, 0.35),
    "knighttd_cross": (1, 1.3, 1.7, 0.0, 0.35),
    "knighttd_iaido": (1, 1.3, 2.2, 0.0, 0.4),
    "knightt_blade": (1, 1.3, 2.2, 0.0, 0.35),
    "knightt_step": (1, 1.3, 2.2, 0.0, 0.35),
    "knightt_iaido": (1, 1.3, 2.2, 0.0, 0.4),
    "knightt_flame": (1, 1.3, 2.2, 0.0, 0.45),
    "knight_cross": (1, 1.7, 2.2, 0.0, 0.35),
    "knight_blade": (1, 1.6, 2.2, 0.0, 0.35),
    "knight_step": (1, 1.5, 2.2, 0.0, 0.35),
    "knight_iaido": (1, 1.7, 2.2, 0.0, 0.4),
    "knight_flame": (1, 1.6, 2.2, 0.0, 0.45),
    "chest_projection": (1, 1.6, 1.0, 0.0, 1.2),
    # final bosses of the seals 2-6 (tools/art/gen_boss_kit.py fx, 2026-10-17)
    "iron_boss_final_fx1": (1, 1.6, 2.2, 0.0, 0.45),
    "iron_boss_final_fx2": (1, 1.6, 2.2, 0.0, 0.4),
    "iron_boss_final_fx3": (1, 1.6, 2.2, 0.0, 0.45),
    "iron_boss_final_fx4": (1, 1.6, 2.2, 0.0, 0.45),
    "iron_boss_final_fx5": (1, 1.6, 2.2, 0.0, 0.4),
    "silver_boss_final_fx1": (1, 1.6, 2.2, 0.0, 0.45),
    "silver_boss_final_fx2": (1, 1.6, 2.2, 0.0, 0.4),
    "silver_boss_final_fx3": (1, 1.6, 2.2, 0.0, 0.45),
    "silver_boss_final_fx4": (1, 1.6, 2.2, 0.0, 0.45),
    "silver_boss_final_fx5": (1, 1.6, 2.2, 0.0, 0.4),
    "gold_boss_final_fx1": (1, 1.6, 2.2, 0.0, 0.45),
    "gold_boss_final_fx2": (1, 1.6, 2.2, 0.0, 0.4),
    "gold_boss_final_fx3": (1, 1.6, 2.2, 0.0, 0.45),
    "gold_boss_final_fx4": (1, 1.6, 2.2, 0.0, 0.45),
    "gold_boss_final_fx5": (1, 1.6, 2.2, 0.0, 0.4),
    "obsidian_boss_final_fx1": (1, 1.6, 2.2, 0.0, 0.45),
    "obsidian_boss_final_fx2": (1, 1.6, 2.2, 0.0, 0.4),
    "obsidian_boss_final_fx3": (1, 1.6, 2.2, 0.0, 0.45),
    "obsidian_boss_final_fx4": (1, 1.6, 2.2, 0.0, 0.45),
    "obsidian_boss_final_fx5": (1, 1.6, 2.2, 0.0, 0.4),
    "astral_boss_final_fx1": (1, 1.6, 2.2, 0.0, 0.45),
    "astral_boss_final_fx2": (1, 1.6, 2.2, 0.0, 0.4),
    "astral_boss_final_fx3": (1, 1.6, 2.2, 0.0, 0.45),
    "astral_boss_final_fx4": (1, 1.6, 2.2, 0.0, 0.45),
    "astral_boss_final_fx5": (1, 1.6, 2.2, 0.0, 0.4),
    "explosion_staff": (1, 1.6, 2.4, 0.0, 0.35),
    # seventh pass: gravity well, frost zone and cone
    "gravity_well": (1, 1.6, 2.4, 0.0, 0.9),
    "well_collapse": (1, 1.6, 2.4, 0.0, 0.5),
    "frost_zone": (3, 1.6, 2.4, 0.0, 0.9),
}
# name: (candidate, cell file name)
CELLS = {
    "p_orb": (1, "01_orb"), "p_bullet": (1, "03_bullet"), "p_missile": (1, "04_missile"), 
    "p_fireball": (1, "07_fireball"), "p_ice_shard": (1, "08_ice_shard"), "p_lightning": (1, "09_lightning"),
    "p_arrow": (1, "10_arrow"),  "p_bomb": (1, "13_bomb"),
    "p_fire_flask": (1, "14_fire_flask"), "p_frost_flask": (1, "15_frost_flask"), "p_grenade": (1, "16_grenade"),
    "p_cannonball": (1, "17_cannonball"), "p_bomb_flask": (2, "23_bomb_flask"),
}

# Melee swings (dev notes, 2026-10-10): the specks (sparks, droplets, embers) around the art are visual noise.
# They are removed at bake time: every small isolated blob of a frame is erased.
NO_SPECKS = {"flame_wave", "iaido_line", "steel_slash", "fang_slash", "axe_slam", "hammer_smash", "rune_sigil",
             "rapier_slash", "rapier_prick", "spear_pierce", "crystal_beam", "frost_beam", "storm_arc",
             "meteor_fall", "meteor_impact", "frost_shards", "fire_puddle", "frost_zone"}
# Sheets made of dark solid matter (rock): their dark pixels stay opaque instead of fading with their brightness.
SOLID = {"meteor_fall", "meteor_impact"}
# Cartoon sheets (dev note 2026-10-17): hard edges, no soft halo; dark outline pixels stay opaque.
TOON_PREFIX = ("knightt", "toon_")
TOON_FIT = 0.82
NO_FIT = {"knighttd_strip", "toon_gold_chain", "toon_obsidian_web", "toon_silver_wave"}  # stretched along a line: its ends are already inside the cell
# Wider fade at the cell border (px of the baked cell): the art reaches the edge of its cell and the
# frame would show as a hard line (the sigil's light pillar was cut flat at the top).
SOFT_MARGIN = {"rune_sigil": 90}
SPECK_SIDE = 96  # masks are worked on at this size per frame
SPECK_KEEP = 0.10  # a blob smaller than this share of the frame's biggest blob is a speck
SPECK_KEEP_BY_SHEET = {"frost_shards": 0.3, "fire_puddle": 0.3, "frost_zone": 0.3}  # dev note 2026-10-19: fewer loose particles


def strip_specks(image: Image.Image, columns: int, rows: int, keep: float = SPECK_KEEP) -> None:
    """Erases the small isolated blobs (and their halo) of every frame, in place."""
    cell_w, cell_h = image.width // columns, image.height // rows
    alpha_full = image.getchannel("A")
    small = alpha_full.resize((columns * SPECK_SIDE, rows * SPECK_SIDE), Image.BOX)
    pixels = small.load()
    erase = Image.new("L", small.size, 0)
    erase_pixels = erase.load()
    for r in range(rows):
        for c in range(columns):
            x0, y0 = c * SPECK_SIDE, r * SPECK_SIDE
            seen = set()
            blobs = []
            for y in range(SPECK_SIDE):
                for x in range(SPECK_SIDE):
                    if (x, y) in seen or pixels[x0 + x, y0 + y] < 40:
                        continue
                    stack = [(x, y)]
                    seen.add((x, y))
                    blob = []
                    while stack:
                        cx, cy = stack.pop()
                        blob.append((cx, cy))
                        for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1), (cx + 1, cy + 1), (cx - 1, cy - 1), (cx + 1, cy - 1), (cx - 1, cy + 1)):
                            if 0 <= nx < SPECK_SIDE and 0 <= ny < SPECK_SIDE and (nx, ny) not in seen and pixels[x0 + nx, y0 + ny] >= 40:
                                seen.add((nx, ny))
                                stack.append((nx, ny))
                    blobs.append(blob)
            if not blobs:
                continue
            biggest = max(len(b) for b in blobs)
            for blob in blobs:
                if len(blob) < biggest * keep:
                    for bx, by in blob:
                        for dx in (-1, 0, 1):
                            for dy in (-1, 0, 1):
                                ex, ey = bx + dx, by + dy
                                if 0 <= ex < SPECK_SIDE and 0 <= ey < SPECK_SIDE:
                                    erase_pixels[x0 + ex, y0 + ey] = 255
    mask = erase.resize(image.size, Image.BILINEAR).filter(ImageFilter.GaussianBlur(2))
    keep = ImageChops.invert(mask)
    image.putalpha(ImageChops.multiply(alpha_full, keep))
    red, green, blue, alpha = image.split()
    image.paste(Image.merge("RGBA", (ImageChops.multiply(red, keep), ImageChops.multiply(green, keep), ImageChops.multiply(blue, keep), image.getchannel("A"))))


# Sheets whose art runs edge to edge (lines): their reach is the whole half-frame.
LINES = {"iaido_line": 0.97, "spear_pierce": 0.97, "rapier_slash": 0.97, "crystal_beam": 0.97, "frost_beam": 0.97,
         "storm_arc": 0.97}
# Extra EffectSheet fields written after the template. squash: height of a plain sheet relative to its width (the
# meteor impact is painted in perspective, an oval: it is stretched back to the round damage circle). head: where the
# meteor's rock sits in its frame, as a share of the frame side from the center (it lands on the impact point).
EXTRA = {"meteor_impact": "squash = 1.35", "frost_zone": "opacity = 0.9", "explosion_flask": "squash = 1.4",
         "meteor_fall": "head = Vector2(0.26, 0.18)\nart_angle = 0.64"}

TRES = """[gd_resource type="Resource" script_class="EffectSheet" format=3]

[ext_resource type="Script" path="res://src/vfx/effect_sheet.gd" id="1_sheet"]
[ext_resource type="Texture2D" path="res://assets/vfx/{name}.png" id="2_tex"]

[resource]
script = ExtResource("1_sheet")
texture = ExtResource("2_tex")
columns = {columns}
rows = {rows}
frames = {frames}
duration = {duration}
scale = {scale}
forward = {forward}
reach = {reach}
"""


def measure_reach(image: Image.Image, columns: int, rows: int) -> float:
    """How far the art reaches from the frame center, as a share of half a frame: the radius that
    holds 95 % of the painted mass, worst frame (so a damage circle matches what is seen)."""
    side = 96  # measured on a small copy of the alpha channel
    alpha = image.getchannel("A").resize((columns * side, rows * side), Image.BOX)
    pixels = alpha.load()
    half = side / 2.0
    worst = 0.0
    for r in range(rows):
        for c in range(columns):
            bins = [0.0] * 200
            total = 0.0
            for y in range(side):
                for x in range(side):
                    a = pixels[c * side + x, r * side + y]
                    if a:
                        d = math.hypot(x + 0.5 - half, y + 0.5 - half)
                        bins[min(199, int(d / half * 100.0))] += a
                        total += a
            if total < 1.0:
                continue
            run = 0.0
            for k, mass in enumerate(bins):
                run += mass
                if run >= 0.95 * total:
                    worst = max(worst, (k + 1) / 100.0)
                    break
    return max(0.2, min(1.0, worst))


# Sheets whose frames were doubled by tools/art/interpolate_sheet.py: art_tests/vfx_hd/<name>_x2.png, 8 columns of 320 px cells.
X2 = {"explosion_fire", "explosion_frost", "explosion_blast", "explosion_star", "explosion_bomb", "explosion_flask",
      "explosion_cannon", "explosion_staff", "hammer_smash", "axe_slam", "meteor_impact", "rune_sigil",
      "fire_puddle", "meteor_fall", "scythe_blade", "gravity_well", "well_collapse", "frost_zone"}
X2_CELL = 320


# Sheets whose drawing points somewhere (a beam, a crescent, a cone): only their vertical offset is corrected.
DIRECTIONAL = ("iaido", "strip", "chain", "web", "wave", "gold_fx4", "astral_fx1", "astral_fx2", "astral_fx5", "silver_fx2", "silver_fx3")


def recentre(image: Image.Image, columns: int, rows: int, keep_x: bool) -> Image.Image:
    """Moves the drawing of the biggest frame onto the frame center (x too unless `keep_x`), every frame by the same shift."""
    cell_w, cell_h = image.width // columns, image.height // rows
    gray = image.convert("L")
    best = None
    for k in range(columns * rows):
        cell = gray.crop(((k % columns) * cell_w, (k // columns) * cell_h, (k % columns + 1) * cell_w, (k // columns + 1) * cell_h))
        box = cell.point(lambda v: 255 if v > 50 else 0).getbbox()
        if box and (best is None or (box[2] - box[0]) * (box[3] - box[1]) > best[0]):
            best = (( box[2] - box[0]) * (box[3] - box[1]), box)
    if best is None:
        return image
    box = best[1]
    dx = 0 if keep_x else round(cell_w / 2 - (box[0] + box[2]) / 2)
    dy = round(cell_h / 2 - (box[1] + box[3]) / 2)
    out = Image.new("RGB", image.size)
    for k in range(columns * rows):
        x0, y0 = (k % columns) * cell_w, (k // columns) * cell_h
        cell = image.crop((x0, y0, x0 + cell_w, y0 + cell_h))
        moved = Image.new("RGB", cell.size)  # the shifted copy stays inside its own cell
        moved.paste(cell, (dx, dy))
        out.paste(moved, (x0, y0))
    return out


def extent_reach(image: Image.Image, columns: int, rows: int, circle: bool = False) -> float:
    """How far the drawing of the biggest frame reaches from the frame center, as a share of half a frame: the painting is
    drawn exactly as big as the damage shape it is asked for. A line or a cone: the farthest point (no overshoot at its
    end). A round effect: the radius holding 95 % of the drawing (a few thin shards may stick out of the zone)."""
    cell_w, cell_h = image.width // columns, image.height // rows
    alpha = np.array(image.getchannel("A"))
    best = None
    for k in range(columns * rows):
        cell = alpha[(k // columns) * cell_h:(k // columns + 1) * cell_h, (k % columns) * cell_w:(k % columns + 1) * cell_w]
        count = int((cell > 60).sum())
        if count and (best is None or count > best[0]):
            best = (count, cell)
    if best is None:
        return 0.7
    ys, xs = np.nonzero(best[1] > 60)
    if circle:
        return float(np.percentile(np.hypot(xs - cell_w / 2, ys - cell_h / 2), 95)) / (cell_w / 2)
    return float(max(cell_w / 2 - xs.min(), xs.max() + 1 - cell_w / 2, cell_h / 2 - ys.min(), ys.max() + 1 - cell_h / 2)) / (cell_w / 2)


def bake_sheet(name: str) -> None:
    hd = name in SHEETS_HD
    pick, boost, scale, forward, duration = SHEETS_HD[name] if hd else SHEETS[name]
    doubled = name in X2
    image = Image.open((SRC_HD if hd else SRC) / (("%s_x2.png" % name) if doubled else ("%s_%d.png" % (name, pick)))).convert("RGB")
    columns = 8 if doubled else 4 if hd else 3
    rows = image.height // X2_CELL if doubled else (4 if image.width == image.height else 3) if hd else 2
    if hd and not doubled:  # 512 px cells are more than the game ever shows: 384 px keeps the texture memory in check
        image = image.resize((columns * HD_CELL, rows * HD_CELL), Image.LANCZOS)
    width, height = image.size
    cell_w, cell_h = width // columns, height // rows
    if name.startswith(TOON_PREFIX) and name not in NO_FIT:  # the flat art runs to the cell border: shrink every frame inside its cell (no cut edge)
        fitted = Image.new("RGB", image.size)
        for row in range(rows):
            for col in range(columns):
                box = (col * cell_w, row * cell_h, (col + 1) * cell_w, (row + 1) * cell_h)
                small = image.crop(box).resize((int(cell_w * TOON_FIT), int(cell_h * TOON_FIT)), Image.LANCZOS)
                fitted.paste(small, (box[0] + (cell_w - small.width) // 2, box[1] + (cell_h - small.height) // 2))
        image = fitted
    if name.startswith(TOON_PREFIX):  # the drawing sits a little off the frame center: shift every frame of the sheet by the same amount
        image = recentre(image, columns, rows, keep_x=any(tag in name for tag in DIRECTIONAL))
    source = image.load()
    out = Image.new("RGBA", image.size)
    pixels = out.load()
    toon = name.startswith(TOON_PREFIX)
    ramp = 12.0 if toon else 16.0 if name in SOLID else 60.0  # dark rock must be opaque, light is additive-like
    margin = SOFT_MARGIN.get(name, 10)  # px faded to nothing at every cell border: no grid line or neighbour bleed
    for y in range(height):
        fy = min(y % cell_h, cell_h - 1 - y % cell_h)
        for x in range(width):
            red, green, blue = source[x, y]
            m = max(red, green, blue)
            if m < (45 if toon else 22):
                continue  # the generator's near-black noise must not become a visible square
            fx = min(x % cell_w, cell_w - 1 - x % cell_w)
            edge = min(1.0, min(fx, fy) / margin)
            k = (min(1.0, (m - (45 if toon else 22)) / ramp)) * edge
            pixels[x, y] = (int(red * edge), int(green * edge), int(blue * edge), min(255, int(m * boost * k)))
    if name in NO_SPECKS:
        strip_specks(out, columns, rows, SPECK_KEEP_BY_SHEET.get(name, SPECK_KEEP))
    out.save(ROOT / "assets/vfx" / (name + ".png"))
    reach = extent_reach(out, columns, rows, circle=not any(tag in name for tag in DIRECTIONAL)) if name.startswith(TOON_PREFIX) else LINES.get(name) or measure_reach(out, columns, rows)
    text = TRES.format(name=name, reach=round(reach, 3), duration=duration, scale=scale, forward=forward, columns=columns, rows=rows, frames=columns * rows)
    if name.startswith(TOON_PREFIX):
        text += "hostile = true" + chr(10)  # a boss attack: never faded around the hero
    if name in EXTRA:
        text += EXTRA[name] + "\n"
    (ROOT / "data/vfx" / (name + ".tres")).write_text(text, encoding="utf-8", newline="\n")
    print("sheet", name)


def bake_cell(name: str) -> None:
    pick, file_name = CELLS[name]
    image = Image.open(SRC / ("%s_%d.png" % (name, pick))).convert("RGB")
    brightest = ImageChops.lighter(ImageChops.lighter(*image.split()[:2]), image.split()[2])
    source = image.load()
    peak = brightest.load()
    out = Image.new("RGBA", image.size)
    pixels = out.load()
    for y in range(image.height):
        for x in range(image.width):
            m = peak[x, y]
            if m < 8:
                continue
            red, green, blue = source[x, y]
            k = 255.0 / m
            alpha = int(255 * min(1.0, max(0.0, (m / 255.0 - 0.03) / 0.5)) ** 0.8)
            pixels[x, y] = (min(255, int(red * k)), min(255, int(green * k)), min(255, int(blue * k)), alpha)
    out.save(ROOT / "art_source/ai/projectiles" / (file_name + ".png"))
    out.save(ROOT / "assets_src/drawn/projectiles" / (file_name + ".png"))
    print("cell", name, "->", file_name)


def main() -> None:
    (ROOT / "assets/vfx").mkdir(exist_ok=True)
    (ROOT / "data/vfx").mkdir(exist_ok=True)
    names = sys.argv[1:] or [*dict.fromkeys([*SHEETS, *SHEETS_HD]), *CELLS]
    for name in names:
        if name in SHEETS or name in SHEETS_HD:
            bake_sheet(name)
        else:
            bake_cell(name)


if __name__ == "__main__":
    main()
