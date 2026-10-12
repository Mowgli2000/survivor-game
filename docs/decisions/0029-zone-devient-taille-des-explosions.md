# 0029 — La Zone devient « Taille des explosions »

Date : 2026-10-12 · Statut : accepté (choix du dev, valeurs laissées à Claude)

## Contexte
La stat Zone (`StatIds.AREA`) agrandissait les coups de mêlée, la largeur des faisceaux, les météores, les explosions et les lames en orbite. Avec les animations peintes (12 à 32 images) qui grossissent avec elle, une Zone haute remplissait l'écran (bruit visuel, retour du dev). Brotato n'a pas de stat Zone : la mêlée y grandit avec la Portée, et « Explosion Size » est un bonus d'objets qui ne touche que les explosions.

## Décision
- `area` (id inchangé : objets, persos, sauvegardes) ne touche plus que les **explosions** (`ProjectileShooterBehavior`) et les **impacts de météores** (`StrikeBehavior`). Le texte devient « Taille des explosions » (`STAT_AREA`) ; la taille propre d'une arme (carte de boutique, bonus de rang) s'appelle `STAT_WEAPON_SIZE`.
- **Mêlée** : le rayon du coup et la taille de l'effet = `WeaponStats.area` (qui monte avec le rang) x `MeleeArcBehavior.reach_multiplier` : la Portée compte aux **3/4** (`RANGE_SHARE` 0,75, avant 0,5) et le multiplicateur est **plafonné à x1,6** (`REACH_CAP`). Le temps de recharge ne change pas (pas de malus de recharge : le plafond et les trois quarts suffisent).
- **Faisceaux** : largeur = `WeaponStats.area` (fixe par arme, monte avec le rang) ; longueur = portée x Portée, plafonnée à x1,6.
- **Lames d'ombre** : taille fixe (la stat ne s'applique plus).
- `CombatMath.reach_scale(raw, share, cap)` est la fonction commune.
- Données : `plasma_ring` (+20 % Zone) -> +15 % Portée ; `eternal_frost` (+15 % Zone) -> +12 % Portée ; Épéiste : bonus de Zone +10 % retiré, malus de Portée -25 % adouci à -10 % (rayon de coup net 0,925 contre 0,96 avant). Restent en « Taille des explosions » : Poudre noire, Pendentif de mana, famille Alchimie, Mage, amélioration Amplitude (peu utile hors build explosif : à revoir).
- Simulateur (`wave_sim`, `balance_bot`) aligné sur les nouvelles règles.

## Conséquences
- Équilibre de la mêlée et des faisceaux changé : **nuit de simulation avant/après à faire** (cibles de `notes.md`), puis ajustement des valeurs ci-dessus.
- Le nombre maximal de cibles d'une attaque de zone (`EnemyManager.area_targets_for`) suit toujours la stat `area` : un coup de mêlée ne grossit plus ce plafond.
- Les anciennes sauvegardes ne contiennent pas de statistiques de run : rien à migrer.
