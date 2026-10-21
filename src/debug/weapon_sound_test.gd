extends Control
## Listening bench for the weapon fire sounds: one button per weapon plays its sound at the volume it has in
## a run (fire_volume_db + WeaponHolder.WEAPON_SOUND_TRIM_DB). Open weapon_sound_test.tscn and press F6.
## Space plays the last sound again; "Play all" plays them one after the other.

const GAP_SECONDS := 0.9

var _last: WeaponData
var _playing_all := false


func _ready() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 24)
	add_child(root)
	var top := HBoxContainer.new()
	root.add_child(top)
	var title := Label.new()
	title.text = "Weapon sounds (click to listen, Space repeats)"
	top.add_child(title)
	var all := Button.new()
	all.text = "Play all"
	all.pressed.connect(_play_all)
	top.add_child(all)
	var extra := HBoxContainer.new()
	root.add_child(extra)
	for entry: Array in [["Level-up A", "level_up_a"], ["Level-up B", "level_up_b"], ["Level-up C", "level_up_c"]]:
		var candidate := Button.new()
		candidate.text = entry[0]
		candidate.custom_minimum_size = Vector2(200, 64)
		candidate.pressed.connect(_play_candidate.bind(entry[1]))
		extra.add_child(candidate)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	root.add_child(grid)
	var weapons: Array = ContentDB.get_all(&"weapons")
	weapons.sort_custom(func(a: WeaponData, b: WeaponData) -> bool: return tr(a.name_key) < tr(b.name_key))
	for weapon: WeaponData in weapons:
		var button := Button.new()
		button.text = tr(weapon.name_key)
		button.custom_minimum_size = Vector2(300, 64)
		button.pressed.connect(_play.bind(weapon))
		grid.add_child(button)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_pressed() and (event as InputEventKey).keycode == KEY_SPACE and _last != null:
		_play(_last)


func _play(weapon: WeaponData) -> void:
	_last = weapon
	Audio.forget_last_play(weapon.fire_sound)
	Audio.play(weapon.fire_sound, weapon.fire_volume_db + WeaponHolder.WEAPON_SOUND_TRIM_DB, 0.0)


## Candidate sounds not in the game yet (assets/audio/sfx/candidates/).
func _play_candidate(file: String) -> void:
	var stream := load("res://assets/audio/sfx/candidates/%s.mp3" % file) as AudioStream
	Audio.forget_last_play(stream)
	Audio.play(stream, -4.0, 0.0)


func _play_all() -> void:
	if _playing_all:
		return
	_playing_all = true
	var weapons: Array = ContentDB.get_all(&"weapons")
	weapons.sort_custom(func(a: WeaponData, b: WeaponData) -> bool: return tr(a.name_key) < tr(b.name_key))
	for weapon: WeaponData in weapons:
		_play(weapon)
		await get_tree().create_timer(GAP_SECONDS).timeout
	_playing_all = false
