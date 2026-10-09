#!/bin/bash
# Regenerates weapon and item icons in the T3 "rich" style, from the existing AI references.
W="Redraw this exact weapon as a rich, premium dark-fantasy game icon. KEEP EXACTLY the same silhouette, proportions, length, orientation AND THE SAME COLOR PALETTE as the reference (a flame stays orange, ice stays icy, poison stays green; never recolor to blue). Horizontal, grip left, tip or head right, centered. Change only the rendering: polished painterly anime-game-art look, crisp clean dark outline, strong rim light, metallic reflections, fine details, a soft glow of the weapon's own color on its blade or head, one or two tiny blue crystal sparks. Transparent background, no text, no frame, no floor shadow, no big halo."
I="Redraw this exact item as a rich, premium dark-fantasy game icon, centered, same object and SAME MAIN COLORS as the reference (do not recolor). Polished painterly anime-game-art look, crisp clean dark outline, strong rim light, material reflections, fine details, a soft glow in the item's own color, two or three tiny blue crystal sparks. Transparent background, no text, no frame, no floor shadow, no big halo."
cd "$(dirname "$0")/../.."
OUT=art_tests/ui_final/icons_raw
mkdir -p $OUT
n=0
for kind in weapons items; do
  for f in art_source/ai/$kind/*.png; do
    w=$(basename "$f" .png)
    [ -f "$OUT/$kind-$w.png" ] && continue
    if [ $kind = weapons ]; then P="$W"; S=1536x1024; else P="$I"; S=1024x1024; fi
    python tools/art/gen_image.py --out "$OUT/$kind-$w.png" --image "$f" --prompt "$P" --size $S --quality medium >> $OUT/gen.log 2>&1 &
    n=$((n+1))
    [ $((n % 4)) -eq 0 ] && wait
  done
done
wait
echo done >> $OUT/gen.log
