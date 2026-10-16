"""Generates the treasure chest opening sheets (4 x 4 grid, 16 poses, 2048 px square), 2 candidates per job in
art_tests/boss_anim/chests/<job>_1.png / _2.png. Existing jobs are skipped.
Usage: python tools/art/gen_chest_anim.py [job ...]   (no job: all)
The first pose of a sheet is the closed chest. Cut and aligned by tools/art/make_boss_anim.py --boss chests."""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "art_tests/boss_anim/chests"

STYLE = ("Same drawing style as the reference image (a game character): thick clean black outline of constant weight, flat colors with "
         "one hard cel-shadow tone, chunky stylized proportions, Brawlhalla-style cartoon look, dark-fantasy dungeon theme. ")
GRID = ("A sprite sheet of ONE animation: a grid of 4 columns by 4 rows, 16 equal square cells read left to right then top to bottom, "
        "16 consecutive poses of the same motion, each only slightly further along than the previous one. Transparent background. "
        "The chest is seen from the front, slightly from above (three-quarter top-down view), centered in its cell, with its base on the "
        "same ground line and at exactly the same scale in every cell, fully inside its cell with margin, nothing crossing the cell "
        "borders, no grid lines, no text, no characters. Crisp sharp drawing: NO motion blur. ")

JOBS = {
    "chest_big": ("A grand LEGENDARY treasure chest opening, the reward for beating a boss: massive ornate dark wood chest bound with "
        "heavy gold bands, big golden lock, crimson gems on the lid, glowing golden runes. Poses 1-2: closed, golden light leaking from the "
        "seams, runes glowing. Poses 3-6: it trembles and shakes harder, light beams stream from the seams and the lock. Poses 7-9: the "
        "lid bursts open, a column of golden light shoots up, sparks fly. Poses 10-13: the lid is fully open, golden coins and glowing gems "
        "rise from the chest, sparkles all around, the light pillar at its brightest. Poses 14-16: it settles, open, a steady warm golden "
        "glow, a few coins and gems floating, a few sparkles."),
    "chest_small": ("A smaller wooden treasure chest opening, the reward for beating a mini-boss: sturdy wooden chest with iron bands "
        "and a small gold lock. Poses 1-3: closed. Poses 4-6: it jolts and the lid lifts a crack, a warm glow leaks out. Poses 7-10: the "
        "lid swings fully open, a burst of golden sparkles and a small beam of light. Poses 11-13: a glowing gem and a few coins float up. "
        "Poses 14-16: settled open with a soft glow and a few sparkles."),
}


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    names = sys.argv[1:] or list(JOBS)
    for name in names:
        if (OUT / (name + "_2.png")).exists():
            continue
        prompt = STYLE + GRID + JOBS[name]
        command = [sys.executable, "tools/art/gen_image.py", "--out", "art_tests/boss_anim/chests/%s.png" % name, "--n", "2",
                   "--size", "2048x2048", "--quality", "high", "--image", "art_source/ai/shogun.png", "--prompt", prompt]
        result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
        print(name, result.returncode, result.stderr[-200:].replace("\n", " "), flush=True)
    print("ALLDONE", flush=True)


if __name__ == "__main__":
    main()
