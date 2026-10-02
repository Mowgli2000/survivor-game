# Phase 4 — Vagues : design

Date : 2026-10-02 · Statut : validé en discussion, à relire · Décisions liées : D2, D14, D15 (`PROJECT_STATUS.md`)

## Objectif

Remplacer le spawn continu infini (partie de 15+ min sans structure, retour du playtest Phase 2) par une run de **20 vagues chronométrées** qui se termine par une victoire. Mettre en place le rythme « vague → pause → vague » dans lequel la boutique (Phase 5) et le boss (Phase 6) viendront s'insérer.

**Critère de sortie** : une run complète vague 1 → vague 20 → écran de victoire, avec élites, vagues spéciales, level-ups différés et soin entre les vagues ; tests verts ; stress test ≈ référence ADR 0005 (~200 FPS).

## Décisions (prises avec le dev)

| Sujet | Choix |
|---|---|
| Forme de la run | 20 vagues, durée 20 s (vague 1) → 60 s (vague 20), interpolation linéaire. ~13 min de combat |
| Level-up | **Différé** : l'XP s'accumule pendant la vague, les choix se font à la fin de la vague |
| PV entre les vagues | Remis au max (`heal_between_waves = 1.0`, fraction des PV max, réglable) |
| Description des vagues | Courbes (vague 1 → vague N) + liste de vagues spéciales par numéro |
| Élite | Version renforcée d'un ennemi existant : PV ×5, XP ×10, taille ×1,6, contour doré |
| Fin du chrono | Ennemis et tirs ennemis restants disparaissent, gemmes ramassées automatiquement |
| Après la vague 20 | Écran de victoire (le boss remplacera la vague 20 en Phase 6) |
| Écran inter-vague | Minimal : « Vague X terminée » → level-ups en attente → bouton « Vague suivante » |

Hors périmètre : boutique, boss, objets, statistiques de vague, mode infini, menus.

## Données

### `StageData` (nouveau) — `src/waves/stage_data.gd`, instances dans `data/stages/`

Remplace le groupe « Spawning » de `RunConfig`. Accès : `ContentDB.get_def(&"stages", &"default")`, référencé par `RunConfig.stage`.

| Champ | Type | Valeur initiale | Rôle |
|---|---|---|---|
| `id` | StringName | `default` | |
| `wave_count` | int | 20 | Nombre de vagues |
| `duration_first` / `duration_last` | float | 20 / 60 | Durée (s) de la vague 1 et de la dernière |
| `spawn_rate_first` / `spawn_rate_last` | float | 1.5 / 20.0 | Ennemis par seconde |
| `hp_multiplier_first` / `hp_multiplier_last` | float | 1.0 / 5.0 | Multiplicateur de PV des ennemis |
| `spawn_pool` | Array[SpawnEntry] | grunt (1), runner (3), shooter (4), tank (6) | Entre parenthèses : `min_wave` |
| `max_enemies` | int | 400 | Inchangé |
| `spawn_distance` | float | 1150 | Inchangé |
| `heal_between_waves` | float | 1.0 | Fraction des PV max rendue entre les vagues |
| `elite_hp_multiplier` | float | 5.0 | |
| `elite_xp_multiplier` | float | 10.0 | |
| `elite_scale` | float | 1.6 | Taille visuelle et rayon de collision |
| `events` | Array[WaveEvent] | voir ci-dessous | Vagues spéciales |

Interpolation : `t = (wave - 1) / (wave_count - 1)` (t = 0 si `wave_count == 1`), `valeur = lerp(first, last, t)`. Fonctions statiques pures, testées.

Valeurs = premières estimations, à régler après playtest.

### `SpawnEntry` (modifié)

