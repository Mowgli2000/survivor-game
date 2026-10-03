class_name MainMenu
extends Node2D
## Main menu (ADR 0013, 0015): animated arena backdrop, neon title,
## Play (character select) / Local co-op / Progression / Settings / Quit.
## Buttons only ask SceneRouter to act.

const ARENA_RECT := Rect2(-1200, -700, 2400, 1400)
const CROWD_RECT := Rect2(-850, -420, 1700, 840)
const MUSIC_DB := -8.0

var _crowd: MenuCrowd
var _buttons: VBoxContainer
var _play: Button
var _coop: Button
var _settings_button: Button
var _quit: Button
var _settings: SettingsScreen
var _progression_button: Button
var _character_select: CharacterSelect
var _progression: ProgressionScreen


func _ready() -> void:
	var arena := Arena.new()
	arena.setup(ARENA_RECT)
	add_child(arena)
	_crowd = MenuCrowd.new()
	var enemies: Array[EnemyData] = []
	enemies.assign(ContentDB.get_all(&"enemies"))
	_crowd.setup(CROWD_RECT, enemies)
	add_child(_crowd)
	var camera := Camera2D.new()
	add_child(camera)
	camera.make_current()

	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UiTheme.get_theme()
	layer.add_child(root)
	var veil := ColorRect.new()
	veil.color = Color(UiTheme.DIM, 0.45)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(veil)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 22)
	center.add_child(_buttons)
	var title := Label.new()
	title.text = "GAME_TITLE"
	title.theme_type_variation = &"TitleLabel"
	title.add_theme_font_size_override("font_size", 110)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_buttons.add_child(title)
	_buttons.add_child(Control.new())
	_play = _button("UI_PLAY", _open_character_select.bind(false))
	_coop = _button("UI_COOP", _open_character_select.bind(true))
	_progression_button = _button("UI_PROGRESSION", _open_progression)
	_settings_button = _button("UI_SETTINGS", _open_settings)
	_quit = _button("UI_QUIT", SceneRouter.quit)

	_settings = SettingsScreen.new()
	_settings.closed.connect(_on_settings_closed)
	root.add_child(_settings)
	_character_select = CharacterSelect.new()
	_character_select.started.connect(SceneRouter.goto_run)
	_character_select.closed.connect(func() -> void:
		_on_overlay_closed(_coop if _character_select.coop else _play))
	root.add_child(_character_select)
	_progression = ProgressionScreen.new()
	_progression.closed.connect(_on_overlay_closed.bind(_progression_button))
	root.add_child(_progression)

	Audio.play_music(Sounds.MUSIC_RUN, MUSIC_DB)
	UiFx.pop_in(title)
	_play.grab_focus.call_deferred()


func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.theme_type_variation = &"BigButton"
	button.custom_minimum_size = Vector2(380, 84)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(action)
	UiFx.hover_lift(button)
	_buttons.add_child(button)
	return button


func _open_settings() -> void:
	_buttons.visible = false
	_settings.open()


func _on_settings_closed() -> void:
	_on_overlay_closed(_settings_button)


func _open_character_select(coop: bool) -> void:
	_buttons.visible = false
	_character_select.open(coop)


func _open_progression() -> void:
	_buttons.visible = false
	_progression.open()


func _on_overlay_closed(focus: Button) -> void:
	_buttons.visible = true
	focus.grab_focus()
