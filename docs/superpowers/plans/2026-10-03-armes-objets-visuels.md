# Armes et objets visibles — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Icônes SVG pour les 6 armes et 15 objets, armes visibles autour du joueur (visée, recul, coup), icônes en boutique et dans le HUD.

**Architecture:** `WeaponLayout` (pur) donne les points de montage ; `WeaponHolder` les écrit dans chaque `WeaponSlot` et émet `weapon_fired` ; les comportements tir/rayon partent du canon via `WeaponContext.muzzle()`. `WeaponVisuals` (un nœud, un `_draw`) dessine les armes avec un shader de contour de rang. `IconTile` affiche une icône encadrée à la couleur du rang dans l'interface.

**Tech Stack:** Godot 4.7.2, GDScript typé, GUT 9.6.1, SVG importés.

**Spec:** `docs/superpowers/specs/2026-10-03-armes-objets-visuels-design.md`

## Global Constraints

- Tous les dégâts passent par `EnemyManager` ; cible choisie depuis le centre du perso ; seule l'origine des projectiles/rayons change.
- Stress test ≥ 150 FPS moyen (comparé en alterné, ADR 0009).
- Contenu en `.tres` ; ids inchangés ; icônes = `assets/icons/{weapons,items}/<id>.svg`.
- UI : lit l'état, n'écrit jamais l'état ; textes via clés de traduction.
- Commentaires de code en anglais, docs en français.

## Review Focus

- Arme sans icône (arme de test du stress test) : pas dessinée en jeu, texte seul en interface, aucune erreur → test Task 3/4.
- Aucun ennemi à portée : l'arme vise la direction de marche, pas d'erreur → test Task 3.
- Nombre d'armes qui change (achat, vente, fusion) : points de montage recalculés → test Task 1.
- Visée vers la gauche : arme retournée verticalement, pas à l'envers → vérification visuelle Task 3.
- Projectile qui part du canon hors de l'arène (perso collé au bord) : le projectile reste géré normalement → test Task 1.

---

### Task 1: Points de montage, origine au canon, signal de tir

**Files:** Create `src/weapons/weapon_layout.gd` · Modify `src/weapons/weapon_slot.gd`, `weapon_holder.gd`, `weapon_context.gd`, `behaviors/projectile_shooter_behavior.gd`, `behaviors/beam_behavior.gd` · Test `tests/unit/test_weapons.gd`

**Interfaces — Produces:** `WeaponLayout.MOUNT_RADIUS`, `WeaponLayout.BARREL`, `WeaponLayout.mount_offset(index: int, count: int) -> Vector2` ; `WeaponSlot.mount_offset: Vector2` ; `WeaponHolder.weapon_fired(index: int)` ; `WeaponContext.muzzle(slot: WeaponSlot, direction: Vector2) -> Vector2`.

