# Inventaire des armes et pistes de différenciation

État au 2026-10-11 (28 armes). On parle des armes par leur nom en jeu (table des id dans `docs/weapons-noms.md`).
Document de travail : rien n'est implémenté sans accord du dev. Constat du dev (notes) : l'élément (feu, givre, foudre) ne change presque rien au jeu, car aucun ennemi n'a de résistance. Il faut des armes qui changent la façon de jouer, pas seulement la couleur du tir.

Les 4 comportements du code : `melee_arc` (coup en arc autour du héros), `projectile_shooter` (projectiles, tirés ou lobés), `beam` (rayon instantané), `strike` (coup tombé du ciel).

## Corps à corps (9) : tous le même geste, un arc devant le héros

| Arme | Mécanique actuelle | Problème | Proposition |
|---|---|---|---|
| Faux de guerre | Arc 300°, lent, lourd | Référence de qualité, rien à changer | Garder |
| Hache de guerre | Arc 200°, lent, dégâts forts | Proche de la faux et du marteau | Garder, coup « lourd » : étourdit 0,3 s |
| Marteau de guerre | Arc 160°, très lent, très fort | Pareil | Onde de choc circulaire au sol (étourdit, repousse fort) |
| Épée flamboyante | Arc 140°, brûle | Presque identique au Katana | Lance une vague de feu qui avance (déjà peinte, `flame_wave`) : portée plus longue |
| Katana | Arc 140°, rapide | Identique à l'Épée flamboyante hors brûlure | Trait unique très long (`iaido_line`) : coup en ligne qui traverse tout, critiques élevés |
| Rapière | Arc 30°, très rapide | Proche de la Lance et des Crocs | Garder : 3 estocs rapides, bonus de critique |
| Lance | Arc 40°, longue portée | Proche de la Rapière | Perce en ligne (traverse tous les ennemis alignés), portée max |
| Crocs du venin | Arc 60°, ultra rapide, faible | Poison seulement en statut | Le poison s'empile : chaque coup ajoute un cumul, effet cumulable avec les objets |
| Lame runique | Arc 120° + chaîne 2 | A sa propre identité | Ne pas toucher (demande du dev) |

## Projectiles tirés (11) : le gros du problème

| Arme | Mécanique actuelle | Problème | Proposition |
|---|---|---|---|
| Orbe arcanique | Tir rapide, perce 1 | Plus faible, un tir banal | **Orbes qui tournent autour du héros** (nouveau comportement `orbit`) : protège et touche en continu |
| Bâton de feu | Boule, perce 1, brûle 60 %, mini explosion | Identique au Bâton de foudre en jeu | Boule lente qui explose en grosse zone et laisse une braise |
| Bâton de foudre | Boule qui rebondit 2 à 4 fois + chaîne | Bien, déjà « chaîne » | Garder, c'est l'arme « beaucoup d'ennemis ». Éclair peint |
| Arc long | Flèche rapide, perce 1 | Proche d'Arbalète lourde et Javelots | Tir de précision : dégâts qui montent avec la distance |
| Arbalète lourde | Carreau lent, perce 2-3, 28 dégâts | Idem | Gros recul, le carreau reste planté et ralentit |
| Arbalète à répétition | 0,12 s, 3 dégâts | Mitraillette sans variation | Cadence qui monte avec la durée du tir |
| Javelots | Perce 1, éventail 12° | Idem Arc long | Éventail de 3 à 5 javelots sur courte portée (fusil à pompe) |
| Fronde | Pierre rapide, éventail 10° | La plus basique | Ricoche sur les bords de l'arène |
| Shuriken | Rebondit 1 à 2 fois | Correct | Revient vers le héros (boomerang) |
| Arc céleste | Flèche à tête chercheuse | Correct, laissé tel quel (demande du dev) | Garder |
| Canon alchimique | Obus droit, explose | Même rôle que la Fiole explosive | Obus qui traverse une ligne d'ennemis et explose à la fin |

## Projectiles lobés (5) : bien différenciés depuis cette session

| Arme | Mécanique | Proposition |
|---|---|---|
| Bombe | Tombe, mèche 0,8 s, explosion énorme | Garder |
| Fiole de feu | Explose, laisse une flaque qui brûle 3 s | Garder |
| Fiole explosive | Explose, rebondit sur un second ennemi | Garder |
| Fiole de givre | Explose, ralentit | Laisser une zone de givre au sol qui ralentit (jumelle de la flaque de feu) |
| Grenades à fragments | Explose, 8 éclats | Garder |

