# ADR 0015 — Méta-progression : profil, défis, personnages

**Statut :** accepté (2026-10-03) — étape 7, spec `docs/superpowers/specs/2026-10-03-meta-progression-design.md`, choix D46

## Contexte
Il faut des objectifs d'une partie à l'autre sans puissance permanente (méta horizontale, comme Brotato) : des défis débloquent des personnages et des objets.

## Décisions
1. **`Profile`** (`src/core/`, pur) : déblocages, défis réussis, statistiques ; dictionnaire versionné (version 1), lecture tolérante (types faux ignorés).
2. **Autoload `SaveService`** (prévu par `CLAUDE.md`, validé avec la proposition D46) : `user://profile.json` en JSON uniquement ; `record_run(result)` met à jour les stats, vérifie les défis, applique les déblocages et sauvegarde ; `is_unlocked(category, def)`. Les tests utilisent `user://test_profile.json` (crochet GUT).
3. **Défis** = Resources `ChallengeData` (`data/challenges/`) : type de condition, seuil, cible du déblocage. Vérifiés une seule fois, en fin de partie (aucun coût pendant la partie).
4. **Verrouillage** = `locked: bool` sur `CharacterData`, `WeaponData`, `ItemData` ; le contenu verrouillé reste hors boutique, récompenses et sélection. Le contenu existant reste disponible (faux par défaut). Les ids ne changent pas (sauvegardes).
5. **Personnages** : `CharacterData` gagne une règle affichée, des modificateurs, des effets (mêmes `ItemEffect` que les objets) et un choix d'arme de départ.
6. **Flux** : sélection du perso et de l'arme dans le menu → `RunSetup` dans `SceneRouter.next_run` (gardé pour « Recommencer »). `Run` ne lit ce choix que lancé comme scène (directement sous la racine) et n'enregistre que ces parties : tests et outils de debug n'écrivent jamais dans le profil.

## Conséquences
- Ajouter un perso : un `.tres` (`locked = true` + un défi qui le débloque) et ses textes.
- Ajouter un défi : un `.tres` ; un nouveau type de condition = une valeur de `ChallengeData.Kind` (et une donnée de `RunResult` si besoin).
- Migrations futures : dans `Profile.from_dict`, selon `version`.
- Chaque défi pourra devenir un succès Steam via `Platform` (Phase 10).
