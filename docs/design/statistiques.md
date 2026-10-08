# Statistiques du joueur : ce que chacune fait

Récapitulatif écrit le 2026-10-08 d'après le code (`src/core/stat_ids.gd`, `src/weapons/behaviors/`, `src/items/item_effects.gd`, `src/pickups/`, `src/player/player.gd`). Les stats viennent du personnage, des cartes de niveau, des objets et des familles d'armes ; elles s'additionnent pour **tout le joueur** (pas par arme).

Les armes ont trois types de comportement :
- **Mêlée** (`melee_arc`) : katana, lame runique, rapière, lance, faux, hache, marteau, Crocs du venin.
- **Projectiles** (`projectile_shooter`) : arcs, arbalètes, bâtons, fioles, bombes, grenades, shuriken, fronde…
- **Faisceaux** (`beam`) : pistolet laser, sceptre de givre. **Frappe du ciel** (`strike`) : grimoire de météores (compte comme arme à distance).

## Défense et survie (s'appliquent au joueur, pas aux armes)
| Stat | Effet |
|---|---|
| **PV max** | Points de vie. Gagner des PV max soigne du même montant. |
| **Régénération** | PV rendus par seconde. |
| **Armure** | Réduit les dégâts reçus avec rendements décroissants : 10 = -9 %, 100 = -50 %. Un coup fait toujours au moins 1. |
| **Esquive** | Chance d'ignorer complètement un coup (plafond 60 %). |
| **Vitesse de déplacement** | Pixels par seconde. |
| **Vol de vie** | Chance par dégât infligé de rendre 1 PV (limité à 10 PV par seconde). |

## Attaque (toutes les armes)
| Stat | Effet |
|---|---|
| **Dégâts** | Multiplicateur de tous les dégâts d'armes (100 % = normal). |
| **Vitesse d'attaque** | Réduit le temps entre deux attaques de chaque arme. |
| **Chance de critique** | S'ajoute à la chance de critique de l'arme. |
| **Dégâts critiques** | Multiplicateur d'un coup critique (de base ×1,5). |
| **Recul** | Force avec laquelle les ennemis sont repoussés (toutes les armes). |

## Portée, zone, projectiles : dépendent du type d'arme
| Stat | Mêlée | Projectiles | Faisceaux | Frappe du ciel |
|---|---|---|---|---|
| **Portée** | Distance à laquelle l'arme se déclenche **et** longueur du coup, mais à **moitié** (+20 % de portée = +10 % d'allonge). | Distance de détection de la cible et distance de vol. | Longueur du faisceau. | Distance de la zone d'impact. |
| **Zone** | **Taille du coup** : rayon de l'arc (le « disque » dans lequel les ennemis sont touchés). | Rayon des **explosions** (bombes, fioles, roquettes). Sans effet sur un projectile sans explosion. | **Largeur** du faisceau. | Rayon de chaque impact. |
| **Projectiles** | Nombre de coups : 1 de plus = un coup dans une autre direction (2 = devant et derrière). | Nombre de projectiles par tir (en éventail). | Nombre de faisceaux. | Nombre de météores. |
| **Vitesse des projectiles** | Aucun effet. | Vitesse de vol. | Aucun effet. | Aucun effet. |
| **Perforation** | Aucun effet. | Nombre d'ennemis traversés en plus. | Aucun effet (le faisceau touche déjà tout sur son passage). | Aucun effet. |

Autrement dit : **Projectiles, Vitesse des projectiles et Perforation sont pensés pour les armes à distance**. Pour une arme de mêlée, seul « Projectiles » fait quelque chose (coups supplémentaires). La **Zone** est la stat clé de la mêlée : elle agrandit le coup. La **Portée** allonge un peu le coup et la distance de déclenchement.

## Économie et ramassage
| Stat | Effet |
|---|---|
| **Portée de ramassage** | Distance à laquelle cristaux d'XP et pièces sont aspirés vers toi. |
| **Récolte** | Matériaux gagnés **à la fin de chaque vague**, +5 % par vague déjà jouée (plus la partie avance, plus ça rapporte). |
| **Chance** | +1 % par point sur la rareté des cartes de la boutique **et** sur les chances d'effet des objets (par exemple « 8 % de chance de… »). |

## À savoir
- Les stats ne sont **pas liées à une arme** : elles valent pour toutes les armes que tu possèdes, chacune selon son type (tableau ci-dessus).
- Les **familles d'armes** (Lames, Magie, Alchimie…) donnent des bonus quand tu possèdes plusieurs armes de la même famille (visibles dans le panneau de stats, section « Familles »).
- Les bornes : Zone plafonnée à +200 %, Projectiles à +5, Esquive à 60 %, Vol de vie à 100 %.
