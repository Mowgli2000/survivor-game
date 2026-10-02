# ADR 0005 — API de dégâts centralisée, couche VFX unique, sprites ennemis précalculés

**Statut :** accepté (2026-10-02) — Phase 2

## Contexte
La Phase 2 ajoute plusieurs façons de toucher (arc, rayon, explosion, ricochet, éclair en chaîne), des statuts (brûlure, ralentissement, électrocution), des effets néon et des chiffres de dégâts, sans casser l'objectif de performance.

## Décisions
1. **Toutes les règles de dégâts passent par `EnemyManager`** : `damage_enemy`, `damage_in_radius` (cercle ou arc), `damage_along_segment` (rayon). Armure, statuts, recul, signaux et feedback sont gérés à un seul endroit. Les comportements d'armes ne font que choisir *où* frapper.
2. **Armes = `WeaponData` (niveau 1) + `levels: Array[WeaponLevel]`**, résolues en `WeaponStats` par `WeaponSlot`. Ajouter une arme = un `.tres` ; un comportement nouveau seulement si la forme d'attaque est nouvelle (4 aujourd'hui : tir, arc, rayon, et les options de projectile ricochet/explosion).
3. **Effets visuels** : un seul nœud `Vfx` (tableaux plats, rendu additif, capacité bornée) et un seul `DamageNumbers` (anneau de 160 entrées, max 6 nouveaux chiffres normaux + 6 critiques par image).
4. **Ennemis** : leur look néon (corps sombre, contour, halo, bords lissés) est **précalculé une fois par type** dans une texture (`EnemyArt`) ; chaque ennemi dessine une seule texture.

## Mesures (stress test : 500 ennemis, ~1000 projectiles, 6 armes niveau max)
| Version | FPS moyen | FPS min |
|---|---|---|
| Ennemis dessinés avec halo + lignes anticrénelées | 49 | 35 |
| Ennemis : 2 commandes simples (expérience) | 137 | 109 |
| **Ennemis : 1 texture précalculée** | **204** | **155** |

Les chiffres de dégâts sans limite coûtaient ~14 FPS supplémentaires dans la horde (et étaient illisibles), d'où le plafond par image.

## Conséquences
- Interdit : `draw_*` anticrénelé ou multi-couches par entité de masse. Un look complexe se précalcule en texture (ce sera aussi le chemin des vrais sprites).
- Filtrage de texture par défaut passé en **linéaire** (direction néon, textures tournées).
- `src/debug/vfx_gallery.tscn` montre tous les effets et ennemis pour régler la direction artistique.
