"""Art briefs of the final bosses of the seals 2 to 6 (the Demon Knight's are in gen_boss_anim.py): the look to keep,
how each creature moves (and does NOT move: no human sword poses for a golem, a spider or a dragon), the text of every
animation sheet and the five painted effects of its attacks (each boss has its own matter and its own shapes).
Used by tools/art/gen_boss_kit.py."""

GRID = ("A sprite sheet of ONE animation: a grid of 4 columns by 4 rows, 16 equal square cells read left to right then top to bottom, "
        "16 consecutive poses of the same motion, each pose only slightly further along than the previous one so the animation plays "
        "smoothly. Transparent background. The creature is drawn at exactly the same scale in every cell, with its feet (or lowest "
        "point touching the ground) on the same ground line, three-quarter top-down view facing right, fully inside its cell with "
        "margin, nothing crossing the cell borders, no grid lines, no text. Crisp sharp drawing in every pose: NO motion blur, NO speed "
        "lines, NO ghosting, NO separate special-effect drawing (the effects are added by the game). ")

FX_STYLE = ("Hand-painted stylized 2D game VFX in the style of Hades 2 and anime action: a bright core, saturated glowing color around "
            "it, layered painterly shapes with sharp tapered shards and fluid ribbons, a few sparkles, same painterly look as the "
            "reference images. No characters, no text, no border, no floor. ")
FX_GRID = ("A sprite sheet of ONE smooth animation in a grid of 4 columns by 3 rows, 12 equal square cells read left to right then "
           "top to bottom. Every cell is a consecutive moment of the same motion, each slightly further along than the previous one, "
           "so the animation plays fluidly. Keep the whole effect well inside its cell with a margin of black on every side, nothing "
           "crossing the cell borders, no grid lines, pure black background (#000000). Seen from above, centered in the cell. ")
FX_TIMELINE = ("Timeline: cells 1-2 a thin faint beginning; cells 3-6 it grows quickly; cells 7-8 the full brightest shape; "
               "cells 9-12 it thins, breaks up and fades. ")

