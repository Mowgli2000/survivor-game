"""Draws the five enemy shots as plain, bright balls (Brotato-like): thick black outline, vivid family color,
white-hot core, so they read at once against any floor and never look like a player shot.
Writes the 256 px cells that tools/art/bake_map.gd packs into assets/sprites/projectiles.png.
Usage: python tools/art/make_enemy_shots.py, then powershell tools/bake_sprites.ps1"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
OUTS = [ROOT / "art_source/ai/projectiles", ROOT / "assets_src/drawn/projectiles"]
SIZE = 256
SUPER = 4
# cell file: (edge color, body color, core color)
SHOTS = {
    "06_enemy_orb": ((150, 0, 30), (255, 40, 70), (255, 235, 235)),
    "18_enemy_ice": ((0, 90, 190), (40, 215, 255), (240, 255, 255)),
    "19_enemy_fire": ((170, 50, 0), (255, 140, 0), (255, 250, 190)),
    "20_enemy_acid": ((40, 120, 0), (140, 255, 0), (250, 255, 200)),
    "21_enemy_stone": ((130, 80, 0), (255, 205, 20), (255, 250, 200)),
}
BALL = 0.40  # outer diameter (outline included) vs. the cell


def lerp(a: tuple, b: tuple, t: float) -> tuple:
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def draw_ball(edge: tuple, body: tuple, core: tuple) -> Image.Image:
    big = SIZE * SUPER
    image = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    center = big / 2
    outer = big * BALL / 2
    # Soft halo outside the outline: the shot also reads on a busy floor.
    halo = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    ImageDraw.Draw(halo).ellipse((center - outer * 1.25, center - outer * 1.25, center + outer * 1.25, center + outer * 1.25),
        fill=body + (150,))
    image.alpha_composite(halo.filter(ImageFilter.GaussianBlur(big * 0.03)))
    draw.ellipse((center - outer, center - outer, center + outer, center + outer), fill=(8, 6, 10, 255))
    inner = outer * 0.82
    steps = 40
    for k in range(steps):  # radial gradient: dark edge -> vivid body -> white core
        t = k / (steps - 1)
        radius = inner * (1.0 - t)
        if t < 0.55:
            color = lerp(edge, body, t / 0.55)
        else:
            color = lerp(body, core, ((t - 0.55) / 0.45) ** 1.6)
        draw.ellipse((center - radius, center - radius, center + radius, center + radius), fill=color + (255,))
    # Small specular dot, top-left.
    r = inner * 0.2
    draw.ellipse((center - inner * 0.5 - r, center - inner * 0.5 - r, center - inner * 0.5 + r, center - inner * 0.5 + r),
        fill=(255, 255, 255, 255))
    return image.resize((SIZE, SIZE), Image.LANCZOS)


def main() -> None:
    for name, (edge, body, core) in SHOTS.items():
        cell = draw_ball(edge, body, core)
        for out in OUTS:
            cell.save(out / (name + ".png"))
        print("cell", name)


if __name__ == "__main__":
    main()
