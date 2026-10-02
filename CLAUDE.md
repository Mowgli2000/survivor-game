# Survivor Game (titre de travail) — Guide Claude Code

Survivor-like / roguelite 2D vue de dessus pour PC/Steam. Arène bornée, vagues chronométrées, **boutique entre les vagues** (pilier du design). Attaque 100 % automatique : le joueur ne contrôle que le déplacement. Thème de travail : **cyber-samouraï / ninja néon** (lames, armes high-tech et imaginaires, couleurs néon : une couleur forte par arme).
Boucle : combat → ressources → boutique/choix → build → combat plus dur → boss → récompense.
Moteur : Godot 4.7.2 · GDScript typé · renderer Compatibility · cible 60 FPS avec 500+ ennemis.
Le développeur n'est pas senior : expliquer les décisions importantes, signaler les problèmes, préférer la solution simple.

## État du projet
Phases 0 (setup), 1 (prototype) et 2 (combat : 6 armes à niveaux, statuts, 4 ennemis, rendu néon) terminées. Prochaine : Phase 3 (items, synergies, menus). Roadmap et GDD : `docs/design/gdd.md`. Décisions : `docs/decisions/`.

## Architecture (résumé — détails dans les skills)
- Autoloads minimaux : ContentDB (existe), puis SceneRouter, Settings, SaveService, Audio, EventBus, Platform quand leur phase arrive. Aucune logique de run dans un autoload.
- `src/run/run.gd` = racine de composition d'une partie : crée et branche les systèmes (EnemyManager, ProjectileManager, PickupManager, SpawnDirector, Progression, Shop…).
- Ennemis/projectiles/pickups : gérés en lot par leur manager + `SpatialGrid` + `ObjectPool`. Jamais de `_process` par entité, jamais d'Area2D/physique pour les hits de masse. Seul le Player est un CharacterBody2D. Projectiles = données rendues par un seul MultiMesh (ADR 0004). Ennemis = une texture néon précalculée par type (ADR 0005).
- Code pur testable dans `src/core/` (StatBlock, CombatMath, SpatialGrid, ObjectPool, WeightedPicker).
- Contenu = Resources `.tres` dans `data/<catégorie>/`, classes de définition dans `src/**/<x>_data.gd`, accès via `ContentDB.get_def(&"weapons", &"id")`. Comportements = Resources strategy dans `behaviors/`.
- Armes : `WeaponData` (niveau 1 + `levels`) -> `WeaponStats` via `WeaponSlot` ; `WeaponHolder` les déclenche. Ajouter une arme = un `.tres`.
- **Tous les dégâts passent par l'API d'`EnemyManager`** (`damage_enemy`, `damage_in_radius`, `damage_along_segment`) : armure, statuts, recul et feedback au même endroit (ADR 0005).
- Feedback : `Vfx` (effets additifs, un seul nœud), `DamageNumbers`, `GameCamera.add_trauma()`. Pas de `draw_*` anticrénelé par entité de masse : précalculer en texture.
- UI : lit l'état, écoute les signaux, appelle l'API publique des systèmes. Ne modifie jamais l'état directement.
- Sauvegarde : JSON versionné dans `user://`. **Ne jamais charger de `.tres`/`.res` depuis `user://`** (exécution de code possible).
- Steam : uniquement derrière l'autoload `Platform` (Phase 10). Le jeu doit tourner sans Steam.

## Conventions
- snake_case fichiers/dossiers/variables, PascalCase classes (`class_name`), UPPER_CASE constantes. Typage statique partout (`-> void`, `: float`).
- Dépendances injectées via `setup(...)` ; pas de `get_parent()`, pas de `get_node("../..")` en gameplay.
- Signaux nommés au passé (`enemy_killed`, `level_up_requested`), connectés en code par le parent.
- Textes : `tr("CLE")` ou clé directement dans le `text` d'un Control ; clés dans `localization/strings.csv` (colonnes en + fr obligatoires — un test le vérifie).
- Inputs : actions InputMap uniquement (`move_*`, `pause`, `confirm`, `cancel`, `ui_*`). Touches en `physical_keycode` (compatible AZERTY/QWERTY).
- IDs de contenu `snake_case` stables : ne jamais renommer un ID existant (il est dans les sauvegardes).
- Commentaires de code en anglais ; docs et échanges en français.

## Règles de modification
- Lire les systèmes concernés avant de coder ; réutiliser l'existant ; ne jamais créer un second système qui fait la même chose.
- Modifications minimales et ciblées ; pas de réécriture de fichier sans raison.
- Toute nouvelle abstraction doit être justifiée ; tout changement d'architecture → ADR court dans `docs/decisions/`.
- Pas de nouvel addon/plugin ni de nouvel autoload sans accord explicite.
- Ne pas implémenter une phase future « en avance » sans demande.

## Workflow par fonctionnalité
1. Analyser la demande 2. Localiser les systèmes concernés 3. Plan court 4. Implémenter 5. Écrire/adapter les tests 6. `tools/run_tests.ps1` + `tools/check_scripts.ps1` 7. Résumer : changements, résultats des tests, ce qui reste à vérifier manuellement en jeu.

## Commandes
- Tests (GUT headless, import inclus) : `powershell -ExecutionPolicy Bypass -File tools/run_tests.ps1`
- Compilation de tous les scripts : `powershell -ExecutionPolicy Bypass -File tools/check_scripts.ps1`
- Lancer le jeu : `& "C:\Program Files\Godot\Godot.exe" --path .`
- Export Windows : `& "C:\Program Files\Godot\Godot.exe" --headless --path . --export-release "Windows Desktop" builds/windows/survivor-game.exe`
- Stress test (500 ennemis + 1000 projectiles, imprime FPS/ms) : `& "C:\Program Files\Godot\Godot.exe" --path . res://src/debug/stress_test.tscn -- --duration=20`
- Capture d'écran automatique (pour vérifier un visuel) : `... res://src/debug/capture.tscn -- --time=20 --out=<chemin.png> [--stress] [--levelup] [--die]`
- Overlay debug en jeu : F3 (action `debug_toggle`).
- Galerie d'effets et d'ennemis (direction artistique) : `... res://src/debug/vfx_gallery.tscn [-- --out=<chemin.png>]`
- Chemin Godot surchargeable via la variable d'env `GODOT_BIN`.

## Performance
Profiler avant d'optimiser. Pas d'allocation dans les boucles chaudes. Après tout changement touchant ennemis/projectiles/pickups : vérifier le stress test et comparer aux chiffres de référence de l'ADR 0005 (~200 FPS moyen avec les 6 armes niveau max, physique ~8 ms).

## Git
- **On travaille sur la branche `develop`** (remote `origin` = github.com/Mowgli2000/survivor-game). `main` ne reçoit que des versions validées, sur demande explicite du dev. Ne jamais commiter directement sur `main`.
- Commits petits et logiques (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`). Jamais de secrets, clés Steam, credentials, `.godot/`, builds. Commit/push uniquement sur demande. Les fichiers `.uid` sont commités.

## Skills (`.claude/skills/`)
godot-development · gameplay-programming · game-design · performance · ui-ux · testing · steam-release (Phase 10+ uniquement).
