# Sprites animés — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remplacer les formes néon du joueur et des ennemis par des sprites chibi animés (pack RGS_Dev), avec un sol clair, sans perdre la performance.

**Architecture:** Un outil headless convertit le pack en planches PNG + ressources `SpriteSheet` (`.tres`). `SpriteSheet` (données + dessin) et `SpriteAnimator` (temps, image, orientation) sont du code pur dans `src/core/`. `Enemy` et `Player` dessinent la case courante ; `EnemyManager` fait avancer l'animation dans sa boucle et ne redessine qu'au changement d'image. Repli sur le rendu `EnemyArt` si pas de sprite.

**Tech Stack:** Godot 4.7.2, GDScript typé, GUT 9.6.1, PowerShell.

**Spec:** `docs/superpowers/specs/2026-10-03-sprites-animes-design.md`

## Global Constraints

- Pas de `_process` par ennemi ; animation avancée par `EnemyManager` (ADR 0002).
- Pas de `draw_*` anticrénelé par entité de masse ; une région de texture par ennemi (ADR 0005).
- Stress test ≥ 150 FPS moyen (référence ≈ 180).
- Collisions, rayons et gameplay inchangés.
- Contenu en `.tres` ; jamais de chargement depuis `user://`.
- Pack brut dans `assets_src/` (ignoré par git, `.gdignore` présent) ; sorties commitées dans `assets/sprites/`.
- Commentaires de code en anglais, docs en français.

**Écart assumé avec la spec :** les métadonnées des planches sont des ressources `SpriteSheet` (`.tres`) et non des `.json` : l'export Windows n'embarque pas les `.json` (`include_filter` vide) et le projet stocke son contenu en `.tres`. L'élite a sa propre planche `<id>_elite` (halo doré précalculé) : un liseré doré par double dessin teinterait aussi le sprite.

## Review Focus

