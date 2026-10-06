class_name ButtonHints
extends HBoxContainer
## Gamepad hint bar at the bottom of a screen: a colored round glyph and what it
## does ("A Confirm", "B Back"...). Shown only while a gamepad is connected
## (`show_always` forces it: debug captures). Display only.
## Example: `root.add_child(ButtonHints.create([[&"A", "UI_HINT_CONFIRM"], [&"B", "UI_HINT_BACK"]]))`

const GLYPH_COLORS: Dictionary[StringName, Color] = {
	&"A": Color("3ed16b"), &"B": Color("ff6673"), &"X": Color("5fb4ff"), &"Y": Color("ffd94d")}

static var show_always: bool = false


## `items`: [[glyph, text key], ...]; glyph is A, B, X or Y.
static func create(items: Array) -> ButtonHints:
	var bar := ButtonHints.new()
	bar.add_theme_constant_override("separation", 34)
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bar.offset_left = 64.0
	bar.offset_bottom = -28.0
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for item in items:
		var glyph := Label.new()
		glyph.text = String(item[0])
		glyph.custom_minimum_size = Vector2(40, 40)
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		glyph.add_theme_font_size_override("font_size", 24)
		glyph.add_theme_color_override("font_color", Color("10102a"))
		glyph.add_theme_constant_override("outline_size", 0)
		var color: Color = GLYPH_COLORS.get(StringName(item[0]), UiTheme.ACCENT)
		glyph.add_theme_stylebox_override("normal", UiTheme.glyph_style(color))
		var pair := HBoxContainer.new()
		pair.add_theme_constant_override("separation", 10)
		pair.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pair.add_child(glyph)
		var action := Label.new()
		action.text = String(item[1])
		action.theme_type_variation = &"SmallLabel"
		action.add_theme_font_size_override("font_size", 24)
		pair.add_child(action)
		bar.add_child(pair)
	bar.visible = show_always or not Input.get_connected_joypads().is_empty()
	return bar
