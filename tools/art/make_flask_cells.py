"""Builds the three flask projectile cells (14_fire_flask, 15_frost_flask, 23_bomb_flask) from the weapon icons, so a
thrown flask is the flask of its icon (like the bomb), spinning in flight, not a flaming comet.
Usage: python tools/art/make_flask_cells.py, then tools/bake_sprites.ps1"""
from pathlib import Path

from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
OUTS = [ROOT / "art_source/ai/projectiles", ROOT / "assets_src/drawn/projectiles"]
CELLS = {"14_fire_flask": "fire_flask", "15_frost_flask": "frost_flask", "23_bomb_flask": "bazooka"}
SIZE = 256
FILL = 0.9  # share of the cell the flask takes: it spins, so it must fit as a disc


def main() -> None:
    for cell_name, icon_name in CELLS.items():
        icon = Image.open(ROOT / "assets/icons/weapons" / (icon_name + ".png")).convert("RGBA")
        icon = icon.crop(icon.getchannel("A").getbbox())
        scale = SIZE * FILL / max(icon.size)
        flask = icon.resize((round(icon.width * scale), round(icon.height * scale)), Image.LANCZOS)
        cell = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        cell.paste(flask, ((SIZE - flask.width) // 2, (SIZE - flask.height) // 2), flask)
        for out in OUTS:
            cell.save(out / (cell_name + ".png"))
        print("cell", cell_name)


if __name__ == "__main__":
    main()
