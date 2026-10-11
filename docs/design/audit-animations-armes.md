# Audit des animations d'attaque par arme (2026-10-12)

Règle du dev : aucune animation d'attaque en image statique ou dessinée par code ; tout est peint par IA.
Un test (`test_every_weapon_has_a_painted_animation_for_its_attack`) garantit les animations de coup, de rayon, de chute, d'impact, d'explosion et de sol.

## Peint par IA, animé : OK
| Arme | Animations |
|---|---|
| Faux de guerre, Hache de guerre, Marteau, Épée flamboyante, Katana, Rapière, Lance, Crocs du venin, Lame runique | coup peint (12-24 images) |
| Sceptre de givre | cône peint (24 images) |
| Baguette de cristal | rayon peint (12 images) |
| Grimoire des météores | chute et impact peints (24 images chacun) |
| Lames d'ombre | boucle de la dague (12 images) |
| Bâton de feu | boule animée (12 images) + explosion unique (32 images) |
| Bâton de foudre | éclair animé (12 images) + impact + arc de chaîne peints |
| Bombe | bombe animée (12 images) + explosion unique (32 images) |
| Puits de gravité | sphère animée (12 images) + puits au sol (24) + effondrement (32) |
| Fiole de feu, de givre | explosion (32 images) + zone au sol (24) |
| Fiole explosive, Canon alchimique | explosion unique (32 images) |
| Arbalète lourde | impact peint + carreau planté animé (24 images) |
| Grenades à fragments | grenade animée (**6 images seulement**) + explosion (24 images) |

## Corps du projectile en vol : image IA FIXE (pas animée)
Flèche de l'Arc long, carreau de l'Arbalète lourde, fléchette de l'Arbalète à répétition, javelot, pierre de la Fronde, Shuriken (tourne par le code), Arc céleste (flèche), les trois fioles (tournent par le code), boulet du Canon alchimique, éclats de la grenade.
L'impact ou l'explosion à l'arrivée est peint et animé pour chacune.

## Restes dessinés par code
- arc électrique de chaîne quand l'écran contient plus de 40 effets (`Vfx.lightning` de repli) ;
- mort des monstres (pas une arme) ;
- tourner sur eux-mêmes des objets lancés (rotation d'une image IA).

## Pour tout animer
Il faut 12 images par corps de projectile (11 styles). La bande de projectiles est pleine (89/128 cellules, 8188/8192 px) : passer à un atlas en grille (ADR), puis 11 générations IA.
