# ADR 0025 — Sélection coop partagée et sceaux au sol

**Date :** 2026-10-09 · **Statut :** appliqué sur la branche `visual/ui-refonte`, à valider par le dev avant fusion dans `develop` · **Remplace** la partie « sélection des persos en coop » de l'ADR 0022

## Contexte
La sélection coop affichait deux `CharacterSelect` compactes côte à côte, chacune dans un `SubViewport` (une moitié d'écran par joueur, cadres bleus, une liste de persos par moitié). Le dev veut le même rendu que le solo : un seul écran, pas de cadres, deux sceaux runiques de couleurs différentes sur le sol d'un fond peint, les héros debout dessus, une seule barre de classes. En solo, le sceau était peint dans le fond : impossible de le déplacer, le redimensionner ou le faire briller proprement.

## Décision
- **`CoopCharacterSelect` réécrit** : un seul écran (fond `hall_coop.png`), deux sceaux (cyan à gauche, ambre à droite), un héros par sceau, une plaque d'info par joueur (classe, règle, bonus, stats, deux armes), une barre unique de têtes en bas. Chaque joueur a son curseur (sa couleur sur la tête ; deux contours si les deux sont sur la même classe). Les deux peuvent prendre la même classe.
- **Pas de focus Godot** (un seul par fenêtre) : l'écran lit lui-même les appareils (`PlayerInput.owns_event`) et les traduit en actions (`press(player, action)` : `ui_left/right/up/down`, `ui_accept`, `cancel`, `switch_variant`). Le stick gauche fait un pas par poussée (même règle que `CoopScreens`). La souris est le pointeur du joueur 1.
- Étapes par joueur : liste -> arme -> prêt ; le sceau du joueur s'allume quand il est prêt. Quand les deux sont prêts, l'écran de sceaux partagé (`SealSelect`) s'ouvre, inchangé.
- **`SealGlow`** (`src/ui/common/`) : sceau au sol en deux couches IA alignées pixel à pixel (sceau éteint + version « activée », mêlée en additif), `set_lit` fait monter/descendre la lumière (respire un peu tant qu'allumé ; sans animation si `reduce_motion`). Couleurs `cyan` et `amber` (l'ambre est un décalage de teinte du cyan, même forme). Assets `assets/ui/select/seal_{base,glow}_{cyan,amber}.png`, bords fondus.
- **Solo** : fond `hall_empty.png` (la salle de la guilde sans sceau peint) + `SealGlow` cyan sous le héros ; le sceau s'allume quand le pointeur (souris ou manette) est sur « Suivant ». Le hotspot `UiHotspots.Kind.SEAL` n'est plus utilisé par le solo.
- **Fonds** : générés avec Image 2.5 (`gpt-image-2.5-sunburst`), en référence de style le fond solo. Le fond coop a la moitié gauche en lumière bleue et la droite en ambre.
- Couleurs des joueurs : cyan `#4fc3ff` et ambre `#ffb030`, **une seule source** `RunPlayer.COLORS`, utilisée par toutes les interfaces et en partie (le rose est supprimé).
- Mise en page (retours du dev) : barre de classes en haut de l'écran, têtes de 102 px ; fond coop dézoomé pour laisser un grand sol aux sceaux ; flèches et points d'apparence par joueur (la manette garde Y) ; plus de titre, les plaques disent « Joueur N ».

## Conséquences
- `CoopScreens` ne sert plus qu'aux écrans entre vagues (level-up, boutique).
- Reste à nettoyer (dette) : le mode compact de `CharacterSelect` (`_compact`, `split_index`, `picked/unpicked`, `is_ready`) n'est plus utilisé par le jeu, seulement par un test.
- Ajouter un décor de sélection : un fond avec un sol vide dans la moitié basse ; la position des sceaux est dans `SEAL_X`, `SEAL_Y`, `SEAL_WIDTH`.
- **Décors** (`SelectBackdrops`, `src/ui/common/`) : la salle de la guilde par défaut + un fond par danger (`danger_0..5.png`), débloqué en finissant ce danger et lui seul (`Profile.won_dangers`) ; réglage `select_background` (`default`, `random`, `danger_N`) dans les Paramètres, commun au solo et à la coop. Idée en attente : fonds à acheter en éclats de portail.
- Le choix se fait aussi sur l'écran de sélection (`BackdropPicker`, en haut à droite ; en coop, haut / bas sur la barre). Zoom des fonds : solo 1,12, coop 1,06.
- Fonds : une seule salle de la guilde (`hall.png`, bleue) aux proportions des fonds de danger ; **deux séries d'images, montrées telles quelles (aucun zoom)** : coop (vue lointaine, grand sol) et solo (mêmes scènes de plus près, moins de sol). L'interface prend la couleur du fond : `UiTheme.get_theme(hue_shift)` tourne la teinte du bleu des cadres et boutons cuits (`SelectBackdrops.DANGER_HUES`, `SelectBackdrops.hue`).
- Les fonds sont affichés **en entier** (`UiBackdrop.fit_height`, à la hauteur de l'écran, côtés en miroir) : ni zoom ni rognage, le sol de chaque image garde ses proportions pour les sceaux.
