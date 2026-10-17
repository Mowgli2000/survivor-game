"""Cuts the AI animation sheets of a boss (tools/art/gen_boss_anim.py, 4 x 4 poses each) into ONE grid texture
for `EnemyData.attack_sheet` (a SpriteSheet with several animations). Every pose is aligned on the ground line of
the reference pose and all poses share one crop box and one scale, so the boss keeps the same size in every animation.

Usage: python tools/art/make_boss_anim.py --boss shogun --out assets/sprites/shogun_anim
           attack=attack_windup:1+attack_strike:2 entrance=entrance:1 phase=phase:1 death=death:2 [--height 320] [--columns 8]
Each `name=sheet:pick[@poses][+sheet:pick[@poses]]` is one animation (sheets chained in order; `@1-8,11` keeps only
those poses, numbered from 1). Writes <out>.png and prints the
SpriteSheet animations (first cell, frame count) to copy into the .tres.
"""

import argparse
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
COLUMNS = 4
ROWS = 4
BODY_ALPHA = 160  # the painted body is above this, soft glow and smoke below
MIN_BODY_PIXELS = 4000  # fewer: the pose is smoke or embers, no ground line can be read
FEET_SHARE = 0.25
BELOW_FEET = 24
EDGE_CLEAR = 10
BOX_MARGIN = 28  # source pixels of empty space around the union of all poses


SOLID_ALPHA = 40  # what counts as drawn when looking for the pieces of a pose
MERGE_PIXELS = 3  # pieces closer than this belong together (outline gaps)
HAZE_ALPHA = 22  # fainter than this is the generator's haze: no square of it may remain
MIN_PIECE = 30  # smaller pieces are specks
CELL_PAD = 220  # a sword may cross its cell: each pose gets this margin around its cell


def split_at_necks(solid: np.ndarray, mask: np.ndarray, box: tuple, by_cell: np.ndarray, cell_of_pixel: np.ndarray) -> None:
    """A shape that joins two poses (their wings touch) is cut where it is narrowest, between the bodies, instead of
    along the border of the generation grid (a straight cut across a wing, a stray piece of the neighbour). Seeds: the
    thick core of the shape inside each cell it reaches; the pixels are flooded from them over the shape's thickness."""
    from scipy import ndimage as ndi
    sub = (slice(box[0].start, box[0].stop), slice(box[1].start, box[1].stop))
    shape = mask[sub] & solid[sub]
    if shape.sum() == 0:
        return
    thick = ndi.distance_transform_edt(shape)
    cells = by_cell[sub]
    markers = np.zeros(shape.shape, dtype=np.int32)
    for cell in np.unique(cells[shape]):
        inside = shape & (cells == cell)
        if inside.sum() < MIN_BODY_PIXELS:
            continue  # a tip of the shape that only reaches into this cell: it belongs to the others
        peak = thick[inside].max()
        markers[inside & (thick >= peak * 0.6)] = int(cell) + 1
    if len(np.unique(markers)) < 3:
        return  # one body only: nothing to split
    cost = (255 - (thick / max(thick.max(), 1.0) * 255)).astype(np.uint8)
    flooded = ndi.watershed_ift(cost, markers)
    flooded[~shape] = 0
    region = cell_of_pixel[sub]
    region[flooded > 0] = flooded[flooded > 0] - 1
    cell_of_pixel[sub] = region