- [ ] Tests :
```gdscript
func test_layout_spreads_mounts_on_a_circle() -> void:
	assert_almost_eq(WeaponLayout.mount_offset(0, 1), Vector2(WeaponLayout.MOUNT_RADIUS, 0), Vector2.ONE * 0.01)
	var seen: Array[Vector2] = []
	for i in 6:
		var p := WeaponLayout.mount_offset(i, 6)
		assert_almost_eq(p.length(), WeaponLayout.MOUNT_RADIUS, 0.01)
		for q in seen:
			assert_gt(p.distance_to(q), 1.0)
		seen.append(p)


func test_holder_updates_mounts_when_weapons_change() -> void:
	var holder := _holder()
	var a := holder.add_weapon(_weapon())
	assert_eq(a.mount_offset, WeaponLayout.mount_offset(0, 1))
	var b := holder.add_weapon(_weapon())
	assert_eq(a.mount_offset, WeaponLayout.mount_offset(0, 2))
	assert_eq(b.mount_offset, WeaponLayout.mount_offset(1, 2))
	holder.remove_weapon(0)
	assert_eq(b.mount_offset, WeaponLayout.mount_offset(0, 1))
```
Dans `test_enemy_manager.gd` (contexte réel) :
```gdscript
func test_projectiles_start_at_the_weapon_muzzle() -> void:
	_enemies.spawn(_data, Vector2(300, 0))
	await wait_physics_frames(1)
	var data: WeaponData = ContentDB.get_def(&"weapons", &"pulse")
	var slot := WeaponSlot.new(data)
	slot.mount_offset = Vector2(0, -30)
	var ctx := WeaponContext.new(_player, StatBlock.from_defaults({}), _enemies, _projectiles, RandomNumberGenerator.new())
	assert_true(data.behavior.fire(slot, ctx))
	var expected := ctx.muzzle(slot, (Vector2(300, 0) - Vector2(0, -30)).normalized())
	assert_almost_eq(_projectiles.get_position(0), expected, Vector2.ONE * 0.5)
	assert_ne(expected, _player.global_position)


func test_holder_emits_weapon_fired() -> void:
	_enemies.spawn(_data, Vector2(100, 0))
	await wait_physics_frames(1)
	var holder := WeaponHolder.new()
	add_child_autofree(holder)
	holder.setup(WeaponContext.new(_player, StatBlock.from_defaults({}), _enemies, _projectiles, RandomNumberGenerator.new()))
	holder.add_weapon(ContentDB.get_def(&"weapons", &"pulse"))
	watch_signals(holder)
	await wait_physics_frames(2)
	assert_signal_emitted_with_parameters(holder, "weapon_fired", [0])
```
(Si `ProjectileManager` n'expose pas la position d'un projectile, ajouter `get_position(index: int) -> Vector2` en lecture seule.)
- [ ] Lancer → échec.
- [ ] Implémenter :
  - `weapon_layout.gd` : `class_name WeaponLayout` ; `const MOUNT_RADIUS := 34.0` ; `const BARREL := 22.0` ; `static func mount_offset(index, count)` = `Vector2.from_angle(TAU * index / maxi(count, 1)) * MOUNT_RADIUS`.
  - `WeaponSlot` : `var mount_offset := Vector2.ZERO` (« Position of the weapon around its owner, set by WeaponHolder »).
  - `WeaponHolder` : `signal weapon_fired(index: int)` ; `_refresh_mounts()` appelé après chaque changement de `_slots` (add, remove, merge) ; dans la boucle de tir, `for i in _slots.size()` et `weapon_fired.emit(i)` après un tir réussi.
  - `WeaponContext.muzzle(slot, direction)` = `owner.global_position + slot.mount_offset + direction * WeaponLayout.BARREL`.
  - `ProjectileShooterBehavior` / `BeamBehavior` : cible depuis le centre (inchangé) ; `origin` des projectiles / du rayon = `ctx.muzzle(slot, direction vers la cible depuis le point de montage)`. Le rayon garde sa longueur (portée) depuis le canon.
- [ ] Tests verts ; commit `feat: weapon mounts, muzzle origin, weapon_fired signal`.

---

### Task 2: Icônes SVG + données

**Files:** Create `assets/icons/weapons/*.svg` (6), `assets/icons/items/*.svg` (15), `src/debug/icon_sheet.gd` + `.tscn` · Modify `src/weapons/weapon_data.gd`, `src/items/item_data.gd`, `data/weapons/*.tres`, `data/items/*.tres` · Test `tests/data/test_content.gd`

