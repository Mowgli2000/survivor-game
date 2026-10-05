class_name HintBanner
extends PanelContainer
## First-time tip (onboarding): a panel at the top of a screen that fades out by
## itself. Each tip is shown once per profile (Profile.seen_hints) and can be
## turned off in the settings (`show_hints`). Text key: "HINT_" + key in upper case.
## Example: `HintBanner.show_once(self, &"shop")` when the shop opens.

const WIDTH := 860.0
## Default place: centered, under the wave timer.
const TOP_CENTER := Vector2(0.5, 0.0)
const TOP_SHIFT := Vector2(0.0, 150.0)
## Reading time: a base plus a little per character.
const BASE_TIME := 4.0
const TIME_PER_CHAR := 0.055
const FADE_TIME := 0.5

var key: StringName
## Screen point the banner hangs from (0..1 per axis) and its offset in pixels.
## A point in the lower half makes the banner grow upward.
var at := TOP_CENTER
var shift := TOP_SHIFT
var width := WIDTH


## Adds the tip `key` on top of `parent` (a Control or a CanvasLayer) unless it was already seen or the tips
## are off. Returns the banner, or null when nothing is shown. `p_at`, `p_shift`
## and `p_width` move it away from the screen's own controls.
static func show_once(parent: Node, p_key: StringName, p_at: Vector2 = TOP_CENTER,
		p_shift: Vector2 = TOP_SHIFT, p_width: float = WIDTH) -> HintBanner:
	if not Settings.data.show_hints or SaveService.has_seen_hint(p_key):
		return null
	# Captures and debug tools show the tips without spending them.
	if not Settings.is_debug_run():
		SaveService.mark_hint_seen(p_key)
	var banner := HintBanner.new()
	banner.key = p_key
	banner.at = p_at
	banner.shift = p_shift
	banner.width = p_width
	parent.add_child(banner)
	return banner


static func text_key(p_key: StringName) -> String:
	return "HINT_" + String(p_key).to_upper()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UiTheme.get_theme()
	add_theme_stylebox_override("panel", UiTheme.panel_style(UiTheme.GOLD, 0.8, 14))
	custom_minimum_size.x = width
	var text := Label.new()
	text.text = text_key(key)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", 24)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(text)
	anchor_left = at.x
	anchor_right = at.x
	anchor_top = at.y
	anchor_bottom = at.y
	# Horizontal: centered on the point, or starting from a screen edge.
	var left := shift.x - width * at.x
	offset_left = left
	offset_right = left + width
	offset_top = shift.y
	offset_bottom = shift.y
	grow_vertical = Control.GROW_DIRECTION_BEGIN if at.y > 0.5 else Control.GROW_DIRECTION_END
	UiFx.pop_in(self)
	var tween := create_tween()
	tween.tween_interval(BASE_TIME + TIME_PER_CHAR * tr(text.text).length())
	tween.tween_property(self, "modulate:a", 0.0, FADE_TIME)
	tween.tween_callback(queue_free)
