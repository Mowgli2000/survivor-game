# Skins des personnages jouables

Un dossier par perso (id historique, ex. `gunslinger` = Archère), avec :
- `default/<female|male>/` : le skin par défaut (celui qu'on anime en premier, sprite = carte de sélection). Pour chaque perso, une **version de l'autre sexe** est prévue : **un tout autre personnage** (pas les mêmes couleurs ni le même design que la version d'origine), à générer ;
- `unlockable/` : skins à débloquer par défis (à implémenter après, ADR à écrire).

Nommage : `<id>_<skin>_<f|m>.png`. Modèle : `gpt-image-2.5-sunburst` (`tools/art/gen_image.py`, `--image` = version de référence). Style : proportions trapues, aplats, contour épais, mains vides. Tenues stylisées, non explicites.

## Skins par défaut
| Perso (id) | Skin par défaut | Version de l'autre sexe |
|---|---|---|
| Archère (`gunslinger`) | `default/female/gunslinger_red_f` (carmin, crème, or ; blonde, clip à plumes) | `default/male/gunslinger_ochre_m` (chasseur : cheveux bruns tressés, tunique ocre, cape de plumes, ocre, olive, brun) |
| Mage (`mage`) | `default/female/mage_storm_f` (marine, cyan, blanc ; tresse blanche relevée) | `default/male/mage_burgundy_m` (érudit : lunettes rondes, barbe courte, manteau bordeaux et or) |
| Berserker (`berserker`) | `default/female/berserker_slate_f` (ardoise, rouille, os ; cornes de bélier) | `default/male/berserker_wolf_m` (brute à manteau de loup, cheveux auburn, runes vertes ; sable, vert forêt, os) |
| Épéiste (`ronin`) | `default/female/ronin_crimson_f` (acier laqué carmin, or, crème) | `default/male/ronin_indigo_m` (maître d'armes : cheveux gris argent, haori indigo et blanc) |
| Assassin (`hero`) | `default/male/hero_shadow_m` (manteau noir à capuche, doublure violette ; archétype du chasseur d'ombre, aucun design de Solo Leveling copié) | `default/female/hero_rose_f` (assassine : cheveux argentés, veste rose poudré et gris charbon) |
| Contrebandier (`merchant`) | `default/female/merchant_goggles_f` (tresses noires aux anneaux d'or, lunettes d'aviateur, boléro vert et or, sac à dos de breloques) | `default/male/merchant_coat_m` (blond plaqué, moustache, long manteau vert à liseré d'or, lanterne) |
| Chasseur novice (`drifter`) | `default/female/drifter_ribbon_f` (queue de cheval au ruban bleu, tunique rapiécée, gros bracelets de cuir) | `default/male/drifter_badge_m` (blond hérissé, tunique crème trop grande, médaille de chasseur) |

## Skins à débloquer
- gunslinger : `gunslinger_plum` (prune, argent), `gunslinger_sun` (ivoire, or, turquoise ; dessous de jupe à corriger avant intégration)
- mage : `mage_ember` (noir charbon, orange braise, or), `mage_jade` (ivoire, émeraude, or ; ouverture de hanche à resserrer)
- berserker : `berserker_tundra` (blanc neige, bleu glacé, argent), `berserker_blood` (carmin, noir, or)
- ronin : `ronin_steel` (acier, ivoire, or, émeraude : ancien skin par défaut), `ronin_frost` (acier bleu glacé, argent, blanc)
- hero : `hero_shadowgirl` (assassine, noir, violet, magenta), `hero_kimono` (assassin en kimono, noir, violet, or)

Idée du dev à trancher plus tard : rendre les skins à débloquer plus différents entre eux (autres personnages, avec un repère de classe commun) pour donner plus de valeur au déblocage.

## À faire
- Version de l'autre sexe pour chaque perso : un autre personnage, avec seulement un repère de classe commun (accessoire de la classe).
- Contrebandier (`merchant`) et Chasseur novice (`drifter`) : 2 skins à débloquer chacun (à générer).
- Les skins à débloquer n'existent que dans une version ; à décider s'ils ont aussi une version de l'autre sexe.
