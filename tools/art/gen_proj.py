"""Fourth pass of the painted projectiles (dev notes of 2026-10-10): clean lobbed items without a baked
trail (flasks, grenade, cannonball: the code spins them), a lit bomb with a flickering fuse (6-frame
loop), animated looping bolts (fireball, ice shard, lightning) and hostile enemy shots.
2 candidates per job in art_tests/proj/<name>_1.png / _2.png. Existing jobs are skipped.
Usage: python tools/art/gen_proj.py [name ...]   (no name: all jobs). Baked by tools/art/bake_proj.py."""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "art_tests/proj"

STYLE = ("Hand-painted stylized 2D game art in the style of Hades 2 and anime action (Demon Slayer, Bleach): saturated colors, "
         "layered painterly shapes, a white-hot highlight, a thick dark outline, a few sparkles, same painterly look as the first "
         "reference image. No characters, no text, no border, no floor. ")
CLEAN = ("A single {what}, seen from above, centered in the image and filling about 60 percent of it, a clean sprite: NO trail, NO "
         "motion lines, NO streak, nothing attached behind it. Pure black background (#000000) everywhere else, nothing else in the "
         "image. ")
LOOP = ("A sprite sheet of ONE looping animation in a grid of 3 columns by 2 rows, 6 equal square cells read left to right then top to "
        "bottom, nothing crossing the cell borders, no grid lines, pure black background (#000000). In every cell the same projectile "
        "{what}, pointing exactly to the RIGHT, centered, with its long painted trail streaming to the LEFT; the body keeps the same "
        "size and place, only the flames/crackle/trail shift and flicker from cell to cell so the sequence loops smoothly (cell 6 "
        "flows into cell 1). Keep everything well inside its cell with a black margin. ")
ENEMY = ("A single HOSTILE enemy projectile, seen from above, pointing exactly to the RIGHT, centered vertically, a short painted "
         "trail to the LEFT, {what} It must look menacing and clearly different from friendly shots: a thick black outline and a "
         "blood-red or dark crimson glowing rim. Pure black background (#000000) everywhere else, nothing else in the image. ")

FIRE_REFS = ["image-59.png", "image-61.png", "image-57.png"]
MAGIC_REFS = ["image-56.png", "image-62.png", "image-55.png"]
SPARK_REFS = ["image-60.png", "image-62.png", "image-54.png"]

