---
name: game-design
description: Game design du survivor-like - boucle de jeu, économie et boutique, progression, difficulté, synergies, équilibrage, récompenses, rejouabilité, méta-progression. À utiliser pour proposer ou évaluer une mécanique, des valeurs, du contenu ou une courbe.
---

# game-design

## Objectif
Aider à concevoir un survivor-like avec une identité propre, centré sur une boutique qui compte vraiment, et à l'équilibrer avec des chiffres.

## Quand l'utiliser
- Nouvelle mécanique, nouveau contenu (arme, item, ennemi, perso, boss).
- Valeurs : stats, prix, courbes d'XP, scaling de difficulté, raretés.
- Décisions de boutique, d'économie, de méta-progression.
- Analyse d'un retour de playtest.

## Décisions déjà prises
- Arène bornée, vagues chronométrées, boutique entre les vagues.
- Attaque 100 % automatique : la profondeur vient du positionnement, du build et de l'économie.
- Ne pas copier Brotato / Vampire Survivors : s'en servir comme références, pas comme modèles.

## Règles
1. **Le dev décide.** Toujours présenter 2-3 options avec avantages/inconvénients/coût de production, puis une recommandation.
2. **Chiffrer** : DPS, temps-pour-tuer, PV effectifs, or gagné/vague, coût moyen d'un build, nombre de choix par minute.
3. Toute valeur vit dans un `.tres` ; documenter les intentions dans `docs/design/`.
4. Chaque mécanique doit servir au moins un pilier : décisions fréquentes, sensation de puissance, synergies, risque/récompense, rejouabilité.
5. Penser lisibilité : une mécanique invisible à l'écran n'existe pas pour le joueur.
6. Pas de code : déléguer l'implémentation à `gameplay-programming`.

## Connaissances spécifiques
- Courbe d'XP : `xp_requis(n) = a * n^b` (b ≈ 1.2-1.5) ; cible : un level-up toutes les 20-40 s en début de run.
- Scaling : densité ↑ avant PV ↑ (plus satisfaisant) ; élites comme « pics » de difficulté ; boss comme examen du build.
- Boutique : stock pondéré par rareté et par vague, reroll à coût croissant, verrouillage, vente partielle. Pistes différenciantes à prototyper (Phase 5) : intérêts sur l'or non dépensé (épargner vs dépenser), stock influencé par ce qu'on a tué (tags), marchand pendant la vague (risque).
- Synergies : par tags (élément, type d'arme, style) avec seuils (2/4/6) — lisibles et faciles à produire.
- Méta-progression (Phase 7, non décidée) : déblocages de contenu (élargit les builds) vs bonus de stats permanents (facilite) — préférer élargir que faciliter.
- Anti-patterns : choix évidents (un item toujours meilleur), builds solveurs uniques, fausse variété (+5 % partout).

## Contraintes
- Production réaliste pour un petit studio utilisant l'IA : préférer des mécaniques qui démultiplient le contenu existant (modificateurs, tags) plutôt que du contenu unique coûteux.

## Interactions
Fournit les specs à `gameplay-programming` et `ui-ux` ; demande à `testing` des simulations headless pour vérifier l'équilibrage ; consulte `performance` si une mécanique multiplie les entités.
