"""Generates 2 candidate walk strips (6 poses in a row) for one monster sprite with the validated
method of the playable heroes (one generation, the monster's own look + a motion reference).
Usage: python tools/art/gen_monster_walk.py <sprite_id> <kind> [--ref <png>] [--motion <png>]
  kind: biped | heavy | quad | crawl | slither | fly | float | hop (selects the gait text and the default motion image)
  --ref: look of the monster (default art_source/ai/<sprite_id>.png, tiers: art_source/ai/<tier>/<id>.png)
  --motion: strip to copy the poses from (default: the swordswoman's walk for biped/heavy; for the
            other kinds a strip already validated on the same species, otherwise text only)
Output: art_tests/anim/<sprite_id>/walk_1.png, walk_2.png (then tools/art/slice_ai_sheet.gd).
"""
import argparse
import subprocess
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
HUMAN_WALK = ROOT / "art_tests/animation_ia/v2/ronin_walk_from_drifter.png"

GAITS = {
    "biped": "a heavy menacing biped walk: same 6 leg and arm poses in the same order as the motion reference, wide stride, weapon or arms swinging, body bobbing",
    "heavy": "a slow heavy stomping walk of a huge creature: wide stride, the whole body rolling and bobbing from side to side with each step, arms swinging low, big weight shifts, clearly different leg positions in each pose",
    "quad": "a fast four-legged trot: the legs alternate in diagonal pairs with clearly different leg positions in each of the 6 poses (reach, push, stretch, tuck), the spine flexing, the head bobbing and the tail swinging",
    "crawl": "a skittering six-or-eight-legged crawl: the legs alternate in two groups with clearly different leg positions in each of the 6 poses, the body rocking and bobbing, antennae or fuse swaying",
    "fly": "a flying flap cycle: the wings (or limbs) beat through clearly different positions in each of the 6 poses (raised, mid, lowered, mid), the body bobbing up and down and tilting forward, the tail or legs trailing",
    "float": "a floating drift: the body bobbing up and down and swaying side to side, the loose parts (flames, cloth, crystals, wisps) trailing and changing shape clearly in each of the 6 poses, no legs touching the ground",
    "hop": "a waddling hop of an object-like creature that cannot walk: the body squashes down, stretches up and rocks side to side over the 6 poses, the little legs, tentacles or roots under it moving to clearly different positions",
    "slither": "a slithering glide: the long body coils and undulates as a travelling wave, the hood and head sway side to side, clearly different curves of the body in each of the 6 poses",
}


def white_ref(src: Path, dst: Path) -> None:
    image = Image.open(src).convert("RGBA")
    background = Image.new("RGBA", image.size, (255, 255, 255, 255))
    background.alpha_composite(image)
    background.convert("RGB").save(dst)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("sprite_id")
    parser.add_argument("kind", choices=GAITS)
    parser.add_argument("--ref")
    parser.add_argument("--motion")
    parser.add_argument("--n", default="2")
    args = parser.parse_args()
    out_dir = ROOT / "art_tests/anim" / args.sprite_id
    out_dir.mkdir(parents=True, exist_ok=True)
    ref = Path(args.ref) if args.ref else ROOT / "art_source/ai" / (args.sprite_id + ".png")
    white = out_dir / "ref_white.png"
    white_ref(ref, white)
    motion = Path(args.motion) if args.motion else (HUMAN_WALK if args.kind in ("biped", "heavy") else None)
    images = [str(white)] + ([str(motion)] if motion else [])
    copy = (" Copy the poses of the SECOND reference image (same 6 poses in the same order, same alternation, same bobbing)"
            " but adapted to this creature's body." if motion else "")
    prompt = (
        "Sprite sheet for a 2D game on a plain flat pure white background (#FFFFFF everywhere, no gradient, no shadow, "
        "no floor shadow). Draw the creature of the FIRST reference image (exactly the same face, skin, armor, weapon, colors, "
        "thick black outline, flat cel-shaded Brawlhalla style, same chunky proportions, same size in every pose) 6 times in one "
        "horizontal row, evenly spaced with clear white gaps, feet or body on the same baseline. The 6 poses are one loop of "
        + GAITS[args.kind] + "." + copy + " The limbs keep the thick chunky size of the first image in every frame, never thin. "
        "Three-quarter view facing right. No text, no numbers, no borders."
    )
    command = [sys.executable, str(ROOT / "tools/art/gen_image.py"), "--out", str(out_dir / "walk.png"), "--n", args.n,
               "--size", "1536x1024", "--quality", "high", "--opaque", "--image", *images, "--prompt", prompt]
    subprocess.run(command, check=True, cwd=ROOT)


if __name__ == "__main__":
    main()
