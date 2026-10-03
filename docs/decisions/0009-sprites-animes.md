# ADR 0009 — Sprites animés : atlas précalculé, animation pilotée par les managers

**Statut :** accepté (2026-10-03) — chantier visuel 1/3, spec `docs/superpowers/specs/2026-10-03-sprites-animes-design.md`
**Complète :** ADR 0005 (la texture néon précalculée par type d'ennemi devient une planche animée dans un atlas commun)

## Contexte
Le joueur et les ennemis étaient des formes néon provisoires. On passe à des personnages chibi animés (pack CC0 RGS_Dev, D31) sans casser l'objectif de 500+ ennemis à l'écran ni l'architecture « entités en lot » (ADR 0002).

## Décisions
1. **Outil de conversion** `tools/bake_sprites.ps1` (script Godot headless, recette `tools/sprites/sprites.json`) : recadrage sur l'union des images d'une animation, réduction à 128 px de haut, halo néon (silhouette floutée) de la couleur de menace, variante `<id>_elite` à halo doré. Toutes les planches sont empilées dans **un seul atlas** `assets/sprites/atlas.png` ; une ressource `SpriteSheet` (`.tres`) par planche donne son origine, la taille de case et les animations. Le pack brut reste dans `assets_src/` (hors git). L'outil est déterministe.
2. **Métadonnées en `.tres`, pas en `.json`** : l'export n'embarque pas les `.json`, et le contenu du projet est en Resources.
3. **`SpriteSheet` + `SpriteAnimator`** (`src/core/`, code pur testé) : image courante selon l'animation et le temps, retournement horizontal (rectangle de largeur négative, sans `draw_set_transform`). Une animation absente retombe sur `walk`.
4. **Ennemis** : `EnemyData.sprite_id` / `sprite_tint` / `sprite_scale`. `EnemyManager` avance l'animation dans sa boucle (pas de `_process` par ennemi) et n'appelle `queue_redraw()` que quand l'image ou l'orientation change. Départ d'animation aléatoire pour désynchroniser la horde. Sans `sprite_id`, repli sur le rendu `EnemyArt`. Le sprite habille le cercle de collision : gameplay inchangé.
5. **Joueur** : même mécanique (`CharacterData.sprite_id`), dessiné dans `Player._draw()`.
6. **Profondeur** : conteneur `Actors` (`y_sort_enabled`) qui regroupe `EnemyManager` (aussi trié) et `Player`.
7. **Sol** : texture du pack répétée, teintée bleu-violet moyen (demande du dev : pas de jeu trop sombre).

## Mesures (stress test : 500 ennemis, ~1000 projectiles, 6 armes rang IV, alterné 3 × 15 s avec la version précédente sur la même machine)
| Version | FPS moyen | FPS min |
|---|---|---|
| Avant (formes néon) | 176 | 118-132 |
| **Sprites animés + y-sort + atlas** | **163** | 103-134 |

Coût ≈ 7 % : le FPS reste au-dessus du seuil fixé (≥ 150 FPS moyen). Les mesures isolées varient de ±15 FPS d'une exécution à l'autre : comparer en alterné. Répartition estimée : redessins au changement d'image ≈ 10 FPS, y-sort ≈ 5 FPS. Le nombre d'appels de dessin (~730, nouvelle ligne du stress test) ne change pas. Si la marge devient insuffisante : un MultiMesh par type d'ennemi (comme ADR 0004).

## Conséquences
- Ajouter ou changer un sprite = ligne dans la recette + `tools/bake_sprites.ps1` + `sprite_id` dans la donnée. Aucun code.
- Un seul atlas pour tous les sprites : une seule texture à charger, et pas de changement de texture entre ennemis voisins au rendu (gain non mesurable aujourd'hui, mais aucun coût).
- `src/debug/vfx_gallery.tscn` montre chaque ennemi animé, brûlé et en élite.
