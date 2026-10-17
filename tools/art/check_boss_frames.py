"""Looks for visible cuts in the frames of the boss animation atlases: a long straight edge (a pose chopped by the
generation grid) or a detached fragment (a piece of the neighbouring pose). Usage: python tools/art/check_boss_frames.py [boss ...]"""
import re
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

ROOT = Path(__file__).resolve().parents[2]
BOSSES = ["shogun", "iron_boss_final", "silver_boss_final", "gold_boss_final", "obsidian_boss_final", "astral_boss_final"]
STRAIGHT = 70  # px of a straight cut edge that is seen
FRAGMENT = 400  # px of a detached piece that is seen


def frames(boss: str):
    text = (ROOT / "assets/sprites" / (boss + "_attack.tres")).read_text()
    cw, ch = map(int, re.search(r"cell_size = Vector2i\((\d+), (\d+)\)", text).groups())
    columns = int(re.search(r"columns = (\d+)", text).group(1))
    anims = {m[0]: (int(m[1]), int(m[2])) for m in re.findall(r'&"(\w+)": Vector3i\((\d+), (\d+), \d+\)', text)}
    alpha = np.array(Image.open(ROOT / "assets/sprites" / (boss + "_anim.png")).convert("RGBA"))[..., 3]
    for name, (start, count) in anims.items():
        for k in range(count):
            f = start + k
            x0, y0 = (f % columns) * cw, (f // columns) * ch
            yield name, k, alpha[y0:y0 + ch, x0:x0 + cw]


def straight_cut(a: np.ndarray) -> int:
    solid = a > 128
    best = 0
    for axis in (0, 1):
        edge = np.diff(solid.astype(np.int8), axis=axis) != 0
        edge &= np.abs(np.diff(a.astype(np.int16), axis=axis)) > 150
        # longest run of edge pixels along the other axis, on one coordinate
        for line in (edge if axis == 1 else edge.T):
            pass
        lines = edge.T if axis == 1 else edge
        for row in (lines if axis == 1 else lines.T):
            runs = np.diff(np.flatnonzero(np.diff(np.concatenate(([0], row.astype(np.int8), [0])))))[::2]
            if len(runs):
                best = max(best, int(runs.max()))
    return best


def fragments(a: np.ndarray) -> int:
    solid = a > 40
    labels, count = ndi.label(ndi.binary_dilation(solid, iterations=3))
    if count < 2:
        return 0
    sizes = ndi.sum(solid, labels, range(1, count + 1))
    order = np.argsort(sizes)[::-1]
    return int(sizes[order[1]]) if sizes[order[1]] >= FRAGMENT else 0


if __name__ == "__main__":
    for boss in [a for a in sys.argv[1:] if a != "-v"] or BOSSES:
        report = {}
        for name, k, a in frames(boss):
            cut, frag = straight_cut(a), fragments(a)
            if cut >= STRAIGHT or frag:
                report.setdefault(name, []).append((k, cut, frag))
        print(boss, {n: len(v) for n, v in report.items()})
        if "-v" in sys.argv:
            for n, v in report.items():
                print("  ", n, v)
