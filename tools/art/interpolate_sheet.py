"""Doubles the frames of a generated animation sheet by motion interpolation (optical flow), with no new image
generation (dev, 2026-10-11: the big slow animations - blasts, hammer smash - read as choppy at 24-27 images per second).
Reads art_tests/vfx_hd/<name>_<pick>.png (4 columns, square cells, black background), writes
art_tests/vfx_hd/<name>_x2.png: n frames become 2n - 1 (the last cell repeats the final frame to fill the grid),
8 columns. tools/art/bake_vfx.py bakes it (table GRIDS).
A looping animation (--loop before its name) also gets a frame between the last and the first: n frames become 2n.
Usage: python tools/art/interpolate_sheet.py [--loop] <name> <pick> [...]"""
import sys
from pathlib import Path

import cv2
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "art_tests/vfx_hd"
CELL = 320  # px of the output cells (the game draws these at 150-400 px)
OUT_COLUMNS = 8


def cut(sheet: np.ndarray, columns: int, rows: int) -> list:
    cell_h, cell_w = sheet.shape[0] // rows, sheet.shape[1] // columns
    return [sheet[r * cell_h:(r + 1) * cell_h, c * cell_w:(c + 1) * cell_w] for r in range(rows) for c in range(columns)]


def warp(image: np.ndarray, flow: np.ndarray, share: float) -> np.ndarray:
    height, width = image.shape[:2]
    grid_x, grid_y = np.meshgrid(np.arange(width, dtype=np.float32), np.arange(height, dtype=np.float32))
    return cv2.remap(image, grid_x + flow[..., 0] * share, grid_y + flow[..., 1] * share, cv2.INTER_LINEAR,
                     borderMode=cv2.BORDER_CONSTANT, borderValue=(0, 0, 0))


def midpoint(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    gray_a = a.max(axis=2).astype(np.uint8)
    gray_b = b.max(axis=2).astype(np.uint8)
    # Flow computed on a boosted, slightly blurred copy: dark edges of a blast must still guide it.
    boost = lambda g: cv2.GaussianBlur(np.clip(g.astype(np.float32) * 2.0, 0, 255).astype(np.uint8), (0, 0), 1.5)
    gray_a, gray_b = boost(gray_a), boost(gray_b)
    a_to_b = cv2.calcOpticalFlowFarneback(gray_a, gray_b, None, 0.5, 4, 25, 4, 7, 1.5, 0)
    b_to_a = cv2.calcOpticalFlowFarneback(gray_b, gray_a, None, 0.5, 4, 25, 4, 7, 1.5, 0)
    from_a = warp(a, b_to_a, 0.5)    # a, carried half-way toward b
    from_b = warp(b, a_to_b, 0.5)    # b, carried half-way back toward a
    return np.clip(0.5 * from_a.astype(np.float32) + 0.5 * from_b.astype(np.float32), 0, 255).astype(np.uint8)


def double(name: str, pick: int, loop: bool = False) -> None:
    sheet = cv2.imread(str(SRC / ("%s_%d.png" % (name, pick))))
    rows = 4 if sheet.shape[0] == sheet.shape[1] else 3
    frames = [cv2.resize(f, (CELL, CELL), interpolation=cv2.INTER_AREA) for f in cut(sheet, 4, rows)]
    out = []
    for k in range(len(frames) if loop else len(frames) - 1):
        out.append(frames[k])
        out.append(midpoint(frames[k], frames[(k + 1) % len(frames)]))
    if not loop:
        out.append(frames[-1])
    out_rows = -(-len(out) // OUT_COLUMNS)
    while len(out) < out_rows * OUT_COLUMNS:
        out.append(frames[-1])
    canvas = np.zeros((out_rows * CELL, OUT_COLUMNS * CELL, 3), np.uint8)
    for i, f in enumerate(out):
        canvas[(i // OUT_COLUMNS) * CELL:(i // OUT_COLUMNS + 1) * CELL, (i % OUT_COLUMNS) * CELL:(i % OUT_COLUMNS + 1) * CELL] = f
    cv2.imwrite(str(SRC / ("%s_x2.png" % name)), canvas)
    print(name, len(frames), "->", len(out), canvas.shape[1], "x", canvas.shape[0])


if __name__ == "__main__":
    args = sys.argv[1:]
    looping = False
    while args:
        if args[0] == "--loop":
            looping = True
            args = args[1:]
            continue
        double(args[0], int(args[1]), looping)
        args = args[2:]
