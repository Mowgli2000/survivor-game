#!/bin/bash
cd "$(dirname "$0")/../.."
B="Create ONLY a background painting for a game screen: no interface, no text, no logo, no frames, no characters or people. Painterly anime dark-fantasy concept art in the exact mood and rendering of the reference image: deep midnight-blue and cyan lighting, floating glowing blue crystal shards, volumetric fog, gothic architecture. Wide cinematic composition, the center is calm and slightly darker so interface cards can sit on top."
R=art_tests/ui_ai/t3_run.png
O=art_tests/ui_final/bg
python tools/art/gen_image.py --out $O/shop_bg.png --opaque --size 1536x1024 --image $R --prompt "$B Scene: the inside of a vast underground arcane merchant hall, stone arches, shelves of glowing potions and relics, hanging lanterns, piles of gold, a large glowing blue crystal in the background." &
python tools/art/gen_image.py --out $O/select_bg.png --opaque --size 1536x1024 --image $R --prompt "$B Scene: an ancient hunters' guild temple hall with a huge glowing cyan summoning circle on the floor in the center, tall pillars, banners, crystals along the walls, candles." &
python tools/art/gen_image.py --out $O/defeat_bg.png --opaque --size 1536x1024 --image $R --prompt "$B Scene: a ruined battlefield at night after defeat, broken pillars and fallen banners, dying embers, cold blue fog, a dim red-orange portal glowing far away, somber and dramatic." &
python tools/art/gen_image.py --out $O/victory_bg.png --opaque --size 1536x1024 --image $R --prompt "$B Scene: triumphant dawn over the citadel, golden light breaking through the clouds onto gothic towers, the portal sealed and calm, golden and cyan light rays, floating crystals, hopeful and epic." &
wait
