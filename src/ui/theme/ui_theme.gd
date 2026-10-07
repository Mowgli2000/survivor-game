class_name UiTheme
## Single source of the UI look ("chibi neon", ADR 0011; "Portal" pass: pill
## buttons, violet focus fill with a cyan frame, violet main-action button):
## drawn like the characters and icons: thick dark outline, flat dark fill.
## Builds the Godot Theme once (fonts, styles, type variations) and exposes the
## palette plus accented style factories for elements colored by tier / weapon.
## Screens set `theme = UiTheme.get_theme()` on their root Control and use the
## type variations; only semantic colors are set per widget.

const FREDOKA := preload("res://assets/fonts/Fredoka.ttf")
const NUNITO := preload("res://assets/fonts/Nunito.ttf")
## Manga title font (art bible): only for TitleLabel.
const BANGERS := preload("res://assets/fonts/Bangers.ttf")

const TEXT := Color("eef0ff")
const MUTED := Color(0.93, 0.94, 1.0, 0.55)
## General UI accent (titles, level-up, focus).
const ACCENT := Color("66f2ff")
## Materials, "better" values.
const GOOD := Color("73ff8c")
## HP, "worse" values, too expensive, defeat.
const BAD := Color("ff6673")
## Victory, elites.
const GOLD := Color("ffd94d")
## Section headings (settings).
const VIOLET := Color("b86bff")
const XP := Color("59b8ff")
const PANEL_BG := Color(0.106, 0.09, 0.188, 0.95)
## Full-screen veil behind menus: night violet, not pure black.
const DIM := Color(0.06, 0.04, 0.12, 0.78)
const OUTLINE := Color.BLACK
## Thinner frames and a tighter glow (playtest: thick neon borders hurt the eyes, the
## accent glow read as color bleeding past the black outline).
const OUTLINE_WIDTH := 3
const GLOW_SIZE := 4
## Portal theme: focused / hovered button fill, main-action button fill.
const FOCUS_FILL := Color("4a2a86")
const CTA_FILL := Color("7b3ff2")
## Buttons are pills: the radius is half their height or more.
const PILL := 40

static var _theme: Theme
static var _fonts: Dictionary = {}


static func get_theme() -> Theme:
	if _theme == null:
		_theme = _build()
	return _theme


## Variable font at a given weight (Fredoka for display, Nunito for text). Cached.
static func font(weight: int, display: bool = false) -> FontVariation:
	var key := "%s%d" % ["F" if display else "N", weight]
	if not _fonts.has(key):
		var variation := FontVariation.new()
		variation.base_font = FREDOKA if display else NUNITO
		variation.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
		_fonts[key] = variation
	return _fonts[key]


## Panel: dark violet fill tinted by `accent`, black outline, accent glow.
static func panel_style(accent: Color, strength: float = 1.0, radius: int = 16) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG.lerp(Color(accent, PANEL_BG.a), 0.07 * strength)
	style.border_color = OUTLINE
	style.set_border_width_all(OUTLINE_WIDTH)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(accent, 0.14 * strength)
	style.shadow_size = roundi(GLOW_SIZE * strength)
	style.set_content_margin_all(20)
	style.anti_aliasing = true
	return style


## Column of the select screen; `lit`: the step being edited (soft accent frame).
static func column_style(lit: bool) -> StyleBoxFlat:
	var style := panel_style(ACCENT, 0.4, 22)
	style.bg_color = Color(0.05, 0.03, 0.12, 0.8)
	style.border_color = Color(ACCENT, 0.8) if lit else OUTLINE
	style.set_border_width_all(3)
	style.set_content_margin_all(18)
	return style


## Window (pause, settings): the panel with a cyan frame.
static func window_style() -> StyleBoxFlat:
	var style := panel_style(ACCENT, 0.5, 26)
	style.border_color = Color(ACCENT, 0.85)
	style.set_border_width_all(3)
	style.set_content_margin_all(26)
	return style


## Shop / level-up card colored by tier: stronger glow when `strength` is 1.
static func card_style(accent: Color, strength: float = 1.0) -> StyleBoxFlat:
	var style := panel_style(accent, strength)
	style.set_content_margin_all(16)
	return style


## Focus frame of a card-shaped button (card_style): same rounded corners as the card,
## a pill frame on a card read as a second, different outline (playtest).
static func card_focus_style(accent: Color = ACCENT) -> StyleBoxFlat:
	var style := focus_style(accent, 21)
	style.set_border_width_all(3)
	return style


## Focus frame (keyboard / gamepad): crisp neon border drawn around the control.
static func focus_style(accent: Color = ACCENT, radius: int = 18) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.border_color = accent
	style.set_border_width_all(3)
	style.set_corner_radius_all(radius)
	style.set_expand_margin_all(5)
	style.anti_aliasing = true
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
	style.bg_color = Color(0.05, 0.03, 0.12, 0.55)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(22)
	style.anti_aliasing = true
	return style


