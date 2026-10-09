class_name SelectBackdrops
extends RefCounted
## Backgrounds of the character select screens, solo and coop (dev's decision, 2026-10-09): the
## hunters' hall by default, and one picture per danger level, unlocked by winning that danger
## (only that very level counts: `Profile.has_won_danger`). The setting `select_background` picks one:
## `default`, `random` (a different one among the hall and the unlocked ones each time a screen
## opens) or `danger_N` (N = 0..5; the hall while that danger is not won yet).
## Display only; the unlock itself is the profile's.

const DEFAULT := &"default"
const RANDOM := &"random"
const DANGER_COUNT := 6
## Two sets of native 16:9 pictures (dev, 2026-10-09), each shown as it is, never zoomed: the coop set
## is drawn from far (decor in the upper half, a huge empty floor for two seals), the solo set from
## closer (the same scenes, bigger, with less floor for one seal). Same distance inside a set.
const HALL := preload("res://assets/ui/backgrounds/hall.png")
const SOLO_HALL := preload("res://assets/ui/backgrounds/solo_hall.png")
const SOLO_DANGERS: Array[Texture2D] = [
	preload("res://assets/ui/backgrounds/solo_danger_0.png"), preload("res://assets/ui/backgrounds/solo_danger_1.png"),
	preload("res://assets/ui/backgrounds/solo_danger_2.png"), preload("res://assets/ui/backgrounds/solo_danger_3.png"),
	preload("res://assets/ui/backgrounds/solo_danger_4.png"), preload("res://assets/ui/backgrounds/solo_danger_5.png")]
const DANGERS: Array[Texture2D] = [
	preload("res://assets/ui/backgrounds/danger_0.png"), preload("res://assets/ui/backgrounds/danger_1.png"),
	preload("res://assets/ui/backgrounds/danger_2.png"), preload("res://assets/ui/backgrounds/danger_3.png"),
	preload("res://assets/ui/backgrounds/danger_4.png"), preload("res://assets/ui/backgrounds/danger_5.png")]
## Hue shift (degrees) of the interface frames and buttons for each picture: the HUD takes the color
## of the background (blue hall, orange dungeon, turquoise temple, ice, red citadel, green hive, red
## lair). The baked frames are blue (about 200 degrees).
const HALL_HUE := 0.0
const DANGER_HUES: Array[float] = [-165.0, -25.0, -14.0, -195.0, -85.0, -205.0]
## Saturation and brightness of that shift: the stone dungeon is grey, the frozen forest a light ice
## blue, the hive a softer green.
const DANGER_SATURATIONS: Array[float] = [0.1, 1.0, 0.5, 1.0, 0.6, 1.0]
const DANGER_VALUES: Array[float] = [1.0, 1.0, 1.5, 1.0, 0.9, 1.0]
## Opacity of the frames of the select screens (the background shows through).
const FRAME_ALPHA := 0.72

## Hue shift of the picture shown by the last `apply` (the screens style their own panels with it).
static var hue: float = 0.0


## Setting value of danger `level`.
static func id_of(level: int) -> StringName:
	return StringName("danger_%d" % level)


## True once danger `level` itself has been won with any hunter.
static func is_unlocked(level: int) -> bool:
	return level >= 0 and level < DANGER_COUNT and SaveService.profile.has_won_danger(level)


## Levels of the pictures the player owns.
static func unlocked_levels() -> Array[int]:
	var levels: Array[int] = []
	for level in DANGER_COUNT:
		if is_unlocked(level):
			levels.append(level)
	return levels


## Level shown for `setting`: -1 is the hall. `random` draws among the hall and the unlocked
## pictures (`roll` in 0..1, so tests can fix it).
static func resolve(setting: String, roll: float = randf()) -> int:
	if setting == String(RANDOM):
		var pool: Array[int] = [-1]
		pool.append_array(unlocked_levels())
		return pool[clampi(floori(roll * pool.size()), 0, pool.size() - 1)]
	for level in DANGER_COUNT:
		if setting == String(id_of(level)):
			return level if is_unlocked(level) else -1
	return -1


## Puts the picture of the current setting on `backdrop`. Returns true when it is the hall (the
## painted flames and crystals of the hall pictures only fit that one).
static func apply(backdrop: UiBackdrop, coop: bool) -> bool:
	var level := resolve(Settings.data.select_background)
	backdrop.base_zoom = 1.0
	backdrop.shift = Vector2.ZERO
	# The pictures are native 16:9 (widened by tools/art/widen.py): they fit a 16:9 screen exactly, no zoom.
	backdrop.texture = picture(level, coop)
	hue = DANGER_HUES[level] if level >= 0 else HALL_HUE
	UiTheme.shift_saturation = DANGER_SATURATIONS[level] if level >= 0 else 1.0
	UiTheme.shift_value = DANGER_VALUES[level] if level >= 0 else 1.0
	backdrop.queue_redraw()
	return level < 0


## A frame of the select screens a little transparent, so the background shows through.
static func ghost(style: StyleBoxTexture) -> StyleBoxTexture:
	return UiTheme.translucent(style, FRAME_ALPHA)


## The picture of danger `level` (-1: the hall) for the coop or the solo screen.
static func picture(level: int, coop: bool) -> Texture2D:
	if coop:
		return DANGERS[level] if level >= 0 else HALL
	return SOLO_DANGERS[level] if level >= 0 else SOLO_HALL


## Name of the place of danger `level` (the seal screen's own wording).
static func place_name(level: int) -> String:
	var levels := SealSelect.all_levels()
	if level < 0 or level >= levels.size():
		return ""
	var difficulty := levels[level]
	return TranslationServer.translate("BIOME_DUNGEON" if difficulty.biome == null else difficulty.biome.name_key)
