class_name MainMenu
extends Node2D
## Main menu (ADR 0013, 0015): the dev's "Portal C2" mockup. Title and pill
## buttons in a column on the left, over the lit arena: a big red gate (the only
## thing that moves: spiral core, halo, runes), the demon knight standing in
## front of it and his horde standing around (a still picture).
## Play (character select) / Local co-op / Progression / Settings / Quit.
## Buttons only ask SceneRouter to act.

const ARENA_RECT := Rect2(-1200, -700, 2400, 1400)
const MUSIC_DB := 0.0
const GATE_COLOR := Color(1.0, 0.33, 0.47)
const GATE_CORE := Color(0.29, 0.06, 0.19)
const GATE_RADIUS := 330.0
## World positions (the camera is centered on 0, 0 of a 1920x1080 screen).
const GATE_POSITION := Vector2(440.0, -160.0)
const BOSS_FEET := Vector2(460.0, 470.0)
const BOSS_HEIGHT := 800.0
## Left column: x of the title and buttons, their width, y of the first button.
const COLUMN_X := 100.0
const BUTTON_SIZE := Vector2(520.0, 80.0)
const FIRST_BUTTON_Y := 360.0
const FADE_WIDTH := 880.0

var _crowd: MenuCrowd
var _crowd_front: MenuCrowd
var _boss: MenuBoss
var _hints: ButtonHints
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
	var enemies: Array[EnemyData] = []
	enemies.assign(ContentDB.get_all(&"enemies"))
	var camera := Camera2D.new()
	add_child(camera)
	camera.make_current()
	var gate := MenuGate.new()
	gate.radius = GATE_RADIUS
	gate.color = GATE_COLOR
	gate.core = GATE_CORE
	gate.position = GATE_POSITION
	add_child(gate)
	# Far monsters, then the knight, then the near monsters in front of him.
	_crowd = MenuCrowd.new()
	_crowd.y_to = BOSS_FEET.y
	_crowd.setup(enemies)
	add_child(_crowd)
	_boss = MenuBoss.new()
	_boss.height = BOSS_HEIGHT
	_boss.position = BOSS_FEET
	add_child(_boss)
	_crowd_front = MenuCrowd.new()
	_crowd_front.y_from = BOSS_FEET.y
	_crowd_front.setup(enemies)
	add_child(_crowd_front)

	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UiTheme.get_theme()
	layer.add_child(root)
	root.add_child(_left_fade())
	var title := Label.new()
	title.text = "GAME_TITLE"
	title.theme_type_variation = &"TitleLabel"
	title.add_theme_font_size_override("font_size", 120)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.position = Vector2(COLUMN_X + 6.0, 70.0)
	title.custom_minimum_size.x = BUTTON_SIZE.x + 160.0
	title.size.x = BUTTON_SIZE.x + 160.0
	root.add_child(title)
	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 20)
	_buttons.position = Vector2(COLUMN_X, FIRST_BUTTON_Y)
	root.add_child(_buttons)
	_play = _button("UI_PLAY", _open_character_select.bind(false))
	_coop = _button("UI_COOP", _open_character_select.bind(true))
	_progression_button = _button("UI_PROGRESSION", _open_progression)
	_settings_button = _button("UI_SETTINGS", _open_settings)
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
	_character_select.closed.connect(func() -> void:
		_on_overlay_closed(_coop if _character_select.coop else _play))
	root.add_child(_character_select)
	_progression = ProgressionScreen.new()
	_progression.closed.connect(_on_overlay_closed.bind(_progression_button))
	root.add_child(_progression)

	_hints = ButtonHints.create([[&"A", "UI_HINT_CONFIRM"], [&"B", "UI_HINT_BACK"]])
	root.add_child(_hints)
	Audio.play_music(Sounds.MUSIC_MENU, MUSIC_DB)
	UiFx.pop_in(title)
	_play.grab_focus.call_deferred()


## Dark fade on the left so the title and buttons stay readable over the arena.
func _left_fade() -> TextureRect:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(UiTheme.DIM, 0.94))
	gradient.set_color(1, Color(UiTheme.DIM, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 256
	texture.height = 8
	texture.fill_from = Vector2(0.0, 0.0)
	texture.fill_to = Vector2(1.0, 0.0)
	var fade := TextureRect.new()
	fade.texture = texture
	fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fade.stretch_mode = TextureRect.STRETCH_SCALE
	fade.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	fade.offset_right = FADE_WIDTH
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return fade


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
	_character_select.open(coop)


func _open_progression() -> void:
	_buttons.visible = false
	_hints.visible = false
	_progression.open()


func _on_overlay_closed(focus: Button) -> void:
	_buttons.visible = true
	_hints.visible = ButtonHints.show_always or not Input.get_connected_joypads().is_empty()
	focus.grab_focus()
