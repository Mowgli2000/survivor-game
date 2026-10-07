# ADR 0022 — Moitiés d'écran coop : focus géré à la main, sélection des persos scindée

**Date :** 2026-10-08 · **Statut :** appliqué (corrige et étend l'ADR 0021)

## Contexte
Playtest à deux manettes des moitiés d'écran de l'ADR 0021 : impossible de choisir en même temps, puis de valider, sélection invisible dans une moitié, stick sans effet. L'ADR 0021 supposait qu'un `SubViewport` a son propre focus GUI : **c'est faux**. Godot garde **un seul focus par fenêtre** : prendre le focus dans une moitié l'enlève à l'autre sans prévenir. Le dev a aussi demandé que la sélection des persos se fasse en même temps, écran scindé.

## Décision
`CoopScreens` (`src/run/coop_screens.gd`) reste le seul système de moitiés d'écran et gère lui-même ce que Godot ne fait pas :
- **Mémoire du focus par moitié** : le dernier contrôle focalisé de chaque moitié est retenu et rendu à la moitié dont le joueur appuie (`_remember_focus`, `_restore_focus`, `remember_focus` pour le focus de départ). Un contrôle libéré entre-temps est ignoré (pas de variable typée sur une instance libérée).
- **« Accepter » appuie directement** sur le bouton focalisé (`pressed.emit()`) : un bouton annule son appui s'il perd le focus avant le relâchement, ce que l'autre moitié provoquait.
- **Stick gauche → un appui `ui_*` par poussée** (seuil 0,5) : un mouvement de stick poussé dans un `SubViewport` ne déplace pas le focus. Le bruit d'un stick au repos ne fait rien.
- **Cadre de sélection par moitié** (`FocusFrame`) à la couleur du joueur : la boîte de focus du contrôle lui-même, recolorée et sans remplissage. Elle recouvre exactement la boîte de focus de Godot dans la moitié qui l'a : un seul contour, de la bonne forme.
- Les conteneurs ne transmettent plus eux-mêmes clavier et manette (`set_process_input(false)`) : seul le routage par joueur (`PlayerInput.owns_event`) le fait ; la souris passe toujours par la moitié survolée.
- Les moitiés prennent chacune la moitié de la **largeur visible** (fenêtres plus larges que 16:9, `stretch/aspect = expand`).

**Sélection des persos en coop** : `CoopCharacterSelect` (menu principal) héberge dans `CoopScreens` deux `CharacterSelect` compactes (`CharacterSelect.new(true)`, `open(split_index)`). Chaque joueur choisit perso et arme ; le J1 choisit aussi le sceau et appuie sur « Jouer » sans attendre ; la partie part dès que les deux sont prêts, au sceau abaissé à ce que le perso du J2 a débloqué si besoin. L'ancienne sélection tour à tour est supprimée.

## Conséquences
- Tout nouvel écran coop passe par `CoopScreens.add_screen` (un `CanvasLayer`) et hérite de ces règles ; ne pas gérer le focus d'une moitié ailleurs.
- `CoopScreens` vit dans `src/run/` mais sert aussi au menu principal.
- Les écrans hébergés reçoivent leurs événements par `push_input` : `_input` / `_unhandled_input` y marchent (actions propres à un joueur : Share pour les stats, Carré pour fusionner, Triangle pour relancer).
- Tests : `tests/unit/test_coop_screens.gd`, `tests/unit/test_coop_character_select.gd`.
