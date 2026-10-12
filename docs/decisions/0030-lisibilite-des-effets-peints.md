# 0030 — Lisibilité des effets d'attaque peints

Date : 2026-10-12 · Statut : accepté (demande du dev dans `notes.md` : trop d'animations couvrent l'écran quand plus de 100 monstres sont affichés)

## Contexte
Le brief du dev suppose des scènes d'attaque avec `AnimationPlayer`, `YSort` et `queue_free()`. Le projet n'a **aucune scène d'effet** : tous les effets sont dessinés par un seul nœud, `Vfx` (ADR 0004, 0010, 0026), à partir de ressources `EffectSheet` (`data/vfx/*.tres`) ; les projectiles sont un MultiMesh. Il n'y a donc ni nœud à détruire, ni `speed_scale`, ni script d'éditeur à écrire. Déjà en place avant ce changement : couche additive pour les lueurs (`BLEND_MODE_ADD`), effets au sol sous les monstres (`GROUND_Z` -5), monstres et joueur dans un conteneur Y-sort, zone du héros dégagée (`GUARD_RADIUS`), mode « occupé » (> 40 effets : impacts sautés, durées raccourcies).

## Décision (les exigences du dev, traduites dans cette architecture)
- **Opacité** (`Vfx`) : coups, impacts et explosions peints à `PAINTED_OPACITY` 0,55 ; zones au sol à `GROUND_OPACITY` 0,45 ; au-delà de 12 effets vivants la couche peinte s'éclaircit jusqu'à -25 % (`CROWD_*`). Les lueurs restent additives. Les explosions peintes restent en mélange normal : le mode additif ferait disparaître leurs parties sombres (fumée, braises).
- **Ordre d'affichage** : sol -5 < monstres 0 (Y-sort) < projectiles et effets 1-5 < **joueur `Player.RENDER_Z` 10** (toujours devant les monstres et les effets) < nombres de dégâts 20.
- **Durées** : toute animation de coup, d'impact et de faisceau dure au plus 0,25 s ; explosions, météores, marteau, hache, faux et sceau runique au plus 0,3 s (`duration` des `.tres`, repris dans `tools/art/bake_vfx.py` pour qu'une recuisson ne les rétablisse pas). Les zones persistantes (flaque de feu, zone de givre, puits de gravité, carreau planté, effondrement du puits) gardent leurs durées : ce sont des durées de jeu.
- Pas de script d'éditeur ni de classe de base : une nouvelle attaque = un `EffectSheet` `.tres` ; elle hérite des règles ci-dessus par `Vfx`.

## Conséquences
- Les effets sont plus discrets et plus vifs ; le moment des dégâts, lié à la durée de l'effet, arrive plus tôt (impact plus nerveux).
- Réglage central : 4 constantes de `Vfx` et les durées des `.tres`. À valider en jeu en fin de partie (> 100 monstres) et à ajuster.
- Le héros, au-dessus des effets, pourrait avoir une zone dégagée moins grande (`GUARD_RADIUS`) : à décider après essai.

## Révision (même jour, retour du dev après essai : « trop transparent, manque d'impact »)
Approche Brotato : opacité et brièveté plutôt que transparence.
- `PAINTED_OPACITY` 0,92 (au lieu de 0,55) ; plus d'éclaircissement en foule (constantes `CROWD_*` retirées). Zones au sol inchangées (0,45).
- Durées des coups, impacts, faisceaux et explosions : **0,15 s au plus** (zones persistantes inchangées). 12 images en 0,15 s = 80 images/s : ça se lit comme un éclair, pas comme une animation ; réglable dans les `.tres`.
- **Disparition** : visible à 100 % dès la première image, fondu seulement sur les `FADE_OUT` = 0,05 dernières secondes (`Vfx._draw_sheets`).
- **Corps des projectiles** (hors couche peinte, donc non concernés par l'opacité ci-dessus) : deux défauts de déformation corrigés dans le rendu en boucle. (1) La hauteur de la bande de la cellule changeait d'une image à l'autre (la boule de feu : 0,63 puis 0,76 aux images 9-12), d'où une pulsation à chaque cycle : une seule bande par boucle (`ProjectileRenderer._loop_band`). (2) L'ondulation de la traîne couvrait la moitié de la boucle du puits de gravité et de la bombe (plage de cellules trop large) : elle ne couvre plus que la boule de feu et l'éclair (`RIPPLE_FIRST/END`).
