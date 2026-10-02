# ADR 0004 — Projectiles as plain data, rendered with one MultiMesh

**Statut :** accepté (2026-10-02) — complète l'ADR 0002

## Contexte
Stress test (`src/debug/stress_test.tscn`, 500 ennemis + ~1000 projectiles, fenêtre 1280×720) :

| Version | FPS moyen | FPS min | Physique (ms) |
|---|---|---|---|
| Projectiles = `Node2D` avec `_draw`, flash par redraw, requêtes avec rayon max fixe (48 px) | 41 | 25 | 13.0 |
| Flash via `self_modulate` + rayon de requête = plus grand rayon réel | 66 | 51 | 8.8 |
| Expérience : projectiles invisibles | 222 | 183 | 7.7 |
| **Projectiles = données + un seul `MultiMeshInstance2D`** | **220** | **172** | **7.4** |

Le coût dominant était le **rendu** de ~1000 canvas items séparés, pas la logique.

## Décision
- `Projectile` est un `RefCounted` (pas un node). `ProjectileManager` les déplace, résout les impacts et écrit leurs transformations/couleurs dans un `MultiMesh` (un seul draw call). Texture ronde générée en code (`GradientTexture2D`).
- Les ennemis restent des `Node2D` (500 sont abordables, et ils auront des animations/sprites). Leur forme est dessinée une fois en blanc puis teintée avec `self_modulate` : le flash de dégâts ne déclenche jamais de redraw.

## Conséquences
- Ajouter un visuel de projectile = texture/couleur/échelle dans les données, pas de scène par projectile.
- Si les ennemis deviennent le goulot (> ~1000), appliquer la même approche (MultiMesh ou sprites batchés).
- Toujours mesurer avec le stress test après un changement de ces systèmes.
