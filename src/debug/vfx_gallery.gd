extends Node2D
## Shows every combat effect and enemy look side by side, re-triggered in a loop,
## to tune the art direction. Run with F6, or headless capture:
## Godot.exe --path . res://src/debug/vfx_gallery.tscn -- --out=<file.png>

const LOOP := 0.5
const ENEMY_IDS: Array[StringName] = [&"grunt", &"runner", &"shooter", &"tank"]

var _vfx: Vfx
var _timer: float = 0.0
var _time: float = 0.0
var _out: String = ""


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
	var arena := Arena.new()
	arena.setup(Rect2(-960, -540, 1920, 1080))
	add_child(arena)
	var camera := Camera2D.new()
	add_child(camera)

	var x := -450.0
	for id in ENEMY_IDS:
		var data: EnemyData = ContentDB.get_def(&"enemies", id)
		var enemy := Enemy.new()
		add_child(enemy)
		enemy.reset(data, Vector2(x, 330), 1.0)
		var burning := Enemy.new()
		add_child(burning)
		burning.reset(data, Vector2(x + 70, 330), 1.0)
		burning.apply_burn(1.0, 1e9)
		x += 250.0

	_vfx = Vfx.new()
	add_child(_vfx)
	_trigger()


func _process(delta: float) -> void:
	_time += delta
	_timer -= delta
	if _timer <= 0.0:
		_trigger()
	if _out != "" and _time > 0.6:
		_capture()


func _trigger() -> void:
	_timer = LOOP
	var katana: WeaponData = ContentDB.get_def(&"weapons", &"katana")
	var laser: WeaponData = ContentDB.get_def(&"weapons", &"laser_pistol")
	var bazooka: WeaponData = ContentDB.get_def(&"weapons", &"bazooka")
	_vfx.slash(Vector2(-600, -150), 0.0, katana.area, deg_to_rad(katana.arc_degrees) * 0.5, katana.color)
	_vfx.beam(Vector2(-250, -300), Vector2(350, -300), laser.area, laser.color)
	_vfx.lightning(Vector2(-250, -180), Vector2(-50, -120), EnemyManager.SHOCK_COLOR)
	_vfx.lightning(Vector2(-50, -120), Vector2(150, -190), EnemyManager.SHOCK_COLOR)
	_vfx.explosion(Vector2(550, -150), bazooka.explosion_radius, bazooka.color, false)
	_vfx.hit(Vector2(250, 50))


func _capture() -> void:
	set_process(false)
	_trigger()
	# Let the effects run a little so they are mid-animation.
	for i in 3:
		await RenderingServer.frame_post_draw
		_vfx._process(0.02)
	get_viewport().get_texture().get_image().save_png(_out)
	print("capture saved: ", _out)
	get_tree().quit()
