# Audit du projet pour la page Steam (2026-10-12)

Inventaire de ce qui est **réellement implémenté** (comptes lus dans `data/`, états dans `PROJECT_STATUS.md`). Rien n'est supposé terminé parce
qu'il est prévu.

## Gameplay implémenté (montrable)
- **Boucle de run** : arène bornée, vagues chronométrées (20 vagues), élites, mini-boss et boss final, victoire, récompenses.
- **Boutique entre les vagues** : stock, relance, verrou, achat, vente, fusion d'armes en 4 rangs (pilier du design).
- **7 personnages** (14 apparences ♀/♂), règle propre, armes de départ au choix ; **29 armes** (mêlée, arcs, bombes, fioles, bâtons, faisceaux, orbite, météores), **59 objets**, 17 améliorations de niveau, 4 familles d'armes.
- **Ennemis** : 9 types de base et 5 paliers (Fer à Astral), soit 54 définitions, dont mini-boss et boss par palier.
- **6 niveaux de danger (sceaux)**, 6 lieux/biomes (`data/biomes`), **mode infini** après la victoire.
- **Méta-progression** : 28 défis, déblocages de persos/armes/objets, collection, boutique de skins (le système existe ; peu de contenu de skins en `data/`, à vérifier avant de la montrer).
- **Coop locale à 2** (écran partagé, manettes), manette complète, français et anglais, paramètres (dont zoom caméra).

## Ce qui est suffisamment abouti pour être montré
Combat, boutique, level-up, sélection de personnage, sceaux, boss, coop, progression, menu principal. Les animations d'armes sont peintes par IA pour presque toutes les armes (reste : corps animés de l'Arc long, de l'Arbalète à répétition, des Javelots, du Shuriken, grenade à 12 images).

## À ne PAS montrer / à corriger avant les captures finales
- Les armes `TEMP_PLAYTEST_*` données à l'Épéiste et à l'Archère pour les tests (voir `PROJECT_STATUS.md`).
- Contenu de skins incomplet (boutique de skins).
- Équilibrage des dangers non terminé (taux de victoire trop hauts, voir notes de simulation) : sans effet sur les images.
- Bruit visuel en fin de partie : à valider après le changement de Zone (ADR 0029).

## Assets graphiques existants
Logo et icônes (`assets/branding/`), fond de menu 1920x1080 peint, fonds peints par danger (`assets/ui/backgrounds/`), cartes de persos (`assets/characters/cards/`), icônes d'armes et d'objets, sprites animés des persos et monstres, effets d'attaque peints (`assets/vfx/`), décors par lieu (`assets/map/`), thème d'interface « Cristal d'azur ».
Direction artistique : dessin animé peint, trait épais, aplats, proportions trapues ; palette bleu nuit / bleu cristal avec orange feu (portail). Aucune copie d'un autre jeu.

## Scènes Godot capturables
`src/debug/capture.tscn` (voir `screenshots/shots.md`), `vfx_gallery.tscn` (effets), `icon_sheet.tscn`, `shape_check.tscn`. Pas de mode photo : le bot joue, on choisit l'instant (`--time`).
