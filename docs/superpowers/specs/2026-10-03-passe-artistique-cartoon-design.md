# Passe artistique « cartoon lisse » (design + plan)

Date : 2026-10-03 · Demande du dev : personnages en cartoon lisse façon Dofus (pas de pixel), design de la carte, projectiles par arme (missile pour le bazooka, balles pour les fusils…), puis playtest. Pas de validation à chaque étape.

## Capacités et limites (dites au dev)
Dessins **vectoriels écrits par code** (SVG générés par un script Python), rastérisés par Godot (ThorVG) dans l'atlas existant. Style « cartoon propre de jeu indé », pas le niveau d'un illustrateur ; remplaçables plus tard par des images d'artiste sans toucher au code (D8).

## Direction
- **Chibi façon Dofus** : grosse tête (~50 % de la hauteur), petit corps, membres courts et arrondis, grands yeux expressifs.
- **Contour sombre épais** (#1b1026), **aplats + une ombre douce + un reflet** (cel-shading à 2 tons), **un accent néon par personnage** (repris par le halo du bake).
- Animation par **squelette simple** (ombre, jambes, corps, bras, tête, accessoires) : `idle` 6 images (respiration, léger écrasement), `walk` 8 images (jambes et bras alternés, rebond). Les volants battent des ailes.

## Personnages et ennemis (sprite_id)
| id | Rôle | Design |
|---|---|---|
| `drifter` | Vagabond | Sweat à capuche cyan, écharpe qui flotte, lunettes-visière néon |
| `ronin_pc` | Rōnin (perso) | Kimono magenta, chignon, katana dans le dos |
| `gunslinger` | Flingueur | Poncho vert, chapeau large, bandana |
| `merchant` | Marchand | Robe dorée, chapeau rond, sac à dos de caisses |
| `grunt` | Rôdeur | Petit oni rouge masqué à cornes |
| `runner` | Coureur | Drone-chauve-souris orange (vol) |
| `shooter` | Tireur | Tengu-robot violet, bras-canon |
| `tank` | Colosse | Golem blindé rouille, massif |
| `kamikaze` | Kamikaze | Bombe vivante orange, mèche allumée |
| `charger` | Chargeur | Sanglier-robot rouge, corne |
| `spawner` | Pondeuse | Araignée-mère verte, sac d'œufs lumineux |
| `ronin_boss` | Ronin (mini-boss) | Samouraï masqué cyan, chapeau conique |
| `shogun` | Shogun (boss) | Armure magenta, kabuto à cornes dorées |

Pipeline : `tools/art/make_sprites.py` → `assets_src/drawn/<id>/<anim>_<i>.svg` → `tools/bake_sprites.ps1` (recette `"svg"` dans `tools/sprites/sprites.json`) → `assets/sprites/atlas.png` + `.tres`.

## Carte
- Sol : dalles de toit « dojo néon » (pierre violet-bleu, joints néon discrets), texture SVG en mosaïque.
- Décalques au sol (sans collision, ne gênent pas la lecture) : plaques d'égout, cercles peints, câbles, flaques néon. Décor haut (lanternes, enseignes, arbres à fleurs, caisses) **uniquement hors de l'arène**, le long de la bordure.
- `Arena` dessine tout une seule fois (canvas statique).

## Projectiles
- `WeaponData.projectile_style` : `GLOW` (actuel), `ORB` (Pulsar), `BOLT` (pistolet laser), `BULLET` (mitraillette), `MISSILE` (bazooka, traînée de fumée), `SHURIKEN` (tourne).
- `ProjectileRenderer` : un 2e MultiMesh « corps » (mélange normal) qui lit une cellule d'un atlas de formes via `INSTANCE_CUSTOM` dans un shader ; le halo additif reste. Toujours ≤ 2 appels de dessin par gestionnaire.

## Vérification
Galerie d'effets/ennemis (`vfx_gallery.tscn`), captures, planche de sprites, stress test ≥ 100 FPS, tests verts.

## Ordre / commits
A. Sprites (persos + ennemis + boss) · B. Carte · C. Projectiles · D. Docs + statut. Un commit + push par étape.
