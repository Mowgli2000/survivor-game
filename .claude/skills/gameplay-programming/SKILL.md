---
name: gameplay-programming
description: Programmation du gameplay de run - player, ennemis, armes, projectiles, dégâts, statistiques, XP, level-up, pickups, spawn, items et leurs effets. À utiliser pour toute logique de combat ou de progression pendant une run.
---

# gameplay-programming

## Objectif
Implémenter le combat et la progression de run de façon data-driven, testable et performante.

## Quand l'utiliser
Player, ennemis, armes, projectiles, dégâts, statuts, XP, level-up, pickups, spawn/vagues, items, boutique (logique), boss.

## Architecture à respecter
- `run.gd` crée les systèmes et les branche (`setup(...)`). Les systèmes ne se cherchent pas entre eux.
- `RunState` (RefCounted) : temps, niveau, XP, monnaie, inventaire, `RandomNumberGenerator` seedé de la run.
- `EnemyManager`, `ProjectileManager`, `PickupManager` : tableaux d'entités actives + une seule boucle `_physics_process`. Les entités elles-mêmes sont des `Node2D` « passifs » (visuel + données), sans `_process`.
- `SpatialGrid` (src/core) : reconstruite chaque frame par EnemyManager ; requêtes `query_radius`, `nearest`.
- `ObjectPool` pour toute entité créée en masse.
- Stats : `StatBlock` (base + modificateurs plats et %, valeur finale en cache, signal `changed`). IDs de stats dans `stat_ids.gd`. Formule : `(base + somme_plats) * (1 + somme_pourcentages)`, puis bornes par stat.
- Dégâts : `CombatMath` (fonctions statiques pures). Pipeline : dégâts de base de l'arme × stats du porteur → critique → armure/résistance de la cible → application → knockback → feedback (signal).
- Armes : `WeaponData` (stats) + `behavior: WeaponBehavior` (Resource strategy : ProjectileShooter, Orbit, Aura, MeleeArc…). Visée **100 % automatique** : le behavior choisit sa cible (plus proche, aléatoire, direction du mouvement…), recalculée au moment du tir seulement.
- Level-up : `Progression` empile des level-ups en attente ; l'UI les consomme un par un (permet level-up immédiat ou différé à la boutique).
- Items (Phase 3) : `ItemData` = liste de `StatModifier` + liste d'`ItemEffect` déclenchés sur hooks (`on_hit`, `on_kill`, `on_wave_start`, `on_damage_taken`…). Tags pour les synergies.

## Règles
1. Ajouter du contenu = d'abord un `.tres` avec un behavior existant. Nouveau script seulement si le comportement est réellement nouveau.
2. Aucune valeur d'équilibrage en dur dans le code : tout dans les `.tres` (ou constantes nommées documentées si purement technique).
3. Toute aléa passe par le RNG de `RunState` (reproductibilité, tests, défis seedés).
4. Toute nouvelle stat : `stat_ids.gd` + clé de localisation `STAT_<NOM>` + test.
5. Jamais de logique gameplay dans l'UI ; l'UI appelle des méthodes publiques (`progression.choose_upgrade(i)`, `shop.buy(slot)`).
6. Les entités poolées doivent être entièrement réinitialisées à la réutilisation (`reset(data)`), sans état résiduel.
7. Signaux de gameplay pour le feedback (`enemy_hit`, `enemy_killed`, `player_damaged`) ; l'audio/VFX/UI s'y abonnent.

## Connaissances spécifiques
- Archétypes ennemis : chaser, rapide/fragile, tank, tireur à distance (garde une distance), chargeur (télégraphie puis fonce), splitter, élite (data + modificateurs), boss (phases data-driven).
- Séparation ennemis : force de répulsion entre voisins proches via la grille, plafonnée.
- Invincibilité du joueur après un coup (i-frames) ; dégâts de contact appliqués par EnemyManager.
- Fusion des gemmes d'XP au-delà d'un seuil pour limiter le nombre de pickups.

## Contraintes
- Respecter les règles du skill `performance` dans toutes les boucles de managers.
- Logique calculatoire (dégâts, stats, prix, tirages) = code pur testé.

## Interactions
- `game-design` fournit les valeurs et règles ; `performance` valide les boucles chaudes ; `testing` couvre CombatMath/StatBlock/Progression ; `ui-ux` consomme les signaux.
