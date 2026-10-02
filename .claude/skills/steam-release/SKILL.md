---
name: steam-release
description: Intégration Steam et préparation de lancement - GodotSteam, succès, statistiques, Steam Cloud, overlay, Steam Deck, builds/exports, SteamPipe, versioning, page Steam, démo, checklist de release. À utiliser uniquement en Phase 10+ ou pour des questions de préparation (page Steam, démo, export). Ne pas implémenter Steam avant la Phase 10.
---

# steam-release

## Objectif
Brancher Steam proprement sans rendre le jeu dépendant de Steam, et livrer des builds fiables.

## Quand l'utiliser
- Phase 10+ : intégration Steam.
- Avant : uniquement conseils (page Steam, wishlists, démo Next Fest, export Windows, versioning).

## Règles
1. **Tout passe par l'autoload `Platform`** (interface : `unlock_achievement(id)`, `set_stat(id, v)`, `is_available()`…) avec `NullPlatform` par défaut et `SteamPlatform` via GodotSteam. Aucun appel Steam ailleurs.
2. **Le jeu doit fonctionner sans Steam** (Steam absent, hors ligne, build non-Steam).
3. Sauvegardes : rester en fichiers locaux dans `user://` ; Steam Cloud via **Auto-Cloud** configuré dans Steamworks (pas de code dédié).
4. **Aucun secret dans Git** : credentials SteamCMD, tokens, clés → hors repo (variables d'env / fichiers ignorés). `steam_appid.txt` uniquement en local de dev, jamais dans un build release.
5. Succès/stats déclenchés à partir des signaux de l'`EventBus` (pas d'appels dispersés dans le gameplay).
6. Versioning : `config/version` dans `project.godot` (SemVer), affiché dans le menu, inclus dans les sauvegardes.
7. Divulgation du contenu généré par IA sur la page Steam si des assets IA sont utilisés.
8. Ne jamais changer de version de Godot ou de GodotSteam sans vérifier leur compatibilité.

## Connaissances spécifiques
- GodotSteam : version GDExtension compatible avec la version exacte de Godot ; initialisation au démarrage, `run_callbacks` chaque frame.
- Export : templates Godot de la même version ; preset « Windows Desktop » ; `--export-release` headless ; PCK intégré ou séparé.
- SteamPipe / SteamCMD : app, depots, branches (default, beta, privée), scripts `app_build.vdf`.
- Steam Deck : 1280×800, glyphes manette, textes lisibles, pas de lanceur externe.
- Calendrier : page « Coming Soon » le plus tôt possible (vertical slice), démo pour un Steam Next Fest, lancement après accumulation de wishlists.
- Checklist release : succès testés, Cloud testé, overlay, plein écran/fenêtré, résolutions, langues, crash reporting, notes de patch.

## Interactions
`testing` (tests du build release, saves), `ui-ux` (glyphes, overlay, Deck), `godot-development` (export, autoload Platform).
