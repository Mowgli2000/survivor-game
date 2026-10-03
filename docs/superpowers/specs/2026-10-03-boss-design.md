# Étape 6 — Vrais boss (design + plan)

Date : 2026-10-03 · Statut : choix validés par le dev (D46 : mini-boss vague 10 + boss final aléatoire, Shogun d'abord ; « enchaîner sans demander »)

## Objectif
Les boss sont aujourd'hui de gros ennemis qui foncent sur le joueur. Il faut des combats lisibles : attaques annoncées, phases selon les PV, barre de vie, récompense. Critère de réussite : vague 10 = mini-boss Ronin avec barre de vie et récompense ; vague 20 = Shogun en 3 phases ; tuer le Shogun gagne la partie (inchangé).

## Données
- **`BossPattern`** (`src/enemies/boss/boss_pattern.gd`, Resource « strategy ») : `windup` (s, annonce visuelle, le boss s'arrête), `repeats`, `repeat_interval`, `recovery` (pause après le motif). Méthodes `telegraph(ctx, boss)` et `fire(ctx, boss, repeat_index)`.
  - `RadialBurstPattern` : `count` projectiles en cercle, `rotation_step` entre répétitions.
  - `AimedFanPattern` : `count` projectiles en éventail (`spread_degrees`) vers le joueur.
  - `DashPattern` : ruée en ligne droite vers la position du joueur au moment de l'annonce (`dash_speed`, `dash_duration`), annoncée par une ligne.
  - `SummonPattern` : `count` ennemis `enemy` en cercle autour du boss (multiplicateurs de PV/dégâts de la vague).
  - Champs communs de tir : `projectile_speed`, `projectile_damage`, `projectile_radius` (dégâts × multiplicateur de la vague).
- **`BossPhase`** (Resource) : `hp_ratio` (phase active quand PV/PV max ≤ cette valeur ; la première vaut 1), `patterns` (joués dans l'ordre, en boucle), `speed_multiplier`.
- **`EnemyData`** : groupe « Boss » : `phases: Array[BossPhase]` (non vide = barre de vie + motifs), `reward_item_tier` (0 = aucune récompense). `boss = true` garde son sens : le tuer termine la vague. Le mini-boss a des phases mais `boss = false`.
- **`WaveEvent.enemy_choices`** : si non vide, l'ennemi est tiré au hasard dans la liste (boss final aléatoire).

## Système
- **`Enemy`** : `speed_multiplier` (phase), `forced_velocity` + `forced_time` (ruée / arrêt pendant l'annonce). `EnemyManager` les applique dans sa boucle (une comparaison par ennemi).
- **`EnemyManager`** : signal `boss_spawned(enemy)` quand l'ennemi a des phases.
- **`BossDirector`** (nœud de la partie) : suit les boss vivants (1 ou 2, pas de boucle de masse), choisit la phase selon les PV, enchaîne annonce → tirs répétés → récupération. Signaux `boss_started(enemy)`, `boss_phase_changed(enemy, phase_index)`, `boss_ended(enemy)`. Changement de phase : explosion + tremblement.
- **`BossContext`** : ce dont les motifs ont besoin (joueur, ennemis, tirs ennemis, effets, RNG, multiplicateurs de la vague).
- **`Vfx`** : `warning_circle(center, radius, color, life)` et `warning_line(from, to, width, color, life)` (annonces).
- **Récompense** : `Run` donne, à la mort d'un ennemi avec `reward_item_tier > 0`, un objet aléatoire de ce rang ou plus (non bloqué par `max_count`), et le HUD affiche un message (« Récompense : X »).
- **`BossBar`** (HUD, en haut au centre) : nom, barre de PV (couleur du boss), apparaît/disparaît avec les signaux, lit les PV chaque image tant qu'elle est visible.

## Contenu
- **Ronin** (mini-boss, vague 10, remplace les 2 tireurs élites) : 350 PV de base (× ~4,3 en vague 10), sprite du colosse teinté cyan. Phase 1 : ruée, éventail de 3. Phase 2 (≤ 50 %) : cercle de 10 + ruée, vitesse ×1,25. Récompense : objet de rang II ou plus.
- **Shogun** (vague 20, `enemy_choices = [shogun]`) : Phase 1 : éventail de 5, cercle de 12. Phase 2 (≤ 60 %) : ruée, cercle de 16 ×2. Phase 3 (≤ 30 %) : invocation de 6 coureurs, cercle de 20 ×3 en rotation, ruée ; vitesse ×1,3.

## Tests
- `BossPhase` / `EnemyData.phase_index_for(ratio)`.
- Chaque motif : nombre de projectiles / ennemis créés, direction de l'éventail, ruée qui force la vitesse.
- `BossDirector` : boss suivi à l'apparition, annonce puis tir, changement de phase à 50 %, fin à la mort.
- Récompense : tuer le Ronin ajoute un objet de rang ≥ II.
- `WaveEvent.enemy_choices`.
- Données : tout ennemi à phases a une première phase à 1,0, des motifs valides, un rayon ≤ 48.
- `BossBar` visible avec un boss, cachée après.

## Outils
Capture `--boss` (Shogun ou Ronin à côté du joueur). Stress test inchangé (pas de boss).