## [background, fill] flat styles (no outline) for a thin ProgressBar filled with `color`.
static func flat_bar_styles(color: Color) -> Array[StyleBoxFlat]:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(1, 1, 1, 0.1)
	bg.set_corner_radius_all(6)
	bg.anti_aliasing = true
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(6)
	fill.anti_aliasing = true
	return [bg, fill]


## [background, fill] styles for a ProgressBar filled with `color`.
static func bar_styles(color: Color) -> Array[StyleBoxFlat]:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.04, 0.09, 0.9)
	bg.border_color = OUTLINE
	bg.set_border_width_all(3)
	bg.set_corner_radius_all(10)
	bg.anti_aliasing = true
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.border_color = OUTLINE
	fill.set_border_width_all(3)
	fill.set_corner_radius_all(10)
	fill.anti_aliasing = true
	return [bg, fill]


static func _button_style(accent: Color, strength: float, pressed: bool = false) -> StyleBoxFlat:
	var style := panel_style(accent, strength, PILL)
	style.content_margin_left = 26
	style.content_margin_right = 26
	style.content_margin_top = 10 + (3 if pressed else 0)
	style.content_margin_bottom = 12 - (3 if pressed else 0)
	style.shadow_size = 0
	if pressed:
		style.bg_color = style.bg_color.darkened(0.3)
	return style


## Focused / hovered / pressed button: violet fill, cyan frame.
static func _focused_button_style(pressed: bool = false) -> StyleBoxFlat:
	var style := _button_style(ACCENT, 1.0, pressed)
	style.bg_color = FOCUS_FILL.darkened(0.25 if pressed else 0.0)
	style.border_color = ACCENT
	style.set_border_width_all(3)
	return style


## Main action (Play, Next wave): bright violet, white text.
## Unfocused: frame in its own violet, so the white frame of the focused state stands out.
static func _cta_button_style(pressed: bool = false, focused: bool = false) -> StyleBoxFlat:
	var style := _focused_button_style(pressed)
	style.bg_color = CTA_FILL.darkened(0.25 if pressed else 0.0)
	if focused:
		style.bg_color = style.bg_color.lightened(0.15)
		style.border_color = Color.WHITE
		style.set_border_width_all(4)
	else:
		style.border_color = CTA_FILL.lightened(0.2)
	return style


static func _build() -> Theme:
	var theme := Theme.new()
	theme.default_font = font(700)
	theme.default_font_size = 22

	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_outline_color", "Label", OUTLINE)
	theme.set_constant("outline_size", "Label", 4)
	_label_variation(theme, &"TitleLabel", BANGERS, 80, 10, ACCENT)
	_label_variation(theme, &"SubtitleLabel", font(600, true), 32, 6, TEXT)
	_label_variation(theme, &"ValueLabel", font(600, true), 30, 6, TEXT)
	_label_variation(theme, &"SmallLabel", font(800), 17, 3, MUTED)

	theme.set_font("font", "Button", font(600, true))
	theme.set_font_size("font_size", "Button", 26)
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_focus_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", ACCENT)
	theme.set_color("font_disabled_color", "Button", Color(TEXT, 0.4))
	theme.set_color("font_outline_color", "Button", OUTLINE)
	theme.set_constant("outline_size", "Button", 5)
	theme.set_constant("h_separation", "Button", 10)
	theme.set_stylebox("normal", "Button", _button_style(ACCENT, 0.45))
	theme.set_stylebox("hover", "Button", _focused_button_style())
	theme.set_stylebox("pressed", "Button", _focused_button_style(true))
	var disabled := _button_style(ACCENT, 0.0)
	disabled.bg_color = Color(PANEL_BG, 0.7)
	theme.set_stylebox("disabled", "Button", disabled)
	# Keyboard / gamepad focus is shown by the filled style (hover), not an extra frame.
	theme.set_stylebox("focus", "Button", _focused_button_style())
	theme.set_type_variation(&"BigButton", &"Button")
	theme.set_font_size("font_size", &"BigButton", 36)
	# Main action: bright violet in every state.
	theme.set_type_variation(&"CtaButton", &"Button")
	theme.set_font_size("font_size", &"CtaButton", 40)
	theme.set_font("font", &"CtaButton", BANGERS)
	theme.set_stylebox("normal", &"CtaButton", _cta_button_style())
	for state in ["hover", "focus"]:
		theme.set_stylebox(state, &"CtaButton", _cta_button_style(false, true))
	theme.set_stylebox("pressed", &"CtaButton", _cta_button_style(true, true))
	theme.set_stylebox("disabled", &"CtaButton", disabled)

	theme.set_stylebox("panel", "PanelContainer", panel_style(ACCENT, 0.6))
	theme.set_stylebox("panel", "Panel", panel_style(ACCENT, 0.6))
	var bars := bar_styles(ACCENT)
	theme.set_stylebox("background", "ProgressBar", bars[0])
	theme.set_stylebox("fill", "ProgressBar", bars[1])
	var tooltip := panel_style(ACCENT, 0.5, 10)
	tooltip.set_content_margin_all(10)
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
	theme.set_stylebox("panel", "PopupMenu", panel_style(ACCENT, 0.6, 10))
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
