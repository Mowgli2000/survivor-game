# ADR 0003 — Contenu en Resources `.tres`, sauvegardes en JSON

**Statut :** accepté (2026-10-02)

## Contexte
Beaucoup de contenu à produire (armes, ennemis, items, personnages) et des sauvegardes qui doivent survivre aux mises à jour et à Steam Cloud.

## Décision
- **Contenu** : Resources Godot (`.tres`) dans `data/<catégorie>/`, classes de définition `*_data.gd` avec `@export`. Indexé par ID via l'autoload `ContentDB`.
- **Sauvegardes** : **JSON** dans `user://`, avec un champ `version` et une chaîne de migrations ; écriture atomique (fichier temporaire puis renommage) + backup.
- **Paramètres** : `ConfigFile` dans `user://settings.cfg`.
- **Localisation** : `localization/strings.csv` (clé, en, fr, …).

## Pourquoi pas de Resources pour les saves
Charger un `.tres` depuis `user://` peut exécuter du code arbitraire (un fichier de save modifié/partagé devient une faille). JSON est sûr, lisible, versionnable et indépendant de Steam.

## Conséquences
- Les sauvegardes ne référencent le contenu que par **ID stable** : renommer un ID existant est interdit.
- Steam Cloud = Auto-Cloud sur le dossier `user://` (pas de code spécifique).
