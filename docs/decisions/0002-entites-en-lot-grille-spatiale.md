# ADR 0002 — Entités gérées en lot, grille spatiale, pooling

**Statut :** accepté (2026-10-02)

## Contexte
Objectif : 500+ ennemis et 1000+ projectiles à 60 FPS. Avec un `Area2D`/`CharacterBody2D` et un script `_process` par entité, le coût par entité (physique, callbacks, nodes actifs) devient le goulot d'étranglement à quelques centaines d'entités.

## Décision
- Ennemis, projectiles et pickups sont des `Node2D` passifs (visuel + données) **mis à jour par leur manager** dans une seule boucle.
- Collisions et requêtes de proximité par **cercles** via une **grille de hachage spatial** (`src/core/spatial_grid.gd`) reconstruite chaque frame.
- **Pooling** de toutes les entités créées en masse.
- Seul le joueur utilise la physique Godot (`CharacterBody2D`), pour les murs de l'arène.

## Conséquences
- Coût quasi linéaire, logique testable sans moteur physique, comportement déterministe.
- Pas de collisions physiques ennemis/décor : obstacles éventuels gérés comme formes simples dans la grille.
- Règle d'équipe : jamais de `_process` par entité de masse (rappelée dans `CLAUDE.md` et le skill `performance`).