KITS = {
    "iron_boss_final": {
        "ref": "art_source/ai/iron/iron_boss_final.png",
        "look": ("Same character as the reference image: the colossal four-armed stone idol (Colossal Idol) made of dark grey carved stone "
                 "with gold ornaments and glowing turquoise cracks, a glowing turquoise third eye, a golden crescent blade in each of "
                 "its four fists, exactly the same shapes, colors and chunky Brawlhalla-style cartoon look, thick clean black outline, "
                 "flat cel shading. "),
        "motion": ("It is a heavy stone golem, NOT a human fighter: no fencing or martial-arts stances, no sword flourishes. It moves "
                   "with slow, grinding, stomping weight: its whole stone body shifts at once, its four arms move in pairs, stone "
                   "dust and tiny pebbles fall from its joints. "),
        "idle": ("A calm idle loop that loops perfectly (pose 16 flows back into pose 1): the idol stands planted, its four arms "
                 "hanging with the crescent blades pointing down, slowly shifting weight, turquoise cracks pulsing slightly, a few "
                 "pebbles falling. Only small subtle movements."),
        "walk": ("A slow heavy stomping walk cycle in place that loops perfectly (pose 16 flows back into pose 1), facing right: each "
                 "step lifts a massive stone leg and plants it, the whole body rocking, the four blade arms swaying in pairs. Poses "
                 "1-8 left leg forward, poses 9-16 right leg forward."),
        "windup": ("The wind-up of a huge crushing blow, 16 poses. Poses 1-3: from the standing stance it plants its feet wide and "
                   "sinks its weight. Poses 4-8: all four arms rise slowly, the crescent blades swinging up and inward until they "
                   "cross high above its head, its torso arching back. Poses 9-12: hold at the top, trembling, cracks glowing "
                   "brighter, dust falling. Poses 13-16: the final tension, the blades crossed high, the body leaning back."),
        "strike": ("The strike and recovery of a huge crushing blow, 16 poses. Pose 1 is exactly the last pose of the wind-up reference "
                   "(blades crossed high). Poses 2-4: it brings all four arms crashing down together, the body slamming forward. "
                   "Poses 5-6: the impact, blades buried low in front of it, the body bent over them. Poses 7-8: it holds the impact. "
                   "Poses 9-12: it slowly pulls the blades up and straightens. Poses 13-16: it returns to the standing stance, "
                   "pose 16 identical to the reference image."),
        "entrance_a": ("The entrance of a boss, 16 poses. Poses 1-4: a dark mound of rubble and dust, the idol's shape barely "
                       "visible, only the turquoise third eye glowing. Poses 5-9: the stone body assembles and rises out of the "
                       "rubble, pieces of stone snapping into place, head last. Poses 10-13: it stands, the four arms still, crescent "
                       "blades pointing down. Poses 14-16: its third eye flares bright turquoise."),
        "entrance_b": ("The second half of a boss entrance, 16 poses. Pose 1 is exactly the last pose of the reference (standing, "
                       "third eye flaring). Poses 2-6: it raises its four arms wide to the sides. Poses 7-11: it slams all four "
                       "crescent blades into the ground together, the whole body shuddering, dust bursting. Poses 12-16: it rises "
                       "and settles into the standing stance, pose 16 identical to the standing stance of the reference."),
        "phase_a": ("A boss changing phase, 16 poses. Poses 1-2: the standing stance. Poses 3-6: it staggers, a huge crack splits its "
                    "chest and glowing turquoise light pours out, a stone arm shaking. Poses 7-10: more cracks race over the whole "
                    "body, bits of stone fall off, the third eye blazing. Poses 11-16: the body swells and rises taller, the "
                    "turquoise light brighter."),
        "phase_b": ("The second half of a boss changing phase, 16 poses. Pose 1 is exactly the last pose of the reference (taller, "
                    "cracks glowing). Poses 2-6: the four arms raise and pound its chest and the ground in turn. Poses 7-11: it "
                    "spins its four crescent blades overhead in a showy circle. Poses 12-16: it settles into the standing stance "
                    "with the cracks glowing bright turquoise."),
        "death": ("The death of a boss, 16 poses. Poses 1-3: a heavy blow, it rocks back, stone chips flying. Poses 4-7: its arms go "
                  "slack, a crescent blade falls from a hand, the cracks spread and the turquoise glow flickers. Poses 8-11: its "
                  "body crumbles from the top, the head sliding off, blocks falling apart. Poses 12-16: it collapses into a heap of "
                  "rubble with a few glowing turquoise embers and the golden crescent blades lying on top, fading to almost nothing."),
        "fx": {
            "fx1": ("A shockwave of cracks: from the center, jagged cracks race outward over the ground in all directions like a "
                    "spiderweb of fractures with glowing turquoise light inside them, chips of stone flying up, a ring of dust "
                    "expanding. Palette: ochre, grey and turquoise. "),
            "fx2": ("A falling pillar of stone: a tall carved stone block slams down from above onto the center, a burst of grey and "
                    "ochre rock shards and dust, turquoise glyphs flashing on impact. "),
            "fx3": ("Concentric stone rings: three thick rings of rising rubble expanding one after the other from the center, each "
                    "ring a wall of broken stone with turquoise sparks. "),
            "fx4": ("A rune seal: a large circular golden and turquoise rune circle appears on the ground, glyphs lighting up one by "
                    "one around it, then a flash of turquoise light bursts upward from it. "),
            "fx5": ("A stone burst: a ground-level explosion of rock, boulders and gravel thrown outward, thick brown-grey dust "
                    "clouds, a few glowing turquoise cracks. "),
        },
    },
    "silver_boss_final": {
        "ref": "art_source/ai/silver/silver_boss_final.png",
        "look": ("Same character as the reference image: the Ice Giant, a huge bearded frost giant with pale blue skin, white fur "
                 "cloak and a crown of ice crystals, ice crystal armor on its shoulders and arms and a huge ice crystal club in "
                 "one hand, exactly the same shapes, colors and chunky Brawlhalla-style cartoon look, thick clean black outline, "
                 "flat cel shading. "),
        "motion": ("It is a huge frozen brute, NOT a swordsman: it fights with a club and its bare fists, with heavy lumbering "
                   "movements, big arcs of the whole body, frost mist breathing out of its beard. "),
        "idle": ("A calm idle loop that loops perfectly (pose 16 flows back into pose 1): the giant stands with the ice club resting "
                 "on its shoulder, breathing slowly with frost mist from its beard, the fur cloak swaying a little, the crown "
                 "glinting. Only small subtle movements."),
        "walk": ("A slow lumbering walk cycle in place that loops perfectly (pose 16 flows back into pose 1), facing right: heavy "
                 "wide steps, the body rocking side to side, the ice club swinging low in one hand, the other arm swinging. Poses "
                 "1-8 left foot forward, poses 9-16 right foot forward."),
        "windup": ("The wind-up of a huge club slam, 16 poses. Poses 1-3: from the standing stance it grips the ice club with both "
                   "hands and plants its feet wide. Poses 4-8: it hauls the club up and back over its shoulder, twisting its whole "
                   "torso, leaning far back. Poses 9-12: it holds at the top, shaking with effort, frost mist bursting from its "
                   "mouth. Poses 13-16: the final tension, the club high behind its head."),
        "strike": ("The strike and recovery of a huge club slam, 16 poses. Pose 1 is exactly the last pose of the wind-up reference "
                   "(club high behind the head). Poses 2-4: it hurls the club down in front of it with its whole body. Poses 5-6: the "
                   "impact, the club planted low in front of it, the body bent over it. Poses 7-8: it holds the impact. Poses 9-12: "
                   "it heaves the club back up and straightens. Poses 13-16: it returns to the standing stance with the club "
                   "on its shoulder, pose 16 identical to the reference image."),
        "entrance_a": ("The entrance of a boss, 16 poses. Poses 1-4: a block of ice with the dark silhouette of the giant frozen "
                       "inside, frost mist around it, a faint blue glow. Poses 5-9: the ice cracks all over and bursts apart, shards "
                       "flying, the giant bursting out. Poses 10-13: it stands in the middle of the falling ice shards, head bowed. "
                       "Poses 14-16: it lifts its head, eyes flaring bright blue."),
        "entrance_b": ("The second half of a boss entrance, 16 poses. Pose 1 is exactly the last pose of the reference (head up, "
                       "eyes blazing). Poses 2-6: it beats its chest with its free fist, then throws its arms wide and roars, a "
                       "huge cloud of frost mist from its mouth. Poses 7-11: it raises the ice club high with one hand and roars "
                       "again. Poses 12-16: it plants the club on its shoulder and settles into the standing stance, pose 16 "
                       "identical to the standing stance of the reference."),
        "phase_a": ("A boss changing phase, 16 poses. Poses 1-2: the standing stance. Poses 3-6: it staggers and drops to one knee, "
                    "the club planted, ice cracking across its skin. Poses 7-10: new ice crystals grow out of its back and "
                    "shoulders with sharp cracking motion, its eyes glowing brighter. Poses 11-16: it rises to its full height, "
                    "arms wide, roaring, the crystals larger."),
        "phase_b": ("The second half of a boss changing phase, 16 poses. Pose 1 is exactly the last pose of the reference (arms wide, "
                    "larger ice crystals). Poses 2-6: it stamps twice, the whole body shuddering, frost mist bursting. Poses 7-11: "
                    "it swings the ice club in a wide showy circle around itself. Poses 12-16: it settles into the standing stance "
                    "with the bigger crystals glowing icy blue."),
        "death": ("The death of a boss, 16 poses. Poses 1-3: a heavy blow, it rocks back, ice chips flying. Poses 4-7: the club slips "
                  "from its hand and falls, it drops to its knees, ice spreading over its body. Poses 8-11: it freezes solid into a "
                  "statue of ice, cracks racing across it. Poses 12-16: the frozen statue shatters into shards that melt and drift "
                  "away, leaving only the ice crown and a few glittering shards on the ground, fading to almost nothing."),
        "fx": {
            "fx1": ("Ice spikes erupting: a ring of tall sharp ice crystals thrusting up out of the ground one after the other from the "
                    "center outward, glittering, shards flying, a frost ring on the ground. Palette: pale blue, white and cyan. "),
            "fx2": ("A blizzard gust: a wide swirling wall of wind-driven snow and ice crystals sweeping across the cell in one "
                    "direction, streaks of white wind, snowflakes and glittering shards, swirls of frost. "),
            "fx3": ("A frost wall: a long row of tall jagged ice blocks rising from the ground side by side across the cell with a "
                    "narrow gap, cold mist pouring off them, glittering. "),
            "fx4": ("A freezing patch: a large circular patch of ground freezing over, white frost crystals growing outward from the "
                    "center in snowflake patterns, a pale blue glow, cold mist rising. "),
            "fx5": ("A club impact: a heavy blue-white shockwave of ice and snow, a burst of ice chunks and powder thrown out, a "
                    "spiky star of cracks in the ground. "),
        },
    },
    "gold_boss_final": {
        "ref": "art_source/ai/gold/gold_boss_final.png",
        "look": ("Same character as the reference image: the Demon Lord, a red-skinned horned demon in spiked black armor with bat wings, "
                 "a skull belt and a huge black flaming greatsword, exactly the same shapes, colors and chunky Brawlhalla-style "
                 "cartoon look, thick clean black outline, flat cel shading. "),
        "motion": ("It is a winged brute demon, NOT a duelist: it fights with wide brutal sweeping swings, spreads and beats its "
                   "wings to intimidate, stomps and roars. Use the wings in the poses. "),
        "idle": ("A calm idle loop that loops perfectly (pose 16 flows back into pose 1): the demon stands with the flaming "
                 "greatsword resting point-down in front of it, its wings slowly opening and closing, chest heaving, small flames "
                 "flickering on the blade. Only small subtle movements."),
        "walk": ("A slow menacing walk cycle in place that loops perfectly (pose 16 flows back into pose 1), facing right: heavy "
                 "wide strides, the greatsword dragged low in one hand, the wings half open and flapping slowly with each step. "
                 "Poses 1-8 left foot forward, poses 9-16 right foot forward."),
        "windup": ("The wind-up of a huge sideways sweep, 16 poses. Poses 1-3: from the standing stance it spreads its wings wide and "
                   "crouches. Poses 4-8: it winds the greatsword back behind it with both hands, the whole body twisting away "
                   "from the target, the wings flaring. Poses 9-12: it holds the twist, trembling, flames roaring up the blade. "
                   "Poses 13-16: the final tension, sword far behind it, torso fully coiled."),
        "strike": ("The strike and recovery of a huge sideways sweep, 16 poses. Pose 1 is exactly the last pose of the wind-up reference "
                   "(sword far behind, body coiled). Poses 2-4: it unwinds with a brutal wide horizontal sweep of the greatsword in "
                   "front of it, the wings snapping back. Poses 5-6: the end of the sweep, the sword far extended to the front, the "
                   "body twisted forward. Poses 7-8: it holds. Poses 9-12: it pulls the sword back and straightens, wings settling. "
                   "Poses 13-16: it returns to the standing stance, pose 16 identical to the reference image."),
        "entrance_a": ("The entrance of a boss, 16 poses. Poses 1-4: a swirl of black smoke and embers with the dark silhouette of "
                       "the demon, wings folded around it like a cocoon, two orange eyes glowing. Poses 5-9: the wings unfold "
                       "slowly, revealing the demon crouched, smoke streaming off. Poses 10-13: it rises to its feet, the wings "
                       "half open. Poses 14-16: it opens the wings fully and its eyes flare bright orange."),
        "entrance_b": ("The second half of a boss entrance, 16 poses. Pose 1 is exactly the last pose of the reference (wings fully "
                       "open, eyes blazing). Poses 2-6: it throws its head back and roars, chest out, wings spread wide. Poses 7-11: "
                       "it stabs the flaming greatsword into the ground and leans on it, wings beating once, flames bursting up the "
                       "blade. Poses 12-16: it pulls the sword out and settles into the standing stance, wings folding, pose 16 "
                       "identical to the standing stance of the reference."),
        "phase_a": ("A boss changing phase, 16 poses. Poses 1-2: the standing stance. Poses 3-6: it staggers, grips its head, the "
                    "horns glowing red-hot. Poses 7-10: it arches its back, its wings stretching to their full span, its armor "
                    "spikes growing longer, cracks of orange light in its skin. Poses 11-16: it straightens up bigger, roaring."),
        "phase_b": ("The second half of a boss changing phase, 16 poses. Pose 1 is exactly the last pose of the reference (bigger, "
                    "wings spread, glowing). Poses 2-6: it beats its wings twice, the whole body rocking. Poses 7-11: it swings the "
                    "flaming greatsword in a showy circle overhead. Poses 12-16: it settles into the standing stance with the "
                    "orange glow still on its horns and armor."),
        "death": ("The death of a boss, 16 poses. Poses 1-3: a heavy blow, it rocks back, wings flaring in pain. Poses 4-7: the "
                  "greatsword drops, it falls to its knees, the wings drooping, orange cracks of light spreading over its body. "
                  "Poses 8-11: it slumps forward, the body burning from within, turning to ash from the edges. Poses 12-16: it "
                  "crumbles to a pile of glowing embers and ash, the black greatsword stuck upright in the ground, the "
                  "embers drifting away, fading to almost nothing."),
        "fx": {
            "fx1": ("A pillar of hellfire: a tall column of swirling red and orange flame erupting from the ground in a round burst, "
                    "white-hot core, black smoke curling around, flying embers, a ring of scorched ground. Palette: deep red, "
                    "orange and black with a little violet. "),
            "fx2": ("A flaming sword sweep: one huge crescent sweep of orange and red fire with a white-hot edge, black smoke ribbons "
                    "and sparks, sweeping from the left across to the right, about 200 degrees. "),
            "fx3": ("Chains of fire: several heavy glowing chains lashing out from the center and slamming onto the ground, links of "
                    "molten orange iron, sparks and flames at the impact points, scorched marks. "),
            "fx4": ("A rotating beam of fire: a bright straight beam of orange-white flame from the center to the edge of the cell, "
                    "a spiral of embers around it, heat shimmer, a flare at its origin. "),
            "fx5": ("An infernal burst: a ground-level ring of explosion, a wave of flame and shockwave expanding outward, black "
                    "smoke puffs and lava-orange cracks on the ground. "),
        },
    },
    "obsidian_boss_final": {
        "ref": "art_source/ai/obsidian/obsidian_boss_final.png",
        "look": ("Same character as the reference image: the Hive Queen, a giant spider-like insect queen with a dark purple glossy "
                 "chitin shell marked with glowing acid-green patches, a crowned insectoid head, large curved green-tipped legs and "
                 "claws, exactly the same shapes, colors and chunky Brawlhalla-style cartoon look, thick clean black outline, flat "
                 "cel shading. "),
        "motion": ("It is a giant insect, NOT a humanoid: no arms raised like a person, no swords, no martial stances. It moves on its "
                   "many legs: skittering and stabbing with its front legs, rearing up its front half, pulsing its swollen abdomen, "
                   "twitching mandibles. Never stands upright like a person. "),
        "idle": ("A calm idle loop that loops perfectly (pose 16 flows back into pose 1): the queen crouches on its legs, its "
                 "abdomen slowly swelling and shrinking, the front legs tapping the ground one after the other, mandibles twitching, "
                 "the green patches pulsing. Only small subtle movements."),
        "walk": ("A skittering crawl cycle in place that loops perfectly (pose 16 flows back into pose 1), facing right: the legs "
                 "move in alternating groups, the body bobbing low and heavy, the abdomen swaying behind. Poses 1-8 and 9-16 are "
                 "the two alternating leg groups."),
        "windup": ("The wind-up of a stabbing strike, 16 poses. Poses 1-3: from the crouch it plants its rear legs and lowers its "
                   "head. Poses 4-8: it rears up its front half, the two big front legs rising and spreading wide, the abdomen "
                   "tipping down. Poses 9-12: it holds reared up, front legs trembling at the top, mandibles wide, green venom "
                   "dripping from the leg tips. Poses 13-16: the final tension, front legs fully raised, ready to stab."),
        "strike": ("The strike and recovery of a stabbing strike, 16 poses. Pose 1 is exactly the last pose of the wind-up reference "
                   "(reared up, front legs raised). Poses 2-4: it slams both front legs down in front of it, the whole body "
                   "lunging forward. Poses 5-6: the impact, the leg tips driven into the ground, the head low. Poses 7-8: it holds. "
                   "Poses 9-12: it pulls the legs out and lowers its front half. Poses 13-16: it returns to the crouch, pose 16 "
                   "identical to the reference image."),
        "entrance_a": ("The entrance of a boss, 16 poses. Poses 1-4: a huge glistening purple egg sac and cocoon of webbing, a "
                       "dark shape moving inside, a faint green glow. Poses 5-9: the cocoon tears open from inside, green slime "
                       "dripping, a leg poking through. Poses 10-13: the queen crawls out of the torn cocoon, body low. Poses "
                       "14-16: it settles into the crouch and its eyes flare bright acid green."),
        "entrance_b": ("The second half of a boss entrance, 16 poses. Pose 1 is exactly the last pose of the reference (crouching, "
                       "eyes blazing). Poses 2-6: it rears up its front half and screeches, mandibles wide, front legs spread. "
                       "Poses 7-11: it slams its front legs down twice, the abdomen pulsing and swelling. Poses 12-16: it "
                       "lowers and settles into the crouch, pose 16 identical to the crouch of the reference."),
        "phase_a": ("A boss changing phase, 16 poses. Poses 1-2: the crouch. Poses 3-6: it convulses, rears up and shakes, the "
                    "chitin shell cracking open along its back. Poses 7-10: it sheds a layer of old shell and a brighter, glossier "
                    "shell with bigger glowing green patches shows underneath, the legs lengthening. Poses 11-16: it lowers "
                    "itself again, larger and glowing."),
        "phase_b": ("The second half of a boss changing phase, 16 poses. Pose 1 is exactly the last pose of the reference (larger, "
                    "glowing). Poses 2-6: the abdomen swells and a wave of green light runs over its body. Poses 7-11: it "
                    "screeches, the front legs thrashing in the air. Poses 12-16: it settles into the crouch with the green "
                    "patches glowing bright."),
        "death": ("The death of a boss, 16 poses. Poses 1-3: a heavy blow, it recoils, legs flailing. Poses 4-7: its legs buckle "
                  "one by one and it sinks to the ground, green ichor leaking. Poses 8-11: the shell cracks open and the body "
                  "collapses, legs curling inward. Poses 12-16: the body dissolves into green slime and spores that drift away, "
                  "leaving only a few curled leg tips and a faint green glow, fading to almost nothing."),
        "fx": {
            "fx1": ("A venom pool: a large irregular puddle of acid-green poison spreading over the ground with bubbling surface, "
                    "ripples and rising green vapor, a thick dark outline of ooze at its edge. Palette: acid green, yellow-green "
                    "and dark purple. "),
            "fx2": ("A spore burst: a round cloud of glowing green spores and puffs exploding outward from the center, drifting "
                    "motes, sticky strands, a few yellow sparks. "),
            "fx3": ("Web strands: long sticky silk threads shooting out and sticking across the ground in radial lines with a few "
                    "circular strands connecting them, glistening, a green venom drip at the crossings. "),
            "fx4": ("An egg burst: a cluster of glistening purple-green eggs on the ground that crack and burst open in a splash "
                    "of green slime and tiny larvae silhouettes. "),
            "fx5": ("A stabbing impact: a sharp radial burst of green-tipped spikes and ichor splashing out of a point on the "
                    "ground, a star of cracks, a splash of toxic droplets. "),
        },
    },
    "astral_boss_final": {
        "ref": "art_source/ai/astral/astral_boss_final.png",
        "look": ("Same character as the reference image: the Ancient Dragon, a red scaled four-legged dragon with big red bat wings, "
                 "golden-edged black armor plates, horns, a glowing amber chest gem and fire in its mouth, exactly the same shapes, "
                 "colors and chunky Brawlhalla-style cartoon look, thick clean black outline, flat cel shading. "),
        "motion": ("It is a dragon, NOT a humanoid: it walks on four legs, never stands upright like a person, holds no weapon and "
                   "makes no martial poses. It moves with its long neck and head, its wings beating or spreading, its tail "
                   "swinging, its claws and jaws. "),
        "idle": ("A calm idle loop that loops perfectly (pose 16 flows back into pose 1): the dragon stands on four legs, its chest "
                 "rising and falling, its neck swaying slightly, the wings gently folding and unfolding, the tail tip swaying, a "
                 "wisp of smoke from its nostrils. Only small subtle movements."),
        "walk": ("A slow heavy four-legged walk cycle in place that loops perfectly (pose 16 flows back into pose 1), facing right: "
                 "the legs move in diagonal pairs, the body rocking, the neck bobbing, the wings half folded, the tail swinging. "
                 "Poses 1-8 and 9-16 are the two diagonal leg pairs."),
        "windup": ("The wind-up of a huge fire breath, 16 poses. Poses 1-3: from the standing stance it plants its four legs wide "
                   "and lowers its head. Poses 4-8: it rears its head and neck far back, the chest swelling with a glowing amber "
                   "light inside, the wings spreading wide. Poses 9-12: it holds the inhale, throat and chest glowing hot, smoke "
                   "pouring from its nostrils and jaws. Poses 13-16: the final tension, head thrown far back, jaws opening, "
                   "fire glowing inside."),
        "strike": ("The strike and recovery of a huge fire breath, 16 poses. Pose 1 is exactly the last pose of the wind-up reference "
                   "(head thrown back, jaws opening). Poses 2-4: it snaps its head forward and down, jaws wide open, the neck "
                   "stretched long (no flame drawing: the flame is added by the game). Poses 5-6: the head held low and forward, "
                   "jaws wide, the whole body braced. Poses 7-8: it holds. Poses 9-12: it raises its head and closes its jaws, "
                   "smoke curling out. Poses 13-16: it returns to the standing stance, pose 16 identical to the reference image."),
        "entrance_a": ("The entrance of a boss, 16 poses. Poses 1-4: a dark shape curled up asleep like a boulder in swirling "
                       "smoke, two amber eyes cracking open. Poses 5-9: the dragon uncurls, the wings unfolding slowly, the neck "
                       "rising. Poses 10-13: it rises onto its four legs, head lowered. Poses 14-16: it lifts its head, the amber "
                       "chest gem flaring."),
        "entrance_b": ("The second half of a boss entrance, 16 poses. Pose 1 is exactly the last pose of the reference (head up, "
                       "chest gem flaring). Poses 2-6: it throws its head back and roars at the sky, wings spread to their full "
                       "span. Poses 7-11: it beats its wings hard twice, the body rising slightly and settling, claws digging into "
                       "the ground. Poses 12-16: it folds the wings and settles into the standing stance, pose 16 identical to "
                       "the standing stance of the reference."),
        "phase_a": ("A boss changing phase, 16 poses. Poses 1-2: the standing stance. Poses 3-6: it rears up, rocks and screams, "
                    "the chest gem blazing. Poses 7-10: cracks of molten amber light open across its scales and the horns, the "
                    "wings spread and trembling. Poses 11-16: it slams back down onto four legs, larger, glowing."),
        "phase_b": ("The second half of a boss changing phase, 16 poses. Pose 1 is exactly the last pose of the reference (larger, "
                    "glowing). Poses 2-6: it beats its wings twice, the body shuddering. Poses 7-11: it whips its tail around "
                    "and snaps its jaws. Poses 12-16: it settles into the standing stance with the molten cracks glowing bright."),
        "death": ("The death of a boss, 16 poses. Poses 1-3: a heavy blow, it rears back, wings flaring in pain. Poses 4-7: its legs "
                  "buckle, it sinks to the ground, wings drooping, the chest gem flickering. Poses 8-11: it lays its head down, "
                  "the gem going dark, cracks of amber light spreading over the body. Poses 12-16: the body breaks apart into "
                  "glowing embers and ash that drift away, leaving only the great horned skull and a few embers, fading to "
                  "almost nothing."),
        "fx": {
            "fx1": ("A dragon fire breath: a wide cone of roaring fire pouring out to the right from the left edge, orange and "
                    "yellow flames with a white-hot core, swirling red edges, embers and sparks. Palette: gold, orange, red and "
                    "white. "),
            "fx2": ("A wing gust: a huge curved sweep of wind and glowing embers from a beating wing, streaks of hot air, "
                    "feather-like shapes of light, drifting sparks. "),
            "fx3": ("Lightning strikes: several jagged white-gold bolts of lightning crashing down onto the center from above "
                    "with a bright flash and crackling forks along the ground. "),
            "fx4": ("Meteor impacts: a fiery rock plunging down and exploding on the ground, a ring of fire, flying molten rocks, "
                    "a glowing crater. "),
            "fx5": ("A claw swipe: three huge curved golden-white claw slashes sweeping across, with trailing sparks and a "
                    "shockwave. "),
        },
    },
}
