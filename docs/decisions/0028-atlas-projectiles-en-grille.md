# 0028 — Atlas des projectiles en grille

Date : 2026-10-12 · Statut : accepté

## Contexte
Les corps de projectiles peints étaient une bande horizontale (`assets/sprites/projectiles.png`, 89 cellules de 92 px = 8188 px sur 8192 max). Plus aucune animation de 12 images ne pouvait être ajoutée (fronde, Arc long, Arbalète à répétition, Javelots, grenade à 12 images).

## Décision
- L'atlas devient une **grille de 16 colonnes** (cellules toujours de 92 px) : 1472 x 552 px aujourd'hui, jusqu'à 256 cellules (16 lignes). `tools/art/bake_map.gd` (`PROJECTILE_COLUMNS`) cuit la grille.
- Le shader `projectile_body.gdshader` calcule colonne et ligne de la cellule (`columns`, `rows`) ; le code de cellule dans le canal alpha de la couleur d'instance passe de 128 à 256 (`ProjectileRenderer.CELL_CODE`). `ProjectileRenderer.BODY_COLUMNS` doit rester égal à `PROJECTILE_COLUMNS`.
- **La numérotation des cellules ne change pas** (style - 1, boucles `ANIM`) : aucun dessin ni `.tres` d'arme à toucher.

## Conséquences
- Un nouveau corps animé = 12 cellules de plus à la suite, `ANIM` + `BODY_CELLS` + `bake_proj.py` (`LOOPS`), sans limite de largeur.
- Mesure du stress test sur la même machine, en alterné avec l'ancienne bande : mêmes FPS (74-77 des deux côtés ce soir).
- Les shaders qui lisent des cellules sans passer par `ProjectileRenderer` n'existent pas ; le test `test_every_style_has_render_settings_and_a_cell` vérifie la taille de la grille.
