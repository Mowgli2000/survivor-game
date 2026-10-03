# Objets à effets et familles d'armes (étape B / Phase 3)

**Date :** 2026-10-03 · **Statut :** validé (choix « reco » du dev)
**Décisions liées :** D22 (suivre Brotato), D25-D28 (boutique), D41 (équilibrage)

## 1. Objectif

Des builds vraiment différents : des objets qui **font** quelque chose (pas seulement des stats) et des **familles d'armes** avec bonus d'ensemble, comme Brotato.

Choix du dev (« reco ») :
1. **Familles d'armes** avec bonus à 2 / 4 / 6 armes de la même famille.
2. ~**13 nouveaux objets** au mélange Brotato : effets à l'élimination, stats conditionnelles, défense, économie (+ les 15 objets de stats actuels → **28 objets**).
3. **4 nouvelles stats** : esquive, vol de vie, chance, récolte.
4. Les objets à **effet fort sont uniques** (achat une fois) ; les objets de stats restent cumulables.

Critères de réussite : les 4 stats agissent en jeu ; chaque nouvel objet fait ce que dit sa description ; les familles s'activent et se désactivent quand on achète / vend / fusionne ; tout est testé ; textes FR/EN ; aucun coût dans les boucles chaudes (stress test ≥ 100 FPS).

Hors périmètre : objets qui ajoutent des entités (tourelles, drones de combat), effets « à chaque coup » (on-hit), nouvelles armes, méta-progression.

## 2. Nouvelles stats

| Stat | Effet | Défaut | Bornes |
|---|---|---|---|
| `dodge` (Esquive) | Chance d'ignorer complètement un coup reçu | 0 | 0 – 60 % |
| `lifesteal` (Vol de vie) | Chance, à chaque dégât infligé, de rendre 1 PV ; au plus 10 PV/s | 0 | 0 – 100 % |
| `luck` (Chance) | +1 % par point : chances des rangs supérieurs en boutique et level-up, et chances des effets d'objets | 0 | — |
| `harvest` (Récolte) | Matériaux gagnés à chaque fin de vague ; la valeur gagnée augmente de 5 % par vague passée | 0 | ≥ 0 |

Affichées dans le panneau de stats (esquive et vol de vie en %).

## 3. Familles d'armes

- `WeaponData.families: Array[StringName]` ; définitions `FamilyData` dans `data/families/` : nom, couleur, paliers `FamilyBonus` (nombre d'armes → modificateurs de stats).
- Compte : chaque arme possédée compte (les doublons aussi, comme Brotato). Le palier le plus haut atteint s'applique (pas de cumul des paliers).
- Système `WeaponFamilies` (logique pure) : recalcule à chaque `weapons_changed` et applique / retire les modificateurs sur les stats du joueur.

| Famille | Armes | 2 armes | 4 armes | 6 armes |
|---|---|---|---|---|
| Lames | katana, shuriken | +5 % critique | +10 % critique, +20 % dégâts critiques | +15 % critique, +40 % dégâts critiques |
| Armes à feu | pistolet laser, mitraillette, bazooka | +10 % portée | +20 % portée, +1 perforation | +30 % portée, +2 perforation |
| Énergie | Pulsar, pistolet laser | +8 % vitesse d'attaque | +16 % vitesse d'attaque | +25 % vitesse d'attaque, +10 % dégâts |
| Explosif | bazooka | +15 % zone | +30 % zone | +45 % zone, +15 % dégâts |

Interface : familles affichées sur les cartes d'armes (boutique) et une section « Familles » dans le panneau de stats (nombre d'armes, palier actif).

## 4. Effets d'objets

- `ItemData.effects: Array[ItemEffect]` ; `ItemEffect` = Resource « strategy » (comme les comportements d'armes) avec des crochets : `on_acquired`, `on_enemy_killed`, `on_wave_ended`, `on_tick`.
- Chaque exemplaire acheté reçoit **sa propre copie** de l'effet (état interne : compteurs, modificateurs).
- Système `ItemEffects` (nœud de la partie, créé par `run.gd`) : reçoit les achats (`Inventory.item_added`) et les événements (ennemi tué, fin de vague, tick physique) et les transmet aux effets. Contexte : stats, joueur, `EnemyManager`, `Vfx`, portefeuille, RNG de la partie.
- Tous les dégâts passent par `EnemyManager` (règle du projet).

Types d'effets :

| Effet | Paramètres |
|---|---|
| `ExplodeOnKillEffect` | chance, rayon, dégâts (× stat dégâts) |
| `MaterialOnKillEffect` | chance, quantité |
| `InterestEffect` | % des matériaux possédés en fin de vague, plafond |
| `ConditionalStatEffect` | +X % d'une stat par palier d'une autre (bonus au-dessus de la base) |
| `KillStackEffect` | +modificateur tous les N ennemis tués, plafond de cumuls |
| `PeriodicHealEffect` | soin de N PV toutes les X s |

## 5. Nouveaux objets (13)

| Objet (FR / EN) | Rang | Unique | Effet |
|---|---|---|---|
| Réacteur en chaîne / Chain reactor | III | oui | 20 % de chance qu'un ennemi tué explose (rayon 90, 12 dégâts) |
| Aimant à ferraille / Scrap magnet | I | non | 8 % de chance qu'un ennemi tué donne 1 matériau |
| Sangsue nano / Nano leech | II | non | +5 % vol de vie |
| Cape fantôme / Ghost cloak | II | non | +8 % esquive, −2 armure |
| Maneki-néon / Maneki-neon | I | non | +15 chance |
| Ferme hydroponique / Hydroponic farm | I | non | +4 récolte |
| Puce de crédit / Credit chip | II | oui | Fin de vague : +10 % des matériaux possédés (max 25) |
| Volonté de fer / Iron will | III | oui | +1 % dégâts par point d'armure |
| Lame véloce / Swift blade | II | oui | +1 % vitesse d'attaque par 10 de vitesse de déplacement au-dessus de la base |
| Canon de verre / Glass cannon | III | oui | +25 % dégâts, −25 % PV max |
| Overclock / Overclock | II | non | +12 % vitesse d'attaque, −5 % dégâts |
| Moissonneur d'âmes / Soul harvester | IV | oui | +1 PV max tous les 20 ennemis tués (max +60) |
| Drone médical / Med drone | II | oui | Soigne 3 PV toutes les 5 s |

Icônes : générées par `tools/icons/make_icons.py`, même style.

## 6. Tests et validation

- GUT : stats (esquive évite les dégâts avec un RNG forcé, vol de vie soigne et respecte le plafond, chance augmente les rangs, récolte en fin de vague avec croissance) ; familles (paliers, retrait à la vente) ; chaque type d'effet ; données (chaque objet a icône, textes, effets valides ; chaque arme a au moins une famille existante) ; suites existantes vertes.
- Stress test ≥ 100 FPS ; capture de la boutique et du panneau de stats.

## 7. Documentation

ADR 0012 (effets d'objets en strategy + système `ItemEffects`, familles) ; `PROJECT_STATUS.md` (D42) ; `CLAUDE.md` (ajouter un objet à effet).
