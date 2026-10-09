#!/bin/bash
# Backgrounds in the flat 2D cartoon style of the seal-select picture (assets/ui/select/seal_gate.png),
# recolored to the T3 midnight-blue / cyan palette.
cd "$(dirname "$0")/../.."
R=assets/ui/select/seal_gate.png
O=art_tests/ui_final/bg2
B="Create ONLY a background illustration for a game screen: no interface, no text, no logo, no frames, no characters or people. Use EXACTLY the same art style as the reference image: flat 2D cartoon / anime game art, cel shading, clean thick dark outlines, simplified stylized shapes, no photorealism, no painterly realism, no heavy noise. Change the palette from violet to deep midnight blue with cyan glows and small touches of gold, keep gothic dungeon architecture, floating glowing cyan crystals. The center is calm and slightly darker so interface can sit on top. Scene: "
python tools/art/gen_image.py --out $O/menu.png --opaque --size 1536x1024 --image $R --prompt "${B}a huge ruined gothic citadel at night with towers and red banners, a giant glowing orange-red magic portal in the middle distance, tiny monster silhouettes far away, cliffs with waterfalls." &
python tools/art/gen_image.py --out $O/select.png --opaque --size 1536x1024 --image $R --prompt "${B}an ancient temple hall seen from the front, a large glowing cyan summoning seal circle drawn on the stone floor exactly in the lower center of the picture (center of the circle at 50% width and 75% height), pillars, banners and braziers with blue flames on both sides, empty center." &
python tools/art/gen_image.py --out $O/shop.png --opaque --size 1536x1024 --image $R --prompt "${B}the inside of a vast underground arcane merchant hall, stone arches, shelves of glowing potions and relics, hanging lanterns, piles of gold, big glowing blue crystal." &
python tools/art/gen_image.py --out $O/victory.png --opaque --size 1536x1024 --image $R --prompt "${B}triumphant dawn over the gothic citadel, golden sunrays through clouds on the towers, the portal sealed and calm, golden and cyan light, hopeful and epic." &
python tools/art/gen_image.py --out $O/defeat.png --opaque --size 1536x1024 --image $R --prompt "${B}a ruined battlefield at night after defeat, broken pillars and swords stuck in the ground, fallen red banners, dying embers, cold blue fog, a dim red-orange portal glowing far away, somber." &
wait
