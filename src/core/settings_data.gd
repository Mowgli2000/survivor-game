class_name SettingsData
extends RefCounted
## Player settings (audio, display, accessibility, language) as plain data.
## to_dict() gives a versioned dictionary for JSON; from_dict() never trusts its
## input: unknown keys and wrong types are ignored, volumes clamped (ADR 0013).

const VERSION := 1
## "" = system language.
const LOCALES: Array[String] = ["", "en", "fr"]
const VOLUME_KEYS: Array[StringName] = [&"master_volume", &"music_volume", &"sfx_volume"]
const BOOL_KEYS: Array[StringName] = [&"fullscreen", &"vsync", &"screen_shake",
	&"damage_numbers", &"reduce_motion", &"show_hints", &"player_hp_bar"]

var master_volume: float = 0.8
var music_volume: float = 0.7
var sfx_volume: float = 0.8
var fullscreen: bool = false
var vsync: bool = true
var screen_shake: bool = true
var damage_numbers: bool = true
var reduce_motion: bool = false
## First-time tips (HintBanner).
var show_hints: bool = true
## Small HP bar above each player (PlayerHealthBar).
var player_hp_bar: bool = true
var locale: String = ""
## Background of the character select screens: `default`, `random` or `danger_N` (SelectBackdrops).
var select_background: String = "default"


## Values of the `select_background` setting.
static func background_ids() -> Array[String]:
	var ids: Array[String] = ["default"]
	for level in 6:
		ids.append("danger_%d" % level)
	ids.append("random")
	return ids


## Validated write. Returns false (nothing changed) for an unknown key or a wrong type.
func set_value(key: StringName, value: Variant) -> bool:
	if key in VOLUME_KEYS:
		if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
			return false
		set(key, clampf(float(value), 0.0, 1.0))
		return true
	if key in BOOL_KEYS:
		if typeof(value) != TYPE_BOOL:
			return false
		set(key, value)
		return true
	if key == &"select_background":
		if typeof(value) != TYPE_STRING:
			return false
		select_background = value if value in background_ids() else "default"
		return true
	if key == &"locale":
		if typeof(value) != TYPE_STRING:
			return false
		locale = value if value in LOCALES else ""
		return true
	return false


func to_dict() -> Dictionary:
	var result := {"version": VERSION, "locale": locale, "select_background": select_background}
	for key in VOLUME_KEYS + BOOL_KEYS:
		result[String(key)] = get(key)
	return result


static func from_dict(d: Dictionary) -> SettingsData:
	var settings := SettingsData.new()
	for key: Variant in d:
		settings.set_value(StringName(str(key)), d[key])
	return settings
