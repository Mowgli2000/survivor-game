# Menus (étape C) — design

Date : 2026-10-03 · Statut : validé par le dev (choix « reco » sur les 4 questions)

## Objectif

Le jeu démarre sur un menu principal, peut être mis en pause, et propose des paramètres sauvegardés. Aujourd'hui, le jeu démarre directement dans une partie, Échap ne fait rien, et les options « tremblement » et « chiffres de dégâts » existent dans le code sans interface.

Critères de réussite :
- Au lancement (F5 ou exécutable) : menu principal animé → Jouer → partie.
- Échap / Start pendant une vague : menu pause (Reprendre, Paramètres, Recommencer, Menu principal, Quitter), confirmation avant d'abandonner la partie.
- Paramètres modifiables depuis le menu principal et la pause, appliqués tout de suite, retrouvés au relancement.
- Tout est jouable au clavier, à la souris et à la manette.

## Choix du dev

| Sujet | Choix |
|---|---|
| Menu principal | Simple animé : titre néon, Jouer / Paramètres / Quitter, fond = arène avec quelques ennemis qui errent. Pas de choix de personnage (méta-progression plus tard) |
| Pause | Complet : Reprendre / Paramètres / Recommencer / Menu principal / Quitter le jeu, confirmation avant d'abandonner, panneau de stats à côté |
| Paramètres | Audio (général, musique, effets), affichage (plein écran, VSync), jeu/accessibilité (tremblement, chiffres de dégâts, réduire les animations), langue (FR/EN) |
| Autoloads | `SceneRouter` et `Settings` acceptés (déjà prévus par `CLAUDE.md`) |

## Architecture

### `SettingsData` (`src/core/settings_data.gd`, pur, testable)
`RefCounted` avec les valeurs et leurs bornes :
`master_volume`, `music_volume`, `sfx_volume` (0..1, défaut 0,8 / 0,7 / 0,8), `fullscreen` (défaut false), `vsync` (true), `screen_shake` (true), `damage_numbers` (true), `reduce_motion` (false), `locale` (`""` = langue du système, sinon `en` ou `fr`).
- `to_dict() -> Dictionary` avec `version` (1).
- `static from_dict(d) -> SettingsData` : valeurs inconnues ignorées, types vérifiés, volumes bornés, langue hors liste → `""`. Version absente ou future : on lit ce qu'on peut.

### Autoload `Settings` (`src/autoload/settings.gd`)
- `var data: SettingsData`, `signal changed`.
- `load_settings()` au `_ready` : lit `user://settings.json` (JSON uniquement, jamais de `.tres`), fichier absent ou illisible → valeurs par défaut.
- `set_value(key: StringName, value: Variant)` : modifie `data`, applique, sauvegarde, émet `changed`.
- `apply()` : volumes des bus `Master`/`Music`/`SFX` (`linear_to_db`, muet à 0), mode fenêtre, VSync, `TranslationServer.set_locale`, `UiFx.reduce_motion`.
- `path` modifiable pour les tests.
- Aucune logique de partie.

### Autoload `SceneRouter` (`src/autoload/scene_router.gd`)
- `goto_main_menu()`, `goto_run()`, `quit()`.
- Enlève la pause de l'arbre avant de changer de scène (`change_scene_to_file`), coupe la musique de partie.
- Chemins des scènes en constantes.

### Menu principal (`src/ui/main_menu/main_menu.tscn` + `main_menu.gd`)
- Devient la scène principale (`run/main_scene`). L'ancien `src/main.tscn` (placeholder inutilisé) est supprimé.
- Fond : `Arena` existante + ~10 ennemis décoratifs (`SpriteSheet` des `EnemyData`) qui errent lentement, dessinés par un seul nœud ; caméra fixe. Pas d'`EnemyManager` (inutile pour un décor).
- Titre néon (`TitleLabel`), boutons `BigButton` : Jouer (focus par défaut), Paramètres, Quitter.
- Musique : celle de la partie, plus basse (pas de nouvelle piste).

### Écran de paramètres (`src/ui/settings/settings_screen.gd`)
- `Control` réutilisable, ouvert par le menu principal et la pause, signal `closed`.
- Sections : Audio (3 `HSlider` avec valeur en %), Affichage (2 `CheckButton`), Jeu (3 `CheckButton`), Langue (`OptionButton` : Système / English / Français).
- Chaque contrôle appelle `Settings.set_value` ; l'écran ne garde aucun état propre.
- Retour : bouton « Retour » et action `cancel`.
- Styles des `HSlider`, `CheckButton`, `OptionButton` ajoutés au thème unique (`UiTheme._build`), pas de style construit dans l'écran (ADR 0011).

### Menu pause (`src/ui/pause/pause_menu.gd`)
- `CanvasLayer` créé par `Run`, `PROCESS_MODE_ALWAYS`.
- `Run` l'ouvre sur l'action `pause` uniquement pendant une vague, sans autre écran ouvert et partie non terminée ; il met l'arbre en pause et l'enlève à « Reprendre ».
- `pause` ou `cancel` dans le menu = Reprendre (ou retour depuis Paramètres / confirmation).
- Recommencer, Menu principal, Quitter → panneau de confirmation (« Abandonner la partie ? » Oui / Non, focus sur Non).
- Panneau de stats (`StatsPanel` + familles) à droite, comme en boutique.
- Signaux : `resume_requested`, `restart_requested`, `main_menu_requested`, `quit_requested` ; `Run` les branche sur `SceneRouter`.

### Écran de fin
- Bouton « Menu principal » ajouté sous « Recommencer ».

### Branchement des paramètres en partie
- `Run` lit `Settings.data` à la création (`DamageNumbers.enabled`, `GameCamera.shake_enabled`) et se met à jour sur `Settings.changed`.

## Erreurs et cas limites
- `settings.json` corrompu → valeurs par défaut, fichier réécrit au prochain changement, avertissement dans la console.
- Bus audio absent → ignoré sans planter.
- Pause pendant level-up, boutique ou fin de partie → ignorée (ces écrans pausent déjà le jeu).
- Les tests et outils de debug (`stress_test`, `capture`) instancient `run.tscn` directement : inchangés.

## Tests
- `SettingsData` : aller-retour dict, bornes, types faux, langue inconnue, dict vide.
- `Settings` : sauvegarde puis relecture dans un fichier temporaire, JSON corrompu → défauts, volume appliqué au bus.
- Menu pause : ouverture → arbre en pause ; Reprendre → plus en pause ; ignoré hors vague.
- Écran de paramètres : un `CheckButton` modifie `Settings.data`.
- Menu principal : la scène se charge, le bouton Jouer a le focus.
- Clés de traduction en + fr (test existant).

## Hors périmètre
Remappage des touches, choix de résolution, choix de personnage, crédits, méta-progression.

## Documentation
ADR 0013 (autoloads `Settings` / `SceneRouter`, menus). `CLAUDE.md` : liste des autoloads. `PROJECT_STATUS.md`.
