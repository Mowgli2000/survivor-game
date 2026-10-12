# Équilibrage des armes — passe du 2026-10-11

## Intention du dev
Les trois armes les plus fortes du jeu : 1. **Arc céleste** (obtenu seulement après avoir fini le jeu, non modifié pour l'instant), 2. **Lames d'ombre**, 3. **Faux de guerre**. Il est normal que certaines armes soient plus fortes que d'autres. Lame runique : intacte.

## Mesure
70 ennemis (14 px, 1e9 PV, 60 px/s) répartis à 130-420 px du héros, un héros immobile, l'arme seule, stats de base, 6 s ; dégâts par seconde. Le banc favorise les zones (explosions, arcs) face aux tirs à cible unique : c'est un repère, pas un verdict. Le verdict viendra de la simulation de parties complètes (`tools/balance/run_balance.py`).

| Arme | I | IV (avant) | IV (après) |
|---|---|---|---|
| Arc céleste | 1793 | 4098 | 4098 (non touché) |
| Lames d'ombre | 540 | 152 -> 1375 | 1361 |
| Faux de guerre | 495 | 926 | **1167** (dégâts 18 -> 22) |
| Hache de guerre | 215 | 833 | 840 |
| Épée flamboyante | 219 | 809 | 827 |
| Bâton de feu | 193 | 782 | 784 |
| Grimoire des météores | 208 | 740 | 759 |
| Fiole explosive | 253 | 982 | **754** (dégâts 22 -> 19) |
| Marteau de guerre | 261 | 606 | 668 |
| Crocs du venin | 266 | 581 | 620 |
| Fiole de feu | 306 | 595 | 596 |
| Canon alchimique | 398 | 597 | 594 |
| Fiole de givre | 233 | 453 | 452 |
| Bombe | 238 | 403 | 403 |
| Puits de gravité | 184 | 396 | 393 |
| Arbalète lourde | 231 | 360 | 362 |
| Baguette de cristal | 102 | 385 | 349 |
| Sceptre de givre | 79 | 333 | 327 |
| Grenades à fragments | 135 | 311 | 290 |
| Lame runique (intacte) | 176 | 267 | 289 |
| Arbalète à répétition | 75 | 165 | **275** (dégâts 3 -> 5) |
| Bâton de foudre | 104 | 149 | **261** (dégâts 8 -> 14) |
| Javelots | 97 | 128 | **213** (dégâts 12 -> 20) |
| Arc long | 88 | 105 | **197** (dégâts 15 -> 28) |
| Shuriken | 44 | 105 | **180** (dégâts 7 -> 12) |
| Lance | 52 | 106 | **174** (dégâts 10 -> 16) |
| Rapière | 64 | 71 | **128** (dégâts 7 -> 11) |
| Katana | 43 | 62 | **120** (dégâts 12 -> 20) |
| Fronde | 20 | 35 | **70** (dégâts 5 -> 10) |

Ordre obtenu : Arc céleste > Lames d'ombre > Faux de guerre > le reste (<= 840).
Armes à tir unique encore basses sur ce banc (Fronde, Katana, Rapière, Lance...) : à confirmer ou corriger avec la simulation (critiques, ennemis isolés, boss).

## À régler avec la simulation (voir `plan-simulation-nuit.md`)
- vérifier que les trois premières restent premières en partie réelle ;
- victoires par arme de départ et par danger ;
- courbe de difficulté des dangers 0-5 et du mode infini (boss toutes les 5 vagues, très difficile vers la vague 35).
