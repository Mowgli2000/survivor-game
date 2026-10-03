extends Node
## Plays a run with a bot and saves a screenshot, so visuals can be checked
## without a human at the keyboard (used by Claude Code).
## Usage: Godot.exe --path . res://src/debug/capture.tscn -- --time=20 --out=user://capture.png [--stress] [--allweapons] [--levelup] [--waveend] [--shop] [--die] [--pause] [--settings] [--menu] [--characters] [--progression] [--boss=shogun|ronin]

const RUN_SCENE := preload("res://src/run/run.tscn")
const MENU_SCENE := preload("res://src/ui/main_menu/main_menu.tscn")
const STRESS_CONFIG := preload("res://src/debug/stress/stress_run.tres")

var _run: Run
var _time: float = 0.0
var _capture_at: float = 10.0
var _out: String = "user://capture.png"
var _mode: String = ""
var _done: bool = false
var _boss_id: StringName = &""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var stress := false
	var all_weapons := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--time="):
			_capture_at = arg.trim_prefix("--time=").to_float()
		elif arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg == "--stress":
			stress = true
		elif arg in ["--levelup", "--die", "--waveend", "--shop", "--pause", "--settings", "--menu", "--characters", "--progression"]:
			_mode = arg
		elif arg.begins_with("--boss="):
			_boss_id = StringName(arg.trim_prefix("--boss="))
		elif arg == "--allweapons":
			all_weapons = true
	if _mode in ["--menu", "--characters", "--progression"]:
		var menu: MainMenu = MENU_SCENE.instantiate()
		add_child(menu)
		if _mode == "--characters":
			menu._open_character_select()
		elif _mode == "--progression":
			menu._open_progression()
		return
	_run = RUN_SCENE.instantiate()
	if stress:
		_run.config = STRESS_CONFIG
	_run.seed_override = 7
	_run.player_invincible = true
	_run.auto_choose_upgrades = _mode not in ["--levelup", "--waveend", "--shop", "--pause", "--settings"]
	_run.bot_input = func() -> Vector2: return Vector2.from_angle(_time * 0.5)
	add_child(_run)
	if all_weapons:
		for def in ContentDB.get_all(&"weapons"):
			var weapon := def as WeaponData
			_run.player.weapons.add_weapon(weapon, weapon.max_level())
	if _boss_id != &"":
		# Boss next to the player, telegraphs and volleys on screen by --time.
		_run.enemies.spawn(ContentDB.get_def(&"enemies", _boss_id), Vector2(320, -60), 3.0)


func _process(delta: float) -> void:
	_time += delta
	if _done or _time < _capture_at:
		return
	if _mode == "--levelup" and not get_tree().paused:
		_run.progression.add_xp(_run.progression.xp_needed())
		_run.waves.time_left = 0.05  # level-ups are shown at the end of the wave
		_capture_at = _time + 0.8
		return
	if _mode == "--shop" and not get_tree().paused:
		# Own a few items so the inventory row shows, then end the wave.
		for id in [&"oni_mask", &"magnet_glove", &"magnet_glove", &"plasma_ring"]:
			_run.inventory.add(ContentDB.get_def(&"items", id))
		_run.waves.time_left = 0.05
		_capture_at = _time + 0.8
		return
	if _mode == "--shop" and not _run.shop_screen.visible:
		# Skip the level-up cards: straight to the shop.
		_run.progression.pending_level_ups = 0
		_run._resolve_level_ups()
		_capture_at = _time + 0.5
		return
	if _mode in ["--pause", "--settings"] and not get_tree().paused:
		_run.open_pause()
		if _mode == "--settings":
			_run.pause_menu._open_settings()
		_capture_at = _time + 0.5
		return
	if _mode == "--waveend" and not get_tree().paused:
		_run.waves.time_left = 0.05
		_capture_at = _time + 0.8
		return
	if _mode == "--die" and not _run.state.is_over:
		_run.player.invincible = false
		_run.player.take_damage(1e9)
		_capture_at = _time + 0.3
		return
	_done = true
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(_out)
	print("capture saved: ", ProjectSettings.globalize_path(_out))
	get_tree().quit()
