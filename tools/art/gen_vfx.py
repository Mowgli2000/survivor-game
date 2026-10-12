"""Generates the painted combat effects of the style validated by the dev on 2026-10-10 (slash
and impact sheets, projectile cells). 2 candidates per job in art_tests/vfx/<name>_1.png / _2.png.
Existing jobs are skipped. Usage: python tools/art/gen_vfx.py [name ...]   (no name: all jobs)
References: the dev's inspirations (image-5x.png at the repo root, not versioned) and the
validated outputs as style anchors (art_tests/vfx/slash_1.png for sheets, arrow_1.png for cells).
Sheets: 3 columns x 2 rows on pure black (baked premultiplied by tools/art/bake_vfx.py).
Cells: one square image on pure black, pointing right, trail on the left."""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "art_tests/vfx"

STYLE = ("Hand-painted stylized 2D game VFX in the style of Hades 2 and anime action (Demon Slayer, Bleach): a white-hot core, "
         "saturated glowing color around it, layered painterly shapes with sharp tapered shards and fluid ribbons, a few sparkles, "
         "same painterly look as the first reference image. No characters, no text, no border, no floor.")
GRID = ("A sprite sheet of ONE animation in a grid of 3 columns by 2 rows, 6 equal square cells read left to right then top to "
        "bottom, nothing crossing the cell borders, no grid lines, pure black background (#000000). ")
ARC = ("Seen from above. In every cell the effect is centered on the cell center, where the attacker stands (do not draw him); the "
       "swing sweeps in front of him toward the RIGHT as a big curved crescent spanning about 120 degrees (from upper right to lower "
       "right) and reaching almost to the cell edge. ")
BURST = "Each cell shows the effect centered on the same point, the biggest frame fills most of its cell. "
CELL = ("A single projectile seen from above, pointing exactly to the RIGHT, horizontal, centered vertically, a long painted trail "
        "streaming to the LEFT that fades out. Pure black background (#000000) everywhere else, nothing else in the image. ")

FIRE_REFS = ["image-59.png", "image-61.png", "image-57.png"]
MAGIC_REFS = ["image-56.png", "image-62.png", "image-55.png"]
SPARK_REFS = ["image-60.png", "image-62.png", "image-54.png"]

