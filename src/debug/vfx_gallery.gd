extends Node2D
## Shows every combat effect and enemy look side by side, re-triggered in a loop,
## to tune the art direction. Run with F6, or headless capture:
## Godot.exe --path . res://src/debug/vfx_gallery.tscn -- --out=<file.png>
## [--slashes [--steps=N]]: every melee weapon's slash side by side, captured after
## N steps of 0.02 s (default 3: mid-sweep).
## [--blasts]: the explosions of the bomb, explosive flask, cannon, fire staff and fire flask (one row each) at 6 ages.

const LOOP := 0.5
const ENEMY_IDS: Array[StringName] = [&"grunt", &"runner", &"shooter", &"tank", &"shogun"]

var _vfx: Vfx
var _timer: float = 0.0
var _time: float = 0.0
var _out: String = ""
var _slashes: bool = false
var _blasts: bool = false
var _projectiles: bool = false
var _renderer: ProjectileRenderer
var _steps: int = 3
var _gallery_enemies: Array[Enemy] = []


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg == "--slashes":
			_slashes = true
		elif arg == "--blasts":
			_blasts = true
		elif arg == "--projectiles":
			_projectiles = true
		elif arg.begins_with("--steps="):
			_steps = arg.trim_prefix("--steps=").to_int()
	var arena := Arena.new()
	arena.setup(Rect2(-960, -540, 1920, 1080))
	add_child(arena)
	var camera := Camera2D.new()
	add_child(camera)

	var x := -450.0
	for id in ENEMY_IDS:
		var data: EnemyData = ContentDB.get_def(&"enemies", id)
		_add_enemy(data, Vector2(x, 330), false)
		var burning := _add_enemy(data, Vector2(x + 70, 330), false)
		burning.apply_burn(1.0, 1e9)
		if not data.boss:
			_add_enemy(data, Vector2(x + 35, 180), true)
		x += 250.0

	_vfx = Vfx.new()
	add_child(_vfx)
	if _projectiles:
		_show_projectiles()
	_trigger()


## [--projectiles]: every weapon's projectile at its in-game size, flying right, one per row cell.
func _show_projectiles() -> void:
	_renderer = ProjectileRenderer.new()
	add_child(_renderer)
	var list: Array[Projectile] = []
	var weapons: Array = ContentDB.get_all(&"weapons").filter(func(w: WeaponData) -> bool: return w.projectile_style != 0 and not w.is_melee())
	for i in weapons.size():
		var w: WeaponData = weapons[i]
		var p := Projectile.new()
		p.reset_basic(Vector2(-700 + (i % 4) * 400, -420 + (i / 4) * 130), Vector2.RIGHT * 100.0, 1.0, w.projectile_radius, 1.0, w.color, w.projectile_style)
		list.append(p)
		var label := Label.new()
		label.text = String(w.id)
		label.position = p.position + Vector2(-60, 40)
		add_child(label)
	_renderer.render(list)


func _add_enemy(data: EnemyData, pos: Vector2, elite: bool) -> Enemy:
	var enemy := Enemy.new()
	add_child(enemy)
	enemy.reset(data, pos, 1.0, elite, 1.6 if elite else 1.0)
	_gallery_enemies.append(enemy)
	return enemy


func _process(delta: float) -> void:
	_time += delta
	# Burning copies face left: checks mirroring stays centered on the enemy.
	for enemy in _gallery_enemies:
		var facing := -1.0 if enemy.burn_time > 0.0 else 1.0
		if enemy.animator.advance(delta, &"walk", facing):
			enemy.queue_redraw()
	_timer -= delta
	if _timer <= 0.0:
		_trigger()
	if _out != "" and _time > 0.6:
		_capture()


