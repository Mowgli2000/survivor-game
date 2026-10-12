# 0027 — Armes en orbite et vortex

Date : 2026-10-11 · Statut : accepté

## Contexte
Presque toutes les armes à distance tirent un projectile droit : l'élément ne change que le dessin (retour du dev). Il faut des mécaniques de jeu différentes.

## Décision
Pas de nouveau système : les nouvelles mécaniques sont des **champs de `Projectile`**, gérés par `ProjectileManager` (un seul MultiMesh, ADR 0004).
- **Orbite** (`OrbitBehavior`, Lames d'ombre) : à chaque cooldown, des projectiles reçoivent `orbit_owner/angle/radius/speed`. Le manager les place autour du héros chaque frame (`_orbit`), ils traversent tout et **tournent en permanence** : ils finissent avec leur arme (`WeaponSlot.retired`, vendue ou fusionnée). Le « cooldown » de l'arme n'est qu'un entretien : apparition quand un ennemi est à l'écran, remplacement si le nombre change (rang, objets), mise à jour des dégâts et de la taille.
- **Forme de touche en capsule** (`WeaponData.hit_half_length`) : une lame longue touche sur toute sa longueur peinte (dessiné = ce qui fait mal).
- **Touches répétées** (`WeaponData.rehit_time`) : toutes les `rehit_time` secondes la liste `hit_ids` du projectile est vidée, il peut re-toucher.
- **Vortex** (`WeaponData.pull_radius` / `pull_speed`, Orbe arcanique) : `EnemyManager.pull_in_radius` rapproche les ennemis du projectile ; les boss sont tirés 4 fois moins fort.
- Nouveau style de projectile `SHADOW_BLADE` (ajouté en fin d'enum : les `.tres` existants ne changent pas), animation IA de 12 images.

## Conséquences
- Bande de projectiles : 89 cellules de 92 px (8188 px, sous 8192).
- Les `.tres` d'armes existants sont inchangés ; `pulse.tres` change de mécanique (même id, sauvegardes intactes).
