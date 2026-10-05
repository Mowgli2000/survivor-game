# Équilibrage v2 — 2026-10-05 (ta demande : « ne pas trop nerf le perso »)

**Branche :** `balance/overnight` (v2 par-dessus la proposition de nuit). À jouer sur la branche `playtest/2026-10-05`, qui ajoute les récompenses de sceaux.

## Ta demande
Pas de plafond trop dur (projectiles +5 plutôt que +3, critiques et coups de zone libres si possible). Plutôt **freiner les matériaux et l'XP**, et faire un mélange si nécessaire.

## Ce que les vraies parties ont montré
| Essai (Cuivre, joueur correct) | Résultat |
|---|---|
| v2a : plafonds assouplis, matériaux et XP freinés, PV ×70 en vague 20 | 100 % de victoires, **aucun dégât après la vague 12** : freiner l'économie seule ne suffit pas |
| v2b : idem + au plus 20 ennemis par coup de zone | idem, aucun dégât en fin de partie |
| v2c : idem + **PV ×160** en vague 20 | **le bot doit bouger** : 34 à 75 % de PV perdus par vague de 15 à 19, puis plus de 100 % en vague 20 |
| v2d : PV ×200 | trop dur pour les sceaux élevés (Or 29 %, Astral 14 %) |

Conclusion : tant que les armes de zone touchent une grande partie de la foule, ce sont **les PV des monstres de fin de partie** qui recréent le danger. C'est ce que tu disais : « j'aime avoir des stats cheatées, mais alors il faut plus de PV ou d'ennemis ».

## Réglage v2 retenu (différences avec la version actuelle de `develop`)
| # | Changement | `develop` | v2 |
|---|---|---|---|
| 1 | Projectiles bonus | sans limite | **+5 max** |
| 2 | Dégâts critiques | sans limite | **sans limite** (inchangé) |
| 3 | Ennemis touchés par un coup de zone | tous | **20 max** (seulement dans les foules très denses) |
| 4 | XP (exposant) | 1,42 | **1,65** : niveau ~23 en vague 10 (au lieu de 30), ~43 en vague 19 (au lieu de 60) |
| 5 | Matériaux par XP en vague 20 | 0,35 | **0,15**, vague 8 inchangée (courbe 1,85) |
| 6 | Hausse des prix après la vague 10 | 0 | **+15 % par vague** |
| 7 | PV des ennemis en vague 20 | ×14 | **×160**, vague 10 inchangée (courbe 5,15 : la hausse vient surtout après la vague 13) |
| 8 | Sceaux (PV et dégâts ; apparitions) | Fer 1 · Argent 1,15 · Or 1,15/1,15 · Obs. 1,3/1,15 · Astral 1,3/1,15 | **Fer 1,15 · Argent 1,3 · Or 1,5/1,2 · Obs. 1,62/1,22 · Astral 1,75/1,25** |
| 9 | Mage / Assassin / armes de Magie | — | inchangés depuis la nuit : Mage +12 % par arme de Magie, Assassin −15 % PV, Orbe perce 1, Bâton de feu explose (45 px), Bâton de foudre 4 rebonds |

## Résultats (vraies parties, bot « joueur correct », 14 parties par sceau)
| Sceau | `develop` (avant) | v2 | Cible |
|---|---|---|---|
| Cuivre | 100 % | **100 %** | 80 % |
| Or | — | **50 %** | 44 % |
| Astral | 71 % | **36 %** | 25 % |

PV perdus par vague en Cuivre (médiane) :

| Vagues | `develop` | v2 |
|---|---|---|
| 1-7 | 0 % | 0-2 % (inchangé) |
| 8-14 | 0-17 % | 7-19 % |
| 15-19 | 0 % | **34 à 77 %** |
| 20 | 0 % | **116 %** (il faut bouger et se soigner) |

- Niveau atteint : ~23 en vague 10 (au lieu de 30) et ~43 en vague 19 (au lieu de 60).
- DPS en vague 19 : ~6 000 à 20 000 (au lieu de 22 000 à 110 000).

## À savoir
- Bruit : ±15-20 points par case (14 parties).
- **Mode infini non re-mesuré** : il part de la vague 20 (désormais ×160 PV) et ajoute +25 % par vague. Il sera nettement plus dur qu'avant ; à essayer.
- Un joueur qui achète au hasard ne gagne plus en Cuivre (il meurt vers la vague 9).
- Les nombres de dégâts deviennent grands en fin de partie (PV ×160) : voulu (« stats cheatées »).