def cut(sheet: Image.Image) -> list:
    """The 16 poses of a sheet, each rebuilt from the pieces (connected shapes) whose center lies in
    its cell: a sword crossing the cell border stays whole, a fragment of the neighbouring pose is left out,
    and the haze of the generator is cleared (no visible square around the boss)."""
    from scipy import ndimage as ndi
    cw, ch = sheet.width // COLUMNS, sheet.height // ROWS
    pixels = np.array(sheet)
    solid = pixels[..., 3] > SOLID_ALPHA
    grown = ndi.binary_dilation(solid, structure=np.ones((3, 3)), iterations=MERGE_PIXELS)
    labels, count = ndi.label(grown)
    sizes = ndi.sum(solid, labels, range(1, count + 1))
    centers = ndi.center_of_mass(solid, labels, range(1, count + 1))
    owner = np.full(count + 1, -1, dtype=np.int32)
    for i in range(count):
        if sizes[i] < MIN_PIECE:
            continue
        cy, cx = centers[i]
        owner[i + 1] = min(int(cy // ch), ROWS - 1) * COLUMNS + min(int(cx // cw), COLUMNS - 1)
    cell_of_pixel = owner[labels]
    # A shape that spans two poses (wings touching the neighbour's) cannot be given to one of them:
    # its pixels go to the cell they lie in.
    boxes = ndi.find_objects(labels)
    ys_all, xs_all = np.indices(labels.shape)
    by_cell = np.minimum(ys_all // ch, ROWS - 1) * COLUMNS + np.minimum(xs_all // cw, COLUMNS - 1)
    for i, box in enumerate(boxes):
        if box is None or owner[i + 1] < 0:
            continue
        height, width = box[0].stop - box[0].start, box[1].stop - box[1].start
        if width > cw * 1.3 or height > ch * 1.3:
            mask = labels == i + 1
            cell_of_pixel[mask] = by_cell[mask]
            split_at_necks(solid, mask, box, by_cell, cell_of_pixel)
    result = []
    padded = np.pad(pixels, ((CELL_PAD, CELL_PAD), (CELL_PAD, CELL_PAD), (0, 0)))
    padded_owner = np.pad(cell_of_pixel, CELL_PAD, constant_values=-1)
    for i in range(COLUMNS * ROWS):
        # The pose's pieces, wherever they reach (up to CELL_PAD beyond its cell).
        x0, y0 = (i % COLUMNS) * cw, (i // COLUMNS) * ch
        window = (slice(y0, y0 + ch + 2 * CELL_PAD), slice(x0, x0 + cw + 2 * CELL_PAD))
        piece = padded[window].copy()
        piece[padded_owner[window] != i, 3] = 0
        piece[piece[..., 3] < HAZE_ALPHA, 3] = 0
        result.append(Image.fromarray(piece))
    return result


def feet_of(alpha: np.ndarray):
    """(x center, y bottom) of the painted body's feet, None when the pose has no readable body."""
    ys, xs = np.where(alpha > BODY_ALPHA)
    if len(ys) < MIN_BODY_PIXELS:
        return None
    y0, y1 = ys.min(), ys.max() + 1
    rows = alpha[int(y1 - (y1 - y0) * FEET_SHARE):y1]
    ry, rx = np.where(rows > BODY_ALPHA)
    return float(rx.mean()), float(y1)


def picked(spec: str) -> list:
    """'1-8,9,11' -> [1..8, 9, 11] (poses numbered from 1)."""
    result = []
    for part in spec.split(","):
        if "-" in part:
            first, last = part.split("-")
            result.extend(range(int(first), int(last) + 1))
        else:
            result.append(int(part))
    return result


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--boss", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--height", type=int, default=320)
    parser.add_argument("--columns", type=int, default=8)
    parser.add_argument("animations", nargs="+")
    args = parser.parse_args()
    source = ROOT / "art_tests/boss_anim" / args.boss
    names, poses = [], []
    for spec in args.animations:
        name, chain = spec.split("=")
        frames = []
        for part in chain.split("+"):
            part, _, wanted = part.partition("@")
            sheet, pick = part.split(":")
            cells = cut(Image.open(source / ("%s_%s.png" % (sheet, pick))).convert("RGBA"))
            if wanted:
                cells = [cells[i - 1] for i in picked(wanted)]
            frames.extend(cells)
        names.append(name)
        poses.append(frames)
    cw, ch = poses[0][0].size  # a padded pose (cell + CELL_PAD each side)
    # Ground line of the reference: the first pose of the first animation.
    ref = feet_of(np.array(poses[0][0])[..., 3])
    if ref is None:
        raise SystemExit("the first pose of the first animation has no readable body")
    pad = max(cw, ch)
    canvas_size = (cw + pad * 2, ch + pad * 2)
    aligned: list = []
    box = None
    for frames in poses:
        row = []
        last_shift = (0, 0)
        for cell in frames:
            alpha = np.array(cell)[..., 3]
            feet = feet_of(alpha)
            shift = (int(round(ref[0] - feet[0])), int(round(ref[1] - feet[1]))) if feet is not None else last_shift
            last_shift = shift
            canvas = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
            canvas.alpha_composite(cell, (pad + shift[0], pad + shift[1]))
            row.append(canvas)
            ys, xs = np.where(np.array(canvas)[..., 3] > 12)
            if len(ys):
                b = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
                box = b if box is None else (min(box[0], b[0]), min(box[1], b[1]), max(box[2], b[2]), max(box[3], b[3]))
        aligned.append(row)
    feet_y = pad + ref[1]
    box = (box[0], box[1], box[2], min(box[3], int(feet_y) + BELOW_FEET))
    # A margin all round: a sword tip must never touch the border of its cell (it would show as a cut).
    box = (box[0] - BOX_MARGIN, box[1] - BOX_MARGIN, box[2] + BOX_MARGIN, box[3] + BOX_MARGIN)
    box_w, box_h = box[2] - box[0], box[3] - box[1]
    scale = args.height / box_h
    cell_w = round(box_w * scale)
    cells = []
    first = {}
    for name, row in zip(names, aligned):
        first[name] = len(cells)
        for canvas in row:
            piece = canvas.crop(box).resize((cell_w, args.height), Image.LANCZOS)
            arr = np.array(piece)
            arr[:, :EDGE_CLEAR, 3] = 0
            arr[:, -EDGE_CLEAR:, 3] = 0
            cells.append(Image.fromarray(arr))
    rows = -(-len(cells) // args.columns)
    atlas = Image.new("RGBA", (cell_w * args.columns, args.height * rows), (0, 0, 0, 0))
    for i, cell in enumerate(cells):
        atlas.alpha_composite(cell, ((i % args.columns) * cell_w, (i // args.columns) * args.height))
    atlas.save(ROOT / (args.out + ".png"))
    print("cell %d x %d, %d columns x %d rows, %d cells" % (cell_w, args.height, args.columns, rows, len(cells)))
    ref_pose = np.array(poses[0][0])[..., 3]
    ys, xs = np.where(ref_pose > BODY_ALPHA)
    print("character height share of the cell: %.3f" % ((ys.max() - ys.min() + 1) / box_h))
    for name, row in zip(names, aligned):
        print("%s: first %d, frames %d" % (name, first[name], len(row)))


main()
