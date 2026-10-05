# ADR 0020 — Pantin articulé des persos jouables

**Date :** 2026-10-05 · **Statut :** pilote (Épéiste), à valider par le dev avant les 6 autres persos

## Contexte
Les persos jouables n'étaient animés que par le code, par-dessus une image fixe : inclinaison, ondulation du manteau, poussière (D51). Pour la bande-annonce et la page Steam, il faut des membres qui bougent. D51 prévoyait un pantin articulé à partir de planches de pièces générées (`art_source/ai/rig/<perso>_parts.png`, fond transparent).

## Décision
- **Données** : `RigData` (`src/player/rig/rig_data.gd`), une ressource par perso (`assets/rigs/<id>.tres`) avec une texture qui contient toutes les pièces (`assets/rigs/<id>.png`, mipmaps). Par pièce : le rectangle dans la texture, l'articulation dans la pièce, l'articulation sur le corps au repos, et la pièce parente. Les tableaux sont dans l'ordre de dessin.
- **Fabrication** : `tools/art/make_rig.gd -- --id=<id>` lit `tools/art/rigs/<id>.json`, qui donne les points dans la planche : une graine par pièce, une coupe éventuelle (tête et buste se touchent), l'articulation, sa place sur le corps et la profondeur. Les pièces en miroir (bras, mains, jambes) ne sont décrites qu'une fois.
- **Affichage** : `CharacterRig` (Node2D, enfant du `Player`) crée un `Sprite2D` par pièce. Ce sont tous des enfants directs, dans l'ordre de dessin, et chaque pièce est posée par le code à chaque image : chacune tourne autour de son articulation et suit son parent. C'est sans coût notable, car il n'y a qu'un ou deux joueurs. Le flash de coup reçu passe par un seul matériau partagé.
- **Animations par le code** (comme `PlayerMotion`) : respiration au repos ; marche avec les jambes qui se lèvent tour à tour, les bras qui balancent, un rebond et la jupe qui ondule ; coup reçu (bras projetés, flash) ; chute à la mort, puis relève (`revive`). L'inclinaison, l'écrasement et le retournement restent ceux de `PlayerMotion`.
- `CharacterData.rig` : si une ressource est définie, le pantin remplace le sprite précalculé en jeu. Sinon on garde le sprite, donc les persos sans pantin ne changent pas. La carte de sélection garde son illustration.
- Planche de contrôle : `tools/art/rig_preview.gd -- --character=<id> --out=<png>` (fenêtre requise).

## Planche « prête pour l'animation » (retour du dev sur le pilote 1)
Le premier pilote utilisait la planche de face (`art_source/ai/rig/ronin_parts.png`). Le dev l'a refusé : les pièces bord à bord laissaient des vides aux articulations (tête et buste), et une vue de face symétrique cache le retournement gauche/droite. Il faut donc des planches **pensées pour l'animation**, générées avec le sprite du perso comme référence (`gen_image.py --image art_source/ai/<id>.png`, invite dans `tools/art/rigs/parts_prompt.txt`) :
- vue de **trois quarts tournée vers la droite** (comme les sprites) ;
- **rotules arrondies qui se chevauchent** (cou, épaules, coudes, hanches, genoux) ;
- bras et jambe arrière séparés, assombris par l'outil (`shade`) et retournés si besoin (`flip`) ;
- cuisse et tibia séparés (le genou plie), **queue de cheval ou cheveux à part** (ressort).
Épéiste : `art_source/ai/rig/v2/ronin_parts_1.png`, 12 pièces.

## Conséquences
- Ajouter un perso : faire sa planche de pièces, son `rigs/<id>.json`, lancer `make_rig.gd` et l'import, puis renseigner `rig` dans `data/characters/<id>.tres`.
- Une seule vue (trois quarts) : pas de vue de dos. Le retournement gauche/droite reste un miroir.
- Pas d'animation d'attaque : les armes flottent autour du perso (façon Brotato, ADR 0010).
