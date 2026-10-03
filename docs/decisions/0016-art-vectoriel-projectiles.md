# ADR 0016 — Art vectoriel dessiné par code et projectiles stylés

**Statut :** accepté (2026-10-03) — passe artistique, spec `docs/superpowers/specs/2026-10-03-passe-artistique-cartoon-design.md`. Remplace le pack RGS_Dev de l'ADR 0009 (le pipeline atlas + `SpriteSheet` reste).

## Contexte
Demande du dev : personnages en cartoon lisse façon Dofus (pas de pixel), un vrai design de carte, des projectiles reconnaissables par arme (missile, balles…). Le pack d'origine n'est plus présent dans `assets_src/`.

## Décisions
1. **Dessins vectoriels écrits par code** : `tools/art/make_sprites.py` (13 personnages/ennemis/boss, squelette chibi animé), `tools/art/make_map.py` (sol, décalques, décor, corps de projectiles). Les SVG vont dans `assets_src/drawn/` (non versionné, régénérable) ; **Godot les rastérise** (ThorVG) dans `tools/bake_sprites.ps1` (`bake_sprites.gd` lit les entrées `"svg"`, `tools/art/bake_map.gd` fait le sol, l'atlas de décor `DecorAtlas` et la bande des projectiles). Aperçu sans conversion : `tools/art/preview_sheet.gd`.
2. **Carte** : `Arena` dessine une fois le sol en mosaïque, des décalques plats (graine fixe, centre dégagé), un mur néon et le décor haut **uniquement hors de l'arène** ; une seule texture d'atlas pour tout le décor.
3. **Projectiles** : `WeaponData.projectile_style` (`GLOW`, `ORB`, `BOLT`, `BULLET`, `MISSILE`, `SHURIKEN`, `ENEMY_ORB`). `ProjectileRenderer` garde 2 appels de dessin : les projectiles sans style en halo additif (comme avant), les stylés **uniquement** en corps opaque tiré d'une bande de cases ; la case passe dans l'alpha de la couleur d'instance (shader `projectile_body.gdshader`), donc 2 appels de setter par projectile comme avant.
4. **Mesures (stress test, 650 ennemis, ~1 100 projectiles)** : remplir les buffers MultiMesh depuis GDScript (12 à 16 écritures de flottants par projectile) coûtait **plus** que les setters (−12 à −15 FPS) : abandonné. Version retenue : ~102 FPS contre ~106 pour l'ancien rendu, mesurés en alternance (dans le bruit de ±15, au-dessus du seuil de 100, D37).

## Conséquences
- Changer un personnage : modifier sa fonction dans `make_sprites.py`, puis `python tools/art/make_sprites.py` et `tools/bake_sprites.ps1`.
- Ajouter un style de projectile : une case SVG dans `make_map.py` (ordre des fichiers = ordre de l'enum), une valeur d'enum, une entrée dans les tableaux de `ProjectileRenderer` (un test vérifie la cohérence).
- Un artiste pourra remplacer les SVG (ou fournir des PNG via des entrées `"src"`) sans toucher au code du jeu (D8).
