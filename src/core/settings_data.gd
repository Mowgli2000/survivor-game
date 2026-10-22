class_name SettingsData
extends RefCounted
## Player settings (audio, display, accessibility, language) as plain data.
## to_dict() gives a versioned dictionary for JSON; from_dict() never trusts its
## input: unknown keys and wrong types are ignored, volumes clamped (ADR 0013).

const VERSION := 1
## "" = system language.
const LOCALES: Array[String] = ["", "en", "fr"]
const VOLUME_KEYS: Array[StringName] = [&"master_volume", &"music_volume", &"sfx_volume",
	&"ambience_volume"]
## Camera zoom range (player option): below 1 shows more of the arena, above 1 less.
const ZOOM_MIN := 0.75
const ZOOM_MAX := 1.15
## Frame-rate caps offered (0 = none).
const FPS_CAPS: Array[int] = [0, 30, 60, 120, 144, 240]
## Window sizes offered; the setting `resolution` is 0 (leave the window alone) or 1 + the index here.
const RESOLUTIONS: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080),
	Vector2i(2560, 1440)]
## Text sizes offered (multiplies every font size, UiTheme.text_scale).
const TEXT_SCALES: Array[float] = [1.0, 1.15, 1.3]
## Colorblind modes: 0 off, 1 protanopia, 2 deuteranopia, 3 tritanopia (ColorFilter).
const COLORBLIND_MODES := 4
const BOOL_KEYS: Array[StringName] = [&"fullscreen", &"vsync", &"screen_shake",
	&"damage_numbers", &"reduce_motion", &"show_hints", &"player_hp_bar", &"light_mode", &"reduce_flashes", &"auto_pause"]

var master_volume: float = 0.8
var music_volume: float = 0.7
var sfx_volume: float = 0.8
var ambience_volume: float = 0.7
var fullscreen: bool = false
var vsync: bool = true
## Cap on frames per second, one of FPS_CAPS (0 = none).
var fps_cap: int = 0
## Window size when not fullscreen: 0 = untouched, else 1 + index in RESOLUTIONS.
var resolution: int = 0
## Fewer cosmetic effects at once, for weak PCs (Vfx.LIGHT_BUSY_COUNT).
var light_mode: bool = false
## Index in TEXT_SCALES.
var text_size: int = 0
var colorblind: int = 0
## Controls chosen by the player (InputBindings): only what differs from the defaults.
var bindings: Dictionary = {}
## No white hit flashes, dimmer glows (photosensitivity).
var reduce_flashes: bool = false
## The run pauses by itself when the window loses focus or a pad is unplugged.
var auto_pause: bool = true
var screen_shake: bool = true
var damage_numbers: bool = true
var reduce_motion: bool = false
## Multiplies the run camera zoom (RunConfig.camera_zoom).
var camera_zoom: float = 1.0
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
	if key == &"camera_zoom":
		if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
			return false
		camera_zoom = clampf(float(value), ZOOM_MIN, ZOOM_MAX)
		return true
	if key in BOOL_KEYS:
		if typeof(value) != TYPE_BOOL:
			return false
		set(key, value)
		return true
	if key == &"fps_cap":
		if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
			return false
		fps_cap = int(value) if int(value) in FPS_CAPS else 0
		return true
	if key == &"resolution":
		if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
			return false
		resolution = clampi(int(value), 0, RESOLUTIONS.size())
		return true
	if key == &"text_size" or key == &"colorblind":
		if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
			return false
		set(key, clampi(int(value), 0, (TEXT_SCALES.size() if key == &"text_size" else COLORBLIND_MODES) - 1))
		return true
	if key == &"bindings":
		if not value is Dictionary:
			return false
		bindings = InputBindings.sanitize(value)
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
	var result := {"version": VERSION, "locale": locale, "select_background": select_background,
		"camera_zoom": camera_zoom, "fps_cap": fps_cap, "resolution": resolution,
		"text_size": text_size, "colorblind": colorblind,
		"bindings": bindings}
	for key in VOLUME_KEYS + BOOL_KEYS:
		result[String(key)] = get(key)
	return result


static func from_dict(d: Dictionary) -> SettingsData:
	var settings := SettingsData.new()
	for key: Variant in d:
		settings.set_value(StringName(str(key)), d[key])
	return settings
