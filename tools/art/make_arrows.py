"""Draws the long bow arrow and the heavy crossbow bolt as flat cartoon shots: a solid shaft and head with a dark outline
and ONE tapered streak BEHIND them (nothing floats around the shot: no sparks, no wisps).
Writes the 1024 px cells 10_arrow (long bow) and 04_missile (heavy crossbow) that tools/art/bake_map.gd packs into
assets/sprites/projectiles.png. The art points right, the head touches the right edge, the trail fades out on the left.
Usage: python tools/art/make_arrows.py, then powershell tools/bake_sprites.ps1"""
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
OUTS = [ROOT / "art_source/ai/projectiles", ROOT / "assets_src/drawn/projectiles"]
SIZE = 1024
SUPER = 2
OUTLINE = (14, 18, 40, 255)


def px(value: float) -> float:
    return value * SIZE * SUPER


def poly(draw: ImageDraw.ImageDraw, points: list, fill: tuple, outline_width: float = 0.0) -> None:
    pts = [(px(x), px(y)) for x, y in points]
    draw.polygon(pts, fill=fill)
    if outline_width > 0.0:
        draw.line(pts + [pts[0]], fill=OUTLINE, width=int(px(outline_width)), joint="curve")


def streak(draw: ImageDraw.ImageDraw, tail_x: float, head_x: float, half: float, body: tuple, core: tuple) -> None:
    """Three nested tapered strokes: dark outline, color body, bright core. Widest at the head end, a point at the tail."""
    cy = 0.5
    for grow, color in ((1.0, OUTLINE), (0.8, body), (0.4, core)):
        h = half * grow
        poly(draw, [(tail_x, cy), (tail_x + (head_x - tail_x) * 0.55, cy - h), (head_x, cy - h * 0.55),
                    (head_x, cy + h * 0.55), (tail_x + (head_x - tail_x) * 0.55, cy + h)], color)


def arrow(body: tuple, core: tuple, feather: tuple) -> Image.Image:
    image = Image.new("RGBA", (SIZE * SUPER, SIZE * SUPER), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    streak(draw, 0.04, 0.50, 0.075, body, core)
    # shaft
    poly(draw, [(0.30, 0.488), (0.88, 0.488), (0.88, 0.512), (0.30, 0.512)], (176, 120, 56, 255), 0.008)
    # fletching: two swept feathers
    for sign in (-1, 1):
        poly(draw, [(0.30, 0.5), (0.43, 0.5 + sign * 0.07), (0.455, 0.5 + sign * 0.07), (0.40, 0.5)], feather, 0.007)
    # steel head
    poly(draw, [(0.86, 0.455), (0.985, 0.5), (0.86, 0.545), (0.895, 0.5)], (214, 224, 236, 255), 0.009)
    return image.resize((SIZE, SIZE), Image.LANCZOS)


def bolt(body: tuple, core: tuple) -> Image.Image:
    """The heavy bolt: a thick dark-steel shaft, a broad head, a short orange streak."""
    image = Image.new("RGBA", (SIZE * SUPER, SIZE * SUPER), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    streak(draw, 0.12, 0.52, 0.09, body, core)
    poly(draw, [(0.38, 0.472), (0.90, 0.472), (0.90, 0.528), (0.38, 0.528)], (96, 104, 124, 255), 0.01)
    poly(draw, [(0.38, 0.49), (0.90, 0.49), (0.90, 0.5), (0.38, 0.5)], (170, 180, 200, 255))
    for sign in (-1, 1):
        poly(draw, [(0.38, 0.5), (0.46, 0.5 + sign * 0.075), (0.50, 0.5 + sign * 0.075), (0.47, 0.5)], (228, 70, 60, 255), 0.008)
    poly(draw, [(0.88, 0.43), (0.985, 0.5), (0.88, 0.57), (0.915, 0.5)], (226, 232, 242, 255), 0.01)
    return image.resize((SIZE, SIZE), Image.LANCZOS)


def main() -> None:
    cells = {
        "10_arrow": arrow((120, 205, 255, 255), (245, 252, 255, 255), (245, 245, 250, 255)),
        "04_missile": bolt((255, 150, 30, 255), (255, 240, 170, 255)),
    }
    for name, cell in cells.items():
        for out in OUTS:
            cell.save(out / (name + ".png"))
        print("cell", name)


if __name__ == "__main__":
    main()
