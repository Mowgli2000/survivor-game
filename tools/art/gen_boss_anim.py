"""Generates boss character animation sheets (4 x 4 grid, 16 poses of one animation, 2048 px square),
the look of the boss kept from its reference image. 2 candidates per job in art_tests/boss_anim/<boss>/<job>_1.png / _2.png.
Existing jobs are skipped. Usage: python tools/art/gen_boss_anim.py <boss> [job ...]   (no job: every job without a chained reference)
A job with `chain` uses the last pose of a chosen sheet as an extra reference: give it with --chain <png>.
Cut and aligned by tools/art/make_boss_anim.py."""
import argparse
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

LOOK = ("Same character as the reference image: the horned demon knight in dark grey armor with crimson cape and a huge flaming greatsword, "
        "exactly the same costume, colors, proportions and chunky Brawlhalla-style cartoon look, thick clean black outline, flat cel shading. ")
GRID = ("A sprite sheet of ONE animation: a grid of 4 columns by 4 rows, 16 equal square cells read left to right then top to bottom, "
        "16 consecutive poses of the same motion, each pose only slightly further along than the previous one so the animation plays "
        "smoothly. Transparent background. The character is drawn at exactly the same scale in every cell, with his feet on the same "
        "ground line (when he stands or kneels), three-quarter top-down view facing right, fully inside his cell with margin, "
        "nothing crossing the cell borders, no grid lines, no text. Crisp sharp drawing in every pose: NO motion blur, NO speed lines, "
        "NO ghosting, NO separate special-effect drawing (the effects are added by the game). ")

JOBS = {
    "shogun": {
        "idle": (False, "A calm idle loop, 16 poses, that loops perfectly (pose 16 flows back into pose 1). He stands in the ready "
            "stance of the reference image (greatsword lowered in front of him, pointing right-down), breathing slowly: the chest "
            "rises and falls, the shoulders shift slightly, the cape sways a little, the sword tip bobs slightly. Only small subtle "
            "movements between poses, the feet planted."),
        "walk": (False, "A slow heavy walk cycle in place, 16 poses, that loops perfectly (pose 16 flows back into pose 1), facing "
            "right. The knight marches with big heavy stomping steps, the greatsword held low in front and swaying with each step, the "
            "body bobbing up and down, the cape swaying behind him. Poses 1-8 are the left foot stepping forward, poses 9-16 the right "
            "foot stepping forward. The ground line stays the same in every cell."),
        "attack_windup": (False, "The wind-up of a huge overhead sword strike, 16 poses. Poses 1-3: from the ready stance (sword lowered "
            "in front, like the reference) he shifts his weight and crouches slightly. Poses 4-8: he swings the greatsword up in an arc "
            "until it is high above his head, leaning back. Poses 9-12: he holds the sword at the top, body coiled, armor trembling, "
            "slightly different pose each cell. Poses 13-16: the final tension before the blow, torso twisted back, sword at its "
            "highest, about to strike."),
        "attack_strike": (True, "The strike and recovery of a huge overhead sword blow, 16 poses. Pose 1 is exactly the last pose of the "
            "wind-up reference (sword high, body coiled). Poses 2-4: explosive downward swing, body lunging forward. Poses 5-6: the "
            "impact pose, sword fully extended low in front of him. Poses 7-8: he holds the impact, bent forward. Poses 9-12: slow "
            "follow-through, he straightens up, sword lifting. Poses 13-16: he returns to the ready stance, pose 16 identical to the "
            "reference image."),
        "entrance": (False, "The entrance of a boss, 16 poses. Poses 1-3: a dark silhouette of the kneeling knight half hidden in "
            "swirling black smoke with a faint crimson glow (very dark, mostly smoke). Poses 4-6: he kneels, head bowed, the greatsword "
            "planted blade-down in front of him. Poses 7-9: he rises slowly to his feet pulling the sword out. Poses 10-12: standing in "
            "the ready stance, his eyes flaring bright crimson. Poses 13-16: he throws his head back and roars, chest out, arms wide, "
            "sword held up in one hand, then lowers into the ready stance."),
        "phase": (False, "A boss changing phase, 16 poses. Poses 1-2: the ready stance. Poses 3-5: he staggers, clutches his chest, "
            "drops to one knee with the sword planted. Poses 6-9: his armor cracks, red light pouring from the cracks, horns glowing, "
            "body shaking. Poses 10-12: he stands up taller, arms spread wide, roaring, armor glowing. Poses 13-16: he settles back "
            "into the ready stance, with the cracks still glowing a hot crimson."),
        "death": (False, "The death of a boss, 16 poses. Poses 1-3: a heavy hit, he recoils and staggers backward. Poses 4-6: the sword "
            "slips and drops, he falls to one knee. Poses 7-9: kneeling with his head bowed, armor cracking with red light. Poses 10-12: "
            "he collapses forward onto the ground. Poses 13-16: his body breaks apart into glowing embers and ash that drift away until "
            "almost nothing remains: pose 16 shows only a few embers and the greatsword stuck in the ground, fading."),
    },
}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("boss")
    parser.add_argument("jobs", nargs="*")
    parser.add_argument("--chain", help="PNG of the last pose of the previous sheet (jobs marked as chained)")
    args = parser.parse_args()
    out = ROOT / "art_tests/boss_anim" / args.boss
    out.mkdir(parents=True, exist_ok=True)
    table = JOBS[args.boss]
    names = args.jobs or [n for n, (chained, _) in table.items() if not chained]
    for name in names:
        chained, text = table[name]
        if (out / (name + "_2.png")).exists():
            continue
        refs = ["art_source/ai/%s.png" % args.boss]
        if chained:
            if not args.chain:
                print(name, "needs --chain", flush=True)
                continue
            refs.append(args.chain)
        prompt = LOOK + GRID + text
        command = [sys.executable, "tools/art/gen_image.py", "--out", "art_tests/boss_anim/%s/%s.png" % (args.boss, name), "--n", "2",
                   "--size", "2048x2048", "--quality", "high", "--image", *refs, "--prompt", prompt]
        result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
        print(name, result.returncode, result.stderr[-200:].replace("\n", " "), flush=True)
    print("ALLDONE", flush=True)


if __name__ == "__main__":
    main()
