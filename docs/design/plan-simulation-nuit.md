# Plan de simulation de nuit (à lancer sur « go nuit » du dev)

Branche à part (worktree `../sg_balance`, branche `night/sim` ou `sim/<date>`), rapport le matin. Simulateur : ADR 0019,
`python tools/balance/run_balance.py`, ~14 processus parallèles sur 16 coeurs, 1-3 min de CPU par partie. Durée estimée : ~4 h.

1. **Joueur mobile** : `--characters all --seals 0-5 --weapons both --policies dps,family,random` (~252 parties, ~1 h 30).
   Cibles du dev (mémoire `seal-difficulty-curve`) : victoires ~100/90/75/55/40/25 % aux dangers 0-5 ; crescendo net.
2. **Joueur immobile** : `--static --seals 0-2` (~40 min) : un build immobile doit gagner au danger 0, rester envisageable aux dangers 1-2.
3. **Mode infini** : `--endless 40 --seals 0-2 --policies dps` (~1 h 30) : boss toutes les 5 vagues (`endless_boss_every = 5`) ;
   cible : « vraiment, vraiment difficile » vers la vague 35 (médiane de mort entre les vagues 30 et 40 pour le bot dps au danger 0 ; au danger 2,
   plus tôt). Leviers : `endless_hp_growth` (0,07), `endless_damage_growth` (0,04), `endless_spawn_growth` (0,03), `endless_elite_growth` (0,015).
4. **Armes** : taux de victoire et dégâts par arme de départ (rapport `report.py`) ; contrôle de l'ordre Arc céleste > Lames d'ombre > Faux > le reste.

Le matin : rapport + propositions de valeurs ; aucune valeur de donnée n'est modifiée sans accord du dev, sauf le réglage évident de la
courbe infinie si la cible n'est manifestement pas atteinte.
