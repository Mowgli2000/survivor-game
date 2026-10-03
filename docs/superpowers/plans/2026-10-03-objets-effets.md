# Objets à effets et familles d'armes — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 4 nouvelles stats, familles d'armes à paliers, effets d'objets en « strategy » et 13 nouveaux objets.

**Architecture:** `StatIds` gagne `dodge`, `lifesteal`, `luck`, `harvest`. `WeaponFamilies` (pur) applique les bonus de famille sur le `StatBlock`. `ItemEffects` (nœud de la partie) route les événements (achat, ennemi tué, dégâts, fin de vague, tick) vers des `ItemEffect` (Resources, une copie par exemplaire) et gère vol de vie et récolte. La chance agit dans `ShopConfig.roll_tier` et sur les chances des effets.

**Tech Stack:** Godot 4.7.2, GDScript typé, GUT 9.6.1.

**Spec:** `docs/superpowers/specs/2026-10-03-objets-effets-design.md`

## Global Constraints

- Tous les dégâts via `EnemyManager` ; aucun travail par ennemi ajouté dans les boucles chaudes (les effets réagissent aux signaux existants).
- RNG de la partie (`state.rng`) pour tout tirage de gameplay (rejouabilité).
- Textes : clés dans `localization/strings.csv` (en + fr).
- IDs de contenu stables, `snake_case`.

## Review Focus

- Vendre ou fusionner une arme : bonus de famille recalculé (descente de palier) → test Task 2.
- Objet unique : jamais proposé une 2e fois en boutique une fois acheté → test Task 4.
- `ConditionalStatEffect` dont la stat cible change la stat source (boucle) : interdit par validation de données → test Task 3.
- Vol de vie avec des centaines de coups par seconde : plafond 10 PV/s → test Task 1.
- Esquive bornée à 60 % même avec beaucoup d'objets → test Task 1.

---

### Task 1: Nouvelles stats (esquive, vol de vie, chance, récolte)
- [ ] Tests : esquive (RNG forcé) ignore le coup ; borne 60 % ; vol de vie soigne 1 PV par coup réussi et plafonne à 10 PV/s ; récolte : matériaux en fin de vague, +5 % par vague ; chance : `roll_tier` donne des rangs supérieurs plus souvent ; clés de traduction des stats.
- [ ] `StatIds` (+ bornes, `SHOWN_AS_PERCENT`) ; `Player.rng` (RNG de la partie, posé par `run.gd`) et esquive dans `take_damage` ; `ShopConfig.roll_tier(wave, rng, luck)` ; `Progression.roll_offers` passe la chance ; nœud `ItemEffects` (vol de vie sur `enemy_damaged`, récolte sur fin de vague) branché par `run.gd`.
- [ ] Commit `feat: dodge, lifesteal, luck and harvest stats`.

### Task 2: Familles d'armes
- [ ] Tests : paliers 2/4/6 ; doublons comptés ; vente → palier inférieur ; donnée : chaque arme a ≥ 1 famille existante.
- [ ] `FamilyBonus`, `FamilyData` (`data/families/`), catégorie ContentDB ; `WeaponData.families` ; `WeaponFamilies.setup(holder, stats)` ; 4 familles + armes taguées.
- [ ] Commit `feat: weapon families with set bonuses`.

### Task 3: Effets d'objets
- [ ] Tests : un test par type d'effet (`ExplodeOnKillEffect`, `MaterialOnKillEffect`, `InterestEffect`, `ConditionalStatEffect`, `KillStackEffect`, `PeriodicHealEffect`) ; copie par exemplaire ; validation (cible ≠ source).
- [ ] `ItemEffect` (base) + 6 effets dans `src/items/effects/` ; `ItemData.effects` ; `Inventory.item_added` ; `ItemEffects` route `on_acquired`, `on_enemy_killed`, `on_wave_ended`, `on_tick`.
- [ ] Commit `feat: item effects`.

### Task 4: 13 nouveaux objets
- [ ] Tests de données (icône, textes, effets, unicité via `max_count = 1`) ; boutique : objet unique possédé jamais reproposé.
- [ ] 13 `.tres` + icônes (`make_icons.py`) + traductions (noms, descriptions d'effets) ; description d'effet affichée sur la carte.
- [ ] Commit `feat: 13 new items with effects`.

### Task 5: Interface et documentation
- [ ] Panneau de stats : 4 nouvelles stats + section « Familles » ; cartes d'armes : familles. Captures.
- [ ] ADR 0012, `CLAUDE.md`, `PROJECT_STATUS.md` (D42) ; stress test ; revue finale.