JOBS = {
    # kind: "cell" (one 1024 image) or "sheet" (1536x1024, 3x2)
    "c_fire_flask": ("cell", FIRE_REFS, CLEAN.format(what="round glass flask with a cork, full of burning bright orange liquid with a few flames licking out of the neck")),
    "c_frost_flask": ("cell", SPARK_REFS, CLEAN.format(what="round glass flask with a cork, full of glowing cyan frost liquid with ice crystals clinging to the glass")),
    "c_bomb_flask": ("cell", FIRE_REFS, CLEAN.format(what="round glass flask with a cork, full of volatile bright yellow-orange liquid with bubbles and a tiny fuse spark on the cork")),
    "c_grenade": ("cell", FIRE_REFS, CLEAN.format(what="round olive-green frag grenade with a pin ring and a lever")),
    "c_cannonball": ("cell", FIRE_REFS, CLEAN.format(what="heavy black iron cannonball with a dull highlight and a few scratches")),
    "a_bomb": ("sheet", FIRE_REFS, "A sprite sheet of ONE looping animation in a grid of 3 columns by 2 rows, 6 equal square cells read left to right "
               "then top to bottom, nothing crossing the cell borders, no grid lines, pure black background (#000000). In every cell the SAME "
               "round black iron bomb seen from above, centered, identical size and position, with a short fuse sticking out at the upper "
               "right whose tip burns: the sparks and little flame at the fuse tip flicker and change shape from cell to cell, growing "
               "hotter, so the fuse seems to be burning down; a faint orange glow on the bomb. NO trail. The sequence loops smoothly."),
    "a_fireball": ("sheet", FIRE_REFS, LOOP.format(what="is a blazing fireball: a white-yellow core, orange and red painted flames streaming into a long fiery trail with embers")),
    "a_orb": ("sheet", MAGIC_REFS, LOOP.format(what="is an arcane energy orb: a glowing violet-white sphere with a white-hot core, a swirling magenta and violet aura, a few small sparks orbiting it, a short flowing tail of violet energy; it is round, NOT a fireball")),
    "c_shard": ("cell", FIRE_REFS, CLEAN.format(what="jagged shard of shrapnel metal, a small sharp steel-grey splinter pointing exactly to the RIGHT with a hot orange glowing edge")),
    "a_grenade": ("sheet", FIRE_REFS[:2] + ["art_tests/proj/c_grenade_1.png"], "A sprite sheet of ONE looping animation in a grid of 3 columns by 2 rows, 6 equal square cells read left to right then top to bottom, nothing crossing the cell borders, no grid lines, pure black background (#000000). In every cell the SAME olive-green military fragmentation grenade as in the last reference image (round segmented olive-green body, steel pin ring and lever), seen from above, centered, identical size and position, NO trail. Only small things move from cell to cell so it loops smoothly (cell 6 flows into cell 1): a bright glint of light sweeps across the metal body, the pin ring swings slightly, the lever trembles. Keep the body solid and opaque, no camouflage patches. "),
    "a_ice": ("sheet", SPARK_REFS, LOOP.format(what="is a spear of ice: a faceted cyan-white crystal with a white-hot tip, a trail of frost mist and glittering snow sparkles")),
    "a_lightning": ("sheet", SPARK_REFS, LOOP.format(what="is a ball of crackling lightning: a white-hot core wrapped in many jagged yellow-white electric arcs that lash out in every direction, a short electric tail of forking sparks; it is round and spiky, NOT an arrow, NOT a spear")),
    "e_orb": ("cell", MAGIC_REFS, ENEMY.format(what="a dark crimson energy orb with a black core.")),
    "e_ice": ("cell", SPARK_REFS, ENEMY.format(what="a spiky shard of dark blue-black ice with a magenta-red edge glow.")),
    "e_fire": ("cell", FIRE_REFS, ENEMY.format(what="a black-red fireball with a dark core and orange flame tongues, smoky.")),
    "e_acid": ("cell", MAGIC_REFS, ENEMY.format(what="a blob of sickly yellow-green acid with a black core, dripping.")),
    "e_stone": ("cell", FIRE_REFS, ENEMY.format(what="a jagged black-brown rock with glowing red cracks.")),
}


# Twelve-frame versions of the energy loops (dev, 2026-10-11: attack animations must all be as fluid as the melee ones).
for _name in ("fireball", "orb", "lightning"):
    _kind, _refs, _text = JOBS["a_" + _name]
    JOBS["a12_" + _name] = ("sheet12", _refs, _text.replace("3 columns by 2 rows, 6 equal", "4 columns by 3 rows, 12 equal").replace("cell 6 flows", "cell 12 flows"))
# Weapon icon: same style as the other icons (thick black outline, flat saturated colors, gold trim), transparent background.
JOBS["i_grenade"] = ("icon", ["art_source/ai/weapons/frag_grenade.png", "art_tests/proj/c_grenade_1.png"],
    "Game item icon in exactly the style of the FIRST reference image (thick black outline, flat saturated colors with simple painterly highlights, "
    "gold trim and gold diamond studs). It shows ONE single olive-green military fragmentation grenade copied from the SECOND reference image "
    "(round segmented olive-green body, steel pin ring, lever), centered, tilted slightly, filling about 80 percent of the image, "
    "NO fuse, NO flame, NOT a spiked bomb. Transparent background.")

# Sixth pass: the bomb and the explosive flask look like their weapon icons (dev, 2026-10-11). Upright, fuse straight UP.
_BOMB_LOOP = ("A sprite sheet of ONE looping animation in a grid of 4 columns by 3 rows, 12 equal square cells read left to right then top to "
    "bottom, nothing crossing the cell borders, no grid lines, pure black background (#000000). In every cell the SAME object, copied from the "
    "SECOND reference image: {what}, seen from above, centered, identical size and position, standing upright with its fuse pointing "
    "exactly STRAIGHT UP, NO trail. Only the burning tip of the fuse changes from cell to cell: the spark and little flame flicker, grow and "
    "change shape, a few sparks fly off, so the fuse seems to be burning and the sequence loops smoothly (cell 12 flows into cell 1). "
    "The body stays solid, opaque and identical. Keep everything well inside its cell with a black margin. ")
