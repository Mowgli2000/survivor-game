# ADR 0012 — Effets d'objets et familles d'armes

**Statut :** accepté (2026-10-03) — étape B / Phase 3, spec `docs/superpowers/specs/2026-10-03-objets-effets-design.md`

## Contexte
Les objets ne donnaient que des stats. Pour des builds variés comme dans Brotato, il faut des objets qui *font* quelque chose, des bonus d'ensemble par famille d'armes et quelques stats de plus.

## Décisions
1. **4 stats** dans `StatIds` :
   - `dodge` : esquive, bornée à 60 % ;
   - `lifesteal` : vol de vie, plafonné à 10 PV par seconde ;
   - `luck` : chance, +1 % par point sur les chances de rang en boutique et au level-up, et sur les chances des effets ;
   - `harvest` : récolte, matériaux en fin de vague, +5 % par vague passée.

   L'esquive est gérée dans `Player.take_damage`, avec le RNG de la partie. Les autres sont gérées dans `ItemEffects`.
2. **Effets d'objets en « strategy »** : `ItemData.effects: Array[ItemEffect]`. Les crochets sont `on_acquired`, `on_enemy_killed`, `on_wave_ended` et `on_tick`, plus `validate()` pour les tests de données. Chaque exemplaire acheté reçoit une **copie** de l'effet, qui garde son propre état. Il y a 6 types d'effets : explosion à l'élimination, matériaux à l'élimination, intérêts, stat conditionnelle, cumul par éliminations, soin périodique.
3. **Système `ItemEffects`** (nœud de la partie, créé par `run.gd`) : il réagit aux signaux existants (`Inventory.item_added`, `enemy_damaged`, `enemy_killed`, fin de vague) et à son propre tick. Il n'ajoute rien dans les boucles par ennemi. Les dégâts des effets passent par `EnemyManager`. Les explosions d'effet sont **mises en file** et traitées à l'image physique suivante, au plus 12 par image et 64 en attente. Les déclencher immédiatement réécrivait les tampons de la boucle de dégâts de zone en cours, et l'attaque de l'arme était interrompue (trouvé en revue). Les éliminations causées par un effet ne déclenchent pas d'autres dégâts d'effet, ce qui évite une réaction en chaîne sur toute la horde.
4. **Familles d'armes** :
   - `WeaponData.families` ; définitions `FamilyData` et `FamilyBonus` dans `data/families/` (lames, armes à feu, énergie, explosif) ;
   - `WeaponFamilies` (logique pure) recalcule les familles à chaque `weapons_changed` ;
   - les doublons comptent, et seul le palier le plus haut atteint s'applique.
5. **Objets uniques** : `max_count = 1`. La boutique ne propose jamais un objet qu'on ne peut plus ajouter. La carte affiche « (Unique) » et le texte d'effet (`effect_key`).

## Conséquences
- Ajouter un objet à effet : un `.tres` avec un `ItemEffect` paramétré, un `effect_key` traduit et une icône. Un nouveau type d'effet demande un nouveau script dans `src/items/effects/`.
- Les règles des futurs personnages (méta-progression) pourront réutiliser les mêmes effets.
- Mesure (stress test, 650 ennemis, 7 armes rang IV) :
  - environ 100 FPS de moyenne, contre environ 120 avant, au niveau du seuil de 100 (D37) ;
  - surtout dû aux familles toutes actives dans ce pire cas : plus de perforation et de vitesse d'attaque, donc plus de projectiles en vol ;
  - le crochet du vol de vie n'écoute les coups que si la stat est au-dessus de 0 (environ 6 FPS économisés).

  Si le jeu réel descend sous 100 FPS, la piste est d'afficher les ennemis en un seul lot (option B de l'ADR 0009).
