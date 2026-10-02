# Phase 5 (avancée) — Boutique façon Brotato : design

Date : 2026-10-02 · Statut : validé en discussion, à relire · Décisions liées : D15, D22 (`PROJECT_STATUS.md`)

## Objectif

Le playtest de la Phase 4 a montré que le joueur survit en fuyant, sans sensation de puissance. Comme dans Brotato, la puissance doit venir de la **boutique entre les vagues** : on y achète des armes et des objets, et le level-up ne donne plus que des stats.

**Critère de sortie** : une run complète où l'on achète, verrouille, relance, vend et fusionne en boutique à chaque fin de vague. On choisit ses stats au level-up (4 cartes à rang, relance payante). Tests verts. Stress test ≈ référence ADR 0006 (~185 FPS moyen).

**Critère de ressenti** (playtest du dev) : sur une bonne run, les achats rendent nettement plus fort et le joueur finit par nettoyer les vagues au lieu de fuir.

## Décisions (prises avec le dev)

| Sujet | Choix |
|---|---|
| Ordre des phases | Boutique (Phase 5) avancée avant les objets riches (Phase 3) et les menus |
| Monnaie | **Matériaux** : les gemmes d'XP deviennent des matériaux, 1 ramassé = +1 XP **et** +1 matériau. Départ : 30 matériaux |
| Armes en double | **Autorisées** (6 emplacements). 2 armes identiques de même rang → 1 arme du rang supérieur |
| Rangs | **4 rangs** (I gris, II bleu, III violet, IV rouge) pour armes, objets et cartes de level-up |
| Objets | ~15 objets **de stats simples** (bonus/malus), rang fixe, prix. Pas d'effets spéciaux (Phase 3) |
| Level-up | **Stats seulement**, 4 cartes à rang, relance payante |
| Fin de vague | Level-ups (un à la fois) → boutique → « Vague suivante » |

Hors périmètre : effets spéciaux et synergies d'objets, caisses lâchées par les élites, stat « récolte », chance (luck), variantes de boutique différenciantes du GDD, sauvegarde, menus, art définitif des matériaux.

## Architecture

Logique pure (`RefCounted`, testable sans scène) + un écran qui lit l'état et appelle l'API. `Run` crée et branche tout, comme aujourd'hui.

