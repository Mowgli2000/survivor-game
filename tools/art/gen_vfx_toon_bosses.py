"""Cartoon / manga attack effects of the five final bosses of the seals 2-6 plus the three remaining ones of the Demon
Knight (dev note 2026-10-17: flat bold shapes, 3 tones, thin outline, no particles; "detailed" level validated on the
knight's cross and crescent). Candidates: art_tests/vfx_hd/toon_<boss>_fx<n>_1.png / _2.png (knight: knighttd_<name>).
Baked by tools/art/bake_vfx.py. Usage: python tools/art/gen_vfx_toon_bosses.py [label ...]"""
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from gen_vfx_toon import GRID12, JOBS as KNIGHT_JOBS, SEEN, TIMELINE  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "art_tests/vfx_hd"

BASE = ("Flat 2D cartoon / manga action effect with craft: ONE bold graphic shape in flat cel-shaded colors, %s, a thin dark outline "
        "and a few clean brush-stroke streaks inside the shape. ABSOLUTELY NO particles, no sparks, no embers, no smoke, no dust, "
        "no glow haze, no gradients, no scattered debris, no tiny details. No characters, no text, no border, no floor. ")
PALETTES = {
    "iron": "ochre-brown and grey stone with a bright turquoise glowing accent and a white-hot core",
    "silver": "pale ice blue, white and cyan with a deep navy shade band",
    "gold": "deep crimson, bright orange and a yellow-white core with a dark violet shade band",
    "obsidian": "acid green, yellow-green and a dark purple shade band with a pale yellow core",
    "astral": "gold, bright orange, red and a white-hot core",
}
SHAPES = {
    "iron_fx1": "A web of cracks seen from above: 8 bold jagged cracks radiating from the center like a star, turquoise light inside each crack, one thick round shockwave ring around them.",
    "iron_fx2": "A heavy stone block slamming down: one big flat square grey stone slab at the center, a bold white impact star behind it, one round shockwave ring and 4 big chunky rock pieces flying out.",
    "iron_fx3": "Three thick concentric rings, each ring a band of jagged stone teeth, turquoise light between the teeth, growing outward one after the other.",
    "iron_fx4": "A rune seal: a big double circle with 8 simple bold glyph shapes around it that light up turquoise one by one, ending in a bright star flash at the center.",
    "iron_fx5": "A stone burst: a bold starburst of 8 big chunky rock pieces thrown outward from a bright impact core, with a thick shockwave ring.",
    "silver_fx1": "Ice spikes: a ring of 10 tall sharp flat triangular ice crystals thrusting outward from the center, white tips, one frost ring on the ground.",
    "silver_fx2": "A blizzard gust sweeping toward the RIGHT: 4 big curved wind swoosh strokes of white and pale blue, flat, tapered, with 3 big simple snowflake shapes.",
    "silver_fx3": "A frost wall seen from above: a straight row of 5 tall jagged ice blocks side by side across the middle of the cell, white edges.",
    "silver_fx4": "A freezing patch: a flat round disc of ice with one big six-armed snowflake pattern across it and a thick jagged frost edge.",
    "silver_fx5": "A club impact: a thick round shockwave ring and a spiky star of cracks, with 6 big sharp ice shards thrown outward.",
    "gold_fx1": "A hellfire eruption seen from above: a round burst of bold pointed flame tongues in layers, a yellow-white core, a dark violet outer ring.",
    "gold_fx2": "The effect sweeps in front of the attacker toward the RIGHT: ONE huge crescent flame sweep of about 200 degrees whose outer edge is made of bold pointed flame tongues, white-hot inner edge.",
    "gold_fx3": "Chains: 4 thick heavy chains of oval links lashing out from the center in a cross layout, each ending in a flat starburst impact.",
    "gold_fx4": "A beam of fire: one thick straight beam from the center to the right edge of the cell with zigzag flame edges, a round bright flare at its origin.",
    "gold_fx5": "An infernal burst: an expanding flat ring of bold flame tongues around a dark empty center, a second thinner ring outside.",
    "obsidian_fx1": "A venom pool: one big flat irregular blob puddle of acid green with a thick dark outline, three big round bubbles on it.",
    "obsidian_fx2": "A spore burst: a round cluster of 7 big round glowing green blobs bursting outward from the center like a comic poof.",
    "obsidian_fx3": "A spider web seen from above: 8 radial straight lines and 3 concentric polygon rings connecting them, a green drop at each crossing of the outer ring.",
    "obsidian_fx4": "An egg burst: three big purple-green eggs cracking open, a flat splash of green slime around them.",
    "obsidian_fx5": "A stabbing impact: a radial burst of 8 pointed green spikes around a splash star shape.",
    "astral_fx1": "A dragon fire breath pointing to the RIGHT: a wide wedge from the left edge widening to the right, made of bold pointed flame tongues, white-hot core.",
    "astral_fx2": "A wing gust: two huge curved wing-shaped sweeps spreading to the left and to the right of the center, with 3 bold feather streaks each.",
    "astral_fx3": "Lightning seen from above: a bright round flash at the center with 6 bold jagged zigzag bolts radiating outward.",
    "astral_fx4": "A meteor impact: a round fireball with bold flame tongues, a thick shockwave ring and a dark crater center.",
    "astral_fx5": "A claw swipe: three parallel huge curved tapered claw slashes sweeping across, golden-white with orange edges.",
}
KNIGHT = {"knighttd_blade": "knightt_blade", "knighttd_step": "knightt_step", "knighttd_flame": "knightt_flame"}
KNIGHT_BASE = BASE % "crimson red body, a darker blood-red inner shade band, a bright orange-red edge and a white-hot core"


