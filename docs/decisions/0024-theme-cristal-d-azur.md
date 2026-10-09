# ADR 0024 — Thème d'interface « Cristal d'azur » (T3)

**Date :** 2026-10-09 · **Statut :** appliqué sur la branche `visual/ui-refonte`, à valider par le dev avant fusion dans `develop`

## Contexte
Le dev a choisi la maquette T3 (D97) pour refondre tout le visuel : bleu nuit, cyan, coins dorés, corail pour les alertes, polices à empattement, cadres biseautés à pointes de cristal. Contraintes : ne rien changer à la mécanique, aux statistiques ni aux personnages ; ornements faits par le code, fonds et icônes générés par IA.

## Décision
- **Cadres en 9-slice** : `tools/ui/make_frames.py` écrit des SVG (`assets_src/ui_frames/`), `tools/ui/bake_frames.gd` les convertit en PNG (`assets/ui/frames/`). Deux variantes des cadres de fenêtres, panneaux, cartes et cases : `x` (traits blancs, teintés par `modulate_color` selon le rang ou l'arme) et `x_cyan` (traits cyan déjà cuits ; les coins dorés restent dorés). `UiTheme.accent_frame` choisit.
- **`UiTheme` reconstruit** sur ces textures (`StyleBoxTexture`) avec la même API (`panel_style`, `card_style`, `window_style`, `focus_style`, `bar_styles`…). Nouveaux : `slot_style`, `frame_style`, `frame_tint`, `frame_texture`. Les écrans n'ont pas changé d'appels. Polices : Cinzel (titres, boutons) et Cinzel Decorative (gros titres), Nunito pour le texte (Bangers reste pour les chiffres de dégâts).
- **`UiBackdrop`** (`src/ui/common/`) : fond peint plein écran (cover), dérive lente, vignette, étincelles de cristal. Utilisé par le menu (couche -10), la boutique, la sélection, la progression, la boutique de skins, l'écran de fin (victoire/défaite). Fonds IA dans `assets/ui/backgrounds/`.
- **`WorldGrade`** : l'arène est teintée bleu nuit (`Arena.modulate`, persos et monstres gardent leurs couleurs) et une vignette est posée sous le HUD. Pas de calque multiplicatif plein écran (coût de remplissage).
- **Icônes** : 28 armes et 59 objets régénérés par IA à partir des anciennes images comme référence (même silhouette, même couleur, rendu plus riche), 17 icônes d'amélioration neuves (`UpgradeData.icon`, affichées sur les cartes de niveau supérieur). Recettes : `tools/ui/gen_icons.sh`, `gen_upgrades.sh`, `gen_bgs.sh` (fonds réalistes, remplacés) puis `gen_bgs_toon.sh` (fonds en dessin animé, retenus), `bake_icons.sh` (sorties dans `art_tests/ui_final/`, non versionné) (`make_icon.gd --cut=` retire les halos).
- **Effets** : couleur par arme inchangée ; éclats de cristal ajoutés aux explosions et petites poussières de cristal à la mort des monstres (couche additive, bornés quand l'écran est chargé).

## Conséquences
- Le menu perd la porte dessinée par le code (`MenuGate` supprimé) au profit du fond peint.
- Les icônes d'armes servent aussi d'armes flottantes en jeu : rendu un peu plus fin (à surveiller en playtest).
- `tools/icons/make_icons.py` (icônes SVG de dépannage) n'est plus la source des icônes.
- Ajouter un cadre : l'écrire dans `make_frames.py`, relancer `bake_frames.gd`, `--import`.
- Ajouter un écran : `theme = UiTheme.get_theme()` + `UiBackdrop.create(...)` ; aucun `StyleBoxFlat` à la main.
