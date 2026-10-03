class_name GameOverScreen
extends CanvasLayer
## Shown when the run ends (death or victory): run summary, retry and main menu buttons.

signal retry_requested
signal main_menu_requested
signal endless_requested

## Defeat veil: the night violet of the UI, pushed toward red.
const DEFEAT_DIM := Color(0.16, 0.03, 0.08, 0.8)

## True when the last open() was a victory.
var is_victory: bool = false

var _title: Label
var _dim: ColorRect
var _summary: Label
var _unlocks: HBoxContainer
var _retry: Button
var _main_menu: Button
var _endless: Button


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

	_unlocks = HBoxContainer.new()
	_unlocks.alignment = BoxContainer.ALIGNMENT_CENTER
	_unlocks.add_theme_constant_override("separation", 18)
	_unlocks.visible = false
	box.add_child(_unlocks)

	_retry = Button.new()
	_retry.text = "UI_RETRY"
	_retry.custom_minimum_size = Vector2(340, 84)
	_retry.theme_type_variation = &"BigButton"
	_retry.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_retry.pressed.connect(func() -> void: retry_requested.emit())
	box.add_child(_retry)

	_endless = Button.new()
	_endless.text = "UI_CONTINUE_ENDLESS"
	_endless.custom_minimum_size = Vector2(340, 64)
	_endless.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_endless.pressed.connect(func() -> void: endless_requested.emit())
	box.add_child(_endless)

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
	_endless.visible = victory
	visible = true
	UiFx.pop_in(_title)
	UiFx.pop_in(_summary, 0.08)
	UiFx.pop_in(_retry, 0.16)
	UiFx.pop_in(_main_menu, 0.24)
	_retry.grab_focus()


## New unlocks from this run (challenges completed), one card each: the
## character's animated sprite or the item/weapon icon, its name, "Unlocked!".
func show_unlocks(challenges: Array[ChallengeData]) -> void:
	for child in _unlocks.get_children():
		_unlocks.remove_child(child)
		child.queue_free()
	var delay := 0.3
	for challenge in challenges:
		var def := ContentDB.get_def(challenge.unlock_category, challenge.unlock_id)
		if def == null:
			continue
		var card := _unlock_card(def)
		_unlocks.add_child(card)
		UiFx.pop_in(card, delay)
		delay += 0.12
	_unlocks.visible = _unlocks.get_child_count() > 0


## Names (translation keys) of the unlock cards shown, in order (tests).
func unlock_names() -> PackedStringArray:
	var names: PackedStringArray = []
	for card in _unlocks.get_children():
		names.append(card.get_meta(&"name_key"))
	return names


func _unlock_card(def: Resource) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(190, 0)
	card.add_theme_stylebox_override("panel", UiTheme.card_style(UiTheme.GOLD, 0.9))
	card.set_meta(&"name_key", def.get(&"name_key"))
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)
	var visual: Control
	if def is CharacterData:
		visual = SpritePreview.create(CharacterSelect.character_sheet(def), 110.0)
	else:
		visual = IconTile.create(def.get(&"icon"), int(def.get(&"tier")) if def is ItemData else 1, 96.0)
	visual.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(visual)
	var name_label := Label.new()
	name_label.text = def.get(&"name_key")
	name_label.theme_type_variation = &"SubtitleLabel"
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if not def is CharacterData:
		name_label.add_theme_color_override("font_color", Tiers.color(int(def.get(&"tier")) if def is ItemData else 1))
	box.add_child(name_label)
	var tag := Label.new()
	tag.text = "UI_UNLOCKED_TAG"
	tag.theme_type_variation = &"SmallLabel"
	tag.add_theme_color_override("font_color", UiTheme.GOLD)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(tag)
	return card


func close() -> void:
	visible = false