JOBS = {
    # --- melee swings
    "steel_slash": ("sheet", MAGIC_REFS, ARC + "A clean thin curved slash of polished steel light: white-silver core, pale blue-white edge, fine speed lines. Frame 1 a thin line at the top right; frame 2 it grows downward; frame 3 the full crescent, brightest; frames 4-6 it thins and fades into a few sparkles."),
    "fang_slash": ("sheet", MAGIC_REFS, ARC + "Two parallel curved fang-shaped slashes, one violet and one toxic green, with dripping venom droplets and small sparks. Frame 1 two thin lines at the top right; frame 2 they grow; frame 3 the full double crescent; frames 4-6 they fade, droplets falling."),
    "thrust": ("sheet", ["image-54.png", "image-62.png"], "Colors: WHITE, pale silver and ice blue only, absolutely no purple or pink. Seen from above. In every cell the effect starts at the cell center, where the attacker stands (do not draw him), and goes straight to the RIGHT edge: a piercing thrust, a long narrow spike of white-silver light with a shock cone and speed lines, no crescent. Frame 1 a short spike; frame 2 longer; frame 3 reaches the right edge, brightest, with a ring shockwave at the tip; frames 4-6 it thins out and fades into sparkles."),
    "axe_slash": ("sheet", FIRE_REFS, ARC + "A heavy wide steel-white arc with a thick body, grey-blue smoke trail, flying sparks, a feeling of weight. Frame 1 a thick line at the top right; frame 2 it grows; frame 3 the full thick crescent with sparks; frames 4-6 the smoke trail lingers and fades."),
    "scythe_slash": ("sheet", MAGIC_REFS, ARC + "A wide violet crescent with dark purple and magenta wisps and floating soul sparks. Frame 1 a thin violet line at the top right; frame 2 it grows; frame 3 the full wide crescent with wisps; frames 4-6 wisps and sparks drift and fade."),
    "hammer_smash": ("sheet", FIRE_REFS, BURST + "A ground smash seen from above: a golden-white flash at the center, a shockwave ring expanding outward with cracks radiating on the ground, gold sparks and dust. Frame 1 a flash; frame 2 the first ring; frame 3 the ring at full size with cracks; frames 4-6 the ring fades, dust and sparks settle."),
    "runic_slash": ("sheet", MAGIC_REFS, ARC + "A crescent slash of cyan magical light with glowing rune glyphs along the arc and floating rune sparks. Frame 1 a thin cyan line at the top right; frame 2 it grows with a few runes; frame 3 the full crescent with many runes; frames 4-6 runes and light fade."),
    # --- impacts and explosions
    "impact_generic": ("sheet", SPARK_REFS, BURST + "A small hit impact in WHITE and pale gold only: frame 1 a flash; frame 2 a sharp 4-point star flash; frame 3 a burst of sharp shards with a thin ring; frames 4-6 shards thin out into sparkles."),
    "impact_fire": ("sheet", FIRE_REFS, BURST + "A fire impact: frame 1 a flash; frame 2 a burst of orange flames with a white core; frame 3 the biggest, flames and flying embers, dark red smoke accents; frames 4-6 flames die into embers and smoke."),
    "impact_frost": ("sheet", SPARK_REFS, BURST + "A frost impact: frame 1 a flash; frame 2 sharp ice crystals burst out, cyan and white; frame 3 the biggest, shattering ice shards with a thin frost ring; frames 4-6 shards fall away into glittering snow sparkles."),
    "impact_lightning": ("sheet", SPARK_REFS, BURST + "An electric impact: frame 1 a flash; frame 2 branching yellow-white lightning forks burst out; frame 3 the biggest, many forks and a crackling ring; frames 4-6 forks flicker and fade into sparks."),
    "explosion_fire": ("sheet", FIRE_REFS, BURST + "A big fire explosion: frame 1 a bright flash; frame 2 a fireball swelling with a white-yellow core; frame 3 the full fireball, swirling orange and red ribbons, a shockwave ring, sharp flying shards; frame 4 smoke and flames boil, the ring expands; frames 5-6 dark red smoke and embers fade."),
    "explosion_frost": ("sheet", SPARK_REFS, BURST + "A frost explosion: frame 1 a flash; frame 2 a swelling ball of cyan-white frost; frame 3 the full burst, icy ribbons, sharp ice shards flying out, a ring; frame 4 the ring expands and shards fall; frames 5-6 snow sparkles and cold mist fade."),
    "explosion_blast": ("sheet", FIRE_REFS, BURST + "A concussive blast: frame 1 a white flash; frame 2 a yellow-white fireball with a sharp star flare; frame 3 the full blast, bright yellow-orange, a hard shockwave ring and flying sparks; frames 4-6 grey-brown smoke puffs and sparks fade."),
    # --- projectile cells (1024 px, pointing right)
    "p_orb": ("cell", MAGIC_REFS, CELL + "A bright golden energy orb with a white-hot core and a swirling painted trail, a few sparkles."),
    "p_bullet": ("cell", SPARK_REFS, CELL + "A glowing tracer bolt of green light with a white-hot tip, a short sharp body and a fine painted trail with sparks."),
    "p_missile": ("cell", FIRE_REFS, CELL + "A small rocket with a dark metal body and an orange nose, a long painted fire and smoke trail with embers."),
    "p_shuriken": ("cell", SPARK_REFS, "A single spinning steel ninja star (four sharp blades) seen from above, centered in the image, perfectly symmetric, with a soft silver-blue motion glow around it and a few sparkles. Pure black background (#000000) everywhere else, nothing else in the image."),
    "p_fireball": ("cell", FIRE_REFS, CELL + "A blazing fireball: a white-yellow core, orange and red painted flames streaming into a long fiery trail, embers."),
    "p_ice_shard": ("cell", SPARK_REFS, CELL + "A sharp spear of ice: a faceted cyan-white crystal with a white-hot tip, a trail of frost and glittering snow sparkles."),
    "p_lightning": ("cell", SPARK_REFS, CELL + "A bolt of crackling lightning: a jagged yellow-white spear of electricity with a white core, small forks and sparks, a short electric trail."),
    "p_arrow": ("cell", MAGIC_REFS, CELL + "A glowing green arrow: a slim bright arrowhead with a white-hot tip, a glowing green shaft and fletching, a long painted trail of green light with a few sparkles."),
    "p_stone": ("cell", FIRE_REFS, CELL + "A hurled jagged rock, grey-brown with a thick dark outline, spinning, with a trail of brown dust and small pebbles."),
    "p_javelin": ("cell", MAGIC_REFS, CELL + "A thrown javelin: a long wooden shaft with a green-glowing steel head and fletching, a painted trail of green light."),
    "p_bomb": ("cell", FIRE_REFS, CELL + "A round black iron bomb with a lit sparking fuse, an orange glow around it, a trail of sparks and smoke."),
    "p_fire_flask": ("cell", FIRE_REFS, CELL + "A glass flask full of burning orange liquid with a cork, flames licking out of it, a long fiery trail."),
    "p_frost_flask": ("cell", SPARK_REFS, CELL + "A glass flask full of glowing cyan frost liquid with a cork, ice crystals around it, a trail of cold mist and snow sparkles."),
    "p_grenade": ("cell", FIRE_REFS, CELL + "A round olive-green frag grenade with a pin ring, tumbling, a faint trail of sparks and smoke."),
    "p_cannonball": ("cell", FIRE_REFS, CELL + "A heavy black iron cannonball with a dull highlight, a thick trail of grey smoke and orange sparks."),
    # --- second pass (dev notes, 2026-10-10)
    "explosion_star": ("sheet", ["image-62.png", "image-56.png", "image-55.png"], BURST + "A violet celestial star explosion: frame 1 a white flash; frame 2 a swelling ball of vivid violet and magenta light with a white core and 4-point star flares; frame 3 the full burst, sharp violet shards flying out, small constellation stars, a thin ring; frame 4 the ring expands, shards and stars drift; frames 5-6 violet mist and sparkles fade."),
    "rapier_slash": ("sheet", ["image-56.png", "image-62.png"], "Seen from above. In every cell the effect starts at the cell center, where the attacker stands (do not draw him), and goes to the RIGHT: a very fast fencing lunge made of THREE thin straight silver-white needle lines fanning slightly, with a bright point flash at the tip and tiny sparkles. Frame 1 one short thin line; frame 2 three lines longer; frame 3 reaches the right edge with a star flash at the tips, brightest; frames 4-6 the lines fade into sparkles. Colors: white and pale silver only, thin and elegant, not wide, no crescent, no purple."),
    "p_bomb_flask": ("cell", FIRE_REFS, CELL + "A round glass flask with a cork, full of volatile bright yellow-orange liquid with bubbles, a lit fuse spark on the cork, thick black outline, tumbling; a trail of orange sparks and a little smoke. NOT a missile, NOT a rocket."),
    "p_shuriken_dark": ("cell", SPARK_REFS, "A single spinning ninja star (four sharp blades) seen from above, centered, perfectly symmetric: dark black-purple steel blades with a thick black outline and a vivid violet glow edge and violet sparkles, a violet ring of motion glow around it. Pure black background (#000000) everywhere else, nothing else in the image."),
}


def main() -> None:
    names = sys.argv[1:] or list(JOBS)
    for name in names:
        kind, refs, text = JOBS[name]
        if (OUT / (name + "_2.png")).exists():
            continue
        anchor = "art_tests/vfx/slash_1.png" if kind == "sheet" else "art_tests/vfx/arrow_1.png"
        size = "1536x1024" if kind == "sheet" else "1024x1024"
        prompt = STYLE + " " + text
        if kind == "sheet":
            prompt = STYLE + " " + GRID + text
        command = [sys.executable, "tools/art/gen_image.py", "--out", "art_tests/vfx/%s.png" % name, "--n", "2", "--size", size,
                   "--quality", "high", "--opaque", "--image", anchor, *refs, "--prompt", prompt]
        result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
        print(name, result.returncode, result.stderr[-160:].replace("\n", " "), flush=True)
    print("ALLDONE", flush=True)


if __name__ == "__main__":
    main()
