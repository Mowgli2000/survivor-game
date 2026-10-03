class_name GameOverScreen
extends CanvasLayer
## Shown when the run ends (death or victory): run summary, retry and main menu buttons.

signal retry_requested
signal main_menu_requested

## Defeat veil: the night violet of the UI, pushed toward red.
const DEFEAT_DIM := Color(0.16, 0.03, 0.08, 0.8)

## True when the last open() was a victory.
var is_victory: bool = false

var _title: Label
var _dim: ColorRect
var _summary: Label
var _unlocks: Label
var _retry: Button
var _main_menu: Button


func _init() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiTheme.get_theme()
	add_child(root)

	_dim = ColorRect.new()
	_dim.color = DEFEAT_DIM
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(_dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 32)
	center.add_child(box)

	_title = Label.new()
	_title.text = "UI_GAME_OVER"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.theme_type_variation = &"TitleLabel"
	_title.add_theme_font_size_override("font_size", 88)
	box.add_child(_title)

	_summary = Label.new()
	_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_summary.theme_type_variation = &"ValueLabel"
	_summary.add_theme_font_size_override("font_size", 32)
	box.add_child(_summary)

	_unlocks = Label.new()
	_unlocks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_unlocks.theme_type_variation = &"SubtitleLabel"
	_unlocks.add_theme_color_override("font_color", UiTheme.GOLD)
	_unlocks.visible = false
	box.add_child(_unlocks)

	_retry = Button.new()
	_retry.text = "UI_RETRY"
	_retry.custom_minimum_size = Vector2(340, 84)
	_retry.theme_type_variation = &"BigButton"
	_retry.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_retry.pressed.connect(func() -> void: retry_requested.emit())
	box.add_child(_retry)

	_main_menu = Button.new()
	_main_menu.text = "UI_MAIN_MENU"
	_main_menu.custom_minimum_size = Vector2(340, 64)
	_main_menu.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_main_menu.pressed.connect(func() -> void: main_menu_requested.emit())
	box.add_child(_main_menu)


func open(time_survived: float, level: int, kills: int, wave: int, victory: bool = false) -> void:
	is_victory = victory
	_title.text = "UI_VICTORY" if victory else "UI_GAME_OVER"
	_title.add_theme_color_override("font_color", UiTheme.GOLD if victory else UiTheme.BAD)
	_dim.color = UiTheme.DIM if victory else DEFEAT_DIM
	_summary.text = "%s %d\n%s %s\n%s %d\n%s %d" % [
		tr("UI_WAVE_REACHED"), wave,
		tr("UI_TIME_SURVIVED"), Hud.format_time(time_survived),
		tr("UI_LEVEL_LABEL"), level,
		tr("UI_KILLS"), kills,
	]
	_unlocks.visible = false
	visible = true
	UiFx.pop_in(_title)
	UiFx.pop_in(_summary, 0.08)
	UiFx.pop_in(_retry, 0.16)
	UiFx.pop_in(_main_menu, 0.24)
	_retry.grab_focus()


## New unlocks from this run (challenges completed), one line each.
func show_unlocks(challenges: Array[ChallengeData]) -> void:
	var lines: PackedStringArray = []
	for challenge in challenges:
		var def := ContentDB.get_def(challenge.unlock_category, challenge.unlock_id)
		var target: String = tr(def.get(&"name_key")) if def != null else String(challenge.unlock_id)
		lines.append(tr("UI_UNLOCKED") % target)
	_unlocks.text = "\n".join(lines)
	_unlocks.visible = not lines.is_empty()
	if _unlocks.visible:
		UiFx.pop_in(_unlocks, 0.3)
