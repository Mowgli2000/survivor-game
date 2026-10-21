"""Cuts the arrow sheet (art_tests/proj/arrows_flat_1.png: 3 columns x 2 rows, flat cartoon style, a short trail behind
each shot) into the five projectile cells that tools/art/bake_map.gd packs into assets/sprites/projectiles.png.
Each shot is scaled to fill the width of its 1024 px cell, head at the right edge, on the horizontal axis.
Usage: python tools/art/bake_arrows.py, then powershell tools/bake_sprites.ps1"""
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from bake_proj import OUTS, key_solid  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
SHEET = ROOT / "art_tests/proj/arrows_flat_1.png"
CELL = 1024
FILL = 0.97  # share of the cell width the shot covers
# (column, row) -> cell file
CELLS = {
    (0, 0): "10_arrow",       # Arc long
    (1, 0): "22_star_arrow",  # Arc céleste
    (2, 0): "03_bullet",      # Arbalète à répétition
    (0, 1): "04_missile",     # Arbalète lourde
    (1, 1): "12_javelin",     # Javelot
}


def main() -> None:
    sheet = Image.open(SHEET).convert("RGB")
    width, height = sheet.width // 3, sheet.height // 2
    for (column, row), name in CELLS.items():
        part = key_solid(sheet.crop((column * width, row * height, (column + 1) * width, (row + 1) * height)))
        box = part.getchannel("A").point(lambda v: 255 if v > 24 else 0).getbbox()
        shot = part.crop(box)
        scale = min(CELL * FILL / shot.width, CELL * 0.9 / shot.height)
        shot = shot.resize((round(shot.width * scale), round(shot.height * scale)), Image.LANCZOS)
        cell = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
        cell.alpha_composite(shot, (round(CELL * (0.5 + FILL / 2)) - shot.width, (CELL - shot.height) // 2))
        for out in OUTS:
            cell.save(out / (name + ".png"))
        print("cell", name, shot.size)


if __name__ == "__main__":
    main()
