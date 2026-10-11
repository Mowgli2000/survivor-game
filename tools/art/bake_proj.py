"""Bakes the fourth pass of painted projectiles (tools/art/gen_proj.py, art_tests/proj) into the cells
tools/art/bake_map.gd cuts into assets/sprites/projectiles.png: black keyed to alpha, written to
art_source/ai/projectiles/ and assets_src/drawn/projectiles/.
Singles replace the cell of their style (clean flasks, enemy shots); the 6-frame loops (bomb fuse,
fireball, ice, lightning) become 6 extra cells each, after the 23 style cells (ProjectileRenderer.ANIM_FIRST).
Usage: python tools/art/bake_proj.py"""
import re
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "art_tests/proj"
OUTS = [ROOT / "art_source/ai/projectiles", ROOT / "assets_src/drawn/projectiles"]

# name: (candidate, cell file name)
SINGLES = {
    "c_fire_flask": (1, "14_fire_flask"), "c_frost_flask": (1, "15_frost_flask"), "c_bomb_flask2": (1, "23_bomb_flask"),
    "c_shard": (2, "02_bolt"), "c_grenade": (1, "16_grenade"), "c_cannonball": (1, "17_cannonball"),
    "e_orb": (1, "06_enemy_orb"), "e_ice": (1, "18_enemy_ice"), "e_fire": (2, "19_enemy_fire"),
    "e_acid": (1, "20_enemy_acid"), "e_stone": (2, "21_enemy_stone"),
}
# name: (candidate, first cell file number, cell file prefix)
# name: (candidate, first cell file number, cell file prefix, frames)  (12 frames = 4x3 sheet, 6 = 3x2)
LOOPS = {
    "a12_bomb": (2, 24, "bomb", 12), "a12_fireball": (2, 36, "fireball", 12), "a12_lightning": (2, 48, "lightning", 12),
    "a12_gravity_sphere": (1, 60, "gravity", 12), "a_grenade": (2, 72, "grenade", 6),
    "a12_shadowblade": (1, 78, "shadowblade", 12),
}


# Cells cut out of a grid image (tools/art/gen_proj.py, kind "sheet": 3 columns x 2 rows): name: list of (candidate, column,
# row, cell file name). The art fades out at the cell border. 04_missile (the unused MISSILE style) now draws the heavy bolt.
GRID_SINGLES = {
    "p_ranged": [(1, 0, 0, "10_arrow"), (2, 2, 0, "03_bullet"), (2, 1, 0, "04_missile"), (1, 0, 1, "12_javelin"), (1, 1, 1, "11_stone")],
}


def key(image: Image.Image) -> Image.Image:
    """Black background -> alpha (alpha = brightest channel), color un-premultiplied."""
    image = image.convert("RGB")
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
    return out


def key_solid(image: Image.Image) -> Image.Image:
    """Dark objects (a black bomb, a cannonball, a hostile core): the whole silhouette stays opaque. The background is
    what a flood fill from the corners reaches over the (slightly grown) non-black pixels, so a dark body or a dark
    patch inside it is never keyed away, even when its dark outline touches the black background."""
    rgb = image.convert("RGB")
    brightest = ImageChops.lighter(ImageChops.lighter(*rgb.split()[:2]), rgb.split()[2])
    grow = max(5, (rgb.width // 100) | 1)  # odd filter size: about 2 % of the image
    closed = brightest.point(lambda v: 0 if v < 14 else 255).filter(ImageFilter.MaxFilter(grow))
    for corner in ((0, 0), (closed.width - 1, 0), (0, closed.height - 1), (closed.width - 1, closed.height - 1)):
        if closed.getpixel(corner) == 0:
            ImageDraw.floodfill(closed, corner, 128, thresh=0)
    body = closed.point(lambda v: 0 if v == 128 else 255).filter(ImageFilter.MinFilter(grow))
    alpha = body.filter(ImageFilter.GaussianBlur(1.2))
    # Glow outside the body keeps its soft brightness alpha.
    soft = key(rgb).getchannel("A")
    out = rgb.convert("RGBA")
    out.putalpha(ImageChops.lighter(alpha, soft))
    return out


def stabilize(frames: list) -> list:
    """The generator lets a rigid object drift between frames (a dagger stepping 7 px up from one row of the sheet to the
    next shows as a jump in the loop). Every frame is shifted so its solid body (alpha > 200: the smoke and sparks are
    fainter) has the same left edge and bottom edge as the median frame."""
    boxes = [f.getchannel("A").point(lambda v: 255 if v > 200 else 0).getbbox() for f in frames]
    left = sorted(b[0] for b in boxes)[len(boxes) // 2]
    bottom = sorted(b[3] for b in boxes)[len(boxes) // 2]
    out = []
    for f, b in zip(frames, boxes):
        shifted = Image.new("RGBA", f.size, (0, 0, 0, 0))
        shifted.paste(f, (left - b[0], bottom - b[3]))
        out.append(shifted)
    return out


def fade_edges(image: Image.Image, margin: int = 24) -> Image.Image:
    """The generator lets long shafts run to the cell border: fade the alpha to nothing over `margin` px."""
    alpha = image.getchannel("A")
    ramp = Image.new("L", image.size, 255)
    pixels = ramp.load()
    for y in range(image.height):
        for x in range(image.width):
            edge = min(x, y, image.width - 1 - x, image.height - 1 - y)
            if edge < margin:
                pixels[x, y] = int(255 * edge / margin)
    image.putalpha(ImageChops.multiply(alpha, ramp))
    return image


def save(image: Image.Image, file_name: str) -> None:
    image = image.resize((256, 256), Image.LANCZOS)  # the strip cell is 128 px: keep 2x for the downscale
    for out in OUTS:
        image.save(out / (file_name + ".png"))
    print("cell", file_name)


def main() -> None:
    for name, (pick, file_name) in SINGLES.items():
        save(key_solid(Image.open(SRC / ("%s_%d.png" % (name, pick)))), file_name)
    for name, cells in GRID_SINGLES.items():
        for pick, column, row, file_name in cells:
            sheet = Image.open(SRC / ("%s_%d.png" % (name, pick))).convert("RGB")
            side = sheet.width // 3
            cell = sheet.crop((column * side, row * side, (column + 1) * side, (row + 1) * side))
            save(fade_edges(key(cell)), file_name)
    for out in OUTS:  # the loops are renumbered: drop every old loop cell first
        for old in out.glob("*.png"):
            if re.match(r"^\d\d_(bomb|fireball|ice|lightning|orb|gravity|grenade|shadowblade)_\d+$", old.stem):
                old.unlink()
    for name, (pick, first, prefix, frames) in LOOPS.items():
        sheet = Image.open(SRC / ("%s_%d.png" % (name, pick))).convert("RGB")
        columns = 4 if frames == 12 else 3
        cell = sheet.width // columns
        keyed = []
        for k in range(frames):
            frame = sheet.crop(((k % columns) * cell, (k // columns) * cell, (k % columns + 1) * cell, (k // columns + 1) * cell))
            keyed.append(key_solid(frame) if prefix in ("bomb", "grenade", "gravity") else key(frame))
        if prefix in ("shadowblade", "gravity"):
            keyed = stabilize(keyed)
        for k, image in enumerate(keyed):
            save(image, "%02d_%s_%d" % (first + k, prefix, k + 1))


if __name__ == "__main__":
    main()
