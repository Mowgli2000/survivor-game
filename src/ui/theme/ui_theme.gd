class_name UiTheme
## Single source of the UI look ("Azure Crystal", theme T3, ADR 0024): midnight-blue
## panels with bevelled, crystal-tipped frames (9-slice textures baked from SVG by
## tools/ui/make_frames.py), cyan accent, gold corners, coral for alerts, serif titles.
## Builds the Godot Theme once (fonts, styles, type variations) and exposes the
## palette plus accented style factories for elements colored by tier / weapon.
## Screens set `theme = UiTheme.get_theme()` on their root Control and use the
## type variations; only semantic colors are set per widget.
## Frames are drawn in near-white lines: the accent is applied as `modulate_color`.

const NUNITO := preload("res://assets/fonts/Nunito.ttf")
## Serif display font (headings, buttons) and its decorative cut (big titles).
const CINZEL := preload("res://assets/fonts/Cinzel.ttf")
const CINZEL_DECO := preload("res://assets/fonts/CinzelDecorative-Bold.ttf")
## Manga font: damage numbers only.
const BANGERS := preload("res://assets/fonts/Bangers.ttf")

const FRAMES := "res://assets/ui/frames/"

const TEXT := Color("eaf4ff")
const MUTED := Color(0.82, 0.9, 1.0, 0.6)
## General UI accent (titles, level-up, focus).
const ACCENT := Color("5fd4ff")
## Materials, "better" values.
const GOOD := Color("6dffa0")
## HP, "worse" values, too expensive, defeat (coral).
const BAD := Color("ff6b5e")
## Victory, elites, ornaments.
const GOLD := Color("f0cd7c")
## Section headings (settings), rare things.
const VIOLET := Color("a98bff")
const XP := Color("9b6dff")
const PANEL_BG := Color(0.035, 0.07, 0.18, 0.95)
## Full-screen veil behind menus: deep midnight blue, not pure black.
const DIM := Color(0.015, 0.03, 0.09, 0.8)
const OUTLINE := Color(0.01, 0.02, 0.06)
const OUTLINE_WIDTH := 3
## Kept for the few flat styles (glyphs, plates).
const GLOW_SIZE := 4
## Hovered / focused flat fills and the main-action fill (kept for debug tools).
const FOCUS_FILL := Color("1f5fd0")
const CTA_FILL := Color("2a7cf5")

static var _theme: Theme
static var _fonts: Dictionary = {}
static var _textures: Dictionary = {}


static func get_theme() -> Theme:
	if _theme == null:
		_theme = _build()
	return _theme


## Variable font at a given weight (Cinzel for display, Nunito for text). Cached.
static func font(weight: int, display: bool = false) -> FontVariation:
	var key := "%s%d" % ["F" if display else "N", weight]
	if not _fonts.has(key):
		var variation := FontVariation.new()
		variation.base_font = CINZEL if display else NUNITO
		variation.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
		_fonts[key] = variation
	return _fonts[key]


static func frame_texture(frame_name: String) -> Texture2D:
	if not _textures.has(frame_name):
		_textures[frame_name] = load(FRAMES + frame_name + ".png")
	return _textures[frame_name]


## Line color of a frame: dim blue-grey when `strength` is low, the accent when it is 1.
static func frame_tint(accent: Color, strength: float = 1.0) -> Color:
	var tint := Color(0.5, 0.62, 0.85).lerp(accent, clampf(strength, 0.0, 1.0))
	tint.a = lerpf(0.6, 1.0, clampf(strength, 0.0, 1.0))
	return tint


## 9-slice style from a baked frame. `margin` is the fixed corner size in texture pixels.
static func frame_style(frame_name: String, margin_h: int, margin_v: int, tint: Color,
		content: float = 16.0) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = frame_texture(frame_name)
	style.texture_margin_left = margin_h
	style.texture_margin_right = margin_h
	style.texture_margin_top = margin_v
	style.texture_margin_bottom = margin_v
	style.modulate_color = tint
	style.set_content_margin_all(content)
	return style


