# ADR 0001 — GDScript typé, Godot 4.7.2, renderer Compatibility

**Statut :** accepté (2026-10-02)

## Contexte
Jeu 2D commercial développé par un dev non senior assisté par Claude Code, avec beaucoup d'entités à l'écran.

## Décision
- Langage : **GDScript avec typage statique** partout.
- Moteur figé sur **Godot 4.7.2** (ne changer de version qu'après vérification GodotSteam/GUT et via un nouvel ADR).
- Renderer **Compatibility** (OpenGL) pour couvrir le maximum de PC et le Steam Deck.

## Conséquences
- Itération rapide, pas de build C#, intégration éditeur complète.
- Les performances reposent sur l'architecture (traitement en lot, grille spatiale, pooling — voir ADR 0002), pas sur le langage.
- Plan B si un hot-path ne tient pas après mesure : MultiMesh, données en tableaux packés, puis GDExtension/C# ciblé.
