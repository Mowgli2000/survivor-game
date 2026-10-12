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

## Nuit du 2026-10-12 au 13 (prête, à lancer sur « go nuit »)
Worktree `../sg_night2`, branche `sim/2026-10-13` (depuis `visual/projectiles-grille`, donc **avec tous les changements de la session** :
Zone -> Taille des explosions, mêlée à Portée 3/4 plafonnée x1,6, faisceaux à largeur fixe, durées d'effets par catégorie (les dégâts
arrivent plus tôt), Fronde animée, Lames d'ombre 2 lames puis +1 au rang III et dégâts 22). Script : `balance_reports/night3.sh` (6 workers).
Dossier commun `balance_reports/normal` : les phases réutilisent les parties déjà faites.
1. Toutes les armes de départ (26 combinaisons perso-arme), sceaux 0-5, bot `dps` : 156 parties, ~100 min.
2. Profils débutant (`random`) et moyen (`family`), première arme de chaque perso : 84 parties, ~55 min.
3. Deuxième graine pour les trois profils : 126 parties, ~80 min.
4. Mode infini jusqu'à la vague 70, sceaux 0 et 5, `family` et `dps` : 28 parties, ~110 min (estimation).
Total estimé : **~6 h**. Mesures de la nuit précédente : 84 parties normales en 54 min, 21 parties infinies (vague 40) en 50 min.
Avant de dormir : fermer Godot, le jeu, le navigateur (RAM : 16 Go, 6 workers). Le matin : rapport avec taux de victoire par danger,
intervalles de confiance, tableau par arme, comparaison avec la nuit précédente (parties `dps` identiques) et avec les cibles de `notes.md`.
Aucune valeur de données n'est modifiée sans accord du dev.
