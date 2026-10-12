# ADR 0026 — Effets peints et formes de dégâts : ce qu'on voit est ce qui blesse

**Date :** 2026-10-10 · **Statut :** appliqué sur la branche `visual/ui-refonte`, à valider en jeu par le dev

## Contexte
Les attaques de mêlée blessaient toutes un secteur instantané autour du héros (`area`, `arc_degrees`), alors que les animations peintes (IA) ont été refaites une par arme : vague, ligne, griffes, chute, anneau, lame orbitale… L'écran montrait un effet qui ne couvrait pas la zone des dégâts. Le dev exige l'inverse : la forme dessinée est la forme des dégâts, chaque arme a sa mécanique et son visuel (Hades 2, Vampire Survivors, Soulstone Survivor : héros toujours visible).

## Décision
- **`WeaponData.swing_fx`** (`ARC`, `TRAVEL`, `LINE`, `ORBIT`, `TARGET`, `RING`, `FLURRY`) choisit à la fois l'animation et la forme de dégâts ; `MeleeArcBehavior` les joue (`play_visual` pour l'image, fonctions de forme pour les dégâts). Paramètres : `hit_width`, `hit_radius`, `hit_time`, `target_sheet` (marque sur chaque ennemi blessé).
- **`EffectSheet.reach`** (mesuré à la cuisson par `tools/art/bake_vfx.py`) donne la portée du dessin dans sa case : `Vfx.sheet_at` dessine l'image exactement à la taille de la forme qui blesse. Les explosions peintes sont ajustées au rayon réel (`PAINTED_BLAST_SHARE`).
- **API de dégâts** : `damage_in_radius` et `damage_along_segment` acceptent `skip` (ennemis déjà touchés par ce coup : une forme mobile blesse chacun une fois) et `hit_log` (positions des ennemis blessés, pour les marques). Une forme qui se déplace ou grandit (vague, anneau, lame orbitale) est découpée en ticks.
- **Tirs en cloche** (bombe, fioles, grenade, boulet) : `Projectile.lob_peak/lob_total`, arc visuel dans `ProjectileRenderer`, aucun contact en vol, explosion à l'arrivée, anneau d'arrivée (`Vfx.landing`) à la taille exacte de l'explosion. Projectiles animés en boucle (bombe à mèche, boule de feu, éclat de glace, foudre) : 6 cellules par style après les 23 cellules de style (`ANIM_FIRST`), choisies par le temps ; le shader lit maintenant jusqu'à 64 cellules (`CELL_CODE`).
- **Outils** : F4 en jeu (ou `--shapes` de `capture.tscn`) dessine les formes de dégâts réelles ; `src/debug/shape_check.tscn --weapon=<id>` tire une arme sur un champ d'ennemis et montre les ennemis blessés.

## Conséquences
- Équilibrage : hache, marteau, lame runique, crocs et rapière ne blessent plus derrière le héros ; ils frappent en zone sur la cible ou sur une ligne. À repasser en simulation (`sg_balance`).
- Un effet à l'écran = une zone de dégâts : toute nouvelle arme de mêlée choisit un `swing_fx` et une planche dont la forme correspond.
- Pas fait : rayons peints (laser, sceptre de givre), foudre en chaîne, mort des monstres.

## Règles ajoutées après les retours du soir (2026-10-10)
- **Rien ne commence dans l'anneau des armes flottantes** (`MeleeArcBehavior.RING_GAP` = rayon des montures + 16 px) : lignes, éventail et vague partent de là ; un coup au sol sur un ennemi plus proche est repoussé à cette distance. Conséquence : un ennemi collé au héros n'est plus touché par les lignes (katana d'acier, lance, rapière) ; les autres armes le couvrent.
- **Taille selon la cadence** : rayon d'un cercle ou d'une vague = (36 + 30 × cooldown) × Zone ; `hit_scale` pour affiner. Arme rapide = petit effet.
- **Aucune rotation vers l'ennemi** pour les effets au sol (cercles, anneau, marques) ; seuls la vague, les lignes et l'orbite sont orientés.
- **Projectiles supplémentaires** : vague, ligne et éventail se répètent l'un après l'autre dans la même direction (0,1 s) ; les coups au sol vont sur des ennemis différents ; les lames orbitales s'espacent régulièrement.
- **Particules** : retirées des planches de mêlée au bake (`strip_specks`, petites taches isolées) ; celles collées au dessin restent (il faudrait régénérer).
- **Tirs en cloche** : correction d'un bug (l'explosion était rejouée à chaque image pendant le vol, `ProjectileManager`) ; plus d'anneau d'arrivée ; tailles ramenées à ~35 px.

## Copies d'une même arme (2026-10-10, nuit)
- Deux copies d'une même arme étaient indépendantes mais pouvaient frapper à la même image (une arme sans cible reste prête, donc après un moment sans ennemi toutes se déclenchent ensemble) et viser le même ennemi : un seul effet visible, deux fois les dégâts.
- `WeaponSlot.copy_rank` / `copy_count` (posés par `WeaponHolder._refresh_mounts`). Les copies gardent un écart de recharge ÷ nombre de copies (`_last_copy_fire`, y compris après une période sans ennemi) et la copie de rang *k* vise le *k*-ième ennemi le plus proche (`EnemyManager.find_nth_nearest`, `WeaponContext.pick_target`, utilisé par la mêlée, les tirs, les rayons et l'orientation des armes flottantes). Lame orbitale : les copies s'espacent régulièrement autour du héros.
- Les dégâts totaux ne changent pas : seule leur répartition dans le temps et dans l'espace.

## Rayons, éclair en chaîne et météore peints (2026-10-11)
- **Rayons** (baguette de cristal, sceptre de givre) : `WeaponData.beam_sheet`, feuille étirée sur la longueur réelle du rayon (`Vfx.sheet_stretch`, mode `STRETCH`), hauteur dessinée = largeur des dégâts × 18 (`BEAM_HEIGHT_PER_WIDTH`) : le cœur du rayon reste aussi fin que ce qui blesse. La baguette de cristal passe au rouge rubis (couleur de l'arme et icône) pour ne plus ressembler au sceptre de givre (bleu glacé).
- **Éclair en chaîne** (toute arme qui électrocute) : `Vfx.lightning` joue la feuille `storm_arc` étirée entre les deux ennemis ; au-delà de `BUSY_COUNT` effets à l'écran, repli sur l'éclair dessiné par code (peu coûteux).
- **Météore** : `StrikeBehavior.fall_sheet` (un rocher enflammé qui tombe, mode `FALL`, `EffectSheet.head` = position de la tête du rocher dans l'image) puis `impact_sheet` (impact de roche en fusion, unique, ovale étiré à `squash` 1,35 pour couvrir le cercle de dégâts). **Les dégâts tombent à l'impact**, plus au tir (règle : ce qui est dessiné blesse quand il touche) ; les météores d'une salve partent 0,1 s l'un après l'autre.
- Bake : `SOLID` (pixels sombres opaques pour la roche) ; après un nouveau bake lancer `Godot --headless --path . --import`.