JOBS["a12_bomb"] = ("sheet12", FIRE_REFS[:1] + ["art_source/ai/weapons/bomb.png"],
    _BOMB_LOOP.format(what="a round black iron bomb with gold trim, a golden skull and crossbones on its belly, gold scrolls and red gems, and a braided brown fuse with a bright star-shaped spark at its tip"))
JOBS["c_bomb_flask2"] = ("cell", FIRE_REFS[:1] + ["art_source/ai/weapons/bazooka.png"],
    "A single clean game sprite copied from the SECOND reference image: the round glass flask full of bubbling orange liquid with gold trim and red gems and a cork topped by a short fuse with a tiny spark, seen from above, centered, filling about 60 percent of the image, NO trail, nothing attached. Pure black background (#000000) everywhere else. ")


# Seventh pass: the Shadow blades (orbiting weapon, dev, 2026-10-11): icon first, then the looping blade copied from it.
JOBS["i_shadowblade"] = ("icon", ["art_source/ai/weapons/scythe.png", "art_source/ai/weapons/bomb.png"],
    "Game item icon in exactly the style of the reference images (thick black outline, flat saturated colors with simple painterly highlights, "
    "gold trim and gold diamond studs). It shows ONE single ethereal SHADOW DAGGER: a slim curved blade of dark indigo-black shadow "
    "with a glowing electric-blue edge and a few wisps of dark smoke curling off it, an ornate gold crossguard with a blue gem, and a "
    "dark leather grip; tilted diagonally, filling about 80 percent of the image. Transparent background.")
JOBS["a12_shadowblade"] = ("sheet12", MAGIC_REFS[:1] + ["art_source/ai/weapons/shadow_blades.png"],
    "A sprite sheet of ONE looping animation in a grid of 4 columns by 3 rows, 12 equal square cells read left to right then top to bottom, "
    "nothing crossing the cell borders, no grid lines, pure black background (#000000). In every cell the SAME shadow dagger copied from the "
    "SECOND reference image (slim curved dark indigo blade, glowing electric-blue edge, gold crossguard with a blue gem), seen from above, "
    "pointing exactly to the RIGHT, centered, identical size and position, with a short wisp of dark smoke and blue sparks trailing to the "
    "LEFT. Only the smoke wisps, the blue edge glow and the sparks flicker and shift from cell to cell so the sequence loops smoothly "
    "(cell 12 flows into cell 1). The blade body stays solid and identical. Keep everything well inside its cell with a black margin. ")



# Eighth pass: the gravity well weapon (dev, 2026-10-11): icon first, then the sphere copied from it.
JOBS["i_gravity"] = ("icon", ["art_source/ai/weapons/bomb.png", "art_source/ai/weapons/alchemy_cannon.png"],
    "Game item icon in exactly the style of the reference images (thick black outline, flat saturated colors with simple painterly highlights, "
    "gold trim and gold diamond studs). It shows ONE single GRAVITY SPHERE: a heavy dark iron-and-violet orb held by a three-claw gold mount, "
    "its center a swirling dark violet vortex with a glowing white-violet ring and a few tiny stones floating around it, a purple gem on the mount; "
    "centered, filling about 80 percent of the image. Transparent background.")
JOBS["a12_gravity_sphere"] = ("sheet12", MAGIC_REFS[:1] + ["art_source/ai/weapons/pulse.png"],
    "A sprite sheet of ONE looping animation in a grid of 4 columns by 3 rows, 12 equal square cells read left to right then top to bottom, "
    "nothing crossing the cell borders, no grid lines, pure black background (#000000). In every cell the SAME gravity sphere copied from the "
    "SECOND reference image (heavy dark iron-and-violet orb with a three-claw gold mount, swirling dark violet vortex in the center with a glowing "
    "white-violet ring), seen from above, centered, identical size and position, NO trail. Only the vortex inside it moves: its spiral turns "
    "30 degrees further in every cell (so after 12 cells it is back at the start) and the tiny stones around it orbit and the ring pulses, so the "
    "sequence loops smoothly (cell 12 flows into cell 1). The body stays solid and identical. Keep everything well inside its cell with a black margin. ")