## Rayons et frappes (4)

| Arme | Mécanique actuelle | Proposition |
|---|---|---|
| Baguette de cristal | Rayon rubis, chaîne 2 | Garder : rayon long, instantané |
| Sceptre de givre | Rayon givre, ralentit | Le transformer en **cône de givre** courte portée qui gèle (≠ Baguette) |
| Grimoire des météores | Météore du ciel | Garder |

## Décisions du 2026-10-11

- **Lames d'ombre** : nouvelle arme (`shadow_blades`, comportement `orbit`) : 2 dagues spectrales qui tournent autour du héros (rang IV : 4), contact répété toutes les 0,45 s, ralentissent. Faite.
- **Orbe arcanique** : devient un vortex (orbe lente, perce tout, attire les ennemis, les broie par touches répétées). Fait.
- Le reste du tableau ci-dessus reste à valider.

## Nouvelles armes proposées (le dev ne s'y oppose pas)

1. **Lames spectrales** (comportement `orbit`) : trois lames qui tournent autour du héros. Si on convertit l'Orbe arcanique, c'est l'Orbe qui prend ce rôle ; sinon c'est une 29e arme. Recommandation : convertir l'Orbe, pas d'arme en plus.
2. **Totem** (comportement `summon`) : on pose un totem qui tire seul sur place pendant 8 s. Change vraiment le placement du joueur (rester près du totem ou le laisser derrière).
3. **Nova** : onde qui part du héros à intervalle fixe, rayon croissant. Arme défensive pour les foules serrées.

## Ordre conseillé

1. Orbe arcanique en orbite (le plus grand gain de variété, 1 comportement neuf).
2. Sceptre de givre en cône, Fiole de givre avec zone de givre (comportements déjà là, peu de code).
3. Arc long / Arbalète lourde / Javelots / Fronde : une mécanique propre chacun (rampe de distance, planté, éventail, ricochet).
4. Corps à corps : Katana en ligne, Lance qui perce, Crocs en cumuls.
5. Totem, puis Nova si le besoin se confirme.

Chaque nouvelle arme ou changement doit garder les règles du dev : ce qui est dessiné = ce qui fait mal, une explosion unique et reconnaissable, animation IA, ID stables.

## Règle des projectiles en plus (stat Projectiles), par motif d'arme — validé le 2026-10-11

Chaque motif d'arme garde son sens ; la stat « Projectiles » ajoute des tirs, jamais n'importe lesquels.

| Motif | Les tirs en plus... | Armes |
|---|---|---|
| Tir droit en éventail | partent en éventail autour de la direction visée | arcs, arbalètes, javelots, fronde, bâtons, shuriken |
| Lancé (fioles, bombes, grenades) | atterrissent chacun sur **un autre ennemi / groupe**, jamais en rangée en arc ; sans autre cible, dispersés autour de la première | Fiole de feu, de givre, explosive, Bombe, Grenades |
| Tombé du ciel | tombent sur d'autres groupes (écart >= 1,6 rayon), 0,25 s d'intervalle | Grimoire des météores |
| Onde, estoc, cône étroit (< 180°) | visent **d'autres ennemis**, l'un après l'autre (0,1 s) | Épée flamboyante, Lance, Rapière, Katana, Sceptre de givre, Crocs |
| Grand arc ou tourbillon (>= 180°) | se répartissent régulièrement **autour du héros** | Faux, Hache, Marteau |
| Orbite | = nombre de lames | Lames d'ombre |
| Puits de gravité | **aucun** (`projectile_stat_applies = false`) : trois puits côte à côte ne servent à rien | Puits de gravité |

Effets par arme (nouveaux) : Arc long (+100 % de dégâts en fin de portée), Arbalète à répétition (cadence jusqu'à x2), Arbalète lourde (carreau planté qui ralentit), Javelots (éventail de 3), Fronde (ricochets sur les murs), Shuriken (revient), Bâton de feu (explosion large), Canon alchimique (traverse 3 ennemis avec petites explosions), Crocs du venin (poison cumulable jusqu'à 6 fois), Sceptre de givre (cône 45°), Fiole de givre (zone de givre, opacité 55 %).