## Frame in the accent color: the cyan accent uses the frame baked in cyan (its gold corners
## stay gold), any other accent tints the white one (corners take the tint too).
static func accent_frame(frame_name: String, margin: int, accent: Color, strength: float,
		content: float) -> StyleBoxTexture:
	var tint := frame_tint(accent, strength)
	if accent.is_equal_approx(ACCENT):
		return frame_style(frame_name + "_cyan", margin, margin, Color(1.0, 1.0, 1.0, tint.a).lerp(
			Color(0.55, 0.65, 0.85), 1.0 - clampf(strength, 0.0, 1.0)), content)
	return frame_style(frame_name, margin, margin, tint, content)


## Panel: midnight fill, bevelled frame with gold corner brackets, tinted by `accent`.
## `radius` is kept for older callers (the frame shape is fixed).
static func panel_style(accent: Color, strength: float = 1.0, _radius: int = 16) -> StyleBoxTexture:
	return accent_frame("panel", 56, accent, strength, 24.0)


## Column of the select screen; `lit`: the step being edited (bright frame).
static func column_style(lit: bool) -> StyleBoxTexture:
	return accent_frame("panel", 56, ACCENT, 1.0 if lit else 0.4, 22.0)


## Window (pause, settings): the large panel with a bright frame.
static func window_style() -> StyleBoxTexture:
	return accent_frame("window", 56, ACCENT, 1.0, 44.0)


## Shop / level-up card colored by tier: brighter frame when `strength` is 1.
static func card_style(accent: Color, strength: float = 1.0) -> StyleBoxTexture:
	return accent_frame("card", 36, accent, strength, 16.0)


## Square slot (item tile): thin frame tinted by `accent`.
static func slot_style(accent: Color, strength: float = 1.0) -> StyleBoxTexture:
	return accent_frame("slot", 26, accent, strength, 8.0)


## Focus frame of a card-shaped button (card_style).
static func card_focus_style(accent: Color = ACCENT) -> StyleBoxTexture:
	return focus_style(accent, 20)


## Focus frame (keyboard / gamepad): glowing outline drawn around the control.
static func focus_style(accent: Color = ACCENT, _radius: int = 18) -> StyleBoxTexture:
	var style := frame_style("focus", 44, 44, accent, 0.0)
	style.draw_center = false
	style.expand_margin_left = 6.0
	style.expand_margin_right = 6.0
	style.expand_margin_top = 6.0
	style.expand_margin_bottom = 6.0
	return style


## Round colored glyph (gamepad button hint): dark outline, flat fill.
static func glyph_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = OUTLINE
	style.set_border_width_all(3)
	style.set_corner_radius_all(24)
	style.anti_aliasing = true
	return style


## Borderless soft panel (info plates): the text carries the screen, not a frame.
static func plate_style(radius: int = 22) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.04, 0.12, 0.6)
	style.set_corner_radius_all(mini(radius, 12))
	style.set_content_margin_all(22)
	style.anti_aliasing = true
	return style


## [background, fill] flat styles (no outline) for a thin ProgressBar filled with `color`.
static func flat_bar_styles(color: Color) -> Array[StyleBoxFlat]:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(1, 1, 1, 0.1)
	bg.set_corner_radius_all(4)
	bg.anti_aliasing = true
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(4)
	fill.anti_aliasing = true
	return [bg, fill]


## [background, fill] styles for a ProgressBar filled with `color` (slanted ends).
static func bar_styles(color: Color) -> Array[StyleBoxTexture]:
	var bg := frame_style("bar_bg", 12, 10, Color.WHITE, 0.0)
	var fill := frame_style("bar_fill", 12, 8, color, 0.0)
	return [bg, fill]


static func _button_style(frame_name: String, tint: Color = Color.WHITE) -> StyleBoxTexture:
	var style := frame_style(frame_name, 30, 24, tint, 0.0)
	style.content_margin_left = 30.0
	style.content_margin_right = 30.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	return style


