---
name: testing
description: Tests et validation - tests unitaires GUT, validation des données .tres et des traductions, smoke tests headless, tests de sauvegarde et migrations, régressions, edge cases. À utiliser après chaque fonctionnalité, avant chaque commit, et à chaque ajout de contenu.
---

# testing

## Objectif
Garantir qu'une nouvelle fonctionnalité ne casse pas les anciennes, et que tout le contenu est valide.

## Quand l'utiliser
Après toute implémentation, avant tout commit, lors d'ajout de contenu, de changement de format de sauvegarde, ou d'un bug (écrire d'abord le test qui le reproduit).

## Outils
- Framework : **GUT 9.x** dans `addons/gut/`, config `.gutconfig.json` (dossier `res://tests/`, préfixe `test_`).
- `tools/run_tests.ps1` : import + toute la suite, code de sortie ≠ 0 en cas d'échec.
- `tools/check_scripts.ps1` : compile tous les scripts de `src/` et `tests/`.

## Organisation
- `tests/unit/` : code pur (StatBlock, CombatMath, SpatialGrid, ObjectPool, WeightedPicker, Progression, Shop, migrations de save, ContentDB).
- `tests/data/` : charge **tout** le contenu via ContentDB et vérifie : IDs uniques et non vides, références valides (arme → behavior, ennemi → drops…), valeurs dans les bornes (PV > 0, cadence > 0…), clés de traduction présentes en en + fr.
- `tests/smoke/` : instancie la scène de run headless avec seed fixe et input simulé, avance N secondes, vérifie : aucune erreur, entités créées et détruites, level-up déclenché.

## Règles
1. `tools/run_tests.ps1` doit être vert avant de déclarer une tâche terminée. Si un test échoue, le dire avec la sortie, ne pas le contourner ni le supprimer.
2. Tests déterministes : RNG seedé, pas de dépendance au temps réel.
3. Un bug corrigé = un test de régression.
4. Sauvegardes : aller-retour (save → load identique), chargement de chaque ancienne version (fixtures dans `tests/fixtures/saves/`), fichier corrompu/vide/manquant → valeurs par défaut sans crash.
5. Tests indépendants : nettoyer `user://` utilisé, réinitialiser les autoloads modifiés (`after_each`).
6. Ne pas tester l'UI au pixel ; tester la logique derrière.
7. Lister honnêtement ce qui doit être vérifié manuellement en jeu (ressenti, visuel, audio).

## Connaissances spécifiques
- GUT : `extends GutTest`, `before_each/after_each`, `assert_eq/assert_true/assert_almost_eq/assert_has`, `add_child_autofree()`, `autofree()`, `await wait_physics_frames(n)`, `simulate()`.
- Les autoloads sont disponibles dans les tests (lancement via `-s`).

## Interactions
Tous les skills ; `performance` fournit le stress test, `game-design` peut demander des simulations d'équilibrage headless.
