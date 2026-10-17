"""Measures the painted effect sheets (assets/vfx): for the biggest frame, the center offset of its drawing from the
frame center and its extent, as shares of half a frame. Usage: python tools/art/measure_sheets.py [name ...]"""
import glob
import os
import re
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def measure(name: str) -> str:
    tres = open(os.path.join(ROOT, "data/vfx", name + ".tres")).read()
    columns = int(re.search(r"columns = (\d+)", tres).group(1))
    rows = int(re.search(r"rows = (\d+)", tres).group(1))
    reach = float(re.search(r"reach = ([\d.]+)", tres).group(1))
    image = Image.open(os.path.join(ROOT, "assets/vfx", name + ".png")).convert("RGBA")
    alpha = image.getchannel("A")
    cw, ch = image.width // columns, image.height // rows
    best = None
    for k in range(columns * rows):
        cell = alpha.crop(((k % columns) * cw, (k // columns) * ch, (k % columns + 1) * cw, (k // columns + 1) * ch))
        box = cell.point(lambda v: 255 if v > 60 else 0).getbbox()
        if box:
            area = (box[2] - box[0]) * (box[3] - box[1])
            if best is None or area > best[0]:
                best = (area, box, k)
    _, box, k = best
    cx = ((box[0] + box[2]) / 2 - cw / 2) / (cw / 2)
    cy = ((box[1] + box[3]) / 2 - ch / 2) / (ch / 2)
    return "%-26s frame %2d  center off (%+.3f, %+.3f)  half w %.3f h %.3f  reach %.3f" % (
        name, k, cx, cy, (box[2] - box[0]) / cw, (box[3] - box[1]) / ch, reach)


if __name__ == "__main__":
    names = sys.argv[1:] or sorted(os.path.basename(p)[:-4] for p in glob.glob(os.path.join(ROOT, "assets/vfx/toon_*.png")) + glob.glob(os.path.join(ROOT, "assets/vfx/knighttd_*.png")))
    for n in names:
        print(measure(n))
