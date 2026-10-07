extends Node
## Plays a run with a bot and saves a screenshot, so visuals can be checked
## without a human at the keyboard (used by Claude Code).
## Usage: Godot.exe --path . res://src/debug/capture.tscn -- --time=20 --out=user://capture.png [--stress] [--allweapons] [--levelup] [--waveend] [--shop] [--die] [--unlocks] [--pause] [--settings] [--menu] [--characters] [--coopselect] [--progression] [--boss=shogun|ronin] [--coop] [--character=<id>]

const RUN_SCENE := preload("res://src/run/run.tscn")
const MENU_SCENE := preload("res://src/ui/main_menu/main_menu.tscn")
const STRESS_CONFIG := preload("res://src/debug/stress/stress_run.tres")

var _run: Run
var _time: float = 0.0
var _capture_at: float = 10.0
var _out: String = "user://capture.png"
var _mode: String = ""
## --fullshop: 6 weapons and 30 items in the shop (layout worst case).
var _full_shop := false
var _done: bool = false
var _boss_id: StringName = &""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ButtonHints.show_always = true  # the gamepad hint bars appear on captures too
	var stress := false
	var all_weapons := false
	var coop := false
	var character_id := ""
	var danger := -1
	var variant := 0
	var show_pickups := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--time="):
			_capture_at = arg.trim_prefix("--time=").to_float()
		elif arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg == "--stress":
			stress = true
		elif arg in ["--levelup", "--die", "--unlocks", "--waveend", "--shop", "--pause", "--settings", "--menu", "--characters", "--coopselect", "--progression"]:
			_mode = arg
		elif arg == "--coop":
			coop = true
		elif arg.begins_with("--character="):
			character_id = arg.trim_prefix("--character=")
		elif arg.begins_with("--boss="):
			_boss_id = StringName(arg.trim_prefix("--boss="))
		elif arg.begins_with("--danger="):
			danger = arg.trim_prefix("--danger=").to_int()
		elif arg.begins_with("--variant="):
			variant = arg.trim_prefix("--variant=").to_int()
		elif arg == "--pickups":
			show_pickups = true
		elif arg == "--allweapons":
			all_weapons = true
		elif arg == "--fullshop":
			_full_shop = true
	if _mode in ["--menu", "--characters", "--coopselect", "--progression"]:
		var menu: MainMenu = MENU_SCENE.instantiate()
		add_child(menu)
		if _mode in ["--characters", "--coopselect"]:
			menu._open_character_select(_mode == "--coopselect")
			# With --character=<id>: open that character's starting weapon choice.
			# --variant=1: the cards show the second look.
			if variant > 0:
				for def in ContentDB.get_all(&"characters"):
					menu._character_select._variants[(def as CharacterData).id] = variant
				menu._character_select._build_cards()
			if _mode == "--coopselect" and character_id != "":
				# Both halves pick that character; with --danger too, both are ready.
				for i in 2:
					var half := menu._coop_select.select_of(i)
					half._choose_character(ContentDB.get_def(&"characters", StringName(character_id)))
					if danger >= 0:
						(half._weapons.get_child(0) as Button).pressed.emit()
			elif character_id != "":
				menu._character_select._choose_character(ContentDB.get_def(&"characters", StringName(character_id)))
				# With --danger=N too: pick the first weapon to show the seals row.
				if danger >= 0:
					(menu._character_select._weapons.get_child(0) as Button).pressed.emit()
					# ...and hover seal N to show its effects line.
					var seals := menu._character_select._dangers
					if danger < seals.get_child_count():
						seals.get_child(danger).mouse_entered.emit()
		elif _mode == "--progression":
			menu._open_progression()
			# The seal rewards are at the bottom of the list.
			get_tree().create_timer(0.5).timeout.connect(func() -> void:
				menu._progression._scroll.scroll_vertical = 100000)
		return
	_run = RUN_SCENE.instantiate()
	if stress:
		_run.config = STRESS_CONFIG
	if character_id != "":
		# A config copy, not a RunSetup: setup runs are recorded in the profile.
		var base: RunConfig = _run.config if _run.config != null else ContentDB.get_def(&"runs", Run.DEFAULT_CONFIG_ID)
		var config := base.duplicate() as RunConfig
		config.character = ContentDB.get_def(&"characters", StringName(character_id))
		_run.config = config
	if danger >= 0:
		# A seal (ADR 0018): its biome, bestiary and bosses. The capture ends before the
		# run does, so nothing is recorded in the profile.
		_run.setup = RunSetup.new()
		_run.setup.difficulty = ContentDB.get_def(&"difficulties", StringName("danger_%d" % danger))
		if character_id != "":
			_run.setup.character = ContentDB.get_def(&"characters", StringName(character_id))
	if variant > 0 and character_id != "":
		if _run.setup == null:
			_run.setup = RunSetup.new()
			_run.setup.character = ContentDB.get_def(&"characters", StringName(character_id))
		_run.setup.variant = variant
	_run.seed_override = 7
	_run.player_invincible = true
	_run.auto_choose_upgrades = _mode not in ["--levelup", "--waveend", "--shop", "--pause", "--settings"]
	_run.bot_input = func() -> Vector2: return Vector2.from_angle(_time * 0.5)
	if coop:
		_run.player_count = 2
	add_child(_run)
	if coop:
		# Player 2 walks the other way: the camera zooms out as they spread.
		_run.players[1].player.bot_input = func() -> Vector2: return -Vector2.from_angle(_time * 0.5)
	if show_pickups:
		# A row of crystals and a row of coins, from small to merged, out of the magnet's reach.
		_run.player.bot_input = func() -> Vector2: return Vector2.ZERO
		for i in 8:
			_run.pickups.spawn_xp(Vector2(-420 + i * 120, -330), 1 + i * 7)
			_run.pickups.spawn_material(Vector2(-420 + i * 120, -230), 0.5 + i * 3.0)
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
		if _full_shop:
			# Late-game worst case: every weapon slot used and many different items.
			for def in ContentDB.get_all(&"weapons"):
				if _run.player.weapons.slot_count() >= _run.player.weapons.max_slots - 1:
					break
				_run.player.weapons.add_weapon(def as WeaponData, 3)
			var n := 0
			for def in ContentDB.get_all(&"items"):
				if n >= 30:
					break
				_run.inventory.add(def as ItemData)
				n += 1
		# A mergeable pair (same weapon, same tier) to check the highlight.
		var owned := _run.player.weapons.get_slots()[0]
		_run.player.weapons.add_weapon(owned.data, owned.level)
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
	if _mode in ["--die", "--unlocks"] and not _run.state.is_over:
		_run.player.invincible = false
		_run.player.take_damage(1e9)
		if _mode == "--unlocks":
			# Sample unlock cards: a character and two items.
			var samples: Array[ChallengeData] = []
			for id in [&"win_drifter", &"win_any", &"kill_ronin"]:
				samples.append(ContentDB.get_def(&"challenges", id))
			_run.game_over_screen.show_unlocks(samples)
		_capture_at = _time + 0.8
		return
	_done = true
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(_out)
	print("capture saved: ", ProjectSettings.globalize_path(_out))
	get_tree().quit()
