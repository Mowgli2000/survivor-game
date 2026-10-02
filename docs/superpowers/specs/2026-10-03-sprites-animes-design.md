# Sprites animés — joueur et ennemis (chantier visuel 1/3)

**Date :** 2026-10-03 · **Statut :** validé en discussion, à relire par le dev
**Décision liée :** D31 (chibi façon Dofus × néon, assets gratuits, vue de dessus)

## 1. Objectif

Remplacer les formes néon provisoires (cercles, polygones) du joueur et des ennemis par des personnages chibi animés, pour avoir enfin un visuel de jeu. L'attribution des sprites et leur design sont **provisoires** : le but est un pipeline qui permet de changer de sprite sans toucher au code.

Critères de réussite :
- Joueur et 5 types d'ennemis (grunt, runner, shooter, tank, shogun) affichés avec des sprites animés (idle / marche), orientés selon leur déplacement.
- Rendu **coloré**, pas sombre (demande du dev) : personnages en couleur + halo néon, sol dans un ton moyen.
- Performance : au moins **150 FPS moyen** au stress test (≈ 180 aujourd'hui).
- Le dev valide une capture d'une horde.

Hors périmètre : icônes d'armes et d'objets, armes visibles autour du joueur (chantier 2), thème des interfaces (chantier 3), vrai boss (Phase 6), animations de mort / coup reçu du pack.

## 2. Source : pack RGS_Dev

`assets_src/third_party/rgs_characters/Free 2D Animated Vector Game Character Sprites/` (CC0, ignoré par git). Images 2048×2048, personnage ≈ 500 px en bas au centre, déjà colorées avec un gros contour noir. Variante « no hands » des personnages, adaptée aux armes flottantes façon Brotato (chantier 2).

| Sprite | Source | Animations utilisées | Halo néon |
|---|---|---|---|
| `player` | `Char 1/no hands` | idle 6, walk 8 | cyan (couleur actuelle du joueur) |
| `grunt` | `Enemies/Enemy 1` (diable violet) | idle 6, walk 8 | `color` actuelle du grunt |
| `runner` | `Enemies/Enemy 3` (chauve-souris) | walk = fly 6 | `color` du runner |
| `shooter` | `Enemies/Enemy 2` (ogre vert) | idle 6, walk 8 | `color` du shooter |
| `tank` | `Enemies/Enemy 4` (diable rouge) | idle 6, walk 8 | `color` du tank |
| `shogun` | réutilise la planche `tank` | — | teinte magenta au rendu |

## 3. Outil de conversion

- `tools/sprites/bake_sprites.gd` : script Godot exécuté en headless, lancé par `tools/bake_sprites.ps1`. Pas de Python ni d'outil externe.
- Recette : `tools/sprites/sprites.json`. Par sprite : dossier source (relatif au pack), animations (`nom: nombre d'images`, ou `nom: "nom_source:nombre"` pour renommer, ex. `walk: "fly:6"`), images/seconde, couleur du halo.
- Traitement par sprite :
  1. charger les images listées ;
  2. recadrer sur l'**union** des zones non transparentes de toutes les images (pas de saut d'une image à l'autre) ;
  3. réduire à ≈ 128 px de haut (filtrage de qualité) ;
  4. ajouter un halo néon ≈ 4 px autour de la silhouette (le contour noir du pack reste dessous) ;
  5. assembler une planche horizontale.
- Sortie, commitée :
  - `assets/sprites/<id>.png` : planche ;
  - `assets/sprites/<id>.json` : taille d'une case, point de pied (pour aligner le sprite sur le cercle de collision), et par animation : image de départ, nombre d'images, images/seconde.
- Erreurs : le script échoue avec un message clair si un dossier, une image ou une animation listée manque. Deux exécutions donnent les mêmes fichiers.

## 4. Rendu en jeu

### SpriteSheet (nouveau, `src/core/sprite_sheet.gd`)
Petite classe de données : charge une planche + son JSON, donne la région (`Rect2`) d'une image pour une animation et un temps donnés (bouclage), la taille de case et le point de pied. Code pur, testable.

### Ennemis
- Approche retenue : **A** (une planche par type, chaque `Enemy` dessine la case de son image courante). Repli si la performance ne tient pas : **B** (un MultiMesh par type, comme ADR 0004).
- `EnemyData` reçoit `sprite_id: StringName` (charge `assets/sprites/<id>.png` + `.json`) et `sprite_tint: Color` (blanc par défaut ; magenta pour le Shogun, qui a `sprite_id = &"tank"`). `sprite_id` vide : l'ennemi garde le rendu néon actuel d'`EnemyArt` (repli, aucun plantage).
- `EnemyManager` avance l'animation dans sa boucle existante (pas de `_process` par ennemi) et n'appelle `queue_redraw()` que quand l'image change (≈ 8 fois/s).
- walk si l'ennemi se déplace, idle sinon (tireur qui vise). Décalage de départ aléatoire par ennemi pour éviter que toute la horde marche au même pas.
- Orientation : retournement horizontal selon le signe de la vitesse horizontale (comme Brotato).
- Flash de coup et statuts : `self_modulate`, inchangé.
- **Élite** : même planche ×1,6 ; liseré doré obtenu en dessinant d'abord la silhouette teintée or légèrement agrandie, puis le sprite par-dessus.
- **Shogun** : planche `tank`, agrandie, teintée magenta.
- La taille d'affichage suit le rayon de collision existant (le sprite habille le cercle). Collisions, rayons et gameplay inchangés.

### Joueur
`AnimatedSprite2D` enfant de `Player` (planche `player`), remplace le `_draw()` actuel. idle / walk selon la vitesse, retournement selon la direction.

### Profondeur
Nouveau conteneur `Actors` (`y_sort_enabled`) dans `run.gd`, qui contient `EnemyManager` (lui aussi `y_sort_enabled`) et `Player` : le personnage le plus bas à l'écran passe devant. Le reste de l'ordre d'affichage (sol, pickups, projectiles, VFX, chiffres) ne change pas. Si le tri coûte trop au stress test, on le retire.

### Sol
`Arena` : texture `ground_white.png` du pack répétée sur l'arène, teintée dans un ton moyen (bleu-violet doux, pas sombre), grille néon légère et bordure lumineuse existante par-dessus. La texture est copiée dans `assets/sprites/` par l'outil.

## 5. Tests et validation

- **GUT** :
  - `SpriteSheet` : lecture du JSON, région d'une image (animation + temps), bouclage ;
  - données : chaque `EnemyData` qui a un sprite pointe vers une planche existante qui contient `walk` ; la planche joueur contient `idle` et `walk` ;
  - ennemi sans sprite : rendu de repli, pas d'erreur ;
  - les 153 tests existants passent.
- **Performance** : stress test avant/après ; seuil 150 FPS moyen. En dessous : mesurer d'abord le coût du `y_sort`, puis des redessins ; si insuffisant, approche B.
- **Visuel** : capture d'une horde (`capture.tscn -- --stress`) et galerie `vfx_gallery.tscn` mise à jour (tous les ennemis animés, élite, Shogun), montrées au dev avant de clore.

## 6. Documentation

- ADR 0009 « Sprites animés » (complète ADR 0005 : la texture précalculée par type devient une planche par type ; chiffres du stress test).
- `assets/CREDITS.md` : pack RGS_Dev (CC0).
- `PROJECT_STATUS.md` : décision, changements, prochaines étapes.
