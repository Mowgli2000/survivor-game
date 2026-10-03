# Étape 7 — Méta-progression (design + plan)

Date : 2026-10-03 · Statut : choix validés par le dev (D46 : méta horizontale, déblocages par défis, persos à règle unique + bonus/malus, arme de départ au choix)

## Objectif
Donner des objectifs d'une partie à l'autre sans puissance permanente : des défis débloquent des personnages et des objets ; un profil sauvegardé garde déblocages et records.

## Données
- **`ChallengeData`** (`src/meta/challenge_data.gd`, contenus dans `data/challenges/`) : `id`, `name_key`, `description_key`, `kind` (`WIN_WITH` un perso, `WIN_ANY`, `TOTAL_KILLS`, `REACH_WAVE`, `MATERIALS_HELD`, `KILL_ENEMY` un type d'ennemi), `character_id` / `enemy_id`, `threshold`, `unlock_category` + `unlock_id` (ce qu'il débloque).
- **Verrouillage** : `locked: bool` sur `CharacterData`, `WeaponData`, `ItemData` (faux par défaut : le contenu existant reste disponible ; un contenu verrouillé n'apparaît ni en boutique ni en récompense ni à la sélection tant que son défi n'est pas réussi).
- **`CharacterData`** gagne : `description_key` (sa règle), `modifiers` (bonus/malus), `effects` (mêmes `ItemEffect` que les objets, ADR 0012), `starting_weapons` (choix de l'arme de départ ; vide = `starting_weapon`).

## Profil et sauvegarde
- **`Profile`** (`src/core/profile.gd`, pur) : déblocages par catégorie, défis réussis, statistiques (parties, victoires, victoires par perso, meilleure vague, ennemis tués au total, ennemis spéciaux tués), `to_dict()` / `from_dict()` versionnés (version 1, migrations prévues dans `from_dict`).
- **Autoload `SaveService`** (prévu par `CLAUDE.md`, inclus dans la proposition validée §8) : `user://profile.json` (JSON uniquement), `record_run(result) -> Array[ChallengeData]` (met à jour les stats, vérifie les défis, applique les déblocages, sauvegarde), `is_unlocked(category, def)`. Tests isolés par le crochet GUT (`TEST_PATH`).
- **`RunResult`** : perso, victoire, vague, ennemis tués, matériaux max détenus, ids des ennemis spéciaux tués (boss).

## Flux
- Menu principal → **Jouer** → **sélection du personnage** (cartes ; verrouillé = grisé avec la condition) → **arme de départ** → Commencer. Le choix passe par `SceneRouter.next_run` (`RunSetup` : perso + arme), conservé pour « Recommencer ».
- `Run` : applique perso (stats, modificateurs, effets, arme choisie) ; filtre boutique et récompenses par `SaveService.is_unlocked` ; en fin de partie (si lancée depuis le menu), envoie le `RunResult` et l'écran de fin affiche les nouveaux déblocages.
- Menu principal → **Progression** : liste des défis (réussis / à faire) et statistiques.

## Contenu
- Persos : **Drifter** (dispo, équilibré, Pulsar ou pistolet laser), **Rōnin** (+15 % critique, +20 % vitesse d'attaque, −25 % portée ; katana ou shuriken ; débloqué en gagnant avec Drifter), **Gunslinger** (+25 % portée, +10 % vitesse d'attaque, −3 armure ; pistolet laser ou mitraillette ; débloqué à 2 000 ennemis tués au total), **Marchand** (+3 récolte, intérêts de 10 % plafonnés à 25, −10 % dégâts ; Pulsar ou bazooka ; débloqué en détenant 300 matériaux).
- Défis (8) : les 3 persos ci-dessus + 4 objets forts verrouillés (atteindre la vague 10, tuer le Ronin, gagner une partie, 5 000 ennemis) + « Gagner avec le Rōnin » (débloque un objet).

## Tests
`Profile` (aller-retour, migration d'un dict vide/ancien), `ChallengeData.is_met`, `SaveService.record_run` (stats, déblocage, pas de double déblocage, sauvegarde relue), filtrage boutique, application du perso dans `Run` (modificateurs + arme choisie), sélection du perso (verrouillé non sélectionnable), écran de progression, données (défis cohérents : cible existante, verrouillée).
