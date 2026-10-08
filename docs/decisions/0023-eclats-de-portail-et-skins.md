# ADR 0023 — Éclats de portail, défis de collection et boutique de skins

**Date :** 2026-10-08 · **Statut :** appliqué (étapes 1 à 4 ; le contenu des skins reste à dessiner)

## Contexte
Avec le déblocage global des sceaux (D90), plus rien ne pousse à jouer les autres classes. Le dev veut des skins que le joueur choisit librement, achetés avec une monnaie gagnée en terminant des défis, et deux familles de défis distinctes. Les anciens skins « à débloquer par défis » (D73) sont abandonnés et supprimés des plans.

## Décision
1. **Deux familles de défis**, même classe `ChallengeData` :
   - **Progression** (`data/challenges/`) : débloquent du contenu (persos, armes, objets). Aucune monnaie.
   - **Collection** (`data/collection/`, catégorie `collection`) : `shards > 0`, `unlock_id` vide, ne débloquent rien et paient des **éclats de portail**. `ChallengeData.is_collection()`.
2. **Éclats de portail** : `Profile.shards` (JSON versionné, lecture tolérante). Ils ne s'obtiennent **que** par les défis de collection : aucun revenu par partie. `Profile.add_shards` / `spend_shards`. `SaveService.record_run` paie les défis réussis (une seule fois) ; `SaveService._grant_past_collection` paie au chargement ceux que les statistiques déjà gardées satisfont (`ChallengeData.is_met_by_profile`).
3. **Skins** : `SkinData` (`data/skins/`), **liés à une classe** (`character_id`), prix en éclats, carte de sélection, sprite et échelle. Cosmétique pur : mêmes règles et stats que la classe. Possédés = `Profile.unlocked[&"skins"]`. `SaveService.buy_skin` (refuse : inconnu, déjà possédé, trop cher).
4. **Apparences d'une classe** : `CharacterData.look_count()` = ses 1 ou 2 apparences de base + les skins possédés (du moins cher au plus cher, `owned_skins()`). L'indice d'apparence existant (`RunSetup.variant`) s'étend au-delà de 1 et désigne un skin (`skin_for`). Le plateau tournant de la sélection (`CharacterSelect.look_count`) le suit sans autre changement.
5. **Interface** : `SkinShopScreen` (menu principal, « Boutique de skins ») : un onglet par classe, cartes de skins, acheter / possédé. La progression liste les défis de collection avec leur gain ; l'écran de fin affiche une carte « ◆ +N éclats de portail ».
6. Nouveau type de condition `WIN_SEAL_WITH` (sceau N ou plus avec une classe donnée).

## Conséquences
- Ajouter un défi de collection : un `.tres` dans `data/collection/` + deux textes. Ajouter un skin : un `.tres` dans `data/skins/` + son nom traduit + sa carte et son sprite (`tools/sprites/sprites.json`, `tools/bake_sprites.ps1`).
- Les 33 défis de collection livrés valent 5 760 éclats au total ; les prix des skins se règlent sur ce budget.
- Défis « de style » (esquives de l'Assassin, zone du Mage…) : demandent de nouvelles statistiques dans `RunResult`, non faits.
- Aucun skin dessiné pour l'instant : la boutique affiche « Aucun skin pour cette classe ».
- Tests : `tests/unit/test_collection.gd`, `tests/unit/test_skins.gd`.
