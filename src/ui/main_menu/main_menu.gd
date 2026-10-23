class_name MainMenu
extends Node2D
## Main menu (ADR 0013, 0015, 0021): "Azure Crystal" theme. A framed panel with the
## logo and the buttons on the left, over one painted courtyard with the portal where the
## monsters are part of the picture (a still image, no sprite on top of it).
## Play (character select) / Local co-op / Progression / Settings / Quit.
## Buttons only ask SceneRouter to act.

const MUSIC_DB := 0.0
const BACKGROUND := preload("res://assets/ui/backgrounds/menu.png")
const LOGO := preload("res://assets/branding/title.png")
## Left panel: position and size; x of the logo and buttons, their width, y of the first button.
const PANEL_RECT := Rect2(48.0, 36.0, 640.0, 944.0)
const COLUMN_X := 108.0
const BUTTON_SIZE := Vector2(520.0, 62.0)
const FIRST_BUTTON_Y := 400.0
const LOGO_WIDTH := 520.0

var _hints: ButtonHints
var _buttons: VBoxContainer
var _play: Button
var _coop: Button
var _settings_button: Button
var _quit: Button
var _settings: SettingsScreen
var _progression_button: Button
var _skins_button: Button
var _character_select: CharacterSelect
## Local coop: split-screen pick, both players at once.
var _coop_select: CoopCharacterSelect
var _progression: ProgressionScreen
var _skin_shop: SkinShopScreen
var _credits_button: Button
var _credits: CreditsScreen


func _ready() -> void:
	var backdrop_layer := CanvasLayer.new()
	backdrop_layer.layer = -10
	add_child(backdrop_layer)
	var backdrop := UiBackdrop.create(BACKGROUND, 0.12)
	backdrop.animated = false  # a still picture (dev: the moving background was disliked)
	backdrop.sparks_enabled = false
	backdrop.base_zoom = 1.0  # no crop: the golem stands near the right edge of the picture
	backdrop_layer.add_child(backdrop)
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UiTheme.get_theme()
	layer.add_child(root)
	var frame := Panel.new()
	frame.position = PANEL_RECT.position
	frame.size = PANEL_RECT.size
	frame.add_theme_stylebox_override("panel", UiTheme.window_style())
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(frame)
	var crown := TextureRect.new()
	crown.texture = UiTheme.frame_texture("crown")
	crown.position = Vector2(PANEL_RECT.get_center().x - 110.0, PANEL_RECT.position.y - 34.0)
	crown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(crown)
	var title := TextureRect.new()
	title.texture = LOGO
	title.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title.position = Vector2(PANEL_RECT.get_center().x - LOGO_WIDTH * 0.5, 64.0)
	title.size = Vector2(LOGO_WIDTH, LOGO_WIDTH * LOGO.get_height() / LOGO.get_width())
	title.pivot_offset = title.size * 0.5
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(title)
	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 14)
	_buttons.position = Vector2(COLUMN_X, FIRST_BUTTON_Y)
	root.add_child(_buttons)
	_play = _button("UI_PLAY", _open_character_select.bind(false))
	_coop = _button("UI_COOP", _open_character_select.bind(true))
	_progression_button = _button("UI_PROGRESSION", _open_progression)
	_skins_button = _button("UI_SKIN_SHOP", _open_skin_shop)
	_settings_button = _button("UI_SETTINGS", _open_settings)
	_credits_button = _button("UI_CREDITS", _open_credits)
	_quit = _button("UI_QUIT", SceneRouter.quit)

	# Version in a corner: playtesters quote it in their bug reports.
	var version := Label.new()
	version.text = version_text()
	version.theme_type_variation = &"SmallLabel"
	version.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	version.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	version.grow_vertical = Control.GROW_DIRECTION_BEGIN
	version.offset_right = -24.0
	version.offset_bottom = -16.0
	root.add_child(version)

	_settings = SettingsScreen.new()
	_settings.closed.connect(_on_settings_closed)
	root.add_child(_settings)
	_character_select = CharacterSelect.new()
	_character_select.started.connect(SceneRouter.goto_run)
	_character_select.closed.connect(_on_overlay_closed.bind(_play))
	root.add_child(_character_select)
	_coop_select = CoopCharacterSelect.new()
	_coop_select.started.connect(SceneRouter.goto_run)
	_coop_select.closed.connect(_on_overlay_closed.bind(_coop))
	root.add_child(_coop_select)
	_progression = ProgressionScreen.new()
	_progression.closed.connect(_on_overlay_closed.bind(_progression_button))
	root.add_child(_progression)
	_skin_shop = SkinShopScreen.new()
	_skin_shop.closed.connect(_on_overlay_closed.bind(_skins_button))
	root.add_child(_skin_shop)
	_credits = CreditsScreen.new()
	_credits.closed.connect(_on_overlay_closed.bind(_credits_button))
	root.add_child(_credits)

	_hints = ButtonHints.create([[&"A", "UI_HINT_CONFIRM"], [&"B", "UI_HINT_BACK"]])
	root.add_child(_hints)
	Audio.play_music(Sounds.MUSIC_MENU, MUSIC_DB)
	UiFx.pop_in(title)
	_play.grab_focus.call_deferred()


## "v" + application/config/version (project.godot).
static func version_text() -> String:
	return "v" + str(ProjectSettings.get_setting("application/config/version", "0"))


func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.theme_type_variation = &"BigButton"
	button.custom_minimum_size = BUTTON_SIZE
	button.pressed.connect(action)
	UiFx.hover_lift(button)
	_buttons.add_child(button)
	return button


func _open_settings() -> void:
	_buttons.visible = false
	_hints.visible = false
	_settings.open()


func _on_settings_closed() -> void:
	_on_overlay_closed(_settings_button)


func _open_character_select(coop: bool) -> void:
	_buttons.visible = false
	_hints.visible = false
	if coop:
		_coop_select.open()
	else:
		_character_select.open()


func _open_progression() -> void:
	_buttons.visible = false
	_hints.visible = false
	_progression.open()


func _open_skin_shop() -> void:
	_buttons.visible = false
	_hints.visible = false
	_skin_shop.open()


func _open_credits() -> void:
	_buttons.visible = false
	_hints.visible = false
	_credits.open()


func _on_overlay_closed(focus: Button) -> void:
	_buttons.visible = true
	_hints.visible = ButtonHints.show_always or not Input.get_connected_joypads().is_empty()
	focus.grab_focus()
