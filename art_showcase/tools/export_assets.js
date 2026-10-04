// Exports every style as standalone SVG files into art_showcase/assets/style_xx/.
// Usage (from the repo root): node art_showcase/tools/export_assets.js
"use strict";
const fs = require("fs");
const path = require("path");
const K = require("../js/kage.js");

const root = path.join(__dirname, "..", "assets");
const DIRS = ["S", "SE", "E", "NE", "N", "SW", "W", "NW"];
const ANIMS = { idle: 8, walk: 8, attack: 8, hit: 4, death: 6 };
let count = 0;

function write(file, svg) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, svg);
  count += 1;
}

for (const style of K.STYLES) {
  const dir = path.join(root, style.id);
  for (const d of DIRS) write(path.join(dir, "directions", `kage_${d}.svg`), K.character(style, d));
  write(path.join(dir, "kage_silhouette.svg"), K.character(style, "SE", { silhouette: "#000" }));
  for (const pal of Object.keys(K.PALETTES)) write(path.join(dir, "palettes", `kage_${pal}.svg`), K.character(style, "SE", { palette: pal }));
  for (const [kind, frames] of Object.entries(ANIMS)) {
    for (let i = 0; i < frames; i++) {
      write(path.join(dir, "animations", kind, `kage_${kind}_${i}.svg`), K.character(style, "SE", { poseKind: kind, phase: i / frames }));
    }
  }
  write(path.join(dir, "enemy_imp.svg"), K.imp(style));
  write(path.join(dir, "style.json"), JSON.stringify({
    id: style.id, key: style.key, name: style.name, look: style.look, outline: style.outline,
    shading: style.shading, scores: style.scores, honest: style.honest,
  }, null, 2));
}
console.log(`exported ${count} files to ${root}`);