| Unité | Fichier | Rôle | Dépend de |
|---|---|---|---|
| `Tiers` | `src/core/tiers.gd` | Constantes de rang : `COUNT = 4`, couleurs, chiffres romains, multiplicateurs de bonus du level-up | — |
| `Wallet` | `src/economy/wallet.gd` | Matériaux : `amount`, `add()`, `can_afford()`, `spend() -> bool`, signal `changed(amount)` | — |
| `ItemData` | `src/items/item_data.gd` | Définition d'un objet (`data/items/*.tres`) | `StatModifier` |
| `Inventory` | `src/items/inventory.gd` | Objets possédés (`ItemData -> nombre`), `add(item)` applique les modificateurs, `count(item)`, signal `changed` | `StatBlock` |
| `ShopConfig` | `src/shop/shop_config.gd` | Réglages (`data/shop/default.tres`), tirage du rang, formules de prix et de relance (fonctions pures) | `Tiers` |
| `ShopOffer` | `src/shop/shop_offer.gd` | Un emplacement : arme ou objet, rang, prix, verrouillé, vendu | — |
| `Shop` | `src/shop/shop.gd` | Stock, achat, relance, verrouillage, vente, fusion. Signal `changed` | `ShopConfig`, `Wallet`, `Inventory`, `WeaponHolder` |
| `ShopScreen` | `src/ui/shop/shop_screen.gd` | Écran de boutique (lecture + appels de l'API `Shop`) | `Shop` |

`RunConfig` reçoit `shop: ShopConfig`. `RunState` reçoit `wallet: Wallet`. ContentDB charge deux nouvelles catégories, `items` et `shop`.

Un ADR 0007 décrit les changements d'architecture : armes en double et rangs, monnaie, boutique.

## 1. Matériaux

- `PickupManager` ne change pas (mêmes entités, même pool, aucun impact sur les performances). Seul le branchement change : `xp_collected(amount)` → `progression.add_xp(amount)` **et** `wallet.add(amount)`.
- La collecte automatique en fin de vague donne aussi les matériaux.
- Le HUD affiche le compteur (« ◆ 142 ») en écoutant `Wallet.changed`.
- Le visuel des gemmes est inchangé (placeholder). Clé UI : `UI_MATERIALS`.

## 2. Armes : rangs, doublons, fusion

- **Rangs** : `WeaponData.levels` passe de 4 à **3 entrées** (ce qu'ajoutent les rangs II, III et IV). Règle de recalage : le rang IV garde la puissance totale de l'actuel niveau 5. Les bonus intermédiaires sont répartis sur II et III. `max_level()` vaut donc 4. Le code garde le nom `level` (1..4) ; l'interface affiche le rang (« II »).
- **Prix** : nouveau champ `WeaponData.base_price` (prix du rang I). Valeurs : pulse 15, katana 20, laser_pistol 18, shuriken 18, smg 20, bazooka 25.
- **Doublons** : `WeaponHolder` devient une liste d'emplacements indépendants (indexés). `add_weapon(data, level)` ajoute toujours un nouvel emplacement (refusé si les 6 sont pleins). `get_slot(data)`, `level_up(data)` et `owned_levels()` disparaissent ; ils servaient au level-up d'armes, supprimé.
- **Fusion** : `merge(index) -> bool` cherche un autre emplacement avec la même arme et le même rang (< IV), retire l'un et monte l'autre d'un rang. Signal `weapons_changed`.
- **Vente** : `remove_weapon(index)`. Le gain est calculé par `Shop` (voir 4). On ne peut pas vendre sa dernière arme.
- `max_weapon_slots` (6) reste dans `RunConfig`, passé à `WeaponHolder.setup`.
- Outils de debug (`capture.gd`, `stress_test.gd`) : 6 armes au rang IV, comme avant.

## 3. Objets (`ItemData`)

| Champ | Type | Rôle |
|---|---|---|
| `id` | StringName | ID stable (sauvegardes futures) |
| `name_key` | String | `ITEM_<ID>` |
| `tier` | int | 1..4, fixe |
| `base_price` | int | Prix en vague 1 |
| `modifiers` | Array[StatModifier] | Bonus et malus |
| `max_count` | int | 0 = illimité |

Premier lot (valeurs = premières estimations) :

| ID | Nom FR | Rang | Prix | Effets |
|---|---|---|---|---|
| `sharpened_edge` | Lame affûtée | I | 15 | dégâts +8 %, vitesse d'attaque −3 % |
| `neon_coil` | Bobine néon | I | 15 | vitesse d'attaque +8 %, dégâts −3 % |
| `kevlar_weave` | Trame kevlar | I | 12 | armure +2, vitesse −2 % |
| `nano_stims` | Nano-stimulants | I | 12 | régénération +1 PV/s |
| `exo_knees` | Exo-genoux | I | 15 | vitesse +6 % |
| `magnet_glove` | Gant magnétique | I | 10 | portée de ramassage +40 |
| `targeting_chip` | Puce de visée | II | 30 | critique +5 % |
| `heavy_core` | Noyau lourd | II | 30 | PV max +15, vitesse −4 % |
| `focus_lens` | Lentille focale | II | 30 | portée +15 % |
| `shock_absorber` | Amortisseur | II | 28 | armure +4, vitesse d'attaque −4 % |
| `ronin_seal` | Sceau du rōnin | III | 60 | dégâts +18 %, PV max −10 |
| `split_barrel` | Canon fendu | III | 70 | projectiles +1, dégâts −8 % (max 2) |
| `plasma_ring` | Anneau plasma | III | 55 | zone +20 % |
| `oni_mask` | Masque oni | IV | 110 | dégâts critiques +0,5, critique +5 % |
| `phantom_drive` | Moteur fantôme | IV | 120 | vitesse d'attaque +25 %, PV max −20 |

La description d'un objet est générée à partir de ses modificateurs, avec le formatage déjà utilisé par les cartes de stats. Pas de texte écrit à la main.

## 4. Boutique (logique)

### `ShopConfig` — `data/shop/default.tres`

| Champ | Valeur | Rôle |
|---|---|---|
| `slot_count` | 4 | Emplacements |
| `weapon_chance` | 0.35 | Probabilité qu'un emplacement propose une arme |
| `starting_materials` | 30 | |
| `price_growth_per_wave` | 0.10 | prix = base × (1 + 0,10 × (vague − 1)) |
| `weapon_tier_price` | [1.0, 1.9, 3.4, 6.0] | Multiplicateur du prix d'une arme selon son rang |
| `sell_ratio` | 0.25 | Vente = 25 % du prix d'achat actuel, arrondi, minimum 1 |
| `tier_min_wave` | [1, 2, 4, 8] | Vague d'apparition de chaque rang |
| `tier_base_chance` | [—, 0.10, 0.03, 0.01] | Chance du rang à sa vague d'apparition |
| `tier_chance_per_wave` | [—, 0.05, 0.025, 0.01] | Hausse par vague |
| `tier_max_chance` | [—, 0.60, 0.25, 0.08] | Plafond |

**Tirage du rang** (`roll_tier(wave, rng)`) : du rang IV au rang II, on retient le premier dont le tirage réussit (`chance = min(base + par_vague × (vague − vague_min), max)` si `vague ≥ vague_min`). Sinon rang I. Une seule fonction sert à la boutique et au level-up.

**Relance** : `cost = base + étape × relances_déjà_faites`, avec `base = 1 + floor(vague / 2)` et `étape = max(1, floor(vague / 2))`. Le compteur repart à 0 à chaque nouvelle boutique.

### `Shop` — API

- `open(wave)` : remplace les emplacements non verrouillés, remet le compteur de relances à 0, recalcule les prix à la vague courante (y compris pour les articles verrouillés).
- `reroll() -> bool` : paie et remplace les emplacements non verrouillés et non vendus.
- `toggle_lock(i)`.
- `can_buy(i) -> bool`, `buy(i) -> bool` :
  - **Objet** : refusé si l'argent manque ou si `max_count` est atteint. Sinon `Inventory.add()`.
  - **Arme** : s'il reste un emplacement libre, on l'ajoute. Si les 6 sont pleins **et** qu'une copie identique de même rang (< IV) existe, l'achat fusionne directement. Sinon l'achat est refusé.
  - Un emplacement acheté devient « vendu » (vide) jusqu'à la boutique suivante. Son verrou est retiré.
- `sell_weapon(index) -> int`, `merge_weapon(index) -> bool` : délèguent à `WeaponHolder`.
- **Tirage d'un emplacement** : arme (`weapon_chance`) ou objet. Rang tiré par `roll_tier`. Objet : choix uniforme parmi les objets de ce rang non plafonnés ; si aucun, on descend d'un rang. Arme : choix uniforme parmi toutes les armes, au rang tiré. Un même article n'apparaît pas deux fois dans un même tirage (dans la mesure du possible).
- Tous les tirages utilisent `RunState.rng` : run rejouable depuis sa seed.

## 5. Level-up (stats seulement)

- `Progression.roll_offers` ne propose plus que des `UpgradeData`, **4 cartes** (`RunConfig.upgrade_choices = 4`). Chaque carte reçoit un rang par `ShopConfig.roll_tier(vague)`.
- Bonus selon le rang : modificateurs × `Tiers.UPGRADE_SCALE = [1.0, 1.6, 2.4, 3.2]`. Les `.tres` actuels sont recalés comme valeur du rang I (exemple : power passe de +15 % à +5 %). Recalage détaillé dans le plan.
- `UpgradeOffer` : on retire les types arme et on ajoute `tier`. L'application crée des `StatModifier` mis à l'échelle (les `.tres` ne sont jamais modifiés).
- **Relance** : bouton sur l'écran, coût = formule de la boutique, payé avec le `Wallet`, compteur propre à l'écran de level-up de cette fin de vague.
- Couleur de rang sur chaque carte.

## 6. Déroulé et écrans

`Fin de vague → « Vague X terminée » + level-ups (un à la fois) → boutique → « Vague suivante »`

- `Run._on_level_ups_resolved` ouvre la boutique (`shop.open(vague)` puis `shop_screen.open()`) au lieu d'afficher le bouton « Vague suivante » de `WaveEndScreen`. Le bouton « Vague suivante » de la boutique émet `next_wave_requested`.
- Vague 20 : pas de boutique, victoire directe.
- **Mode auto** (`auto_choose_upgrades`, bots et tests) : première carte de level-up, puis achat du premier article abordable, puis vague suivante.
- `ShopScreen` (`layer` entre l'écran de fin de vague et le level-up), en pause :
  - En-tête : « Boutique — Vague X » et matériaux.
  - 4 cartes : nom, type (arme/objet), rang (couleur + chiffre romain), effets, prix (rouge si inabordable), bouton Acheter, bouton Verrouiller.
  - Bouton Relancer (avec son coût).
  - Rangée des armes (6 cases) : sélection → Vendre (+gain) / Fusionner (si possible).
  - Liste compacte des objets possédés (nom ×nombre).
  - Bouton Vague suivante.
  - Navigation clavier/manette complète, focus initial sur la première carte.
- Le HUD affiche les rangs des armes (« SMG II ») et gère les doublons.
- Tous les textes passent par `localization/strings.csv` (en + fr).

## 7. Tests

- **`Wallet`** : ajout, dépense refusée sans fonds.
- **`ShopConfig`** : `roll_tier` ne sort jamais un rang avant sa vague min, distribution plausible sur 10 000 tirages, prix et relance conformes aux formules.
- **`Shop`** (seed fixe) : 4 emplacements remplis ; achat débite et ajoute ; refus si fonds insuffisants, `max_count` atteint ou emplacements pleins sans fusion possible ; fusion automatique à l'achat ; relance qui coûte de plus en plus et épargne les verrous ; verrou conservé par `open()` ; vente ; dernière arme invendable.
- **`WeaponHolder`** : doublons, fusion (même rang seulement, pas au-delà de IV), suppression.
- **`Inventory`** : modificateurs appliqués, comptage.
- **Level-up** : 4 cartes stats, rang appliqué (×1,6 au rang II), relance payante.
- **Données** : chaque objet a un ID = nom de fichier, des clés en/fr, un rang 1..4, un prix > 0 et au moins un modificateur à stat valide ; chaque arme a `base_price > 0` et 3 entrées de rang ; tableaux de `ShopConfig` de taille 4.
- **Partie simulée** : run courte en mode auto, avec achats en boutique, sans erreur ; la boutique s'ouvre en mode manuel et « Vague suivante » lance la vague.

## Ordre de réalisation

Le jeu reste jouable après chaque étape. Un commit par étape.

1. Matériaux (`Wallet`, branchement, HUD)
2. Rangs et doublons d'armes (`WeaponHolder`, `WeaponData`, recalage des `.tres`, HUD, debug)
3. Objets (`ItemData`, `Inventory`, 15 `.tres`, traductions)
4. Logique de boutique (`Tiers`, `ShopConfig`, `ShopOffer`, `Shop`)
5. Écran de boutique et déroulé de fin de vague
6. Nouveau level-up (stats seulement, 4 cartes à rang, relance)
7. Équilibrage, ADR 0007, `PROJECT_STATUS.md`, GDD

L'étape 2 retire les cartes d'armes du level-up (qui reste à 3 cartes sans rang jusqu'à l'étape 6). Pendant les étapes 2 à 4, on joue donc avec la seule arme de départ. Les armes reviennent par la boutique à l'étape 5.
