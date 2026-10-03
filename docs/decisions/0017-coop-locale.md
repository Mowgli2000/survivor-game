# ADR 0017 — Coop locale à deux joueurs

**Statut :** accepté (2026-10-04) — choix du dev D48

## Contexte
Le dev veut jouer à deux sur le même PC avec deux manettes. Tout le code d'une partie supposait un seul `Player` (ennemis, ramassage, boss, caméra, boutique, HUD). Pas de coop en ligne pour l'instant ; on garde le solo strictement identique.

## Décisions
1. **`RunPlayer`** (`src/run/run_player.gd`, RefCounted) regroupe tout ce qui appartient à un joueur : `Player`, `PlayerInput`, `Progression`, `Wallet`, `Inventory`, `Shop`, `ItemEffects`, `WeaponFamilies`, perso. `Run.players` en contient 1 ou 2. Les anciens champs (`run.player`, `run.progression`, `run.shop`, `run.inventory`, `state.wallet`…) pointent sur le joueur 1 : le solo, les tests et les outils de debug ne changent pas.
2. **`Party`** (`src/run/party.gd`, Node) : la liste des `Player` et les requêtes de groupe (`nearest_alive(pos)`, `center()`, `alive_count()`). Les systèmes qui visaient « le joueur » reçoivent la `Party` : ennemis (cible = joueur vivant le plus proche), tirs ennemis (touchent n'importe quel joueur), kamikazes (souffle sur tous), ramassage (vers le joueur vivant le plus proche, crédité à celui qui ramasse), apparitions (autour du centre du groupe), boss (visent le joueur le plus proche). La `Party` retient aussi les joueurs : ils ne peuvent pas s'éloigner de plus de `MAX_SPREAD` l'un de l'autre.
3. **Caméra de groupe** : `GameCamera` n'est plus enfant du joueur ; elle suit le centre du groupe (identique en solo) et dézoome un peu quand les joueurs s'écartent.
4. **Entrées par appareil** : `PlayerInput` crée pour chaque joueur des actions `move_*_pN` copiées des actions `move_*` de l'InputMap, avec le numéro de manette du joueur (clavier pour le joueur 1 seulement). En solo, le joueur lit directement les actions `move_*` (tous les appareils). Attribution : avec 2 manettes, J1 = clavier + manette 0, J2 = manette 1 ; avec une seule manette, J1 = clavier, J2 = manette 0.
5. **Attribution des dégâts** : `EnemyManager.damage_source` (numéro du joueur) est posé par l'arme qui tire, mémorisé par chaque projectile et par la brûlure. Les effets d'objets « à l'élimination » et le vol de vie ne réagissent qu'aux coups de leur joueur.
6. **Mort** : un joueur mort devient un fantôme (ne tire plus, n'est plus visé, ne ramasse plus) et revient à la vague suivante avec tous ses PV. La partie est perdue quand tous les joueurs sont morts.
7. **Entre les vagues** : chaque joueur a sa boutique et ses level-ups (Brotato). **Première version : à tour de rôle** (J1 puis J2), écrans existants avec une étiquette « Joueur N » ; seule la manette du joueur concerné (et le clavier pour J1) agit. Côte à côte en même temps = plus tard si le tour par tour gêne (Godot n'a qu'un seul focus d'interface par fenêtre : il faudrait un SubViewport par joueur).
8. **Difficulté à deux** : `RunConfig.coop_spawn_multiplier` et `coop_hp_multiplier` (données, à régler en playtest). Le plafond de 650 ennemis ne change pas (performance).
9. **Menu** : bouton « Coop locale » → sélection du perso et de l'arme pour J1 puis J2, Danger choisi une fois (celui de J1). `RunSetup` gagne `character_2` / `weapon_2`. Les défis et records sont enregistrés pour le perso de chaque joueur.

## Conséquences
- Tout nouveau système qui vise « le joueur » doit passer par la `Party`.
- Toute nouvelle source de dégâts doit poser `damage_source` avant d'appeler l'API d'`EnemyManager`.
- Deux joueurs = deux fois plus d'armes et de projectiles : stress test en coop à surveiller.
- Manette vue en double (DS4Windows sans HidHide) : une seule manette physique peut apparaître comme deux appareils et piloter les deux joueurs. Réglage côté PC (HidHide).
