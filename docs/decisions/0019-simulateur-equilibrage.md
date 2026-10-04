# ADR 0019 — Simulateur d'équilibrage

**Statut :** accepté (2026-10-04) — demande du dev, approche « les deux », cible Brotato, rapport HTML, propositions à valider

## Contexte
L'équilibrage est la priorité du dev. Tester à la main toutes les classes, armes, sceaux et achats est impossible. Le dev veut tester le jeu « de A à Z grâce aux stats », sans affichage.

## Décisions
1. **Vraies parties simulées** (`src/debug/balance/balance_sim.tscn`) : une partie complète du vrai jeu, sans affichage et en accéléré (`--fixed-fps 60` : le moteur calcule aussi vite que le processeur le permet). Un bot joue :
   - **déplacement** (`BalanceBot`) : se bat à la portée de ses armes et tourne autour de sa cible, esquive les tirs, fuit s'il est encerclé ou sous 35 % de PV, évite les murs ;
   - **build** (`BalancePolicy`) : cartes de level-up et boutique **par l'API réelle** (`Shop.buy`, `merge_weapon`, `reroll`). Stratégies `dps`, `tank`, `family`, `economy` (= « joueur correct ») et `random` (= « joueur faible »).
   La partie écrit un JSON par vague : tués / apparus, PV perdus, PV mini, niveau, matériaux, dépense en boutique, armes et rangs, objets, DPS théorique, stats.
2. **Crochets dans `Run`** (outils seulement) : `bot_policy` (choix de cartes et tour de boutique quand `auto_choose_upgrades`), `record_profile = false` (le profil du joueur n'est jamais modifié), `unlock_all` (tout le contenu est testé). `EnemyProjectileManager.active_projectiles()` en lecture pour le bot.
3. **Modèle rapide** (`balance_model.tscn`) : sans combat, en quelques secondes, chaque arme à chaque rang : DPS écrit, cibles touchées dans une foule dense, DPS de foule, DPS de foule par matériau. Repère les armes hors norme ; les vraies parties confirment.
4. **Lanceur** `tools/balance/run_balance.py` : matrice classes × armes de départ × sceaux × stratégies × tirages, parties en parallèle (cœurs − 2), puis **rapport** `tools/balance/report.py` → `balance_reports/<nom>/report.html` (graphiques SVG intégrés, aucune dépendance) + `summary.json`. Les rapports ne sont pas versionnés.
5. **Cibles** (dev, logique Brotato) : Cuivre ~80 % de victoires pour un joueur correct, chaque sceau plus dur, Astral ~20-30 % ; pas de « plus besoin de bouger » avant la vague 18-19 ; classes à ±10 points les unes des autres ; l'infini finit par tuer vers 30-40.

6. **Simulateur rapide par vague** (`WaveSim`, `balance_fast.tscn`), ajouté après l'essai des vraies parties (≈ 4-5 min par partie en parallèle, jugé trop long par le dev) : combat remplacé par un calcul par vague, tout le reste est le vrai code (courbes et sceaux, stats, armes, fusions, familles, objets, cartes de level-up, boutique). Trajet des monstres (arrivée avant la fin du chrono), capacité de kill = DPS × ennemis touchés, dégâts subis selon la foule d'ennemis vivants (plafonnée comme en jeu). 4 coefficients dans `tools/balance/calibration.json`, réglés à la main sur 37 vraies parties (Berserker : joueur correct 80-100 % / simulé 100 % ; joueur faible 42 % de victoires, mort vers la vague 7 / simulé 48 %, vague 9). Quelques millisecondes par partie. Modes : matrice (`--out`, `--seeds`, `--policies`, `--characters`, `--params`), calibrage automatique (`--calibrate`, peu fiable : bords de grille) et comparaison d'une vraie partie (`--compare`).
7. **En pause** (2026-10-04) : le dev préfère d'abord donner son ressenti de jeu ; la matrice complète (8 400 parties) n'a pas encore été lancée.

## Conséquences
- Chaque changement d'équilibrage se vérifie par une nouvelle série et la comparaison des rapports avant / après.
- Un bot ne joue pas comme un humain : les chiffres servent à comparer (classes, sceaux, versions), calés sur les retours de playtest du dev.
- Effets spéciaux d'objets : valorisés par un bonus fixe dans la stratégie d'achat (non modélisés un par un).
- Coût : 1 à 3 minutes de calcul par partie ; ~250 parties ≈ 1 h avec 14 processus.
