---
name: ui-ux
description: Interface et expérience joueur - HUD, menus, écran de level-up, boutique, pause, paramètres, game over/victoire, boss bar, feedback (hit flash, screen shake, nombres de dégâts), navigation clavier/manette, lisibilité et accessibilité. À utiliser pour tout Control/écran ou feedback visuel.
---

# ui-ux

## Objectif
Une interface claire et réactive, lisible même au milieu d'une horde, entièrement jouable à la manette.

## Quand l'utiliser
HUD, level-up, boutique, pause, paramètres, menus, écrans de fin, boss bar, tooltips, feedback de combat, glyphes d'input.

## Règles
1. **UI découplée** : elle lit l'état, écoute les signaux et appelle l'API publique des systèmes. Jamais d'état de jeu stocké dans l'UI.
2. **Navigation manette/clavier obligatoire** pour chaque écran : focus initial défini (`grab_focus()`), voisins de focus cohérents, `confirm`/`cancel` gérés. Souris en plus, jamais seule.
3. **Textes localisés** : clés dans `localization/strings.csv`, prévoir +30 % de longueur (allemand) ; pas de texte dans les images.
4. Un **Theme** global (`src/ui/theme/`) : polices, couleurs, styles. Pas de style local sauf exception.
5. Écrans affichés pendant la pause : `process_mode = PROCESS_MODE_ALWAYS`.
6. Lisibilité en combat : HUD aux bords, contours/ombres, contraste fort ; menaces (projectiles ennemis) visuellement distinctes des projectiles du joueur.
7. Accessibilité : options réduction screen shake / flash, taille du texte, daltonisme (ne pas coder une info uniquement par la couleur).
8. Feedback = juice mesuré : hit flash, knockback, nombres de dégâts poolés, son ; jamais au détriment de la lisibilité.

## Connaissances spécifiques
- Containers (VBox/HBox/Grid/Margin) + anchors ; référence 1920×1080, stretch `canvas_items`/`expand` ; tester 16:9, 16:10 (Steam Deck 1280×800), 21:9.
- Level-up : 3-4 cartes, nom + description + rareté + icône, choix par focus, petite protection anti-clic accidentel (délai court à l'ouverture).
- Boutique : prix, rareté, tags/synergies visibles, comparaison avec l'équipement actuel, reroll/lock/vente clairs.
- Glyphes d'input : afficher l'icône clavier ou manette selon le dernier périphérique utilisé.
- Nombres de dégâts : pool + agrégation si trop nombreux.

## Contraintes
- Pas de logique d'équilibrage dans l'UI.
- Pas de nœud UI créé/détruit chaque frame.

## Interactions
`game-design` définit quoi montrer ; `gameplay-programming` expose signaux et API ; `performance` valide feedbacks massifs ; `testing` vérifie la présence des clés de traduction.