# Ninth pass (dev, 2026-10-11): the bow, crossbows, javelin and sling no longer share the same green streak. One grid image,
# five different projectiles (cells 1-5), each pointing right with a short trail; cell 6 stays empty.
JOBS["p_ranged"] = ("sheet", FIRE_REFS[:2], "A sprite sheet in a grid of 3 columns by 2 rows, 6 equal square cells read left to right then top to bottom, nothing crossing the cell borders, no grid lines, pure black background (#000000). Each cell holds ONE DIFFERENT game projectile seen from above, centered, pointing exactly to the RIGHT, with a short painted trail streaming to the LEFT, filling about 70 percent of its cell, and they must NOT look alike (different shapes, sizes and colors): "
    "cell 1: a long wooden ARROW with a steel head and white feather fletching, a thin silver wind streak behind it; "
    "cell 2: a HEAVY crossbow bolt, a thick short black-steel bolt with a big blunt iron head and yellow sparks behind it; "
    "cell 3: a small slim brass crossbow dart, amber and golden, a faint amber glint trail; "
    "cell 4: a bronze JAVELIN, a long spear with a broad leaf-shaped bronze head, a red ribbon tied below the head and a warm golden halo; "
    "cell 5: a round grey cracked SLING STONE, tumbling, with brown dust and small chips flying behind it; "
    "cell 6: leave this cell completely black and empty. ")


# Tenth pass (dev, 2026-10-12): the Sling stone gets its own looping body (12 frames), copied from the current stone cell.
JOBS["a12_sling"] = ("sheet12", ["art_source/ai/projectiles/11_stone.png", "art_source/ai/weapons/sling.png"] + FIRE_REFS[:1],
    "A sprite sheet of ONE looping animation in a grid of 4 columns by 3 rows, 12 equal square cells read left to right then top to "
    "bottom, nothing crossing the cell borders, no grid lines, pure black background (#000000). In every cell the SAME round grey sling stone "
    "copied from the FIRST reference image, flying to the RIGHT, centered, identical size and place, with a short painted dust-and-speed trail "
    "streaming to the LEFT. The stone spins on itself: from cell to cell its cracks, chips and highlight rotate a twelfth of a turn so that "
    "after cell 12 it flows smoothly into cell 1; the trail of brown dust, small grey chips and thin speed streaks shifts and flickers "
    "each cell. Keep everything well inside its cell with a black margin. ")


# Eleventh pass (dev, 2026-10-13): the fragmentation grenade no longer looks like a real military grenade.
JOBS["i_rune_grenade"] = ("icon", ["art_source/ai/weapons/bomb.png", "art_source/ai/weapons/fire_flask.png"],
    "Game item icon in exactly the style of the reference images (thick black outline, flat saturated colors with simple painterly highlights, "
    "gold trim and gold diamond studs). It shows ONE single fantasy RUNE GRENADE: a round dark stone sphere split open by glowing red-orange "
    "crystal shards, bound by a gold band with engraved runes and a small red gem, a short braided fuse with a tiny spark. "
    "NO military grenade, NO pin ring, NO lever. Centered, tilted slightly, filling about 80 percent of the image. Transparent background.")


# Twelfth pass (dev, 2026-10-19): the five hostile shots become 12-frame loops, brighter and easy to spot (a bright hot core, vivid
# color per family, thick black outline). One generation each (--n 1). Baked by bake_proj.py.
_ENEMY_LOOP = ("A sprite sheet of ONE looping animation in a grid of 4 columns by 3 rows, 12 equal square cells read left to right then top to "
    "bottom, nothing crossing the cell borders, no grid lines, pure black background (#000000). In every cell the SAME HOSTILE enemy "
    "projectile {what}, pointing exactly to the RIGHT, centered, identical size and place, with a short painted trail streaming to the LEFT. "
    "It must be easy to spot at a glance on a busy battlefield: a big bright almost white core, very vivid saturated colors, a thick "
    "BLACK outline around the whole shape, a few sparkles. Only the flames, glow, crackle and trail flicker and shift from cell to cell so "
    "the sequence loops smoothly (cell 12 flows into cell 1). Keep everything well inside its cell with a black margin. ")
JOBS["a12_enemy_fire"] = ("sheet12", FIRE_REFS[:1] + ["art_source/ai/projectiles/19_enemy_fire.png"],
    _ENEMY_LOOP.format(what="is a blazing fireball copied in shape from the SECOND reference image but much brighter: a white-yellow core, vivid orange and hot red flame tongues"))
JOBS["a12_enemy_ice"] = ("sheet12", SPARK_REFS[:1] + ["art_source/ai/projectiles/18_enemy_ice.png"],
    _ENEMY_LOOP.format(what="is a spiky shard of ice copied in shape from the SECOND reference image but much brighter: a white-cyan core, vivid electric cyan and sky blue crystal facets, frost sparkles"))
