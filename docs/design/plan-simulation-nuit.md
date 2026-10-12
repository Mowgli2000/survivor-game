# Plan de simulation de nuit (à lancer sur « go nuit » du dev)

Branche à part (worktree `../sg_night`, branche `sim/<date>`), rapport le matin. Simulateur réel : ADR 0019,
`python tools/balance/run_balance.py`. **6 workers maximum** (14 workers ont saturé les 16 Go de RAM le 2026-10-12 et la
tâche a été tuée). Fermer Godot, navigateur et jeu avant de dormir. Les cibles viennent de `notes.md` (le dev), les dangers
« 1 à 6 » du jeu sont les sceaux 0 à 5 du simulateur.

## Cibles (notes.md, hypothèses de départ)
- Taux de victoire par danger 1 à 6 : 65-75 / 55-65 / 45-55 / 35-45 / 25-35 / 15-25 %, mesurés sur toutes les parties.
- Mode infini : vagues 21-25 progressif ; 26-30 les builds moyens échouent ; 31-35 extrême ; 36-40 builds très efficaces ;
  41-50 zone de records ; 51+ sans limite imposée. Mesurer médiane, P10, P90 et records, pas la moyenne seule.

## Profils de joueurs (politiques existantes de `balance_policy.gd`)
`random` = débutant · `family`/`economy` = moyen · `dps`/`zone`/`tank` = expérimenté/optimisé. Les cibles de victoire
s'appliquent au mélange, pas au seul bot `dps` (mesure du 2026-10-12 avec `dps` : 100/93/86/79/71/64 %, trop haut, 14 parties par danger).

## Nuit type (≈ 6-8 h avec 6 workers)
1. Mesure de départ : `--characters all --seals 0-5 --weapons first --policies random,family,dps --seeds 3` (marge d'erreur à chiffrer).
2. Infini : `--endless 70 --seals 0-5 --policies family,dps` (plafond relevé pour voir où les bots meurent réellement).
3. Armes : taux de victoire et dégâts par arme de départ (`report.py`).
Le mode `--static` est laissé de côté (décision du dev, 2026-10-12).

## Le jour
Itérer avec le simulateur rapide `balance_fast.tscn` (millisecondes par partie), un petit nombre de paramètres à la fois,
mêmes seeds avant/après. Les nuits servent à confirmer avec des parties réelles. Aucune valeur de données n'est modifiée
sans accord du dev.
