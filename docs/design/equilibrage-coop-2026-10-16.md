# Équilibrage du coop (2 joueurs), 2026-10-16

Méthode : par le calcul, à partir des courbes solo actuelles (que le dev trouve correctes). Aucune simulation de difficulté : le bot ne joue pas comme un humain (voir la mémoire « balance-human-playtest-first »). Les valeurs sont donc à valider en jeu à deux, manettes en main.

## Ce que le coop change aujourd'hui (`RunConfig`, `StageData.apply_coop`)
| Réglage | Solo | Coop avant | Coop maintenant |
|---|---|---|---|
| Cadence d'apparition | x1 | x1,5 | x1,5 (inchangé) |
| PV des ennemis | x1 | x1,2 | x1,1 |
| PV des boss et mini-boss (en plus) | x1 | x1 | x1,6 |
| Or par ennemi tué | référence | amputé (voir plus bas) | comme en solo |
| Plafond d'ennemis | 650 | 650 | 650 (performance) |

Chaque joueur a son portefeuille, son XP et sa boutique. Les butins appartiennent à celui qui a fait le kill.

## Problème trouvé : l'or par joueur s'effondrait en coop
Le taux d'or par ennemi baisse quand la cadence d'apparition dépasse 8 par seconde (`material_decoupling` 0,7), pour que les hordes tardives ne noient pas le joueur d'or. En coop, la cadence x1,5 déclenchait cette baisse comme si c'était une horde solo : l'équipe gagnait peu plus que seule (x1,13) et **chaque joueur environ 56 % de l'or d'un joueur solo** (alors que chacun affrontait 90 % de la pression solo). Les builds coop étaient donc nettement plus faibles que les builds solo.

Revenu d'or (solo = 1) :

| Vague | Équipe avant | Par joueur avant | Équipe maintenant | Par joueur maintenant |
|---|---|---|---|---|
| 3 | 1,50 | 0,75 | 1,50 | 0,75 |
| 6 à 20 | 1,13 | 0,56 | 1,50 | 0,75 |

Correction : le calcul de la baisse d'or regarde la cadence solo (`StageData.coop_spawn_factor`). Chaque ennemi lâche autant qu'en solo, donc l'équipe gagne x1,5 et chaque joueur 75 %.

## Pression par joueur (estimation, pas une mesure)
Hypothèse : la puissance d'un joueur croît comme son revenu puissance 0,7 (à confirmer en jeu).
- Avant : PV à tuer par joueur 1,5 x 1,2 / 2 = 0,90 ; puissance 0,56^0,7 = 0,67 ; pression 0,90 / 0,67 = 1,34 (34 % plus dur que le solo).
- Maintenant : 1,5 x 1,1 / 2 = 0,825 ; puissance 0,75^0,7 = 0,82 ; pression 1,0 (équivalent au solo).
- Les ennemis se répartissent entre deux joueurs : chacun reçoit moins de coups de contact. Cela joue en faveur du coop et n'est pas compté ci-dessus : le coop devrait être un peu plus facile que le solo par joueur. À confirmer en jeu avant de durcir.

## Boss en coop
À deux, l'équipe tue un boss environ deux fois plus vite. Les PV des boss et mini-boss sont multipliés par 1,6 (en plus de x1,1) : 1,76 au total. Combat de boss : voir `docs/design/` (duel, trois barres), même règle qu'en solo.

## Ce qui n'a PAS été changé
- Aucune valeur solo.
- XP : chaque joueur reçoit l'XP des ennemis qu'il tue : 75 % du solo par joueur. Les niveaux montent un peu plus lentement. À regarder en jeu avant de toucher.
- Élites et événements (hordes de 60 à 80, 2 ou 3 élites) : ne sont pas multipliés en coop. Avec deux joueurs ils pèsent moins. Si le coop est trop facile aux vagues 12-20, c'est le premier levier.
- Pas de ressuscitation en cours de vague : un joueur mort attend la vague suivante (le jeu s'arrête quand les deux sont morts).

## À tester à deux (à noter dans `notes.md`)
1. Or et niveaux comparés au solo à la vague 10 (devrait être proche de 75 %).
2. Danger de la vague 12 à 20 : plus facile, pareil ou plus dur qu'en solo ?
3. Combat de boss (vague 10 et 20) : durée, lisibilité avec deux joueurs, PV du boss.
4. Fluidité (stress test coop) : deux joueurs = deux fois plus d'armes et de projectiles.
