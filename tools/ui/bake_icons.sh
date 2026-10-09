#!/bin/bash
# raw AI icons -> 128 px game icons in art_tests/ui_final/icons/{weapons,items}
cd "$(dirname "$0")/../.."
G="/c/Program Files/Godot/Godot.exe"
mkdir -p art_tests/ui_final/icons/weapons art_tests/ui_final/icons/items
for f in art_tests/ui_final/icons_raw/weapons-*.png; do
  w=$(basename "$f" .png); w=${w#weapons-}
  DIAG=""
  grep -q "icon_diagonal = true" data/weapons/$w.tres && DIAG="--diagonal=1.0"
  "$G" --headless --path . -s res://tools/art/make_icon.gd -- --in=$f --out=art_tests/ui_final/icons/weapons/$w.png --size=128 --cut=0.35 $DIAG | grep -v Godot
done
for f in art_tests/ui_final/icons_raw/items-*.png; do
  w=$(basename "$f" .png); w=${w#items-}
  "$G" --headless --path . -s res://tools/art/make_icon.gd -- --in=$f --out=art_tests/ui_final/icons/items/$w.png --size=128 --cut=0.35 | grep -v Godot
done
