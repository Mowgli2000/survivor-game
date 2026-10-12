---
name: art-pipeline
description: Pipeline des images et animations peintes par IA - génération (gen_*.py), choix des candidats, détourage et cuisson (bake_*.py), interpolation de mouvement, intégration en jeu (EffectSheet, Vfx, projectiles), vérification en mouvement. À utiliser pour toute nouvelle arme, explosion, zone au sol, projectile animé ou icône.
---

# art-pipeline

## Objectif
Produire une animation ou une icône d'arme cohérente avec le reste du jeu, sans gaspiller d'appels IA (qui coûtent de l'argent).

## Règles du dev (à ne jamais enfreindre)
1. **Avant tout appel IA** : lister les images, les prompts, le nombre d'appels, puis **attendre l'accord**. Exception : le dev a dit « fais-le directement » pour regénérer une animation qui resterait saccadée.
2. Toutes les animations en jeu sont **peintes par IA** (pas de mélange avec du dessin par code). La rotation par code d'une image IA est permise (objets lancés).
3. Chaque arme a **sa propre animation d'explosion/d'impact reconnaissable**.
4. Ce qui est dessiné = ce qui fait mal (forme de dégâts identique à la forme peinte).
5. Animations d'attaque : 12 images minimum (16 pour les explosions), >= 24 images/s ; les grosses animations lentes sont doublées par interpolation.
6. Aucun effet peint dans la zone du héros (rayon 100 px) : sauf les effets au sol (sol brûlant, puits), qui ne sont jamais effacés.
7. Un effet au sol n'a pas de disque plein ni de bord net (« autocollant ») : taches irrégulières, trous noirs entre les flammes, bord déchiqueté. Une copie à 30 % passe par-dessus les monstres (`Vfx.GROUND_FRONT_SHARE`).
8. IDs d'armes stables ; on parle des armes par leur nom en jeu (`docs/weapons-noms.md`).

## Étapes
1. **Génération** : ajouter un job dans `tools/art/gen_vfx_hd.py` (effets : grilles `g12` 4x3 ou `g16` 4x4, fond noir) ou `tools/art/gen_proj.py` (projectiles : `sheet12`, `cell`, `icon`). 2 candidats par job dans `art_tests/vfx_hd/<nom>_{1,2}.png` ou `art_tests/proj/`. Les jobs existants sont ignorés. Une icône d'abord, puis l'animation du projectile **copiée de l'icône retenue** (cohérence).
2. **Revue** : montage des 2 candidats côte à côte (Pillow), choisir. Vérifier : continuité de la boucle (image 12 -> 1), pas de dérive du sujet entre les lignes de la planche (voir `stabilize` dans `bake_proj.py`), couleurs imposées respectées.
3. **Interpolation** (grosses animations) : `python tools/art/interpolate_sheet.py [--loop] <nom> <candidat>` écrit `<nom>_x2.png` (8 colonnes, cellules 320 px). Ajouter le nom à `X2` dans `bake_vfx.py`.
4. **Cuisson** : effets -> `python tools/art/bake_vfx.py <nom>` (table `SHEETS_HD` : candidat, boost, échelle, avance, durée ; `EXTRA` : squash, head, art_angle, opacity) ; projectiles -> `python tools/art/bake_proj.py` (tables `SINGLES`, `LOOPS` ; bande de 89 cellules de 92 px, **max 8192 px de large**) puis `powershell -ExecutionPolicy Bypass -File tools/bake_sprites.ps1`. Toujours finir par `Godot --headless --path . --import`.
5. **Icône** : `Godot --headless --path . -s res://tools/art/make_icon.gd -- --in=<png> --out=assets/icons/weapons/<id>.png --cut=0.3 [--diagonal=1.8]` (l'icône sert aussi d'arme flottante : pointe à droite ; `--cut` va de 0 à 1).
6. **Intégration** : `.tres` d'`EffectSheet` dans `data/vfx/`, référencé par l'arme (`slash_sheet`, `beam_sheet`, `zone_sheet`, `zone_end_sheet`, `fall_sheet`...) ou par `EffectSheets.explosion_for`. Un projectile animé = entrée `ANIM` du `ProjectileRenderer` + `BODY_SCALE` + `BODY_CELLS`.
7. **Vérification en mouvement** (jamais une seule image) : `shape_check.tscn -- --weapon=<id> --at=<s> --out=<png>` à plusieurs instants, `vfx_gallery.tscn -- --projectiles|--blasts --steps=N`, `capture.tscn`. Regarder la taille par rapport à un ennemi, l'orientation, la zone de dégâts.
8. Tests (`tools/run_tests.ps1`), `tools/check_scripts.ps1`, stress test (>= 100 FPS ; machine bruyante : comparer en alterné), mettre à jour `PROJECT_STATUS.md`.

## Pièges connus
- Heredoc Python : `\\n` devient un vrai saut de ligne ; ouvrir les fichiers avec `encoding='utf-8', newline=''`.
- Textures importées périmées après une cuisson : relancer `--import`.
- Un `QuadMesh` est dessiné **à l'envers** en 2D : le shader des projectiles retourne `v` ; ne pas le retirer.
- Objets sombres (bombe, sphère) : détourage `key_solid` (fermeture morphologique), pas `key`.
- Le générateur dérive : recaler les images d'une boucle de corps rigide.
- Cellule de bande de projectiles : chaque style animé ajoute 12 cellules ; vérifier la largeur.
