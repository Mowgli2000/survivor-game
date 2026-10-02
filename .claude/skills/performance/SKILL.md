---
name: performance
description: Performance du jeu - profiling, object pooling, grandes quantités d'ennemis/projectiles/pickups, grille spatiale, allocations, rendu 2D, particules. À utiliser pour tout code exécuté chaque frame dans un manager, avant/après un ajout massif de contenu, ou face à un ralentissement.
---

# performance

## Objectif
60 FPS stables avec 500+ ennemis et 1000+ projectiles sur un PC milieu de gamme, sans sacrifier la lisibilité du code.

## Quand l'utiliser
- Code dans `EnemyManager`, `ProjectileManager`, `PickupManager`, `SpatialGrid`, ciblage, VFX, nombres de dégâts.
- Ajout d'un comportement qui multiplie les entités (split, explosions, projectiles multiples).
- Symptôme : chute de FPS, saccades (souvent allocations/GC ou spawns massifs).

## Règles
1. **Mesurer d'abord** : profiler Godot (Debugger > Profiler / Monitors), scène `src/debug/stress_test.tscn`, overlay (FPS, entités, temps de frame). Donner des chiffres avant/après.
2. **Une boucle par type d'entité** dans son manager. Pas de `_process`/`_physics_process` par ennemi/projectile/pickup.
3. **Pas de physique pour les hits de masse** : cercles vs cercles via `SpatialGrid`. Le joueur seul est un CharacterBody2D.
4. **Pooling** pour tout objet créé plus de quelques fois par seconde : ennemis, projectiles, pickups, nombres de dégâts, VFX courts. Masquer + désactiver plutôt que `queue_free`.
5. **Zéro allocation dans les boucles chaudes** : réutiliser des tableaux tampons, éviter de créer des `Array`/`Dictionary`/lambdas/strings par frame, éviter les `RefCounted` par hit.
6. Ciblage recalculé au moment du tir, pas chaque frame. Requêtes spatiales limitées au rayon utile.
7. Pas de `get_nodes_in_group`, `find_child`, `get_node` avec chemin dynamique dans une boucle.
8. Plafonds : nombre max d'ennemis actifs, de projectiles, de sons simultanés par type, de nombres de dégâts.
9. Ne pas optimiser hors systèmes critiques sans mesure ; garder un code lisible.

## Connaissances spécifiques
- Coût d'un node : chaque node actif avec process coûte ; un Sprite2D sans script est bon marché.
- `SpatialGrid` : taille de cellule ≈ 2× le rayon typique ; reconstruction par frame O(n) acceptable.
- Rendu : 2D batching du renderer Compatibility ; partager textures/atlas et matériaux ; `MultiMeshInstance2D` si des milliers de sprites identiques (plan B mesuré).
- Particules : `CPUParticles2D` en Compatibility ; préférer peu de particules bien choisies.
- GDScript : accès aux propriétés typées plus rapides ; `PackedVector2Array`/`PackedFloat32Array` pour des données en masse ; éviter les appels virtuels inutiles dans les boucles.
- Spikes : spawns groupés → étaler sur plusieurs frames ; pré-remplir les pools au chargement de la run.
- Plan de repli si GDScript ne suffit pas : MultiMesh → données en tableaux packés (SoA) → GDExtension/C# pour un seul hot-path.

## Contraintes
Toute optimisation non triviale doit être justifiée par une mesure et notée (commentaire ou ADR).

## Interactions
Relit le code de `gameplay-programming` touchant les boucles ; fournit à `testing` un stress test reproductible (seed fixe) ; conseille `ui-ux` (nombres de dégâts, VFX).