- [ ] Test de contenu (dans `test_weapons()` et `test_items()`) : `assert_not_null(def.icon, "%s has no icon" % def.id)`.
- [ ] Lancer → échec (`icon` inconnu).
- [ ] `WeaponData` (groupe Visual) et `ItemData` : `@export var icon: Texture2D` (« Shop/HUD icon; weapons also use it as their in-game sprite (barrel pointing right) »).
- [ ] Dessiner les 21 SVG (viewBox 0 0 128 128, contour `#000` 6 px `stroke-linejoin="round"`, aplats `#e8e8ee`/`#9a9aa6`, ombre plate, un accent néon). Armes : profil, canon à droite, poignée vers (40, 70). Accents : pulse `#ffeb73`, katana `#ff33cc`, laser `#33f2ff`, shuriken `#fff233`, smg `#8cff4d`, bazooka `#ff8026`. Objets : accent de la stat principale (dégâts rouge `#ff4d5e`, vitesse d'attaque jaune `#ffd23f`, PV vert `#5cff8a`, armure bleu `#4da6ff`, vitesse cyan `#4de6ff`, portée violet `#b366ff`, critique orange `#ff8c1a`, zone magenta `#ff4dd2`, ramassage turquoise `#3dffc5`, régénération vert clair `#a6ff4d`, projectiles blanc-bleu `#cfe8ff`).
- [ ] Import : `.import` de chaque SVG avec `mipmaps/generate=true` et `svg/scale=1.0` (lancer `--import`, puis éditer les `.import` générés, relancer `--import`).
- [ ] Renseigner `icon = ExtResource(...)` dans les 21 `.tres` (ajout d'un `ext_resource` Texture2D).
- [ ] `icon_sheet.tscn` : grille de toutes les icônes d'armes et d'objets (96 px, fond sombre + cadre de rang), capture `-- --out=`.
- [ ] Capture, examen, retouches ; tests verts ; commit `feat: weapon and item SVG icons`.

---

### Task 3: Armes visibles autour du joueur

**Files:** Create `src/weapons/weapon_visuals.gd`, `src/weapons/weapon_outline.gdshader` · Modify `src/player/player.gd` · Test `tests/unit/test_weapon_visuals.gd`

**Interfaces — Consumes:** Task 1 (`mount_offset`, `weapon_fired`), Task 2 (`icon`). **Produces:** `WeaponVisuals.setup(holder: WeaponHolder, enemies: EnemyManager, owner: Player)`, `WeaponVisuals.aim_angle(index: int) -> float`, `WeaponVisuals.kick(index: int) -> float` (0..1).

- [ ] Tests :
```gdscript
# aims at the nearest enemy from its mount; idle aim follows movement; firing kicks; no icon = skipped
```
Cas : ennemi à droite → `aim_angle(0) ≈ 0` après quelques images ; aucun ennemi + joueur qui va à gauche → `aim_angle ≈ PI` ; `holder.weapon_fired.emit(0)` → `kick(0) > 0`, puis retombe à 0 ; arme sans icône → aucune erreur.
- [ ] Lancer → échec.
- [ ] Implémenter `WeaponVisuals` (Node2D, `z_index` 1, `material` = ShaderMaterial du contour) :
  - état par arme (tableaux parallèles, redimensionnés sur `weapons_changed`) : `_aim: PackedFloat32Array`, `_kick: PackedFloat32Array` ;
  - `_process(delta)` : pour chaque slot, cible = `enemies.find_nearest(owner.global_position + mount, range)` ; angle visé → `lerp_angle` (vitesse 18/s) ; `_kick -= delta / KICK_TIME` ; `queue_redraw()` ;
  - `_draw()` : pour chaque slot avec icône : `draw_set_transform(mount - recul, angle (+ swing pour la mêlée), Vector2(1, -1 si |angle| > PI/2 sinon 1) * scale)` puis `draw_texture(icon, -pivot, Tiers.color(slot.level))` ; éclair de bouche (cercle additif de la couleur de l'arme) pendant le début du recul.
  - Mêlée = comportement `MeleeArcBehavior` : swing d'angle `lerp(-1.0, 1.0, 1 - kick)` rad au lieu du recul.
- [ ] Shader `weapon_outline.gdshader` (canvas_item) : échantillonne l'alpha sur 8 voisins à `TEXTURE_PIXEL_SIZE * 3` ; sortie = texture non teintée sur un contour de couleur `COLOR.rgb`.
- [ ] `Player` : crée `WeaponVisuals` dans `_ready()` ; `run.gd` appelle `player.weapon_visuals.setup(player.weapons, enemies, player)` après la création des managers.
- [ ] Tests verts ; capture `capture.tscn -- --time=20 --allweapons` ; examen ; commit `feat: weapons visible around the player`.

---

### Task 4: Icônes dans l'interface

**Files:** Create `src/ui/common/icon_tile.gd` · Modify `src/ui/shop/shop_screen.gd`, `src/ui/hud/hud.gd` · Test `tests/unit/test_shop_screen.gd`, `tests/unit/test_icon_tile.gd`

- [ ] Tests : `IconTile.create(texture, tier, size, badge)` → bordure = `Tiers.color(tier)`, badge visible seulement si non vide, texture nulle → pas d'erreur ; écran boutique : chaque carte d'offre contient une `IconTile` ; la rangée d'objets contient une `IconTile` par objet possédé avec badge `×N`.
- [ ] Lancer → échec.
- [ ] `IconTile` (`PanelContainer`, `class_name IconTile`) : `static func create(texture: Texture2D, tier: int, size: float, badge: String = "") -> IconTile` ; style fond `Color(0.06, 0.06, 0.1, 0.9)`, bordure 3 px couleur de rang, coins 8 ; `TextureRect` (`EXPAND_IGNORE_SIZE`, `STRETCH_KEEP_ASPECT_CENTERED`) ; badge = `Label` en bas à droite.
- [ ] Boutique : carte → `IconTile` 96 px en tête (arme : rang de l'offre ; objet : son rang) ; boutons d'armes possédées → `button.icon = slot.data.icon` + `expand_icon` ; rangée d'objets → `HFlowContainer` d'`IconTile` 56 px (`tooltip_text` = nom traduit) précédée du libellé `UI_SHOP_ITEMS`.
- [ ] HUD : liste des armes → `HBoxContainer` d'`IconTile` 48 px (texte de repli si pas d'icône).
- [ ] Tests verts ; captures `--waveend` (boutique) et partie ; commit `feat: icons in shop and HUD`.

---

### Task 5: Performance, documentation

- [ ] Stress test alterné (3 × 15 s) contre le commit d'avant le chantier, dans un worktree du scratchpad ; seuil 150.
- [ ] ADR 0010 « Armes visibles » ; `CLAUDE.md` (ajouter une arme = `.tres` + icône SVG) ; `PROJECT_STATUS.md` (D36, session 4, suite : chantier 3).
- [ ] Tests + check_scripts ; commit `docs: ADR 0010 visible weapons, status`.
