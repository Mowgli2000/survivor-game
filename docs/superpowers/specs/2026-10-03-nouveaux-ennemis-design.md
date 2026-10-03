# Étape 5b — Nouveaux ennemis (design + plan)

Date : 2026-10-03 · Statut : choix validés par le dev (D46 : chargeur, kamikaze, pondeur)

## Objectif
Varier les menaces avant d'ajouter du contenu : forcer le joueur à bouger autrement que « fuir en cercle ».

## Comportements (dans la boucle d'`EnemyManager`, pas de nœud par ennemi)
`EnemyData.Movement` gagne 3 valeurs, avec leurs réglages dans le groupe « Special » d'`EnemyData` :

| Type | Comportement | Réglages |
|---|---|---|
| `CHARGER` | Approche ; à portée (`charge_range`), s'arrête et annonce la ruée (ligne d'alerte, `charge_windup`), puis fonce tout droit (`charge_speed`, `charge_duration`) ; recharge (`charge_cooldown`) | Réutilise `forced_velocity` / `forced_time` (ADR 0014) |
| `KAMIKAZE` | Rapide ; près du joueur (`fuse_range`), s'arrête et clignote (`fuse_time`, cercle d'alerte), puis explose : dégâts au joueur dans `blast_radius` (× multiplicateur de dégâts de la vague), disparaît **sans XP** (le tuer avant est récompensé) | `fuse_range`, `fuse_time`, `blast_radius`, `blast_damage` |
| `SPAWNER` | Lent ; toutes les `spawn_cooldown` s, fait apparaître `spawn_count` `spawn_enemy` autour d'elle, avec les mêmes multiplicateurs de PV/dégâts qu'elle ; respecte le plafond d'ennemis (`EnemyManager.spawn_cap`, réglé par `Run` sur `max_enemies`) | `spawn_enemy`, `spawn_count`, `spawn_cooldown` |

État par ennemi : `special_timer`, `special_state`, `special_dir` (réinitialisés au recyclage).

## Contenu
- **Chargeur** (`charger`, dès la vague 7, poids 0,6) : 22 PV, vitesse 90, portée 380, annonce 0,6 s, ruée 700 px/s pendant 0,45 s, recharge 2,5 s. Sprite du colosse teinté rouge.
- **Kamikaze** (`kamikaze`, dès la vague 5, poids 0,8) : 8 PV, vitesse 170, mèche 0,55 s à 70 px, explosion 110 px / 18 dégâts. Sprite du coureur teinté orange.
- **Pondeuse** (`spawner`, dès la vague 9, poids 0,3) : 45 PV, vitesse 55, 3 coureurs toutes les 4 s. Sprite du rôdeur teinté vert, plus grande.

## Tests
- Chargeur : annonce (arrêt) puis vitesse forcée vers le joueur, puis recharge.
- Kamikaze : explose après la mèche, blesse le joueur à portée, pas hors portée, meurt sans `enemy_killed`.
- Pondeuse : apparition après le délai, multiplicateur de PV transmis, plafond respecté.
- Données : réglages cohérents selon le type (portées, délais > 0, `spawn_enemy` défini).
- Stress test : ≥ 100 FPS (D37).
