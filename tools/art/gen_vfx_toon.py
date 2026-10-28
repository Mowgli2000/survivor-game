"""Cartoon / manga versions of the Demon Knight's five attack effects (dev note 2026-10-17: the painted ones carry too
many particles). Same grid as gen_vfx_knight.py; candidates in art_tests/vfx_hd/knightt_<name>_1.png / _2.png.
Usage: python tools/art/gen_vfx_toon.py [name ...]"""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "art_tests/vfx_hd"

STYLE = ("Flat 2D cartoon / manga action effect, like a hand-drawn anime or classic arcade beat'em up impact: ONE simple bold shape "
         "made of flat solid colors (cel shading, 2 or 3 colors only: crimson red, bright orange-red and a white core), clean sharp "
         "edges, thick graphic silhouette, a few thin straight speed lines at most. ABSOLUTELY NO particles, no sparks, no embers, "
         "no smoke, no glow haze, no gradients, no tiny details, no scattered debris. No characters, no text, no border, no floor.")
GRID12 = ("A sprite sheet of ONE smooth animation in a grid of 4 columns by 3 rows, 12 equal square cells read left to right then "
          "top to bottom. Every cell is a consecutive moment of the same motion, each slightly further along than the previous one. "
          "Keep the whole effect well inside its cell with a margin of black on every side, nothing crossing the cell borders, "
          "no grid lines, pure black background (#000000). ")
SEEN = "Seen from above. In every cell the effect is centered on the cell center. "
TIMELINE = ("Timeline: cells 1-2 a thin beginning; cells 3-6 it grows quickly; cells 7-8 the full solid shape; "
            "cells 9-12 it shrinks and thins out cleanly to nothing. ")

JOBS = {
    "knightt_cross": SEEN + "A big X: two long straight diagonal slash strokes crossing, each a flat tapered blade shape, white core and crimson body. " + TIMELINE,
    "knightt_blade": SEEN + "A flat crimson sword stabbing down: one simple vertical blade shape at the center and one clean round shockwave ring expanding around it, a few straight impact lines. " + TIMELINE,
    "knightt_step": SEEN + "A shadow vanish: a flat dark-red round burst with a bold white-edged swirl, collapsing to the center like a comic book poof, no smoke texture. " + TIMELINE,
    "knightt_iaido": SEEN + "The effect sweeps in front of the attacker toward the RIGHT: ONE huge clean crescent sword-cut shape, about 200 degrees, thick tapered flat crimson with a white inner edge, reaching almost to the cell edge. " + TIMELINE,
    "knightt_flame": SEEN + "A fire burst seen from above: a flat round starburst of bold cartoon flame tongues (simple pointed shapes, orange-red with a white-yellow core), like a comic explosion. " + TIMELINE,
}

# Second try (more matter): same flat shapes plus a thin dark outline and one darker inner tone, still no particles.
DETAIL = ("Flat 2D cartoon / manga action effect with a bit more craft: bold graphic shape in flat cel-shaded colors, crimson red body, "
          "a darker blood-red inner shade band, a bright orange-red edge and a white-hot core, a thin dark outline and a few clean "
          "brush-stroke streaks inside the shape. ABSOLUTELY NO particles, no sparks, no embers, no smoke, no glow haze, no gradients, "
          "no scattered debris. No characters, no text, no border, no floor.")
# Dev notes 2026-10-28: the venom fangs read as three parallel lines and too many particles; the explosive flask burst
# was too busy. One candidate each (SINGLE), the flat style with the weapon's own colors.
FANG_STYLE = ("Flat 2D cartoon / manga action effect, like a hand-drawn anime or classic arcade beat'em up impact: bold shapes in flat "
              "solid cel-shaded colors (deep violet blade shapes with a white core and a toxic-green edge), clean sharp edges, thick "
              "graphic silhouette. ABSOLUTELY NO particles, no sparks, no embers, no smoke, no glow haze, no gradients, no tiny "
              "details, no scattered debris. No characters, no text, no border, no floor.")
FLASK_STYLE = ("Flat 2D cartoon / manga action effect, like a hand-drawn anime or classic arcade beat'em up impact: bold shapes in flat "
               "solid cel-shaded colors (bright yellow-orange, a darker orange band, a white core), clean sharp edges, thick graphic "
               "silhouette. ABSOLUTELY NO particles, no sparks, no embers, no smoke, no glow haze, no gradients, no tiny details, "
               "no scattered debris. No characters, no text, no border, no floor.")
GRID16 = ("A sprite sheet of ONE smooth animation in a grid of 4 columns by 4 rows, 16 equal square cells read left to right then "
          "top to bottom. Every cell is a consecutive moment of the same motion, each slightly further along than the previous one. "
          "Keep the whole effect well inside its cell with a margin of black on every side (the largest frame must not touch the "
          "cell edge), nothing crossing the cell borders, no grid lines, pure black background (#000000). ")
JOBS["fang_daggers"] = (SEEN + "TWO short straight DAGGERS (a simple blade with a small crossguard) slashing in two fast crossing cuts "
    "toward the RIGHT in front of the attacker: each dagger leaves one clean tapered slash stroke, the second crossing the first like "
    "an X. At most ONE green venom droplet on a blade tip. Timeline: cells 1-2 the first dagger appears; cells 3-5 the first cut; "
    "cells 6-8 the second cut crossing it, the full shape; cells 9-12 the shapes thin out cleanly to nothing. ")
JOBS["explosion_flask_toon"] = (SEEN + "A potion flask bursting: ONE simple round splash burst of liquid with a bold clean ring at its "
    "biggest, 5 or 6 chunky curved glass shards as flat solid shapes (no tiny pieces), no smoke, no bubbles, no vapor, no scattered "
    "debris. Cells 1-2 a white flash; cells 3-6 it expands fast; cells 7-9 the full burst with its ring; cells 10-16 it shrinks and "
    "thins out cleanly to nothing. ")
SINGLE = {"fang_daggers": (GRID12, "2048x1536"), "explosion_flask_toon": (GRID16, "2048x2048")}
JOBS["knighttd_cross"] = JOBS["knightt_cross"]
JOBS["knighttd_iaido"] = JOBS["knightt_iaido"]
STYLES = {"knighttd_cross": DETAIL, "knighttd_iaido": DETAIL, "fang_daggers": FANG_STYLE, "explosion_flask_toon": FLASK_STYLE}


def main() -> None:
    for name in sys.argv[1:] or [n for n in JOBS if n not in STYLES]:
        grid, size, count = (*SINGLE[name], 1) if name in SINGLE else (GRID12, "2048x1536", 2)
        if (OUT / (name + ("_1.png" if count == 1 else "_2.png"))).exists() or (OUT / (name + ".png")).exists():
            continue
        command = [sys.executable, "tools/art/gen_image.py", "--out", "art_tests/vfx_hd/%s.png" % name, "--n", str(count), "--size", size,
                   "--quality", "high", "--opaque", "--prompt", STYLES.get(name, STYLE) + " " + grid + JOBS[name]]
        result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
        print(name, result.returncode, result.stderr[-200:].replace("\n", " "), flush=True)
    print("ALLDONE", flush=True)


if __name__ == "__main__":
    main()
