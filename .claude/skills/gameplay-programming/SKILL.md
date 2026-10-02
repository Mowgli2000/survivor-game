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
- Armes : `WeaponData` (niveau 1) + `levels: Array[WeaponLevel]` (ce que chaque niveau ajoute) + `behavior: WeaponBehavior`. `WeaponSlot` (arme possédée : niveau, cooldown) calcule `WeaponStats` (valeurs effectives) ; `WeaponHolder` déclenche `behavior.fire(slot, ctx)`. Les stats du joueur (DAMAGE, AREA, RANGE…) s'appliquent dans le behavior via `WeaponContext` (`roll_crit`, `hit_damage`). Visée **100 % automatique**, cible recalculée au moment du tir seulement.
- Behaviors existants : `ProjectileShooterBehavior` (options de projectile : pierce, `bounces` ricochet, `explosion_radius`, `inaccuracy_deg`), `MeleeArcBehavior` (arc = `area` + `arc_degrees`), `BeamBehavior` (rayon de largeur `area`). Une nouvelle arme réutilise d'abord ceux-ci.
- **Dégâts : toujours via l'API d'`EnemyManager`** — `damage_enemy`, `damage_in_radius` (cercle ou arc), `damage_along_segment`. Jamais modifier `enemy.hp` ailleurs. Statuts (`StatusData` : BURN, SLOW, SHOCK) passés en paramètre avec leur probabilité.
- Ennemis : `EnemyData.movement` = CHASE ou RANGED (garde ses distances, tire via `EnemyProjectileManager`). Nouveau type d'ennemi = un `.tres` + entrée dans le `spawn_pool` d'un `RunConfig`.
- Feedback : `Vfx` (slash, beam, explosion, hit, lightning), `DamageNumbers` (via le signal `enemy_damaged`), `GameCamera.add_trauma()`.
- Level-up : `Progression` empile des level-ups en attente ; `roll_offers` mélange améliorations de stats, nouvelles armes (si emplacement libre) et niveaux d'armes (`UpgradeOffer`). L'UI les consomme un par un.
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
