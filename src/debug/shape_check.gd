extends Node2D
## Checks that a melee weapon's painted swing matches the shape that really hurts: fires the weapon
## at a field of dummy enemies and captures the painted effect with the damage outlines (magenta)
## and the enemies' health (hurt ones tinted red).
## Godot.exe --path . res://src/debug/shape_check.tscn -- --weapon=<id> [--at=0.15] [--out=<png>]

var _out: String = ""
var _at: float = 0.15
var _weapon_id: StringName = &"katana"
var _enemies: EnemyManager
var _vfx: Vfx
var _player: Player
var _projectiles: ProjectileManager


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--at="):
			_at = arg.trim_prefix("--at=").to_float()
		elif arg.begins_with("--weapon="):
			_weapon_id = StringName(arg.trim_prefix("--weapon="))
	var rect := Rect2(-960, -540, 1920, 1080)
	var arena := Arena.new()
	arena.setup(rect)
	add_child(arena)
	add_child(Camera2D.new())
	_player = Player.new()
	_player.setup(CharacterData.new(), rect)
	_player.invincible = true
	_player.bot_input = func() -> Vector2: return Vector2.ZERO
	add_child(_player)
	_vfx = Vfx.new()
	_vfx.show_shapes = true
	add_child(_vfx)
	var rng := RandomNumberGenerator.new()
	_enemies = EnemyManager.new()
	_enemies.setup(Party.solo(_player), rect, 4, rng, _vfx, null)
	add_child(_enemies)
	_projectiles = ProjectileManager.new()
	add_child(_projectiles)
	_projectiles.setup(_enemies, rect, 8, _vfx)
	var data: EnemyData = (ContentDB.get_def(&"enemies", &"grunt") as EnemyData).duplicate()
	data.max_hp = 100000.0
	data.speed = 0.0
	# A field of enemies every 100 px, the nearest to the right so the blow is aimed at +x.
	for gx in range(-4, 5):
		for gy in range(-3, 4):
			var pos := Vector2(gx, gy) * 100.0
			if pos.length() > 60.0:
				_enemies.spawn(data, pos + Vector2(40.0, 0.0) if gx == 2 and gy == 0 else pos)
	_run()


func _run() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	var weapon: WeaponData = ContentDB.get_def(&"weapons", _weapon_id)
	var slot := WeaponSlot.new(weapon, 1)
	var ctx := WeaponContext.new(_player, StatBlock.from_defaults({}), _enemies, _projectiles, RandomNumberGenerator.new())
	ctx.vfx = _vfx
	weapon.behavior.fire(slot, ctx)
	if OS.get_cmdline_user_args().has("--trace"):
		for k in 14:
			var kinds := {}
			for v in _vfx.active_count():
				kinds[_vfx._kind[v]] = int(kinds.get(_vfx._kind[v], 0)) + 1
			print("t=%.2f projectiles=%d vfx=%s pos=%s" % [k * 0.05, _projectiles.active_count(), kinds, _projectiles.projectile_position(0) if _projectiles.active_count() > 0 else "-"])
			await get_tree().create_timer(0.05).timeout
	await get_tree().create_timer(_at).timeout
	await RenderingServer.frame_post_draw
	for i in _enemies.active_count():
		var enemy := _enemies.get_enemy(i)
		if enemy.hp < enemy.data.max_hp:
			enemy.self_modulate = Color(1.0, 0.3, 0.3)
	await RenderingServer.frame_post_draw
	if _out != "":
		get_viewport().get_texture().get_image().save_png(_out)
		print("capture saved: ", _out)
		get_tree().quit()