static func _build() -> Theme:
	var theme := Theme.new()
	theme.default_font = font(700)
	theme.default_font_size = 22

	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_outline_color", "Label", OUTLINE)
	theme.set_constant("outline_size", "Label", 4)
	_label_variation(theme, &"TitleLabel", CINZEL_DECO, 76, 8, Color.WHITE)
	_label_variation(theme, &"SubtitleLabel", font(700, true), 30, 5, TEXT)
	_label_variation(theme, &"ValueLabel", font(700, true), 28, 5, TEXT)
	_label_variation(theme, &"SmallLabel", font(800), 17, 3, MUTED)

	theme.set_font("font", "Button", font(700, true))
	theme.set_font_size("font_size", "Button", 25)
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_focus_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", Color.WHITE)
	theme.set_color("font_disabled_color", "Button", Color(TEXT, 0.4))
	theme.set_color("font_outline_color", "Button", OUTLINE)
	theme.set_constant("outline_size", "Button", 5)
	theme.set_constant("h_separation", "Button", 10)
	theme.set_stylebox("normal", "Button", _button_style("button_normal"))
	theme.set_stylebox("hover", "Button", _button_style("button_hover"))
	theme.set_stylebox("pressed", "Button", _button_style("button_pressed"))
	theme.set_stylebox("disabled", "Button", _button_style("button_disabled"))
	# Keyboard / gamepad focus is shown by the lit style (hover), not an extra frame.
	theme.set_stylebox("focus", "Button", _button_style("button_hover"))
	theme.set_type_variation(&"BigButton", &"Button")
	theme.set_font_size("font_size", &"BigButton", 34)
	# Main action: bright blue with gold frame in every state.
	theme.set_type_variation(&"CtaButton", &"Button")
	theme.set_font_size("font_size", &"CtaButton", 38)
	theme.set_font("font", &"CtaButton", font(800, true))
	for state in ["normal", "hover", "focus"]:
		theme.set_stylebox(state, &"CtaButton", _button_style("button_cta"))
	theme.set_stylebox("pressed", &"CtaButton", _button_style("button_pressed", Color(1.0, 0.9, 0.7)))
	theme.set_stylebox("disabled", &"CtaButton", _button_style("button_disabled"))

	theme.set_stylebox("panel", "PanelContainer", panel_style(ACCENT, 0.7))
	theme.set_stylebox("panel", "Panel", panel_style(ACCENT, 0.7))
	var bars := bar_styles(ACCENT)
	theme.set_stylebox("background", "ProgressBar", bars[0])
	theme.set_stylebox("fill", "ProgressBar", bars[1])
	var tooltip := accent_frame("card", 36, ACCENT, 0.7, 10.0)
	theme.set_stylebox("panel", "TooltipPanel", tooltip)
	theme.set_color("font_color", "TooltipLabel", TEXT)
	theme.set_font("font", "TooltipLabel", font(700))
	# Settings controls (ADR 0013): sliders reuse the bar styles, toggles and
	# option buttons inherit the Button look; the popup list gets a panel.
	# Chunky track: the styles' content margins give the slider its thickness.
	var slider_bars := bar_styles(ACCENT)
	for style in slider_bars:
		style.content_margin_top = 8.0
		style.content_margin_bottom = 8.0
	theme.set_stylebox("slider", "HSlider", slider_bars[0])
	theme.set_stylebox("grabber_area", "HSlider", slider_bars[1])
	theme.set_stylebox("grabber_area_highlight", "HSlider", slider_bars[1])
	theme.set_stylebox("focus", "HSlider", focus_style(ACCENT, 10))
	theme.set_stylebox("panel", "PopupMenu", accent_frame("card", 36, ACCENT, 0.7, 12.0))
	theme.set_font("font", "PopupMenu", font(700))
	theme.set_font_size("font_size", "PopupMenu", 22)
	# Toggles: only the switch icon, no button frame (the frame read as a big empty button).
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		theme.set_stylebox(state, "CheckButton", StyleBoxEmpty.new())
	theme.set_stylebox("focus", "CheckButton", focus_style(ACCENT, 10))
	return theme


static func _label_variation(theme: Theme, variation: StringName, label_font: Font, size: int,
		outline: int, color: Color) -> void:
	theme.set_type_variation(variation, &"Label")
	theme.set_font("font", variation, label_font)
	theme.set_font_size("font_size", variation, size)
	theme.set_constant("outline_size", variation, outline)
	theme.set_color("font_color", variation, color)