- Ennemi sans `sprite_id` (ou planche absente) : rendu néon actuel, aucune erreur → test Task 3.
- Animation demandée absente de la planche (runner n'a pas `idle`) : garder `walk` → test Task 1.
- Élite d'un type sans planche `_elite` : utiliser la planche normale → test Task 3.
- Ennemi recyclé par le pool avec un autre type : bonne planche, image valide → test Task 3.
- Temps d'animation énorme (partie longue) : image toujours dans les bornes → test Task 1.

---

### Task 1: SpriteSheet et SpriteAnimator

**Files:**
- Create: `src/core/sprite_sheet.gd`, `src/core/sprite_animator.gd`
- Test: `tests/unit/test_sprite_sheet.gd`

**Interfaces:**
- Produces:
  - `SpriteSheet` (Resource) : `texture: Texture2D`, `cell_size: Vector2i`, `animations: Dictionary[StringName, Vector3i]` (x = première case, y = nombre d'images, z = images/s), `has_animation(name: StringName) -> bool`, `frame_at(name: StringName, time: float) -> int`, `region(frame: int) -> Rect2`, `draw(canvas: CanvasItem, frame: int, height: float, foot_y: float, facing: float, tint: Color) -> void`.
  - `SpriteAnimator` (RefCounted) : `sheet`, `animation`, `time`, `frame`, `facing`, `reset(p_sheet: SpriteSheet, start_time: float) -> void`, `advance(delta: float, p_animation: StringName, facing_x: float) -> bool` (true si redessin nécessaire).

- [ ] **Step 1: Tests**

```gdscript
extends GutTest
## SpriteSheet (frame lookup, regions) and SpriteAnimator (looping, facing).


func _sheet() -> SpriteSheet:
	var sheet := SpriteSheet.new()
	sheet.cell_size = Vector2i(10, 20)
	sheet.animations = {&"idle": Vector3i(0, 4, 8), &"walk": Vector3i(4, 2, 10)}
	return sheet


func test_frame_at_loops() -> void:
	var sheet := _sheet()
	assert_eq(sheet.frame_at(&"idle", 0.0), 0)
	assert_eq(sheet.frame_at(&"idle", 0.13), 1)
	assert_eq(sheet.frame_at(&"idle", 0.5), 0, "4 frames at 8 fps loop every 0.5 s")
	assert_eq(sheet.frame_at(&"walk", 0.15), 5)


func test_frame_stays_in_bounds_for_huge_times() -> void:
	var f := _sheet().frame_at(&"walk", 123456.789)
	assert_between(f, 4, 5)


func test_missing_animation_falls_back_to_walk() -> void:
	var sheet := _sheet()
	assert_false(sheet.has_animation(&"fly"))
	assert_eq(sheet.frame_at(&"fly", 0.0), 4)


func test_region() -> void:
	assert_eq(_sheet().region(5), Rect2(50, 0, 10, 20))


func test_animator_reports_frame_and_facing_changes() -> void:
	var animator := SpriteAnimator.new()
	animator.reset(_sheet(), 0.0)
	assert_false(animator.advance(0.01, &"walk", 0.0), "same frame, no facing input")
	assert_true(animator.advance(0.1, &"walk", 0.0), "walk frame 4 -> 5")
	assert_true(animator.advance(0.0, &"walk", -5.0), "turned left")
	assert_eq(animator.facing, -1.0)
	assert_false(animator.advance(0.0, &"walk", -5.0))


func test_animator_keeps_current_animation_when_missing() -> void:
	var animator := SpriteAnimator.new()
	animator.reset(_sheet(), 0.0)
	animator.advance(0.0, &"fly", 0.0)
	assert_eq(animator.animation, &"walk")


func test_animator_without_sheet_does_nothing() -> void:
	var animator := SpriteAnimator.new()
	animator.reset(null, 0.0)
	assert_false(animator.advance(1.0, &"walk", 3.0))
```

- [ ] **Step 2: Lancer, vérifier l'échec** — `powershell -ExecutionPolicy Bypass -File tools/run_tests.ps1` → échec (classes inconnues).

- [ ] **Step 3: Implémentation**

`src/core/sprite_sheet.gd` :
```gdscript
class_name SpriteSheet
extends Resource
## Horizontal strip of animation frames, generated by tools/sprites/bake_sprites.gd.
## Each animation is a run of consecutive cells. Pure data + one draw helper.

## Used when an animation is missing (every sheet has at least "walk").
const FALLBACK := &"walk"

@export var texture: Texture2D
@export var cell_size := Vector2i(1, 1)
## Animation name -> Vector3i(first cell, frame count, frames per second).
@export var animations: Dictionary[StringName, Vector3i] = {}


func has_animation(anim: StringName) -> bool:
	return animations.has(anim)


## Absolute cell index of `anim` after `time` seconds (looping).
func frame_at(anim: StringName, time: float) -> int:
	var info: Vector3i = animations.get(anim, animations.get(FALLBACK, Vector3i(0, 1, 1)))
	var count := maxi(info.y, 1)
	return info.x + posmod(int(floor(time * info.z)), count)


func region(frame: int) -> Rect2:
	return Rect2(frame * cell_size.x, 0, cell_size.x, cell_size.y)


## Draws `frame` scaled to `height` px, feet at `foot_y`, mirrored when facing < 0.
func draw(canvas: CanvasItem, frame: int, height: float, foot_y: float, facing: float, tint: Color) -> void:
	var size := Vector2(height * cell_size.x / float(cell_size.y), height)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0))
	canvas.draw_texture_rect_region(texture, Rect2(Vector2(-size.x * 0.5, foot_y - size.y), size),
		region(frame), tint)
	canvas.draw_set_transform(Vector2.ZERO)
```

`src/core/sprite_animator.gd` :
```gdscript
class_name SpriteAnimator
extends RefCounted
## Playback state of a SpriteSheet: current animation, time, frame and facing.
## advance() tells the owner when it must redraw (frame or facing changed).

## Ignore tiny horizontal movements so sprites do not flicker left/right.
const FACING_DEADZONE := 0.5

var sheet: SpriteSheet
var animation: StringName = SpriteSheet.FALLBACK
var time: float = 0.0
var frame: int = 0
## 1.0 = facing right (art default), -1.0 = mirrored.
var facing: float = 1.0


func reset(p_sheet: SpriteSheet, start_time: float) -> void:
	sheet = p_sheet
	animation = SpriteSheet.FALLBACK
	time = start_time
	facing = 1.0
	frame = sheet.frame_at(animation, time) if sheet != null else 0


func advance(delta: float, p_animation: StringName, facing_x: float) -> bool:
	if sheet == null:
		return false
	var changed := false
	if p_animation != animation and sheet.has_animation(p_animation):
		animation = p_animation
	time += delta
	var f := sheet.frame_at(animation, time)
	if f != frame:
		frame = f
		changed = true
	if absf(facing_x) > FACING_DEADZONE:
		var side := signf(facing_x)
		if side != facing:
			facing = side
			changed = true
	return changed
```

- [ ] **Step 4: Lancer les tests** → tout passe.
- [ ] **Step 5: Commit** — `feat: SpriteSheet and SpriteAnimator`.

---

### Task 2: Outil de conversion + planches générées

**Files:**
- Create: `tools/sprites/sprites.json`, `tools/sprites/bake_sprites.gd`, `tools/bake_sprites.ps1`
- Create (générés) : `assets/sprites/{player,grunt,grunt_elite,runner,runner_elite,shooter,shooter_elite,tank,tank_elite}.png` + `.tres`, `assets/sprites/ground.png`
- Modify: `assets/CREDITS.md`

**Interfaces:**
- Consumes: `SpriteSheet` (Task 1).
- Produces: `res://assets/sprites/<id>.tres` (SpriteSheet) et `res://assets/sprites/ground.png`.

- [ ] **Step 1: Recette** `tools/sprites/sprites.json`

```json
{
  "pack": "assets_src/third_party/rgs_characters/Free 2D Animated Vector Game Character Sprites",
  "height": 128,
  "ground": "Environment/ground_white.png",
  "sprites": {
    "player":  { "src": "Full body animated characters/Char 1/no hands", "anims": { "idle": "idle:6:8", "walk": "walk:8:12" }, "glow": "#4de6ff" },
    "grunt":   { "src": "Full body animated characters/Enemies/Enemy 1", "anims": { "idle": "idle:6:8", "walk": "walk:8:12" }, "glow": "#d94d59", "elite": true },
    "runner":  { "src": "Full body animated characters/Enemies/Enemy 3", "anims": { "walk": "fly:6:14" }, "glow": "#f2a633", "elite": true },
    "shooter": { "src": "Full body animated characters/Enemies/Enemy 2", "anims": { "idle": "idle:6:8", "walk": "walk:8:12" }, "glow": "#bf59ff", "elite": true },
    "tank":    { "src": "Full body animated characters/Enemies/Enemy 4", "anims": { "idle": "idle:6:6", "walk": "walk:8:9" }, "glow": "#ff5933", "elite": true }
  }
}
```
Format d'animation : `"<préfixe source>:<images>:<images/s>"`. Couleurs de halo = `color` actuelle des `EnemyData`.

- [ ] **Step 2: Script** `tools/sprites/bake_sprites.gd` (SceneTree, deux phases : `--phase=images` écrit les PNG ; `--phase=resources` écrit les `.tres` après import).

```gdscript
extends SceneTree
## Converts the raw RGS_Dev pack into game sprite sheets. Run via tools/bake_sprites.ps1:
##   phase "images": crop (union of frames), downscale, add a neon glow, write strips;
##   phase "resources": after import, write one SpriteSheet .tres per strip.
## Fails loudly when a folder, frame or animation of the recipe is missing.

const RECIPE := "res://tools/sprites/sprites.json"
const OUT_DIR := "res://assets/sprites/"
## Transparent margin around each cell, room for the glow.
const PAD := 8
const GLOW_SHRINK := 4
const GLOW_GAIN := 2.2
const ELITE_GLOW := Color(1.0, 0.8, 0.2)
const GROUND_SIZE := 512


func _initialize() -> void:
	var phase := "images"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--phase="):
			phase = arg.trim_prefix("--phase=")
	var recipe: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RECIPE))
	if recipe == null:
		_fail("cannot read " + RECIPE)
		return
	var ok := _bake_images(recipe) if phase == "images" else _write_resources(recipe)
	quit(0 if ok else 1)


func _bake_images(recipe: Dictionary) -> bool:
	var pack := ProjectSettings.globalize_path("res://" + String(recipe.pack))
	var sprites: Dictionary = recipe.sprites
	for id: String in sprites:
		var def: Dictionary = sprites[id]
		var frames := _load_frames(pack.path_join(def.src), def.anims)
		if frames.is_empty():
			return false
		var cells := _crop_and_scale(frames, int(recipe.height))
		_save_strip(cells, Color(def.glow), id)
		if def.get("elite", false):
			_save_strip(cells, ELITE_GLOW, id + "_elite")
	var ground := Image.load_from_file(pack.path_join(recipe.ground))
	if ground == null:
		return _fail("missing ground " + String(recipe.ground))
	ground.resize(GROUND_SIZE, GROUND_SIZE, Image.INTERPOLATE_LANCZOS)
	ground.save_png(OUT_DIR + "ground.png")
	print("Images baked.")
	return true


## Frames of every animation, in recipe order. Empty array on error.
func _load_frames(dir: String, anims: Dictionary) -> Array[Image]:
	var frames: Array[Image] = []
	for anim: String in anims:
		var parts := String(anims[anim]).split(":")
		for i in int(parts[1]):
			var path := dir.path_join("%s_%d.png" % [parts[0], i])
			var image := Image.load_from_file(path)
			if image == null:
				_fail("missing frame " + path)
				return []
			image.convert(Image.FORMAT_RGBA8)
			frames.append(image)
	return frames


## Crops every frame to the union of their used rects, then scales to `height`.
func _crop_and_scale(frames: Array[Image], height: int) -> Array[Image]:
	var union := frames[0].get_used_rect()
	for image in frames:
		union = union.merge(image.get_used_rect())
	var width := maxi(1, roundi(union.size.x * height / float(union.size.y)))
	var cells: Array[Image] = []
	for image in frames:
		var cell := image.get_region(union)
		cell.resize(width, height, Image.INTERPOLATE_LANCZOS)
		cells.append(cell)
	return cells


func _save_strip(cells: Array[Image], glow: Color, id: String) -> void:
	var cw := cells[0].get_width() + PAD * 2
	var ch := cells[0].get_height() + PAD * 2
	var strip := Image.create(cw * cells.size(), ch, false, Image.FORMAT_RGBA8)
	for i in cells.size():
		strip.blit_rect(_with_glow(cells[i], glow), Rect2i(0, 0, cw, ch), Vector2i(i * cw, 0))
	strip.save_png(OUT_DIR + id + ".png")


## Pads the cell and puts a soft neon halo (blurred silhouette) behind it.
func _with_glow(cell: Image, glow: Color) -> Image:
	var w := cell.get_width() + PAD * 2
	var h := cell.get_height() + PAD * 2
	var padded := Image.create(w, h, false, Image.FORMAT_RGBA8)
	padded.blit_rect(cell, Rect2i(Vector2i.ZERO, cell.get_size()), Vector2i(PAD, PAD))
	# Blur by shrinking and growing back (native, fast).
	var blur := padded.duplicate() as Image
	blur.resize(maxi(1, w / GLOW_SHRINK), maxi(1, h / GLOW_SHRINK), Image.INTERPOLATE_BILINEAR)
	blur.resize(w, h, Image.INTERPOLATE_CUBIC)
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var a := clampf(blur.get_pixel(x, y).a * GLOW_GAIN, 0.0, 1.0)
			out.set_pixel(x, y, Color(glow, a * 0.8))
	out.blend_rect(padded, Rect2i(0, 0, w, h), Vector2i.ZERO)
	return out


func _write_resources(recipe: Dictionary) -> bool:
	var sprites: Dictionary = recipe.sprites
	for id: String in sprites:
		var def: Dictionary = sprites[id]
		var ids: Array[String] = [id]
		if def.get("elite", false):
			ids.append(id + "_elite")
		for out_id in ids:
			var texture: Texture2D = load(OUT_DIR + out_id + ".png")
			if texture == null:
				return _fail("strip not imported: " + out_id)
			var sheet := SpriteSheet.new()
			sheet.texture = texture
			var start := 0
			for anim: String in def.anims:
				var parts := String(def.anims[anim]).split(":")
				sheet.animations[StringName(anim)] = Vector3i(start, int(parts[1]), int(parts[2]))
				start += int(parts[1])
			sheet.cell_size = Vector2i(texture.get_width() / start, texture.get_height())
			if ResourceSaver.save(sheet, OUT_DIR + out_id + ".tres") != OK:
				return _fail("cannot save " + out_id)
	print("Resources written.")
	return true


func _fail(message: String) -> bool:
	printerr("bake_sprites: " + message)
	return false
```

- [ ] **Step 3: Lanceur** `tools/bake_sprites.ps1`

```powershell
# Bakes sprite sheets from the raw asset pack (assets_src/, not in git).
# Usage: powershell -ExecutionPolicy Bypass -File tools/bake_sprites.ps1
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$godot = if ($env:GODOT_BIN) { $env:GODOT_BIN } else { "C:\Program Files\Godot\Godot.exe" }
New-Item -ItemType Directory -Force "$root\assets\sprites" | Out-Null
foreach ($step in @(@("-s", "res://tools/sprites/bake_sprites.gd", "--", "--phase=images"),
                    @("--import"),
                    @("-s", "res://tools/sprites/bake_sprites.gd", "--", "--phase=resources"))) {
    $p = Start-Process -FilePath $godot -ArgumentList (@("--headless", "--path", "`"$root`"") + $step) -NoNewWindow -Wait -PassThru
    if ($p.ExitCode -ne 0) { Write-Host "bake_sprites failed at: $step" -ForegroundColor Red; exit $p.ExitCode }
}
Write-Host "Sprites baked." -ForegroundColor Green
```

- [ ] **Step 4: Exécuter** `powershell -ExecutionPolicy Bypass -File tools/bake_sprites.ps1` ; vérifier `assets/sprites/` (9 planches + `.tres` + `ground.png`) ; ouvrir `grunt.png` pour contrôle visuel (halo, recadrage).
- [ ] **Step 5: Relancer une fois** et vérifier `git status` : pas de diff sur les PNG (déterminisme).
- [ ] **Step 6: Crédits** — ajouter à `assets/CREDITS.md` :
`| Characters, enemies, ground (`assets/sprites/`) — "Free 2D Animated Vector Game Character Sprites" | RGS_Dev | https://rgsdev.itch.io/free-2d-animated-vector-game-character-sprites | CC0 1.0 |`
- [ ] **Step 7: Commit** — `feat: sprite baking tool and generated sheets`.

---

### Task 3: Ennemis animés

**Files:**
- Modify: `src/enemies/enemy_data.gd`, `src/enemies/enemy.gd`, `src/enemies/enemy_manager.gd` (`spawn`, boucle `_physics_process`)
- Modify: `data/enemies/{grunt,runner,shooter,tank,shogun}.tres`
- Test: `tests/unit/test_enemy_manager.gd`, `tests/data/test_content.gd`

**Interfaces:**
- Consumes: `SpriteSheet`, `SpriteAnimator` (Task 1), `res://assets/sprites/<id>.tres` (Task 2).
- Produces: `EnemyData.sprite_id: StringName`, `EnemyData.sprite_tint: Color`, `EnemyData.sprite_scale: float`, `EnemyData.get_sheet(elite: bool) -> SpriteSheet`, `Enemy.animator: SpriteAnimator`, `Enemy.SPRITE_HEIGHT_PER_RADIUS`.

- [ ] **Step 1: Tests** (dans `test_enemy_manager.gd`)

```gdscript
func test_enemy_without_sprite_uses_placeholder() -> void:
	var enemy := _enemies.spawn(_data, Vector2(300, 0))
	assert_null(enemy.animator.sheet)
	await wait_physics_frames(2)
	assert_true(enemy.is_alive())


func test_enemy_sprite_animates_and_faces_player() -> void:
	var data := _enemy_data(10.0, 50.0)
	data.sprite_id = &"grunt"
	var enemy := _enemies.spawn(data, Vector2(300, 0))
	assert_not_null(enemy.animator.sheet)
	var start := enemy.animator.time
	await wait_physics_frames(3)
	assert_gt(enemy.animator.time, start)
	assert_eq(enemy.animator.facing, -1.0, "player is on the left")


func test_elite_falls_back_to_normal_sheet() -> void:
	var data := _enemy_data(10.0, 0.0)
	data.sprite_id = &"player"  # has no _elite sheet
	assert_eq(data.get_sheet(true), data.get_sheet(false))


func test_recycled_enemy_switches_sheet() -> void:
	var a := _enemy_data(1.0, 0.0)
	a.sprite_id = &"grunt"
	var b := _enemy_data(1.0, 0.0)
	b.sprite_id = &"tank"
	var enemy := _enemies.spawn(a, Vector2(300, 0))
	_enemies.damage_enemy(_enemies._active.find(enemy), 10.0, false, Vector2.RIGHT, 0.0)
	await wait_physics_frames(1)
	var again := _enemies.spawn(b, Vector2(300, 0))
	assert_eq(again.animator.sheet, b.get_sheet(false))
	assert_true(again.animator.sheet.animations.has(&"walk"))
```

Dans `test_content.gd`, `test_enemies()` (dans la boucle) :
```gdscript
		if enemy.sprite_id != &"":
			var sheet := enemy.get_sheet(false)
			assert_not_null(sheet, "%s: missing sprite sheet %s" % [enemy.id, enemy.sprite_id])
			if sheet != null:
				assert_true(sheet.has_animation(&"walk"), "%s: sheet needs walk" % enemy.id)
```

- [ ] **Step 2: Lancer** → échec (`sprite_id`, `animator` inconnus).

- [ ] **Step 3: `EnemyData`** — dans le groupe visuel, après `shape_sides` :
```gdscript
## Sprite sheet id in assets/sprites/ (empty: neon placeholder shape).
@export var sprite_id: StringName
## Multiplies the sprite colors (e.g. magenta boss reusing another sheet).
@export var sprite_tint: Color = Color.WHITE
## Extra size factor on top of the radius-based sprite size.
@export var sprite_scale: float = 1.0
```
et :
```gdscript
var _sheet: SpriteSheet
var _elite_sheet: SpriteSheet


## Animated sprite of this type (null: placeholder). Elites use "<id>_elite" when it exists.
func get_sheet(elite: bool) -> SpriteSheet:
	if sprite_id == &"":
		return null
	if _sheet == null:
		_sheet = _load_sheet(String(sprite_id))
	if not elite:
		return _sheet
	if _elite_sheet == null:
		_elite_sheet = _load_sheet(String(sprite_id) + "_elite")
		if _elite_sheet == null:
			_elite_sheet = _sheet
	return _elite_sheet


static func _load_sheet(id: String) -> SpriteSheet:
	var path := "res://assets/sprites/%s.tres" % id
	return load(path) as SpriteSheet if ResourceLoader.exists(path) else null
```

- [ ] **Step 4: `Enemy`** — ajouter :
```gdscript
## Sprite height in px per px of collision radius.
const SPRITE_HEIGHT_PER_RADIUS := 3.2
## Feet sit this fraction of the radius below the enemy center.
const SPRITE_FOOT := 0.8

var animator := SpriteAnimator.new()
```
dans `reset()`, avant `_refresh_tint()` :
```gdscript
	if look_changed:
		animator.reset(data.get_sheet(elite), 0.0)
```
`_draw()` devient :
```gdscript
func _draw() -> void:
	if data == null:
		return
	var sheet := animator.sheet
	if sheet != null:
		sheet.draw(self, animator.frame, radius * SPRITE_HEIGHT_PER_RADIUS * data.sprite_scale,
			radius * SPRITE_FOOT, animator.facing, data.sprite_tint)
		return
	var texture := data.get_elite_texture(radius / data.radius) if elite else data.get_texture()
	draw_texture(texture, -texture.get_size() * 0.5)
```
Mettre à jour le commentaire d'en-tête (sprite animé, repli `EnemyArt`).

- [ ] **Step 5: `EnemyManager`** — dans `spawn()`, après `enemy.reset(...)` : `enemy.animator.time = _rng.randf() * 2.0` (désynchronise la horde).
Dans la boucle, remplacer
```gdscript
		if enemy.data.shape_sides >= 3:
			enemy.rotation = direction.angle()
```
par
```gdscript
		if enemy.animator.sheet != null:
			var anim := &"walk" if velocity.length_squared() > 4.0 else &"idle"
			if enemy.animator.advance(delta, anim, direction.x):
				enemy.queue_redraw()
		elif enemy.data.shape_sides >= 3:
			enemy.rotation = direction.angle()
```

- [ ] **Step 6: Données** — `sprite_id` : grunt `&"grunt"`, runner `&"runner"`, shooter `&"shooter"`, tank `&"tank"`, shogun `&"tank"` + `sprite_tint = Color(1, 0.55, 1, 1)`.
- [ ] **Step 7: Lancer tests + `tools/check_scripts.ps1`** → tout passe.
- [ ] **Step 8: Commit** — `feat: animated enemy sprites`.

---

### Task 4: Joueur animé

**Files:**
- Modify: `src/player/character_data.gd`, `src/player/player.gd`, `data/characters/drifter.tres`
- Test: `tests/unit/test_player.gd`

**Interfaces:**
- Consumes: `SpriteSheet`, `SpriteAnimator`.
- Produces: `CharacterData.sprite_id: StringName`, `Player.animator: SpriteAnimator`.

- [ ] **Step 1: Test** (`test_player.gd`, adapter au `before_each` existant si besoin) :
```gdscript
func test_player_sprite_faces_movement() -> void:
	var data := CharacterData.new()
	data.sprite_id = &"player"
	var player := Player.new()
	player.setup(data, Rect2(-500, -500, 1000, 1000))
	player.bot_input = func() -> Vector2: return Vector2.LEFT
	add_child_autofree(player)
	assert_not_null(player.animator.sheet)
	await wait_physics_frames(3)
	assert_eq(player.animator.facing, -1.0)
	assert_eq(player.animator.animation, &"walk")
```
- [ ] **Step 2: Lancer** → échec.
- [ ] **Step 3: Implémentation**
  - `CharacterData` (groupe visuel) : `@export var sprite_id: StringName` (« Sprite sheet id in assets/sprites/ (empty: placeholder circle). »).
  - `Player` : `const SPRITE_HEIGHT_PER_RADIUS := 3.6`, `const SPRITE_FOOT := 0.8`, `var animator := SpriteAnimator.new()`.
  - `setup()` : après `radius = data.radius` :
    ```gdscript
    	var path := "res://assets/sprites/%s.tres" % data.sprite_id
    	animator.reset(load(path) as SpriteSheet if data.sprite_id != &"" and ResourceLoader.exists(path) else null, 0.0)
    ```
  - `_physics_process()` : après `move_and_slide()` / clamp :
    ```gdscript
    	var anim := &"walk" if velocity.length_squared() > 4.0 else &"idle"
    	if animator.advance(delta, anim, velocity.x):
    		queue_redraw()
    ```
  - `_draw()` : en tête
    ```gdscript
    	if animator.sheet != null:
    		animator.sheet.draw(self, animator.frame, radius * SPRITE_HEIGHT_PER_RADIUS, radius * SPRITE_FOOT,
    			animator.facing, Color.WHITE)
    		return
    ```
  - `drifter.tres` : `sprite_id = &"player"`.
- [ ] **Step 4: Lancer tests** → passent.
- [ ] **Step 5: Commit** — `feat: animated player sprite`.

---

### Task 5: Profondeur (y-sort) et sol clair

**Files:**
- Modify: `src/run/run.gd` (création des nœuds), `src/run/arena.gd`
- Test: `tests/smoke/test_run_smoke.gd` (suite existante, doit rester verte)

- [ ] **Step 1: `run.gd`** — créer un conteneur trié :
```gdscript
	var actors := Node2D.new()
	actors.name = "Actors"
	actors.y_sort_enabled = true
```
`enemies.y_sort_enabled = true` ; ajouter `enemies` et `player` à `actors` (au lieu de `add_child`), et `add_child(actors)` à la place de l'ancien `add_child(enemies)`. L'ordre des autres nœuds ne change pas.
- [ ] **Step 2: `arena.gd`** — sol clair texturé :
```gdscript
const GROUND := preload("res://assets/sprites/ground.png")
const OUTSIDE_COLOR := Color(0.1, 0.09, 0.16)
## Multiplies the white ground texture: soft blue-violet, not dark.
const FLOOR_TINT := Color(0.42, 0.42, 0.62)
const LINE_COLOR := Color(0.55, 0.65, 1.0, 0.12)
```
`setup()` : `texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED`. Dans `_draw()`, remplacer `draw_rect(rect, FLOOR_COLOR)` par `draw_texture_rect(GROUND, rect, true, FLOOR_TINT)` ; supprimer `FLOOR_COLOR`. Mettre à jour le commentaire d'en-tête.
- [ ] **Step 3: Tests + check_scripts** → passent.
- [ ] **Step 4: Commit** — `feat: y-sorted actors and lighter textured floor`.

---

### Task 6: Galerie, performance, captures, docs

**Files:**
- Modify: `src/debug/vfx_gallery.gd`
- Create: `docs/decisions/0009-sprites-animes.md`
- Modify: `PROJECT_STATUS.md`, `CLAUDE.md` (commande `bake_sprites.ps1`)

- [ ] **Step 1: Galerie** — garder la liste des ennemis dans `_gallery_enemies: Array[Enemy]`, ajouter une élite par type (`reset(data, pos, 1.0, true, 1.6)`), et dans `_process` : `for e in _gallery_enemies: if e.animator.advance(delta, &"walk", 1.0): e.queue_redraw()`.
- [ ] **Step 2: Stress test** — `& "C:\Program Files\Godot\Godot.exe" --path . res://src/debug/stress_test.tscn -- --duration=20` ; noter FPS moyen/min. Si < 150 : retirer `y_sort_enabled` et remesurer ; si toujours < 150, s'arrêter et passer à l'approche B (nouvelle spec).
- [ ] **Step 3: Captures** — `capture.tscn -- --time=20 --stress --out=<scratchpad>/horde.png` et `vfx_gallery.tscn -- --out=<scratchpad>/gallery.png` ; regarder les images ; ajuster `SPRITE_HEIGHT_PER_RADIUS` / `FLOOR_TINT` si lisibilité insuffisante.
- [ ] **Step 4: ADR 0009** (contexte, décision : planches précalculées + `SpriteSheet` `.tres`, animation avancée par le manager, redessin au changement d'image, y-sort ; mesures ; conséquences : ajouter un sprite = recette + `bake_sprites.ps1` + `sprite_id`).
- [ ] **Step 5: Docs** — `CLAUDE.md` : commande `tools/bake_sprites.ps1` ; `PROJECT_STATUS.md` : D33 (sprites animés, sol clair), session 4, prochaines étapes (chantier 2).
- [ ] **Step 6: Tests + check_scripts** une dernière fois ; **Commit** — `docs: ADR 0009 animated sprites, status`.
