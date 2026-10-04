# Équilibrage de nuit — 2026-10-05

**Branche :** `balance/overnight` (rien n'est fusionné dans `develop` sans ton accord).
**Rapports :** `balance_reports/calib/report.html` (avant) et `balance_reports/after/report.html` (après), à ouvrir dans le navigateur.

## Ton retour de départ
« Vagues 1-10 correctes ; dès la vague 10-12, ça devient exponentiellement trop facile : on achète trop de choses et on améliore le perso trop vite. »

## Ce que les mesures ont montré (vraies parties, bot « joueur correct »)
1. **Le bot ne perdait plus aucun PV à partir de la vague 9**, à tous les sceaux. Il gagnait 100 % des parties en Cuivre et 71 % en Astral.
2. **La puissance explosait en fin de partie** : DPS ×30 à ×60 entre la vague 10 et la vague 19. Les causes, dans l'ordre :
   - **projectiles bonus** jusqu'à +14 à +27. Chaque +1 ajoute un tir à **toutes** les armes, et un coup de plus aux armes de mêlée. Source : la carte de level-up « Tir multiple », qui donne jusqu'à +3 par carte au rang IV, sans plafond ;
   - **niveau 60** atteint en vague 20, soit 60 cartes de stats ;
   - **dégâts critiques** jusqu'à ×5.
3. **Dans les foules denses de fin de partie, les armes de zone touchent tout** (mêlée, explosions, météores) : plus il y a de monstres, plus chaque coup en tue. Gonfler les PV des monstres (même ×70 en vague 20) ne changeait rien : rien n'atteignait le joueur.
4. **Le simulateur rapide** (calcul par vague) a été calé sur 109 vraies parties, avec 11 points d'écart en moyenne. Il a servi à explorer des centaines de réglages en quelques minutes, mais il **sous-estime** la puissance réelle en fin de partie. Les choix finaux ont donc été vérifiés en **vraies parties**.

## Changements proposés (tous sur la branche)
| # | Changement | Avant | Après | Fichier |
|---|---|---|---|---|
| 1 | Plafond des projectiles bonus | aucun | **+3** | `src/core/stat_ids.gd` (BOUNDS) |
| 2 | Plafond des dégâts critiques | aucun | **×3** | `src/core/stat_ids.gd` |
| 3 | **Ennemis touchés au maximum par un coup de zone** (mêlée, explosion, météore) | tous | **10** | `src/enemies/enemy_manager.gd` (`area_max_targets`) |
| 4 | Courbe d'XP (exposant) | 1,42 | **1,5** (niveau ~27 en vague 10, ~50 en vague 20) | `data/runs/default.tres` |
| 5 | PV des ennemis en vague 20 | ×14 | **×70**, vague 10 inchangée (courbe 1,8 → 4,03) | `data/stages/default.tres` |
| 6 | Matériaux par XP en vague 20 | 0,35 | **0,25**, vague 10 inchangée (nouveau réglage `material_rate_curve` = 1,68) | `data/stages/default.tres` |
| 7 | Hausse des prix après la vague 10 | 0 | **+15 % par vague** (nouveau réglage `late_price_growth_per_wave`) | `data/shop/default.tres` |
| 8 | Sceaux (PV et dégâts ennemis ; apparitions) | Fer 1 · Argent 1,15 · Or 1,15/1,15 · Obsidienne 1,3/1,15 · Astral 1,3/1,15 | **Fer 1,15 · Argent 1,3 · Or 1,45/1,15 · Obsidienne 1,6/1,2 · Astral 1,75/1,25** (+ double boss) | `data/difficulties/` |
| 9 | Mage | +8 % dégâts par arme de Magie, armure −2 | **+12 %, armure −1** | `data/characters/mage.tres` |
| 10 | Assassin | PV max −30 % | **−15 %** | `data/characters/hero.tres` |
| 11 | Armes de Magie (faibles dans la foule) | — | **Orbe** : perce 1 · **Bâton de feu** : explosion 45 px · **Bâton de foudre** : 4 rebonds (au lieu de 3) | `data/weapons/` |

Le n° 3 est un **choix de design** à valider en priorité : c'est lui qui rend la fin de partie dangereuse.

## Résultats (vraies parties, bot « joueur correct »)
| Sceau | Avant | Après | Cible |
|---|---|---|---|
| Cuivre | 100 % | **86 %** | 80 % |
| Or | — | **50 %** | 44 % |
| Astral | 71 % | **21 %** | 25 % |

- **Vagues 1-12 en Cuivre : inchangées** (mêmes taux de tués, quasi aucun dégât). Ce que tu trouvais bien est conservé.
- **Vagues 14-20 en Cuivre** : le bot perd 30 % puis 70 % puis plus de 100 % de ses PV par vague (il survit en bougeant et en se soignant). Fini le « plus besoin de bouger ».
- DPS de fin de partie : ~2 700 en vague 19 (contre 22 000 à 110 000).
- Classes : de 2 à 4 victoires sur 6 parties chacune. L'Épéiste (100 % mêlée) est la plus touchée par le plafond de zone.
- Le joueur « faible » (achats au hasard) ne gagne plus en Cuivre et meurt vers les vagues 6 à 10. C'est plus dur pour un joueur qui achète au hasard.
- Stress test : 94 FPS (le plafond de zone allège aussi le calcul).

## Limites
- Un bot ne joue pas comme toi. **Ton playtest sur la branche est le juge final.**
- 6 à 14 vraies parties par case : environ ±15-20 points de bruit.
- Le mode infini n'a pas été re-mesuré.

## Pour tester
1. `git checkout balance/overnight`, puis lance le jeu.
2. Fais une partie en Cuivre avec une classe de mêlée (Épéiste ou Berserker), puis une avec l'Archer ou le Mage.
3. Dis-moi si tu valides, en bloc ou point par point (par exemple : « oui sauf le 3 »).
   - Je fusionne ce que tu valides dans `develop`.
   - Je retire le reste.
   - Je refais une vérification.
4. Pour revenir à la version d'avant : `git checkout develop`.