func _trigger() -> void:
	_timer = LOOP
	if _slashes:
		_trigger_slashes()
		return
	if _blasts:
		_trigger_blasts()
		return
	var katana: WeaponData = ContentDB.get_def(&"weapons", &"katana")
	var laser: WeaponData = ContentDB.get_def(&"weapons", &"laser_pistol")
	var bazooka: WeaponData = ContentDB.get_def(&"weapons", &"bazooka")
	MeleeArcBehavior.play_visual(_vfx, katana, null, Vector2(-600, -150), Vector2.RIGHT, katana.area, Vector2(-600, -150) + Vector2.RIGHT * katana.area * 0.7, 0.0, katana.color, deg_to_rad(katana.arc_degrees) * 0.5,
		MeleeArcBehavior.hit_size(katana, 1.0))
	_vfx.sheet(load("res://data/vfx/star_impact.tres"), Vector2(250, -250), 0.0, 70.0)
	_vfx.beam(Vector2(-250, -300), Vector2(350, -300), laser.area, laser.color, null, laser.beam_sheet)
	var frost: WeaponData = ContentDB.get_def(&"weapons", &"frost_scepter")
	_vfx.slash(Vector2(-250, -230), 0.0, frost.area, deg_to_rad(frost.arc_degrees) * 0.5, frost.color, 0, null, frost.slash_sheet)
	var meteor: StrikeBehavior = (ContentDB.get_def(&"weapons", &"meteor_grimoire") as WeaponData).behavior
	_vfx.sheet_fall(meteor.fall_sheet, Vector2(-450, 40), StrikeBehavior.FALL_FROM.angle(), 90.0 * StrikeBehavior.ROCK_SIDE_PER_RADIUS, StrikeBehavior.FALL_FROM.length())
	_vfx.explosion(Vector2(-250, 40), 90.0, Color.WHITE, false, meteor.impact_sheet)
	_vfx.lightning(Vector2(-250, -180), Vector2(-50, -120), EnemyManager.SHOCK_COLOR)
	_vfx.lightning(Vector2(-50, -120), Vector2(150, -190), EnemyManager.SHOCK_COLOR)
	_vfx.explosion(Vector2(550, -150), bazooka.explosion_radius, bazooka.color, false)
	_vfx.hit(Vector2(250, 50))


## Every melee weapon, 4 per row, each with its own slash style.
func _trigger_slashes() -> void:
	var melee: Array = ContentDB.get_all(&"weapons").filter(func(w: WeaponData) -> bool: return w.is_melee())
	for i in melee.size():
		var w: WeaponData = melee[i]
		var center := Vector2(-660 + (i % 4) * 440, -220 + (i / 4) * 420)
		MeleeArcBehavior.play_visual(_vfx, w, null, center, Vector2.RIGHT, w.area, center + Vector2.RIGHT * w.area * 0.7, 0.0, w.color, deg_to_rad(w.arc_degrees) * 0.5,
			MeleeArcBehavior.hit_size(w, 1.0))


## One Vfx per column, each advanced to a later moment of the same effects.
func _trigger_blasts() -> void:
	for child in get_children():
		if child is Vfx and child != _vfx:
			child.queue_free()
	# One row per explosive weapon (each has its own painted explosion), 6 ages per row.
	var ids: Array[StringName] = [&"bomb", &"bazooka", &"alchemy_cannon", &"fire_staff", &"fire_flask"]
	for c in 6:
		var column := Vfx.new()
		add_child(column)
		var x := -700.0 + c * 270.0
		for r in ids.size():
			var weapon: WeaponData = ContentDB.get_def(&"weapons", ids[r])
			# Over the gallery's monsters: the blast must stay see-through.
			column.explosion(Vector2(x, -300.0 + r * 150.0), 70.0, weapon.color, false,
				EffectSheets.explosion_for(weapon.projectile_style))
		column._process(c * 0.1)


func _capture() -> void:
	set_process(false)
	_trigger()
	# Let the effects run a little so they are mid-animation.
	for i in _steps:
		await RenderingServer.frame_post_draw
		_vfx._process(0.02)
	get_viewport().get_texture().get_image().save_png(_out)
	print("capture saved: ", _out)
	get_tree().quit()
