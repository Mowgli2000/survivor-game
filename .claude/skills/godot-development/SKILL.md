---
name: godot-development
description: Bonnes pratiques Godot 4.7 / GDScript pour ce projet. À utiliser pour toute création ou modification de scène (.tscn), node, script .gd, Resource (.tres), autoload, signal, InputMap ou project.godot.
---

# godot-development

## Objectif
Produire du code Godot idiomatique, typé, lisible et conforme à l'architecture décrite dans `CLAUDE.md`.

## Quand l'utiliser
- Créer/modifier une scène, un script, une Resource, un autoload.
- Toucher à `project.godot` (InputMap, autoloads, rendu, fenêtre, localisation).
- Organiser des nodes, des signaux, ou résoudre un problème propre au moteur.

## Règles
1. **GDScript typé partout** : paramètres, retours, variables membres. `@onready var x: Node2D = $X`.
2. `class_name` pour toute classe réutilisée ailleurs (Resources de données, systèmes core). Pas de `class_name` sur les scripts d'autoload (le nom d'autoload suffit).
3. **Signaux vers le haut, appels vers le bas.** Un enfant n'appelle jamais `get_parent()` ; il reçoit ses dépendances via `setup(...)` appelé par la racine de composition (`run.gd`).
4. Connexion des signaux **en code** dans le parent (`child.died.connect(_on_child_died)`), pas dans l'inspecteur — plus facile à lire et à rechercher.
5. Données de contenu = Resource avec `@export`. Ne jamais modifier une Resource partagée à l'exécution : copier les valeurs dans l'état runtime, ou `duplicate()` si vraiment nécessaire.
6. Pause : `get_tree().paused = true` ; l'UI de pause/level-up a `process_mode = PROCESS_MODE_ALWAYS`, le gameplay reste en `INHERIT`/`PAUSABLE`.
7. Inputs : uniquement `Input.get_vector("move_left", "move_right", "move_up", "move_down")` et actions nommées. Jamais de `KEY_*` en gameplay.
8. Autoloads : pas de nouvel autoload sans accord + ADR. Ordre de chargement défini dans `project.godot`.
9. `.tscn` : les éditer à la main seulement pour des scènes simples (format texte `format=3`, sans `uid` inventé). Pour des scènes complexes, préférer construire les nodes en code dans `_ready()` ou demander au dev de les faire dans l'éditeur. Toujours valider ensuite avec `tools/run_tests.ps1` (qui importe le projet).
10. Fichiers `.uid` générés par Godot : les garder et les commiter.

## Connaissances spécifiques
- Cycle de vie : `_init` → `_enter_tree` → `_ready` (enfants d'abord) → `_process`/`_physics_process`. `@onready` est résolu juste avant `_ready`.
- `StringName` (`&"id"`) pour les IDs et clés comparées souvent.
- Dictionnaires et tableaux typés : `Dictionary[StringName, int]`, `Array[EnemyData]`.
- Exports : les `.tres` deviennent `*.tres.remap` dans un build → ne pas lister des fichiers par extension sans gérer `.remap` (voir `ContentDB`).
- Headless : `Godot.exe --headless --path . --import` (import), `-s script.gd` (script SceneTree, autoloads chargés), `--export-release "Windows Desktop" <out>`. `--check-only` ne connaît pas les autoloads → utiliser `tools/check_scripts.ps1`.
- Stretch mode `canvas_items` + aspect `expand`, viewport de référence 1920×1080.
- Renderer Compatibility : préférer `CPUParticles2D` ou des particules simples ; vérifier le support d'une fonctionnalité de rendu avant de l'utiliser.

## Contraintes
- Pas de chemins absolus de nodes (`/root/...`) hors autoloads.
- Pas de `get_tree().get_nodes_in_group()` / `find_child()` dans une boucle par frame.
- Pas de logique de jeu dans `_input` : lire l'état des actions dans `_physics_process`.

## Interactions
Base de tous les autres skills. `gameplay-programming` et `ui-ux` s'appuient sur ces règles ; `performance` les durcit pour les boucles chaudes ; `testing` vérifie qu'elles tiennent.
