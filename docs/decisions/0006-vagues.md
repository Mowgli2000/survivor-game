# ADR 0006 — Vagues : StageData, WaveDirector et level-up différé

**Statut :** accepté (2026-10-02) — Phase 4 (design validé par le dev, spec `docs/superpowers/specs/2026-10-02-waves-design.md`)

## Résumé
Le spawn continu infini du prototype (débit croissant par minute dans `RunConfig`) est remplacé par une run de 20 vagues chronométrées décrites en données (`StageData`). Le chrono des vagues, l'apparition des ennemis et l'enchaînement de la run sont séparés en trois responsabilités.

## Compatibilité moteur
| Champ | Valeur |
|---|---|
| Moteur | Godot 4.7.2 (GDScript typé) |
| Domaine | Core / Scripting |
| Risque post-cutoff | Faible : `Node`, `Resource`, signaux, `Image`/`ImageTexture` uniquement |
| Vérification | Couverte par les tests GUT (unitaires, données, smoke) |

## Dépendances
| Champ | Valeur |
|---|---|
| Dépend de | ADR 0002 (entités en lot, pooling), ADR 0003 (données `.tres`), ADR 0005 (dégâts centralisés, sprites précalculés) |
| Permet | Phase 5 (boutique entre les vagues), Phase 6 (boss = vague finale) |

## Contexte
Playtest Phase 2 : partie de 15+ min sans structure. Le pilier du jeu (boutique entre les vagues, D2) exige des pauses. Décision D14 : les vagues passent avant les objets.

## Décisions
1. **`StageData`** (`data/stages/`) décrit une run : nombre de vagues, courbes linéaires vague 1 → vague N (durée, débit, PV des ennemis), pool d'ennemis avec `min_wave`, réglages des élites et du soin, liste de **`WaveEvent`** (apparitions scriptées : hordes, élites). `RunConfig` ne garde que personnage, arène, progression, armes et une référence `stage`.
2. **`WaveDirector`** ne gère que le chrono et l'état (`wave_started`, `wave_ended`, `run_won`). Il ne démarre jamais la vague suivante tout seul.
3. **`SpawnDirector`** garde son rôle (quoi / où) et lit la vague en cours ; il ne fait rien entre les vagues.
4. **`Run`** orchestre la fin de vague : `EnemyManager.clear_all()` (**sans XP ni `enemy_killed`**, effets plafonnés), `EnemyProjectileManager.clear_all()`, `PickupManager.collect_all()` (un seul `xp_collected`), soin (`heal_between_waves`), puis écran inter-vague.
5. **Level-up différé** : monter de niveau pendant une vague n'ouvre plus d'écran ; la file `pending_level_ups` est résolue à la fin de la vague. Le HUD montre le nombre en attente.
6. **Élites** = ennemi existant avec PV ×5, XP ×10, taille et rayon ×1,6, contour doré **précalculé une fois par type** (`EnemyData.get_elite_texture`, même principe que l'ADR 0005). Le signal devient `enemy_killed(data, position, elite)`.

## Alternatives écartées
- **Vague unique infinie (Vampire Survivors)** : pas de pause pour la boutique.
- **20 vagues écrites à la main** : long à régler ; une seule valeur doit pouvoir changer la difficulté globale.
- **Spawn et chrono dans un seul système** : mélange deux raisons de changer, plus dur à tester.
- **Level-up immédiat** : interrompt l'action et sépare les décisions de build de la future boutique.

## Mesures (stress test, même machine, même session)
| Version | FPS moyen | FPS min | Physique |
|---|---|---|---|
| Avant (2378b06) | 190–191 | 146–150 | 8,6–9,0 ms |
| Vagues | 180–192 | 130–138 | 8,4–9,3 ms |

Moyenne dans le bruit de mesure ; FPS minimum ~10 % plus bas, à surveiller. Nettoyage de 500 ennemis en une frame : pas de gel visible (effets limités à 40).

## Conséquences
- Ajouter ou régler une run = éditer un `.tres` ; un test de données vérifie qu'aucun événement n'est placé après la fin de sa vague et qu'aucun élite ne dépasse `MAX_ENEMY_RADIUS` (48).
- La boutique (Phase 5) s'insère dans l'écran inter-vague ; le boss (Phase 6) remplacera la dernière vague.
- `state.elapsed` ne compte que le temps passé en vague.
- Les outils de debug utilisent un `StageData` de stress (1 vague de 600 s) ; `capture.tscn` gagne `--waveend`.