# Blade rain strip (stretched along a line by the game): a straight horizontal blade of light, centered, tapered ends.
STRIP = ("Seen from the side, flat. A single straight HORIZONTAL slash of light lying across the center of every cell: a bold flat "
         "crimson bar about one quarter of the cell height thick, a darker blood-red inner band, a white-hot core line, long pointed "
         "tapered ends, perfectly horizontal and vertically centered, its two ends stop 8 percent of the cell width before the left "
         "and the right edge of the cell. Timeline: cells 1-2 a thin line; cells 3-6 it thickens fast into the bold blade; "
         "cells 7-8 the fullest and brightest; cells 9-12 it thins back to a thin line and vanishes cleanly. ")


# Shapes that must match a damage zone exactly (dev note 2026-10-17: warning zone and animation must coincide).
STRIP_TIMELINE = ("Timeline: cells 1-2 a thin faint line; cells 3-6 it grows fast to its full bold shape; cells 7-8 the fullest; "
                  "cells 9-12 it thins back and vanishes cleanly. ")
STRIP_RULES = ("Seen from the side, flat. The shape is perfectly HORIZONTAL and vertically centered in every cell, about one third of the "
               "cell height thick at most, its two ends stop 8 percent of the cell width before the left and the right edge of the cell. ")
RING_RULES = ("Seen from above, perfectly round and centered in every cell, EMPTY in the middle, nothing inside the hole. ")
EXTRA_JOBS = {
    "toon_iron_ring": ("iron", RING_RULES + "ONE single thick ring made of jagged broken stone slabs side by side with bright turquoise light between the slabs, "
        "the outer edge of the ring reaches 90 percent of the cell half-width and the ring is about 18 percent of that radius thick. "
        "Timeline: cells 1-3 the ring appears and brightens; cells 4-8 the full solid ring; cells 9-12 it fades out cleanly, same size all along. "),
    "toon_gold_chain": ("gold", STRIP_RULES + "ONE heavy chain of big oval molten-orange links with white-hot centers lying straight along the line, "
        "ending on the right in a flat starburst impact. " + STRIP_TIMELINE),
    "toon_obsidian_web": ("obsidian", STRIP_RULES + "A band of spider web: two long straight silk lines with simple zigzag cross threads between them, tapered ends, "
        "a green drop on every crossing. " + STRIP_TIMELINE),
    "toon_silver_wave": ("silver", STRIP_RULES + "A frost shockwave flying to the right: a bold arrowhead wedge of sharp ice shards at the right end "
        "and a trail of jagged ice crystals behind it, white edges. " + STRIP_TIMELINE),
    "toon_gold_wings": ("gold", "Seen from above, perfectly symmetrical. TWO wide fan-shaped wedges of bold pointed flame tongues: one pointing straight UP and one pointing "
        "straight DOWN from the exact center of the cell, each wedge exactly 96 degrees wide at its tip and reaching 90 percent of the cell half-height, "
        "the two wedges meet at the center, nothing to the left or right of the center. Timeline: cells 1-2 two thin narrow wedges; cells 3-6 they widen fast; "
        "cells 7-8 the full bright wedges; cells 9-12 they shrink and vanish cleanly. "),
    "toon_astral_ring": ("astral", RING_RULES + "ONE wide thick ring band like a donut, flat golden-orange with flame-edged outer border and a white-hot inner edge; "
        "the outer edge reaches 92 percent of the cell half-width, the empty hole in the middle has a radius of 38 percent of the outer radius. "
        "Timeline: cells 1-3 the band appears and brightens; cells 4-8 the full band; cells 9-12 it fades out cleanly, same size all along. "),
}

def jobs() -> dict:
    result = {}
    for name, source in KNIGHT.items():
        result[name] = KNIGHT_BASE + GRID12 + KNIGHT_JOBS[source]
    result["knighttd_strip"] = KNIGHT_BASE + GRID12 + STRIP
    for label, (boss, shape) in EXTRA_JOBS.items():
        result[label] = BASE % PALETTES[boss] + GRID12 + SEEN + shape
    for key, shape in SHAPES.items():
        boss, fx = key.split("_")
        result["toon_%s_%s" % (boss, fx)] = BASE % PALETTES[boss] + GRID12 + SEEN + shape + " " + TIMELINE
    return result


def main() -> None:
    all_jobs = jobs()
    for label in sys.argv[1:] or list(all_jobs):
        if (OUT / (label + "_2.png")).exists():
            continue
        command = [sys.executable, "tools/art/gen_image.py", "--out", "art_tests/vfx_hd/%s.png" % label, "--n", "2", "--size", "2048x1536",
                   "--quality", "high", "--opaque", "--prompt", all_jobs[label]]
        result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
        print(label, result.returncode, result.stderr[-200:].replace("\n", " "), flush=True)
    print("ALLDONE", flush=True)


if __name__ == "__main__":
    main()
