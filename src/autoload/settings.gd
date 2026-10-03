extends Node
## Settings service (autoload "Settings", ADR 0013): loads and saves
## user://settings.json (JSON only, never a Resource) and applies the values to
## the engine: audio buses, window mode, VSync, locale, UiFx.reduce_motion.
## Gameplay nodes read `data` and listen to `changed`. No run logic here.
## Example: `Settings.set_value(&"music_volume", 0.5)` applies, saves, emits `changed`.

signal changed

const DEFAULT_PATH := "user://settings.json"
## Used by the GUT pre-run hook: tests never touch the player's settings.
const TEST_PATH := "user://test_settings.json"
const BUSES: Dictionary[StringName, StringName] = {
	&"master_volume": &"Master", &"music_volume": &"Music", &"sfx_volume": &"SFX"}

var path: String = DEFAULT_PATH
var data := SettingsData.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()


func load_settings() -> void:
	data = SettingsData.new()
	if FileAccess.file_exists(path):
		# JSON.parse() (not parse_string) reports errors without an engine error log.
		var json := JSON.new()
		if json.parse(FileAccess.get_file_as_string(path)) == OK and json.data is Dictionary:
			data = SettingsData.from_dict(json.data)
		else:
			push_warning("Settings: unreadable %s, using defaults" % path)
	apply()
	changed.emit()


func save_settings() -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("Settings: cannot write %s" % path)
		return
	file.store_string(JSON.stringify(data.to_dict(), "\t"))


func set_value(key: StringName, value: Variant) -> void:
	if not data.set_value(key, value):
		push_warning("Settings: invalid value for %s" % key)
		return
	apply()
	save_settings()
	changed.emit()


func apply() -> void:
	for key: StringName in BUSES:
		var bus := AudioServer.get_bus_index(BUSES[key])
		if bus < 0:
			continue
		var volume: float = data.get(key)
		AudioServer.set_bus_mute(bus, volume <= 0.0)
		AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(volume, 0.0001)))
	TranslationServer.set_locale(data.locale if data.locale != "" else OS.get_locale_language())
	UiFx.reduce_motion = data.reduce_motion
	_apply_window()


func _apply_window() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var mode := DisplayServer.window_get_mode()
	var is_fullscreen := mode == DisplayServer.WINDOW_MODE_FULLSCREEN \
		or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	if data.fullscreen != is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if data.fullscreen
			else DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if data.vsync
		else DisplayServer.VSYNC_DISABLED)
