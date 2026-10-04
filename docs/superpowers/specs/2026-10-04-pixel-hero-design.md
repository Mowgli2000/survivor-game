# Héros ninja en pixel art (64 px) — design

> **Abandonné le 2026-10-04** : le dev ne veut pas de pixel art mais un rendu cartoon manga lisse. Remplacé par `tools/art/hayate.py` (vectoriel dessiné à la main, découpe animée). Outil pixel mis de côté.

Date : 2026-10-04 · Choix du dev : pixel art cartoon inspiré anime, 64 px de haut, 3,5-4 têtes, contour noir + cel-shading 3 tons, idle 4 frames + marche 6 frames, vue 3/4 face + miroir, un seul perso d'abord (nouveau héros ninja), puis déclinaison après validation.

## Objectif
Un perso joueur plus détaillé que les sprites vectoriels actuels (ADR 0016), dans l'esprit du chibi test : un vrai pixel art net, lisible en foule, animé (pas seulement des sauts).

## Le personnage
Ninja chibi : cheveux noirs en pointes, **bandeau rouge à longs pans flottants**, yeux néon cyan, épaulière métal sur l'épaule avant, gi sombre à manches courtes, avant-bras bandés, ceinture rouge nouée, **katana au fourreau à la hanche** (signature ; les vraies armes flottent toujours autour, ADR 0010), hakama bleu nuit évasé, tabi. Palette fixe ≈ 20 couleurs : sombres + rouge + touche cyan. Lumière en haut à gauche.

## Méthode de production
- Script Python `tools/pixel/hero_pixel.py` (sans dépendance : PNG écrit avec `zlib`) qui dessine **au pixel près** : chaque partie (cheveux, tête, bandeau, torse, bras, jambes, pans) est tracée avec des primitives entières (polygones, ellipses, lignes), puis
  - chaque partie reçoit son **contour noir de 1 px** ; une partie posée devant une autre trace ainsi le trait intérieur qui les sépare ;
  - **cel-shading automatique en 3 tons** par partie (bande d'ombre côté opposé à la lumière, liseré clair côté lumière), donc cohérent sur toutes les frames ;
  - les détails fins (yeux, mèches, plis, bandages, rivets) sont **posés à la main** en petits motifs de pixels.
- Écart assumé avec « grilles entièrement écrites à la main » : les grandes formes sont tracées par primitives (elles doivent bouger d'une frame à l'autre sans changer de taille), les petits détails sont dessinés pixel par pixel.
- Sorties : `assets_src/pixel/hero/idle_0..3.png`, `walk_0..5.png` et une planche d'aperçu ×4 (`assets_src/pixel/hero/preview.png`).

## Animation
- Idle (4 frames, 6 i/s) : respiration (torse et tête 1 px), pans du bandeau et de la ceinture qui ondulent.
- Marche (6 frames, 10 i/s) : jambes du hakama dessinées par frame, bras en balancier, rebond de 1 px, pans qui flottent vers l'arrière.
- Proportions identiques sur toutes les frames (mêmes formes, seules positions et angles bougent).

## Intégration au jeu
- `tools/sprites/sprites.json` : entrée `"hero"` avec `"src"` et une option **`"pixel": true`** → le baker recadre sans lisser et agrandit **×2 au plus proche voisin** (128 px de cellule), sans halo flou (un halo pixel à 1 px reste possible plus tard).
- Affichage net : `Player` (seulement lui) passe en `texture_filter = NEAREST` quand sa feuille est en pixel art ; sa hauteur à l'écran devient 128 px (×2 exact, perso un peu plus grand qu'aujourd'hui).
- Nouveau perso `data/characters/hero.tres` (id stable `hero`), textes en + fr ; perso de test `ai_test` retiré.

## Validation
Planche ×4 + capture en jeu (`capture.tscn --character=hero`) avec des ennemis ; tests GUT existants ; le dev juge avant toute déclinaison (autres persos, ennemis, boss).

## Hors périmètre
Autres persos, ennemis, boss, vues de dos/profil, animation d'attaque.
