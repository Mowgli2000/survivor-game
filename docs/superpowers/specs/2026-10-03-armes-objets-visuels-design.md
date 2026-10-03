# Armes et objets visibles (chantier visuel 2/3)

**Date :** 2026-10-03 · **Statut :** validé (choix « reco » du dev)
**Décisions liées :** D33 (passe visuelle), D22 (suivre Brotato), ADR 0009 (sprites animés)

## 1. Objectif

Donner un visuel à chaque arme et à chaque objet :
- une **icône** par arme (6) et par objet (15), visible en boutique, dans l'inventaire de la boutique et dans le HUD ;
- les **armes équipées visibles autour du personnage**, façon Brotato : chacune à une position fixe, tournée vers sa cible, avec un retour visuel quand elle attaque.

Choix du dev (tous « reco ») :
1. Positions **fixes en cercle** autour du perso, chaque arme vise sa cible.
2. Armes **petites** (~moitié de la taille du perso) : la horde reste lisible.
3. Icônes d'objets **dans le même style** que les armes : gros contour noir, aplats, accent néon.
4. Couleur de rang : **cadre de l'icône** en interface + **léger liseré** sur l'arme en jeu.

Critères de réussite : chaque arme et objet a son icône ; on voit en jeu quelles armes on porte, où elles visent et quand elles tirent ; projectiles et rayons partent du canon de l'arme ; stress test ≥ 150 FPS moyen ; planche des icônes et capture en jeu validées par le dev.

Hors périmètre : thème complet des interfaces (chantier 3), icônes des statistiques/level-up, nouvelles armes, animations d'objets.

## 2. Icônes (SVG faits main)

- Fichiers : `assets/icons/weapons/<id>.svg`, `assets/icons/items/<id>.svg` (id = id de contenu).
- Style du pack RGS_Dev : contour noir épais (~6 px sur 128), aplats gris/blancs, ombre plate, **un accent néon** (couleur `WeaponData.color` pour les armes ; pour les objets, couleur de la stat principale). Boîte 128×128, fond transparent.
- Armes dessinées **de profil, canon vers la droite**, poignée vers le centre de la boîte : la même image sert d'icône et de sprite en jeu (rotation vers la cible).
- Import Godot : SVG → texture, mipmaps activées (affichage réduit net).
- Données : `WeaponData.icon: Texture2D`, `ItemData.icon: Texture2D`. Icône absente : l'interface affiche le texte seul, l'arme en jeu n'est pas dessinée (aucune erreur). Un test de contenu exige une icône pour chaque arme et objet de `data/`.
- Les icônes sont **provisoires et remplaçables** une à une (pack, IA d'image, artiste) sans code.

Sujets : pulsar (gantelet émetteur d'orbe), katana à plasma, pistolet laser, shuriken, mitraillette, bazooka ; objets : lame affûtée, bobine néon, trame kevlar, nano-stimulants, exo-genoux, gant magnétique, puce de visée, noyau lourd, lentille focale, amortisseur, sceau du rōnin, canon fendu, anneau plasma, masque oni, moteur fantôme.

## 3. Armes autour du personnage

### Disposition (`WeaponLayout`, code pur, `src/weapons/weapon_layout.gd`)
- `mount_offset(index, count) -> Vector2` : positions fixes sur un cercle de rayon `MOUNT_RADIUS` (≈ 34 px) autour du centre du perso, réparties régulièrement, première arme à droite. Positions stables tant que le nombre d'armes ne change pas.

### Origine des attaques (petit changement de gameplay, façon Brotato)
- Projectiles et rayons partent du **canon** : `point de montage + direction × longueur du canon`.
- La **cible** reste choisie depuis le centre du perso (portée inchangée : pas de rééquilibrage).
- L'arc de mêlée (katana) reste centré sur le perso (zone inchangée).
- Implémentation : `WeaponSlot.mount_offset: Vector2` mis à jour par `WeaponHolder` quand les armes changent ; `WeaponContext.muzzle(slot, direction) -> Vector2` utilisé par les comportements tir et rayon.

### Rendu (`WeaponVisuals`, `src/weapons/weapon_visuals.gd`)
- Un seul nœud enfant du `Player`, qui dessine toutes les armes dans un `_draw()` (6 au plus : redessin à chaque image acceptable).
- Chaque image : visée de chaque arme vers l'ennemi le plus proche de son point de montage, dans sa portée (sinon direction de marche), avec rotation lissée. Image retournée verticalement quand l'arme vise à gauche (pas d'arme à l'envers).
- **Attaque** : `WeaponHolder` émet `weapon_fired(index)`. Armes à distance : recul (~6 px) + petit éclair de bouche de la couleur de l'arme (~0,06 s). Mêlée : coup en arc rapide (rotation de −60° à +60° en ~0,15 s) dans la direction de la cible.
- **Taille** : ~50 % de la hauteur du perso (≈ 40 px de long).
- **Liseré de rang** : shader de contour (`weapon_outline.gdshader`) sur le nœud ; la couleur de contour vient de la couleur de dessin (rang I gris, II bleu, III violet, IV rouge) ; l'image elle-même n'est pas teintée.
- Profondeur : les armes passent devant le perso (enfant dessiné après lui).

## 4. Interface

Composant commun `IconTile` (`src/ui/common/icon_tile.gd`) : carré au fond sombre, bordure de la couleur du rang, icône centrée ; petit badge texte optionnel (« ×3 »).
- **Carte de boutique** : grande `IconTile` (96 px) en haut de la carte, au-dessus du nom.
- **Armes possédées (boutique)** : chaque bouton montre l'icône (cadre de rang) + nom + rang.
- **Objets possédés (boutique)** : rangée d'`IconTile` (56 px) avec badge de quantité, au lieu de la ligne de texte ; info-bulle = nom.
- **HUD** (bas gauche) : rangée d'`IconTile` (48 px) des armes, au lieu de la liste de noms.

## 5. Tests et validation

- GUT :
  - `WeaponLayout` : positions sur le cercle, distinctes, première à droite, stables ;
  - origine des projectiles = canon de l'arme (pas le centre) ; cible toujours choisie depuis le centre ;
  - `weapon_fired` émis à chaque attaque réussie ;
  - données : chaque arme et objet de `data/` a une icône ;
  - `IconTile` : couleur de bordure = couleur du rang, badge affiché si fourni ;
  - suite existante verte.
- Stress test alterné avec la version précédente ; seuil 150 FPS moyen.
- Visuel : planche de toutes les icônes (`src/debug/icon_sheet.tscn`, capture), capture en jeu avec 6 armes, capture de la boutique. Montrées au dev.

## 6. Documentation

ADR 0010 (armes visibles : disposition fixe, origine au canon, rendu en un nœud + shader de contour) ; `PROJECT_STATUS.md` ; `CLAUDE.md` (ajouter une arme = `.tres` + icône SVG).
