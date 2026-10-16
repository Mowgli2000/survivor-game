"""Cuts an AI attack sheet (3 columns x 2 rows, 6 frames) into one horizontal strip for
`EnemyData.attack_sheet`: every frame is aligned on the feet of the first one, then all are
cropped to the same box. Prints the numbers to copy into the enemy data.

Usage: python tools/art/make_boss_attack.py --sheet art_tests/shogun_attack/sheet_2.png
           --out assets/sprites/shogun_attack.png [--height 320]
"""

import argparse

import numpy as np
from PIL import Image

COLUMNS = 3
ROWS = 2
BODY_ALPHA = 160  # the soft glow is below this, the painted body above
FEET_SHARE = 0.25  # bottom share of the body used to find the feet
BELOW_FEET = 24  # source pixels kept under the feet (slash arcs, glow)
EDGE_CLEAR = 10  # pixels cleared at each side of a cell (neighbours' bleed)


def body_box(alpha: np.ndarray) -> tuple:
    ys, xs = np.where(alpha > BODY_ALPHA)
    return xs.min(), ys.min(), xs.max() + 1, ys.max() + 1


def feet_of(alpha: np.ndarray) -> tuple:
    """(x center, y bottom) of the painted body's feet."""
    x0, y0, x1, y1 = body_box(alpha)
    rows = alpha[int(y1 - (y1 - y0) * FEET_SHARE):y1]
    ys, xs = np.where(rows > BODY_ALPHA)
    return float(xs.mean()), float(y1)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--sheet", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--height", type=int, default=320)
    args = parser.parse_args()
    sheet = Image.open(args.sheet).convert("RGBA")
    cw, ch = sheet.width // COLUMNS, sheet.height // ROWS
    cells = [sheet.crop(((i % COLUMNS) * cw, (i // COLUMNS) * ch, (i % COLUMNS + 1) * cw, (i // COLUMNS + 1) * ch))
             for i in range(COLUMNS * ROWS)]
    ref_x, ref_y = feet_of(np.array(cells[0])[..., 3])
    # Same canvas for all frames, feet of every frame on the first frame's feet.
    pad = max(cw, ch)
    canvas_w, canvas_h = cw + pad * 2, ch + pad * 2
    aligned = []
    for cell in cells:
        fx, fy = feet_of(np.array(cell)[..., 3])
        canvas = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
        canvas.alpha_composite(cell, (int(round(pad + ref_x - fx)), int(round(pad + ref_y - fy))))
        aligned.append(canvas)
    # Union box of everything visible, bottom limited to just under the feet.
    union = None
    knight_height = 0
    for canvas in aligned:
        alpha = np.array(canvas)[..., 3]
        ys, xs = np.where(alpha > 12)
        box = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
        union = box if union is None else (min(union[0], box[0]), min(union[1], box[1]), max(union[2], box[2]), max(union[3], box[3]))
        bx0, by0, bx1, by1 = body_box(alpha)
        if canvas is aligned[0]:
            knight_height = by1 - by0  # the ready stance: the character's own height
    feet_y = pad + ref_y
    bottom = min(union[3], int(feet_y) + BELOW_FEET)
    box = (union[0], union[1], union[2], bottom)
    box_w, box_h = box[2] - box[0], box[3] - box[1]
    scale = args.height / box_h
    cell_w = round(box_w * scale)
    strip = Image.new("RGBA", (cell_w * len(aligned), args.height), (0, 0, 0, 0))
    for i, canvas in enumerate(aligned):
        piece = canvas.crop(box).resize((cell_w, args.height), Image.LANCZOS)
        arr = np.array(piece)
        arr[:, :EDGE_CLEAR, 3] = 0  # bleed from the neighbouring cell of the AI sheet
        arr[:, -EDGE_CLEAR:, 3] = 0
        piece = Image.fromarray(arr)
        strip.alpha_composite(piece, (i * cell_w, 0))
    strip.save(args.out)
    feet_in_cell = (feet_y - box[1]) / box_h  # 0..1 from the top of the cell
    print("cell size: %d x %d, frames: %d" % (cell_w, args.height, len(aligned)))
    print("knight height / cell height: %.3f" % (knight_height / box_h))
    print("feet at %.3f of the cell height (1.0 = bottom)" % feet_in_cell)


main()
