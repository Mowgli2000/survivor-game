"""Draws the javelin projectile cell (12_javelin): a clean spear, no fire trail (the painted one read as burning).
Points right, like every projectile cell. Usage: python tools/art/make_javelin.py, then tools/bake_sprites.ps1"""
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
OUTS = [ROOT / "art_source/ai/projectiles", ROOT / "assets_src/drawn/projectiles"]
SIZE, SUPER = 256, 4
INK = (12, 8, 10, 255)


def main() -> None:
    big = SIZE * SUPER
    s = big / 256.0
    image = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(image)
    cy = 128

    def poly(points, fill, grow=0):
        d.polygon([(x * s, y * s) for x, y in points], fill=fill)

    # Shaft: ink outline, then wood.
    d.rounded_rectangle((20 * s, (cy - 7) * s, 190 * s, (cy + 7) * s), radius=6 * s, fill=INK)
    d.rounded_rectangle((24 * s, (cy - 4) * s, 188 * s, (cy + 4) * s), radius=4 * s, fill=(176, 120, 64, 255))
    d.rectangle((24 * s, (cy - 4) * s, 188 * s, (cy - 1) * s), fill=(214, 160, 96, 255))
    # Red binding + tail feathers.
    d.rectangle((168 * s, (cy - 9) * s, 180 * s, (cy + 9) * s), fill=INK)
    d.rectangle((170 * s, (cy - 7) * s, 178 * s, (cy + 7) * s), fill=(220, 40, 50, 255))
    poly([(20, cy), (6, cy - 16), (34, cy - 6)], INK)
    poly([(20, cy), (6, cy + 16), (34, cy + 6)], INK)
    poly([(21, cy), (11, cy - 11), (30, cy - 4)], (230, 230, 235, 255))
    poly([(21, cy), (11, cy + 11), (30, cy + 4)], (200, 200, 210, 255))
    # Steel head.
    poly([(176, cy - 20), (250, cy), (176, cy + 20), (190, cy)], INK)
    poly([(184, cy - 14), (240, cy), (184, cy + 14), (194, cy)], (205, 215, 230, 255))
    poly([(184, cy - 14), (240, cy), (194, cy)], (245, 250, 255, 255))
    cell = image.resize((SIZE, SIZE), Image.LANCZOS)
    for out in OUTS:
        cell.save(out / "12_javelin.png")
    print("cell 12_javelin")


if __name__ == "__main__":
    main()
