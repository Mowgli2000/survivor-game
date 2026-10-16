"""Painted effects of the Demon Knight's attacks (danger 1 final boss), same pipeline and look as
tools/art/gen_vfx_hd.py: 4 x 3 grid of 12 frames, 2 candidates per job in art_tests/vfx_hd/<name>_1.png / _2.png.
Existing jobs are skipped. Usage: python tools/art/gen_vfx_knight.py [name ...]   (no name: all jobs)
Baked by tools/art/bake_vfx.py (table SHEETS_HD)."""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "art_tests/vfx_hd"

STYLE = ("Hand-painted stylized 2D game VFX in the style of Hades 2 and anime action (Demon Slayer, Bleach): a white-hot core, "
         "saturated glowing color around it, layered painterly shapes with sharp tapered shards and fluid ribbons, a few sparkles, "
         "same painterly look as the reference images. Palette: crimson red, deep blood red and black smoke with white-hot highlights "
         "(a demon knight's cursed fire). No characters, no text, no border, no floor.")
GRID12 = ("A sprite sheet of ONE smooth animation in a grid of 4 columns by 3 rows, 12 equal square cells read left to right then "
          "top to bottom. Every cell is a consecutive moment of the same motion, each slightly further along than the previous one, "
          "so the animation plays fluidly. Keep the whole effect well inside its cell with a margin of black on every side, nothing "
          "crossing the cell borders, no grid lines, pure black background (#000000). ")
SEEN = "Seen from above. In every cell the effect is centered on the cell center. "
TIMELINE = ("Timeline: cells 1-2 a thin faint beginning; cells 3-6 it grows quickly; cells 7-8 the full brightest shape; "
            "cells 9-12 it thins, breaks up and fades into a few sparkles. ")

REFS = ["art_tests/vfx_hd/flame_slash_1.png", "art_tests/vfx_hd/steel_slash_1.png", "art_tests/vfx_hd/explosion_fire_2.png"]

JOBS = {
    "knight_cross": SEEN + ("A big CROSS slash: two long straight diagonal cuts of crimson and white-hot light crossing each other in an X, "
        "each cut as long as most of the cell, tapered at both ends, leaving glowing embers and thin black smoke along the cuts. Perfectly "
        "symmetric X centered in the cell. ") + TIMELINE,
    "knight_blade": SEEN + ("A spectral crimson greatsword stabbing down onto the ground: a burst of crimson light shards radiating "
        "from the impact point with a short vertical blade of red light flashing at the center, small cracks and sparks, a round "
        "shockwave ring. Roughly circular overall. ") + TIMELINE,
    "knight_step": SEEN + ("A shadow vanish: a swirling burst of black smoke with crimson edges and red sparks, "
        "a vertical column of dark mist rising and dissolving, sharp red afterimage slashes inside the smoke. Roughly circular overall. ") + TIMELINE,
    "knight_iaido": SEEN + ("The effect sweeps in front of the attacker toward the RIGHT: one HUGE crimson crescent sword cut, "
        "a very wide arc of about 200 degrees from upper left, over the right, to lower left, reaching almost to the cell edge, "
        "thick fiery crimson body, white-hot edge, black smoke ribbons and sparks. ") + TIMELINE,
    "knight_flame": SEEN + ("A pillar of cursed fire erupting from the ground, seen from above: a roughly circular eruption of "
        "crimson and orange flames with a white-hot core, flying embers, black smoke curling at the edges, a ring of scorched "
        "ground. Frames 1-3 the ground glows and cracks, 4-8 the eruption, 9-12 it dies into embers and smoke. ") ,
}


def main() -> None:
    OUT.mkdir(exist_ok=True)
    names = sys.argv[1:] or list(JOBS)
    for name in names:
        if (OUT / (name + "_2.png")).exists():
            continue
        prompt = STYLE + " " + GRID12 + JOBS[name]
        command = [sys.executable, "tools/art/gen_image.py", "--out", "art_tests/vfx_hd/%s.png" % name, "--n", "2", "--size", "2048x1536",
                   "--quality", "high", "--opaque", "--image", *REFS, "--prompt", prompt]
        result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
        print(name, result.returncode, result.stderr[-200:].replace("\n", " "), flush=True)
    print("ALLDONE", flush=True)


if __name__ == "__main__":
    main()
