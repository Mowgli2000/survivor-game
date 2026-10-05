extends Node2D
## Shows every combat effect and enemy look side by side, re-triggered in a loop,
## to tune the art direction. Run with F6, or headless capture:
## Godot.exe --path . res://src/debug/vfx_gallery.tscn -- --out=<file.png>
## [--slashes [--steps=N]]: every melee weapon's slash side by side, captured after
## N steps of 0.02 s (default 3: mid-sweep).
## [--blasts]: explosions (top) and monster deaths (bottom) at 6 ages of their life.

const LOOP := 0.5
const ENEMY_IDS: Array[StringName] = [&"grunt", &"runner", &"shooter", &"tank", &"shogun"]

var _vfx: Vfx
var _timer: float = 0.0
var _time: float = 0.0
var _out: String = ""
var _slashes: bool = false
var _blasts: bool = false
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
	_trigger()


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
	_vfx.slash(Vector2(-600, -150), 0.0, katana.area, deg_to_rad(katana.arc_degrees) * 0.5, katana.color)
	_vfx.beam(Vector2(-250, -300), Vector2(350, -300), laser.area, laser.color)
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
		_vfx.slash(center, -PI / 2.0, w.area, deg_to_rad(w.arc_degrees) * 0.5, w.color, w.slash_style)


## One Vfx per column, each advanced to a later moment of the same effects.
func _trigger_blasts() -> void:
	for child in get_children():
		if child is Vfx and child != _vfx:
			child.queue_free()
	var bazooka: WeaponData = ContentDB.get_def(&"weapons", &"bazooka")
	var grunt: EnemyData = ContentDB.get_def(&"enemies", &"grunt")
	for c in 6:
		var column := Vfx.new()
		add_child(column)
		var x := -700.0 + c * 270.0
		column.explosion(Vector2(x, -330), bazooka.explosion_radius, bazooka.color, false)
		column.death(Vector2(x - 60, -40), 26.0, grunt.color)
		column.death(Vector2(x + 60, -40), 40.0, Color(0.85, 0.3, 0.35))
		column._process(c * 0.055)


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
