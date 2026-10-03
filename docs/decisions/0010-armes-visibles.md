# ADR 0010 — Armes visibles et icônes

**Statut :** accepté (2026-10-03) — chantier visuel 2/3, spec `docs/superpowers/specs/2026-10-03-armes-objets-visuels-design.md`

## Contexte
Le dev veut voir les armes équipées autour du personnage, comme dans Brotato, et des visuels pour les armes et les objets en boutique.

## Décisions
1. **Icônes SVG** (`assets/icons/{weapons,items}/<id>.svg`), générées par `tools/icons/make_icons.py` (source versionnée), dans le style du pack de personnages : gros contour noir, aplats, un accent néon. Import avec mipmaps. `WeaponData.icon` / `ItemData.icon`. Provisoires, remplaçables une à une sans code. Une arme est dessinée de profil, canon à droite, centrée : la même image sert d'icône et de sprite en jeu.
2. **Points de montage** (`WeaponLayout`) : cercle de rayon 50 px centré sur la poitrine du perso (`BODY_CENTER`), positions réparties, recalculées par `WeaponHolder` à chaque changement d'armes (`WeaponSlot.mount_offset`).
3. **Origine des tirs au canon** : projectiles et rayons partent de `WeaponContext.muzzle()` (montage + 28 px dans la direction visée). La **cible** reste choisie depuis le centre du perso : la portée n'a pas changé, pas de rééquilibrage. L'arc du katana reste centré sur le perso.
4. **Rendu** : un seul nœud `WeaponVisuals` (enfant du `Player`) dessine toutes les armes dans un `_draw`. Chaque arme vise l'ennemi le plus proche de son montage (sinon la direction de marche), avec une rotation lissée. Elle est retournée verticalement quand elle vise à gauche. Attaque (signal `WeaponHolder.weapon_fired`) : recul et éclair de bouche pour les armes à distance, coup en arc pour la mêlée. Les éclairs sont dessinés par un nœud enfant en mode additif.
5. **Liseré de rang** : shader `weapon_outline.gdshader`. L'image n'est pas teintée ; le contour prend la couleur de dessin (couleur du rang).
6. **Interface** : composant `IconTile` (icône sur fond sombre, cadre de la couleur du rang, badge de quantité). Utilisé sur les cartes de boutique, dans la rangée d'objets possédés et dans le HUD. Les boutons d'armes possédées affichent aussi l'icône.

## Mesures (stress test, 7 armes, alterné 4 × 15 s avec le commit précédent)
| Version | FPS moyen |
|---|---|
| Avant (dbd3968) | 157 |
| Armes visibles + icônes | 146 |

Coût ≈ 7 %, du même ordre que le bruit de mesure (±15 FPS). Retirer le nœud `WeaponVisuals` ne donne pas de gain mesurable. La machine était plus lente pendant cette session qu'à la mesure de l'ADR 0009 (157 contre 176 pour un code équivalent). Le seuil absolu de 150 n'est donc pas atteint dans ces conditions. À re-mesurer sur une machine au repos ; si le coût se confirme, limiter la recherche de cible des armes à 10 fois par seconde.

## Conséquences
- Ajouter une arme ou un objet = un `.tres` + une icône (ligne dans `make_icons.py`, ou un SVG/PNG fait ailleurs et référencé dans `icon`).
- Un test de contenu exige une icône pour chaque arme et objet de `data/`.
- Outils : `src/debug/icon_sheet.tscn` (planche des icônes) ; `capture.tscn -- --shop` (capture de la boutique).