JOBS["a12_enemy_acid"] = ("sheet12", MAGIC_REFS[:1] + ["art_source/ai/projectiles/20_enemy_acid.png"],
    _ENEMY_LOOP.format(what="is a blob of toxic acid copied in shape from the SECOND reference image but much brighter: a pale lime core, vivid neon green and yellow goo, dripping drops"))
JOBS["a12_enemy_stone"] = ("sheet12", FIRE_REFS[:1] + ["art_source/ai/projectiles/21_enemy_stone.png"],
    _ENEMY_LOOP.format(what="is a jagged flaming boulder copied in shape from the SECOND reference image but much brighter: a bright yellow-white molten core showing through cracks, vivid orange-red rock edges"))
JOBS["a12_enemy_orb"] = ("sheet12", MAGIC_REFS[:1] + ["art_source/ai/projectiles/06_enemy_orb.png"],
    _ENEMY_LOOP.format(what="is a round dark-magic energy orb copied in shape from the SECOND reference image but much brighter: a white-pink core, vivid magenta and hot pink swirling aura, sparks"))


# Thirteenth pass (dev, 2026-10-28): the plain colored balls say nothing about who shoots. One shaped, flat shot per enemy
# family (single cell, pointing right, short trail), thick dark outline plus a thin dark crimson rim so that it never reads as a
# player shot. One candidate each (ONE). Baked by bake_proj.py (SINGLES).
_ENEMY_FLAT = ("Flat 2D cartoon game projectile in the same flat style as the reference image (thick dark navy outline, flat saturated "
    "cel-shaded colors, one simple highlight). A single HOSTILE enemy projectile, seen from above, pointing exactly to the RIGHT, centered "
    "vertically, a SHORT trail to the LEFT: {what} A thin dark crimson rim runs just inside the outline so it reads as hostile. "
    "NO particles, NO sparks, NO glow haze, nothing else. Pure black background (#000000) everywhere else, nothing else in the image. ")
_FLAT_REF = ["art_source/ai/projectiles/10_arrow.png"]
JOBS["c_enemy_orb"] = ("cell", _FLAT_REF, _ENEMY_FLAT.format(what="a dark-magic orb: a dark crimson sphere with a bright magenta core and a swirl, a short tail of dark red embers."))
JOBS["c_enemy_ice"] = ("cell", _FLAT_REF, _ENEMY_FLAT.format(what="a jagged pointed icicle shard of pale blue ice with white facets, tip pointing right, a short cold blue streak."))
JOBS["c_enemy_fire"] = ("cell", _FLAT_REF, _ENEMY_FLAT.format(what="a spat fireball: a round orange fireball with a yellow core and a short tail of flame tongues streaming left."))
JOBS["c_enemy_acid"] = ("cell", _FLAT_REF, _ENEMY_FLAT.format(what="a glob of toxic acid: a neon green blob with a lime highlight and two dripping drops trailing to the left."))
JOBS["c_enemy_stone"] = ("cell", _FLAT_REF, _ENEMY_FLAT.format(what="a rough grey rock chunk with a few cracks and a darker shadow side, a small puff of grey dust trailing to the left."))
ONE = {"c_enemy_orb", "c_enemy_ice", "c_enemy_fire", "c_enemy_acid", "c_enemy_stone"}


def main() -> None:
    OUT.mkdir(exist_ok=True)
    names = sys.argv[1:] or list(JOBS)
    for name in names:
        kind, refs, text = JOBS[name]
        if (OUT / (name + ("_1.png" if name in ONE else "_2.png"))).exists():
            continue
        size = {"sheet": "1536x1024", "sheet12": "2048x1536", "icon": "1536x1024"}.get(kind, "1024x1024")
        prompt = text if kind == "icon" else STYLE + text
        command = [sys.executable, "tools/art/gen_image.py", "--out", "art_tests/proj/%s.png" % name, "--n", "1" if name in ONE else "2", "--size", size,
                   "--quality", "high", *([] if kind == "icon" else ["--opaque"]), "--image", *refs, "--prompt", prompt]
        result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
        print(name, result.returncode, result.stderr[-200:].replace("\n", " "), flush=True)
    print("ALLDONE", flush=True)


if __name__ == "__main__":
    main()
