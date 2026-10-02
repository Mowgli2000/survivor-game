# ADR 0007 — Boutique façon Brotato : matériaux, armes à rangs, objets

**Statut :** accepté (2026-10-02) — Phase 5 avancée (design validé par le dev, spec `docs/superpowers/specs/2026-10-02-shop-design.md`, plan `docs/superpowers/plans/2026-10-02-shop.md`)

## Résumé
La puissance du joueur vient désormais d'une boutique entre les vagues, comme dans Brotato. Les gemmes d'XP deviennent des matériaux (XP + monnaie). Les armes ont 4 rangs, peuvent être possédées en double et fusionnent. Des objets de stats sont vendus en boutique. Le level-up ne donne plus que des stats (4 cartes à rang, relance payante).

## Compatibilité moteur
| Champ | Valeur |
|---|---|
| Moteur | Godot 4.7.2 (GDScript typé) |
| Domaine | Core / Scripting / UI |
| Risque post-cutoff | Faible : `RefCounted`, `Resource`, signaux, `Control` standards |
| Vérification | Tests GUT (unitaires `Shop`, `WeaponHolder`, `Inventory`, `Wallet`, données, smoke) |

## Dépendances
| Champ | Valeur |
|---|---|
| Dépend de | ADR 0003 (données `.tres`), ADR 0006 (vagues, level-up différé) |
| Permet | Phase 3 (objets à effets et synergies, vendus par la même boutique), équilibrage de l'économie |

## Contexte
Playtest de la Phase 4 : le joueur survit en fuyant, sans sensation de puissance. Décision du dev (D22) : suivre au maximum la logique de Brotato, où le build se construit en boutique.

## Décisions
1. **Matériaux** : `Wallet` (`RefCounted`, dans `RunState`). `PickupManager.xp_collected` alimente à la fois `Progression` et `Wallet`. Aucune nouvelle entité. Départ : 30 matériaux (`ShopConfig.starting_materials`).
2. **Armes à rangs** : 4 rangs (I..IV), constantes dans `Tiers` (`src/core/tiers.gd`). `WeaponData.levels` contient 3 entrées (ce qu'ajoutent les rangs II, III et IV). Le code garde le nom `level` (1..4). `WeaponData.base_price` donne le prix du rang I.
3. **Doublons et fusion** : `WeaponHolder` est une liste d'emplacements indépendants. `add_weapon` ajoute toujours un emplacement. La limite (`max_slots`, 6) se lit avec `is_full()` et c'est `Shop` qui la fait respecter. `merge(index)` fusionne deux armes identiques de même rang. Acheter une copie quand les 6 emplacements sont pleins la fusionne directement (`find_slot` + `upgrade_slot`). API supprimée : `get_slot`, `level_up`, `owned_levels`.
4. **Objets** : `ItemData` (`data/items/`, rang fixe, prix, modificateurs, `max_count`) et `Inventory` (`RefCounted`, applique les modificateurs au `StatBlock` du joueur).
5. **Boutique** : `ShopConfig` (`data/shop/`, fonctions pures : tirage du rang, prix, relance, vente), `ShopOffer`, `Shop` (`RefCounted`). `ShopScreen` lit l'état et n'appelle que l'API de `Shop`. La relance remplit tous les emplacements non verrouillés, y compris ceux déjà achetés.
6. **Level-up** : `UpgradeOffer` porte un rang. Les modificateurs sont multipliés par `Tiers.UPGRADE_SCALE` (stats entières arrondies, `StatIds.INTEGER_STATS`) sans modifier les `.tres`. La relance coûte des matériaux, avec la même formule que la boutique.
7. **Déroulé** : fin de vague → level-ups → boutique → vague suivante. `WaveEndScreen` n'affiche plus qu'un titre.

## Alternatives écartées
- **Une arme = un emplacement, racheter = +1 niveau** : plus simple, mais s'éloigne de Brotato (pas de builds « 6 mitraillettes ») et rend la fusion inutile.
- **Garder 5 niveaux** : incohérent avec les 4 rangs de couleur partagés par armes, objets et cartes.
- **Boutique en nœud (`ShopManager`)** : mélange UI et règles, difficile à tester. La logique pure est testée sans scène (19 tests).
- **Système d'offres unique pour level-up et boutique** : généralisation prématurée.

## Conséquences
- Ajouter un objet = un `.tres` dans `data/items/` + une clé de traduction. Les objets à effets (Phase 3) passeront par la même boutique.
- `ContentDB` charge deux nouvelles catégories : `items` et `shop`. `RunConfig.shop` référence le réglage de boutique (repli sur `data/shop/default.tres`).
- Le rang IV d'une arme garde la puissance de l'ancien niveau 5 : le stress test (6 armes au rang max) reste comparable.
- **Performance** : aucun changement dans les boucles chaudes. Mesure du 2026-10-03, machine libre : ~175-184 FPS de moyenne (contre ~180 avant ce travail, sur la même machine). Une petite régression venait du compteur de matériaux du HUD, réécrit à chaque gemme : il est désormais mis à jour une fois par image.
- Équilibrage (prix, chances de rang, valeurs des objets et des cartes) = premières estimations, à régler après playtest.
