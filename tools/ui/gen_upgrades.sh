#!/bin/bash
# Level-up icons (17 stat upgrades) in the T3 rich style; style reference = a finished item icon.
cd "$(dirname "$0")/../.."
REF=assets/icons/items/magnet_glove.png
OUT=art_tests/ui_final/upg_raw
mkdir -p $OUT
BASE="A rich premium dark-fantasy game icon of a single symbolic object, centered, same painterly rendering, crisp dark outline, rim light and glow as the reference image, two or three tiny blue crystal sparks. Transparent background, no text, no frame, no floor shadow, no big halo. The object: "
declare -A P=(
 [amplitude]="a glowing cyan shockwave ring expanding outward from a crystal, concentric energy rings"
 [evasion]="a flowing hooded cape mid dodge with wind swirls and afterimage trails, light blue"
 [ferocity]="a roaring red demon claw with glowing red energy and cracks, a fang"
 [fortune]="a golden four leaf clover on a glowing gold coin, lucky sparkles"
 [harvest]="a golden sickle with a basket of glowing coins and gems"
 [haste]="a white and gold feather wing with speed lines and a lightning bolt"
 [leech]="a red blood droplet with a fang being absorbed, red crystal heart glow"
 [magnet]="a red and silver horseshoe magnet pulling blue crystal shards"
 [multishot]="three crossed glowing arrows fanning out"
 [piercing]="a glowing silver spear tip piercing through a stone shield, cyan energy"
 [plating]="a steel round shield with gold rim and a blue crystal boss"
 [power]="a clenched armored fist with orange glowing power energy"
 [precision]="a golden crosshair target reticle with a glowing red center"
 [reach]="a long glowing spear extending to the right with a distance marker arrow"
 [regeneration]="a green glowing heart with leaves and healing sparkles"
 [swiftness]="winged boots running with blue speed trails"
 [vitality]="a big red crystal heart with golden ornate frame"
)
n=0
for k in "${!P[@]}"; do
  [ -f $OUT/$k.png ] && continue
  python tools/art/gen_image.py --out $OUT/$k.png --image $REF --prompt "$BASE${P[$k]}." --size 1024x1024 --quality medium >> $OUT/gen.log 2>&1 &
  n=$((n+1)); [ $((n % 4)) -eq 0 ] && wait
done
wait
echo done >> $OUT/gen.log
