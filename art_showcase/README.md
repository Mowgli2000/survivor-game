# Character Art Direction — showcase

Exploration de la direction artistique du personnage principal (**Kage**, cyber-ninja néon). Ouvrir `index.html` dans un navigateur (double-clic : la page fonctionne en `file://`, sans serveur ni Internet).

## Ce qu'il y a dedans

| Section | Contenu |
|---|---|
| 00 Références | Analyse des 23 images de `references/` : éléments récurrents, identité retenue |
| 01 Style overview | 11 directions (A à K) : aperçu, notes (détail, lisibilité, personnalité, potentiel commercial, difficulté), avantages / inconvénients, honnêteté du rendu |
| 02 Comparison | Deux styles côte à côte, 8 directions, silhouette, 48 px, curseur A/B |
| 02b Animation | Idle, marche, attaque, coup reçu, mort ; 8 images ; pelure d'oignon (proportions constantes) |
| 03 Scale test | 32 / 48 / 64 / 96 / 128 px et taille réelle en jeu (≈ 102 px en 1080p) |
| 04 Silhouette test | Couleur, noir pur, fond clair, fond sombre |
| 05 Color test | 3 styles finalistes × 6 palettes |
| 05b Laboratoire | Proportions, carrure, tête, coiffure, yeux, masque, écharpe, cape, épaulière, détail, contours, contraste ; 6 variantes retenues |
| 06 Gameplay mockup | Scène 1920×1080 à l'échelle du jeu : sol, ennemis rendus dans le même style, tirs, VFX, chiffres de dégâts ; mode calme / chaos ; caméra coop |
| 07 Recommandation | Analyse argumentée et recommandation finale |

Barre d'outils : style A / B, palette, fond (sombre / sol du jeu / clair), grille, silhouette, zoom, plein écran.

## Honnêteté du rendu

Tout est **dessiné en vectoriel par code** (SVG). Aucune image n'est générée par IA ni peinte à la main.

- **Atteignables quasiment tels quels en jeu** : B Modern Cartoon, G Premium Indie, I Minimal, J Sumi-Neon, K Neon Line (même famille que le pipeline actuel du jeu, ADR 0016).
- **Maquettes de direction** (la version finale demanderait un illustrateur ou un pipeline 3D) : A Hand-Painted (texture de peinture simulée par filtres SVG), C anime haut de gamme, D low-poly (facettes automatiques), E 2.5D (relief par filtre d'éclairage), F look 3D (dégradés), H cinématique (contre-jour peint dans le sprite au lieu d'un shader).
- L'ennemi « imp » du mockup est un générique de démonstration, pas un ennemi du jeu.

## Fichiers

```text
art_showcase/
├── index.html            page de présentation
├── css/showcase.css
├── js/kage.js            squelette paramétrique + 11 moteurs de style (navigateur et Node)
├── js/app.js             construction de la page
├── tools/export_assets.js
├── assets/style_xx/      SVG exportés (générés, non versionnés)
│   ├── directions/       kage_S … kage_NW (8 directions ; W/SW/NW = miroirs)
│   ├── animations/       idle, walk, attack, hit, death
│   ├── palettes/         6 palettes
│   ├── kage_silhouette.svg, enemy_imp.svg, style.json
└── references/           images de référence (tierces, non versionnées)
```

Régénérer les SVG : `node art_showcase/tools/export_assets.js` (depuis la racine du dépôt).

## Remplacer un prototype par un vrai sprite

Chaque style est une entrée de `KAGE.STYLES` dans `js/kage.js` (id `style_01` … `style_11`). Pour montrer un vrai sprite à la place du rendu par code, déposer les images dans `assets/style_xx/` et remplacer, dans `js/app.js`, l'appel `charSvg(...)` du style concerné par une balise `<img>` vers ce fichier. Le squelette (proportions, 8 directions, poses) reste la référence de cadrage : boîte 200×260, pieds sur y = 236, hauteur du perso 196.

## Modifier le personnage

- Proportions et formes : `buildCharacter()` dans `js/kage.js` (tête, cheveux, queue de cheval, écharpe, hakama, bras, katana).
- Styles : tableau `STYLES` (contour, ombrage, lumière, textures, notes, avantages / inconvénients).
- Palettes : objet `PALETTES` (la structure ne change jamais, seules les couleurs).
