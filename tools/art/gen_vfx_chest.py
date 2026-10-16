"""Painted light projection of the boss chest rewards (the items rise in a beam of light above the open chest).
Same pipeline as tools/art/gen_vfx_knight.py: 4 x 4 grid of 16 frames, 2 candidates per job in art_tests/vfx_hd/.
Baked by tools/art/bake_vfx.py (table SHEETS_HD). Usage: python tools/art/gen_vfx_chest.py"""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "art_tests/vfx_hd"
STYLE = ("Hand-painted stylized 2D game VFX in the style of Hades 2 and anime action: a white-hot core, saturated glowing color "
         "around it, layered painterly shapes with sharp tapered shards and fluid ribbons, a few sparkles, same painterly look as the "
         "reference images. Palette: warm gold and white with a little pale cyan. No characters, no text, no border, no floor. ")
GRID16 = ("A sprite sheet of ONE smooth animation in a grid of 4 columns by 4 rows, 16 equal square cells read left to right then top to "
          "bottom. Every cell is a consecutive moment of the same motion. Keep the whole effect well inside its cell with a margin of "
          "black on every side, nothing crossing the cell borders, no grid lines, pure black background (#000000). ")
JOB = ("A holographic LIGHT PROJECTION seen from the front: a wide cone of golden light rising straight up from a small bright point at "
       "the bottom center of the cell (where an open chest sits) and widening upward like a projector beam, with a flat glowing golden "
       "circular halo ring floating at the top of the cone, empty inside (the game puts item icons there), vertical streaks of light, "
       "rising sparkles and tiny floating light motes. Cells 1-4: the beam ignites and grows upward; cells 5-8: the halo ring appears and "
       "the beam is at full height and brightest; cells 9-14: a steady shimmering loop, motes rising, the ring pulsing softly; cells "
       "15-16: it stays steady (these two cells must look like cell 9, so the animation can loop on cells 9-16).")


def main() -> None:
    OUT.mkdir(exist_ok=True)
    if (OUT / "chest_projection_2.png").exists():
        return
    refs = ["art_tests/vfx_hd/knight_flame_1.png", "art_tests/vfx_hd/explosion_fire_2.png"]
    command = [sys.executable, "tools/art/gen_image.py", "--out", "art_tests/vfx_hd/chest_projection.png", "--n", "2", "--size", "2048x2048",
               "--quality", "high", "--opaque", "--image", *refs, "--prompt", STYLE + GRID16 + JOB]
    result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
    print("chest_projection", result.returncode, result.stderr[-200:].replace("\n", " "), flush=True)
    print("ALLDONE", flush=True)


if __name__ == "__main__":
    main()
