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

## Plan complet de la nuit (réécrit à la demande du dev)
**Durée de la simulation : environ 6 h** (estimation d'après la nuit précédente : 84 parties normales en 54 min, 21 parties infinies en 50 min). Les phases
s'enchaînent ; après la phase 3 (environ 4 h) les résultats principaux sont déjà exploitables. Je n'agis pas pendant la simulation (CPU et RAM saturés) ;
le dernier travail est le rapport, déclenché à la fin de la dernière phase.

### Avant de lancer la simulation (travail de rangement, sans Godot sauf la vérification)
1. **Inventaire** de la racine et des gros dossiers (taille, versionné ou non, référencé par le projet ou non).
2. **Dossier `a_supprimer/`** (avec `.gdignore`, pour que Godot l'ignore) : on y **déplace** (rien n'est supprimé, tout se restaure) :
   les images et vidéos de référence du dev à la racine (71 `image-*.png`, `image.png`, `téléchargement.png`, `sheet.png`, `videoframe_54.png`,
   `bg_gate_v2*.png`, `danger_6.png`, deux `efbd6a3b-*.png`, `julie-lafeuille-*.jpg`, 2 `.gif`, 3 `.mp4`) et `interfacetest/`. Les déplacements de fichiers versionnés se font avec `git mv`.
3. **Suppression réelle** : seulement ce qui est certainement inutile : `bash.exe.stackdump` et les dossiers vides. Rien d'autre sans ton accord.
4. **Assets inutilisés** (`assets/`, `assets_src/`, `art_source/`, `art_tests/` : plus de 3 Go au total) : un script Python liste les fichiers qu'aucun `.tres`, `.tscn`, `.gd`, outil ou `.import` ne référence, en traitant les chemins construits par le code (icônes par id d'arme, sprites par id d'ennemi) comme utilisés. Résultat : `a_supprimer/ORPHELINS.md` (liste, tailles). **Aucun déplacement avant que tu aies lu la liste** : les faux positifs sont possibles.
5. **Vérification** : réimport Godot, 643 tests, compilation des scripts, une capture du menu. Commit `chore:` et poussée sur la branche.
6. **Ce que je ne touche pas** : `CLAUDE.md`, `PROJECT_STATUS.md`, `notes.md`, `project.godot`, `docs/`, `data/`, `src/`, `tests/`, `tools/`, `addons/`, configuration des outils (`.claude/`, `design/`, `project.yaml`, `.superpowers`, `production/`), `art_showcase/` (site de référence versionné).

### Pendant la nuit
7. Lancement de `balance_reports/night3.sh` (4 phases, 6 workers) dans `../sg_night2`.
8. À la fin : génération des rapports (taux de victoire par danger avec intervalle de confiance, tableau par arme, profils, infini avec médiane, 10e et 90e percentile), comparaison avec les cibles de `notes.md`, sans modifier aucune valeur.

### Pas fait cette nuit
Mode coop (le simulateur ne sait pas lancer deux joueurs : outil à écrire en journée), page Steam, nouvelles animations.
