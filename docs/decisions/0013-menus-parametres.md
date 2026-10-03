# ADR 0013 — Menus, paramètres et changement de scène

**Statut :** accepté (2026-10-03) — étape C, spec `docs/superpowers/specs/2026-10-03-menus-design.md`

## Contexte
Le jeu démarrait directement dans une partie, Échap ne faisait rien, et les options « tremblement » et « chiffres de dégâts » existaient sans interface. Il faut un menu principal, un menu pause et des paramètres sauvegardés, utilisables au clavier, à la souris et à la manette.

## Décisions
1. **`SettingsData`** (`src/core/`, pur) : valeurs des paramètres, validation (types, volumes bornés entre 0 et 1, langue `""`/`en`/`fr`) et dictionnaire versionné pour le JSON.
2. **Autoload `Settings`** (accord du dev) : lit et écrit `user://settings.json` (JSON uniquement, jamais de Resource) et applique les valeurs au moteur : volumes des bus `Master`/`Music`/`SFX` (muet à 0), plein écran, VSync, langue, `UiFx.reduce_motion`. Signal `changed`. Fichier illisible : valeurs par défaut, avertissement en console. Les tests utilisent `user://test_settings.json` grâce au crochet GUT `tests/helpers/pre_run.gd`.
3. **Autoload `SceneRouter`** (accord du dev) : `goto_main_menu()`, `goto_run()`, `quit()`. Enlève la pause et coupe les sons avant de changer de scène.
4. **Écrans construits en code**, thème unique (ADR 0011) : `MainMenu` (scène principale, arène et quelques ennemis décoratifs dessinés par un seul nœud `MenuCrowd`), `SettingsScreen` (partagé par le menu principal et la pause), `PauseMenu` (créé par `Run`, confirmation avant d'abandonner, panneau de stats). Les styles des curseurs, interrupteurs et listes sont dans `UiTheme`.
5. **`Run`** ouvre la pause uniquement pendant une vague sans autre écran ouvert, et applique `Settings.data` aux chiffres de dégâts et au tremblement (mis à jour sur `changed`).

## Alternatives écartées
- `ConfigFile` : le JSON est déjà la convention de sauvegarde (ADR 0003).
- Paramètres gérés par `Run` : le menu principal en a besoin hors partie.

## Conséquences
- Ajouter un paramètre : un champ et sa clé dans `SettingsData`, son application dans `Settings.apply()` (ou chez le système qui écoute `changed`), un contrôle dans `SettingsScreen`, la clé `SET_<NOM>` traduite.
- Pas encore de remappage des touches ni de choix de résolution (Phase 9).
- Les outils de debug et les tests instancient toujours `run.tscn` directement.
