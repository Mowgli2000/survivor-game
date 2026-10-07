# Survivor Game (titre de travail) — Guide Claude Code

Survivor-like / roguelite 2D vue de dessus pour PC/Steam. Arène bornée, vagues chronométrées, **boutique entre les vagues** (pilier du design). Attaque 100 % automatique : le joueur ne contrôle que le déplacement. Thème : **donjon fantasy façon Solo Leveling** (chasseurs contre monstres sortis de portails), rendu façon Brawlhalla : trait épais, aplats, proportions trapues (D50 ; l'ancien thème cyber-samouraï néon est abandonné).
Boucle : combat → ressources → boutique/choix → build → combat plus dur → boss → récompense.
Moteur : Godot 4.7.2 · GDScript typé · renderer Compatibility · cible 60 FPS avec 500+ ennemis.
Le développeur n'est pas senior : expliquer les décisions importantes, signaler les problèmes, préférer la solution simple.

## État du projet
**Lire `PROJECT_STATUS.md` en début de session et le mettre à jour en fin de session** (décisions, changements, retours de playtest, prochaines étapes).
Phases 0 (setup), 1 (prototype), 2 (combat : 6 armes, statuts, 4 ennemis, rendu néon), 4 (vagues : 20 vagues, élites, boss provisoire) et 5 (socle de boutique façon Brotato : matériaux, armes à 4 rangs en double, objets de stats, level-up à rang) terminées. Faits ensuite : objets à effets/familles (B), menus/paramètres (C, ADR 0013), vrais boss (6, ADR 0014), nouveaux ennemis (5b), méta-progression + difficultés + mode infini (7/7b, ADR 0015). Prochaine : 6b vertical slice. Roadmap et GDD : `docs/design/gdd.md`. Décisions : `docs/decisions/`.

## Architecture (résumé — détails dans les skills)
- Autoloads minimaux : ContentDB, Audio (ADR 0008 : `Audio.play(stream)`, catalogue `Sounds`, son de tir dans `WeaponData`), Settings et SceneRouter (ADR 0013 : `Settings.data` / `set_value` / signal `changed`, fichier `user://settings.json` ; `SceneRouter.goto_main_menu/goto_run/quit`) et SaveService (ADR 0015 : profil `user://profile.json`, défis, déblocages) existent ; puis EventBus, Platform quand leur phase arrive. Aucune logique de run dans un autoload.
- `src/run/run.gd` = racine de composition d'une partie : crée et branche les systèmes (EnemyManager, ProjectileManager, PickupManager, SpawnDirector, Progression, Shop…).
- Ennemis/projectiles/pickups : gérés en lot par leur manager + `SpatialGrid` + `ObjectPool`. Jamais de `_process` par entité, jamais d'Area2D/physique pour les hits de masse. Seul le Player est un CharacterBody2D. Projectiles = données rendues par un seul MultiMesh (ADR 0004). Ennemis et joueur = sprites animés dans un atlas commun, image avancée par le manager, redessin seulement au changement d'image (ADR 0009 ; repli néon ADR 0005). Art vectoriel dessiné par code (ADR 0016) ; projectiles stylés par arme (`WeaponData.projectile_style`).
- Code pur testable dans `src/core/` (StatBlock, CombatMath, SpatialGrid, ObjectPool, WeightedPicker).
- Contenu = Resources `.tres` dans `data/<catégorie>/`, classes de définition dans `src/**/<x>_data.gd`, accès via `ContentDB.get_def(&"weapons", &"id")`. Comportements = Resources strategy dans `behaviors/`.
- Armes : `WeaponData` (rang I + `levels` pour II..IV) -> `WeaponStats` via `WeaponSlot` ; `WeaponHolder` (doublons, fusion, points de montage `WeaponLayout`) les déclenche ; `WeaponVisuals` les dessine autour du perso (ADR 0010). Ajouter une arme = un `.tres` + une icône (`tools/icons/make_icons.py` ou SVG/PNG externe).
- Boutique (ADR 0007) : `Shop` (logique pure : stock, relance, verrou, achat, vente, fusion) + `ShopScreen` ; réglages `data/shop/` ; monnaie `Wallet` ; objets `ItemData` (`data/items/`) + `Inventory` ; rangs `Tiers`.
- Effets d'objets (ADR 0012) : `ItemData.effects` (Resources `ItemEffect` dans `src/items/effects/`, une copie par exemplaire) routés par le nœud `ItemEffects` ; familles d'armes `FamilyData` (`data/families/`) appliquées par `WeaponFamilies`. Ajouter un objet à effet = `.tres` + `effect_key` traduit + icône ; objets forts uniques (`max_count = 1`).
- Méta-progression (ADR 0015) : défis `ChallengeData` (`data/challenges/`), contenu `locked` filtré par `SaveService.is_unlocked`, persos `CharacterData` (règle, modificateurs, effets, armes de départ), choix passé par `SceneRouter.next_run` (`RunSetup` : perso, arme, `DifficultyData`). `Run` travaille sur une copie du stage (`StageData.with_difficulty`, mode infini `endless`).
- Boss (ADR 0014) : `EnemyData.phases` (`BossPhase` + motifs `BossPattern` dans `src/enemies/boss/`) joués par `BossDirector` ; barre `BossBar`. Nouvelle attaque = un script `BossPattern`.
- **Tous les dégâts passent par l'API d'`EnemyManager`** (`damage_enemy`, `damage_in_radius`, `damage_along_segment`) : armure, statuts, recul et feedback au même endroit (ADR 0005).
- Feedback : `Vfx` (effets additifs, un seul nœud), `DamageNumbers`, `GameCamera.add_trauma()`. Pas de `draw_*` anticrénelé par entité de masse : précalculer en texture.
- UI : lit l'état, écoute les signaux, appelle l'API publique des systèmes. Ne modifie jamais l'état directement. Apparence : `theme = UiTheme.get_theme()` sur la racine de chaque écran + variations de type (`TitleLabel`, `SubtitleLabel`, `ValueLabel`, `SmallLabel`, `BigButton`) ; styles colorés via `UiTheme.card_style/panel_style` ; animations via `UiFx` (ADR 0011). Pas de `StyleBoxFlat` construit à la main dans un écran.
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
- Stress test (650 ennemis = plafond du jeu + 1000 projectiles, imprime FPS/ms/draw calls) : `& "C:\Program Files\Godot\Godot.exe" --path . res://src/debug/stress_test.tscn -- --duration=20`
- Capture d'écran automatique (pour vérifier un visuel) : `... res://src/debug/capture.tscn -- --time=20 --out=<chemin.png> [--stress] [--allweapons] [--levelup] [--waveend] [--shop] [--die] [--pause] [--settings] [--menu] [--characters] [--progression] [--boss=shogun|ronin]`
- Planche des icônes d'armes et d'objets : `... res://src/debug/icon_sheet.tscn [-- --out=<chemin.png>]` ; icônes régénérées par `python tools/icons/make_icons.py`
- Overlay debug en jeu : F3 (action `debug_toggle`).
- Galerie d'effets et d'ennemis (direction artistique) : `... res://src/debug/vfx_gallery.tscn [-- --out=<chemin.png>]`
- Art (ADR 0016) : dessiner `python tools/art/make_sprites.py` (persos/ennemis) et `python tools/art/make_map.py` (sol, décor, projectiles) → SVG dans `assets_src/drawn/` ; convertir tout (atlas `assets/sprites/`, `SpriteSheet` `.tres`, `assets/map/decor_atlas.tres`, `projectiles.png`) : `powershell -ExecutionPolicy Bypass -File tools/bake_sprites.ps1` ; aperçu rapide : `& "C:\Program Files\Godot\Godot.exe" --headless --path . -s res://tools/art/preview_sheet.gd -- --out=<png> [--id=drifter]`
- Pantin d'un perso (ADR 0020) : `& "C:\Program Files\Godot\Godot.exe" --headless --path . -s res://tools/art/make_rig.gd -- --id=<id>` (réglages `tools/art/rigs/<id>.json`), puis `--import` ; planche de contrôle : `... -s res://tools/art/rig_preview.gd -- --character=<id> --out=<png>`
- Chemin Godot surchargeable via la variable d'env `GODOT_BIN`.

## Performance
Profiler avant d'optimiser. Pas d'allocation dans les boucles chaudes. Après tout changement touchant ennemis/projectiles/pickups : vérifier le stress test (seuil : ≥ 100 FPS moyen, décision du dev D37 ; référence ~145-165 FPS, ADR 0009/0010 ; les mesures varient de ±15 FPS : comparer en alterné avec la version précédente).

## Git
- **On travaille sur la branche `develop`** (remote `origin` = github.com/Mowgli2000/survivor-game). `main` ne reçoit que des versions validées, sur demande explicite du dev. Ne jamais commiter directement sur `main`.
- **Graphismes, interfaces et visuel : dans une branche à part** (`visual/<sujet>`, créée depuis `develop`), fusionnée dans `develop` quand le dev valide (décision du dev, 2026-10-08). Le gameplay, les corrections et le reste restent sur `develop`.
- Commits petits et logiques (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`). Jamais de secrets, clés Steam, credentials, `.godot/`, builds. Commit/push uniquement sur demande. Les fichiers `.uid` sont commités.

## Skills (`.claude/skills/`)
godot-development · gameplay-programming · game-design · performance · ui-ux · testing · steam-release (Phase 10+ uniquement).