`min_time: float` → **`min_wave: int`** (vague à partir de laquelle l'ennemi peut apparaître). Pas de sauvegarde existante : renommage sans migration.

### `WaveEvent` (nouveau) — `src/waves/wave_event.gd`

Sous-ressource de `StageData` : une apparition scriptée.

| Champ | Type | Rôle |
|---|---|---|
| `wave` | int | Numéro de vague |
| `at_time` | float | Secondes après le début de la vague |
| `enemy` | EnemyData | Type d'ennemi |
| `count` | int | Nombre d'ennemis (apparaissent en cercle autour du joueur, à `spawn_distance`) |
| `elite` | bool | Élites ou non |

Événements initiaux : vague 5 → 40 runners à t=5 s ; vague 8 → 1 tank élite à t=10 s ; vague 10 → 2 shooters élites à t=10 s ; vague 12 → 60 grunts à t=5 s ; vague 15 → 3 tanks élites à t=10 s ; vague 18 → 80 runners à t=5 s + 2 tanks élites à t=20 s.

### `RunConfig` (modifié)

Garde : personnage, arène, progression, armes. Supprime le groupe « Spawning » (déplacé dans `StageData`). Ajoute `stage: StageData`. Les configs de debug (`src/debug/stress/stress_run.tres`) reçoivent un `StageData` de stress : 1 vague très longue (600 s), densité élevée, sans fin anticipée.

## Systèmes

### `WaveDirector` (nouveau) — `src/waves/wave_director.gd`, Node

Seul responsable du **chrono et de l'état** des vagues. Aucune apparition, aucune UI.

- État : `wave: int` (1-based), `time_left: float`, `in_wave: bool`.
- API : `setup(stage: StageData)`, `start_wave(n: int)`, `wave_duration(n) -> float` (statique via StageData), `is_last_wave() -> bool`.
- Signaux : `wave_started(wave: int)`, `wave_ended(wave: int)`, `run_won`.
- `_physics_process` : si `in_wave`, décrémente `time_left` ; à 0 → `in_wave = false`, émet `wave_ended(wave)` ; si c'était la dernière vague, émet aussi `run_won`.
- La vague suivante démarre uniquement sur appel de `start_wave(wave + 1)` par `Run` (après l'écran inter-vague).

### `SpawnDirector` (modifié)

Garde son rôle (quoi / où faire apparaître). Lit la vague en cours au lieu de `state.elapsed` :
- Débit et PV : `StageData.spawn_rate_at(wave)` et `hp_multiplier_at(wave)`.
- Éligibilité : `entry.min_wave <= wave`.
- Événements : à chaque vague, liste des `WaveEvent` de cette vague, déclenchés quand `wave_elapsed >= at_time` (une seule fois chacun).
- Ne fait rien hors vague (`WaveDirector.in_wave == false`).

### Élites

- `EnemyManager.spawn(data, pos, hp_multiplier, elite := false)` ; l'élite multiplie les PV par `elite_hp_multiplier` et le rayon par `elite_scale` (passés par `SpawnDirector` depuis `StageData`).
- `Enemy` : champ `elite: bool`, `scale` appliqué au nœud, texture élite.
- `EnemyData.get_elite_texture()` : texture précalculée une fois par type, contour doré (`EnemyArt.bake(data, outline_color, scale)`), même principe que l'ADR 0005.
- Signal `enemy_killed(data, position)` → **`enemy_killed(data, position, elite)`** ; `Run` multiplie l'XP par `elite_xp_multiplier`.
- Rayon max pour la grille spatiale : tank élite = 30 × 1,6 = 48 = `MAX_ENEMY_RADIUS` (OK, limite atteinte). Le test de données vérifie `radius × elite_scale <= MAX_ENEMY_RADIUS` pour chaque ennemi du stage.

### Fin de vague — orchestrée par `Run`

Sur `wave_ended(n)` :
1. `EnemyManager.clear_all()` : tous les ennemis vivants disparaissent avec un effet de dissolution (nombre d'effets plafonné) ; **pas** d'XP ni d'`enemy_killed`.
2. `EnemyProjectileManager.clear_all()`.
3. `PickupManager.collect_all()` : toutes les gemmes sont ramassées instantanément → un seul `xp_collected(total)` → `Progression.add_xp`.
4. `player.heal(max_hp * heal_between_waves)`.
5. Pause (`get_tree().paused = true`) et ouverture de `WaveEndScreen`.
Si `run_won` : à la place de 5, ouverture de l'écran de victoire.

### Level-up différé

- `Progression` inchangé : la file `pending_level_ups` existe déjà.
- `Run._on_leveled_up` n'ouvre plus l'écran pendant la vague (il met seulement le HUD à jour).
- `WaveEndScreen` enchaîne `LevelUpScreen` tant que `pending_level_ups > 0` (logique existante `_offer_upgrades` / `_apply_offer` réutilisée), puis affiche « Vague suivante ».
- `auto_choose_upgrades` (tests, bots) continue de fonctionner : choix automatiques puis vague suivante automatique.

## Interface

- **HUD** : « Vague 3/20 » + compte à rebours de la vague (remplace le temps total) ; badge « +N » à côté du niveau quand `pending_level_ups > 0`.
- **`WaveEndScreen`** (nouveau, `src/ui/wave_end/`) : titre « Vague X terminée », bouton « Vague suivante » (focus clavier/manette), signal `next_wave_requested`. Pendant les choix de level-up, le bouton est caché.
- **Victoire** : `GameOverScreen.open(..., victory: bool)` — titre « Victoire » et couleur différente, même résumé (temps, niveau, ennemis tués + vague atteinte). Le résumé de défaite affiche aussi la vague atteinte.
- Nouvelles clés de traduction (en + fr) : `UI_WAVE`, `UI_WAVE_CLEARED`, `UI_NEXT_WAVE`, `UI_VICTORY`, `UI_WAVE_REACHED` (le badge « (+N) » n'a pas besoin de texte).

## Tests

- **Unitaires** : interpolation `StageData` (vague 1 = first, vague N = last, milieu, `wave_count = 1`) ; `WaveDirector` (décompte, `wave_ended`, `run_won` uniquement à la dernière, pas de redémarrage automatique) ; éligibilité `min_wave` ; déclenchement unique des `WaveEvent` ; élite (PV, rayon, XP) ; `clear_all` / `collect_all`.
- **Données** : `StageData` valides (`wave_count >= 1`, durées > 0, events dans `1..wave_count`, ennemis non nuls) ; clés de traduction en + fr.
- **Smoke** : run simulée sur un stage de test de 3 vagues courtes, `auto_choose_upgrades`, joueur invincible → `run_won` atteint, level-ups consommés, PV au max après chaque vague.
- **Performance** : stress test avec le `StageData` de stress, comparaison à ~200 FPS moyen / physique ~8 ms ; `clear_all` sur 400 ennemis sans pic visible (effets plafonnés).
- **Manuel (dev)** : ressenti du rythme, lisibilité des élites, durée totale, difficulté des vagues spéciales.

## Documentation

- ADR 0006 « Vagues : StageData, WaveDirector et level-up différé ».
- `docs/design/gdd.md` : roadmap (Phase 4 avant Phase 3, D14).
- `PROJECT_STATUS.md` : décisions, changements, prochaines étapes.

## Risques

- **Signal `enemy_killed` modifié** : tous les abonnés à adapter (Run, tests). Recherche exhaustive avant modification.
- **`RunConfig` réduit** : stress test, capture et tests utilisent ses champs de spawn → à migrer dans le même changement.
- **Pic de frame à la fin de vague** (400 ennemis libérés + effets) → effets plafonnés, mesuré au stress test.
