class_name CharacterSelect
extends Control
## Character and starting weapon choice before a run (ADR 0015). Locked
## characters are shown greyed out with the challenge that unlocks them.
## Emits `started(setup)`; the main menu asks SceneRouter to start the run.

signal started(setup: RunSetup)
signal closed

const CARD_SIZE := Vector2(300, 430)
const PREVIEW_HEIGHT := 170.0

var _character_buttons: Dictionary[StringName, Button] = {}
var _cards: HBoxContainer
var _weapons: HBoxContainer
var _weapon_title: Label
var _dangers: HBoxContainer
var _danger_title: Label
var _weapon: WeaponData
var _back: Button
var _chosen: CharacterData


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.get_theme()
	visible = false
	var dim := ColorRect.new()
	dim.color = UiTheme.DIM
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	center.add_child(box)
	var title := Label.new()
	title.text = "UI_CHOOSE_CHARACTER"
	title.theme_type_variation = &"TitleLabel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_cards = HBoxContainer.new()
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards.add_theme_constant_override("separation", 20)
	box.add_child(_cards)
	_weapon_title = Label.new()
	_weapon_title.text = "UI_CHOOSE_WEAPON"
	_weapon_title.theme_type_variation = &"SubtitleLabel"
	_weapon_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_weapon_title)
	_weapons = HBoxContainer.new()
	_weapons.alignment = BoxContainer.ALIGNMENT_CENTER
	_weapons.add_theme_constant_override("separation", 16)
	box.add_child(_weapons)
	_danger_title = Label.new()
	_danger_title.text = "UI_CHOOSE_DANGER"
	_danger_title.theme_type_variation = &"SubtitleLabel"
	_danger_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_danger_title)
	_dangers = HBoxContainer.new()
	_dangers.alignment = BoxContainer.ALIGNMENT_CENTER
	_dangers.add_theme_constant_override("separation", 12)
	box.add_child(_dangers)
	_back = Button.new()
	_back.text = "UI_BACK"
	_back.custom_minimum_size = Vector2(260, 64)
	_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_back.pressed.connect(_go_back)
	box.add_child(_back)


func open() -> void:
	_build_cards()
	_show_weapons(false)
	_show_dangers(false)
	visible = true
	for button: Button in _character_buttons.values():
		if not button.disabled:
			button.grab_focus()
			break


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		_go_back()


func _go_back() -> void:
	if _dangers.visible:
		_show_dangers(false)
		if _weapons.get_child_count() > 0:
			(_weapons.get_child(0) as Button).grab_focus()
	elif _weapons.visible:
		_show_weapons(false)
		_character_buttons[_chosen.id].grab_focus()
	else:
		close()


func _build_cards() -> void:
	for child in _cards.get_children():
		_cards.remove_child(child)
		child.queue_free()
	_character_buttons.clear()
	var characters: Array[CharacterData] = []
	characters.assign(ContentDB.get_all(&"characters"))
	# Starting characters first, then the ones to unlock (stable by id).
	characters.sort_custom(func(a: CharacterData, b: CharacterData) -> bool:
		return a.locked != b.locked and not a.locked or a.locked == b.locked and String(a.id) < String(b.id))
	for character in characters:
		var unlocked := SaveService.is_unlocked(&"characters", character)
		var button := Button.new()
		button.custom_minimum_size = CARD_SIZE
		button.disabled = not unlocked
		button.add_theme_stylebox_override("normal", UiTheme.card_style(character.color, 0.6 if unlocked else 0.15))
		button.add_theme_stylebox_override("hover", UiTheme.card_style(character.color, 1.0))
		button.add_theme_stylebox_override("disabled", UiTheme.card_style(character.color, 0.1))
		var text := VBoxContainer.new()
		text.set_anchors_preset(Control.PRESET_FULL_RECT)
		text.offset_left = 16
		text.offset_right = -16
		text.offset_top = 16
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text.add_theme_constant_override("separation", 10)
		button.add_child(text)
		var preview := SpritePreview.create(character_sheet(character), PREVIEW_HEIGHT, not unlocked)
		preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		text.add_child(preview)
		var name_label := Label.new()
		name_label.text = character.name_key
		name_label.theme_type_variation = &"SubtitleLabel"
		name_label.add_theme_color_override("font_color", character.color if unlocked else UiTheme.MUTED)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.add_child(name_label)
		var rule := Label.new()
		rule.text = character.description_key if unlocked else _unlock_hint(character)
		rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rule.add_theme_font_size_override("font_size", 18)
		rule.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if not unlocked:
			rule.add_theme_color_override("font_color", UiTheme.MUTED)
		text.add_child(rule)
		if unlocked and not character.modifiers.is_empty():
			var mods := Label.new()
			mods.text = LevelUpScreen.describe_modifiers(character.modifiers)
			mods.theme_type_variation = &"SmallLabel"
			mods.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			mods.add_theme_color_override("font_color", character.color)
			text.add_child(mods)
		button.pressed.connect(_choose_character.bind(character))
		UiFx.hover_lift(button)
		_cards.add_child(button)
		_character_buttons[character.id] = button


## Sprite sheet of a character (same path rule as Player), or null.
static func character_sheet(character: CharacterData) -> SpriteSheet:
	var path := "res://assets/sprites/%s.tres" % character.sprite_id
	return load(path) as SpriteSheet if character.sprite_id != &"" and ResourceLoader.exists(path) else null


## "Locked: <challenge description>" for the challenge that unlocks `character`.
func _unlock_hint(character: CharacterData) -> String:
	for challenge in SaveService.all_challenges():
		if challenge.unlock_category == &"characters" and challenge.unlock_id == character.id:
			return tr("UI_LOCKED") % tr(challenge.description_key)
	return tr("UI_LOCKED") % "?"


func _choose_character(character: CharacterData) -> void:
	_chosen = character
	# Another card may be picked while the previous character's weapon and
	# Danger rows are still shown: forget them (they belong to that character).
	_weapon = null
	for child in _dangers.get_children():
		_dangers.remove_child(child)
		child.queue_free()
	_show_dangers(false)
	for child in _weapons.get_children():
		_weapons.remove_child(child)
		child.queue_free()
	var choices: Array[WeaponData] = []
	for weapon in character.starting_weapons:
		if SaveService.is_unlocked(&"weapons", weapon):
			choices.append(weapon)
	if choices.is_empty() and character.starting_weapon != null:
		choices.append(character.starting_weapon)
	for weapon in choices:
		var button := Button.new()
		button.text = weapon.name_key
		button.icon = weapon.icon
		button.expand_icon = true
		button.custom_minimum_size = Vector2(280, 72)
		button.add_theme_color_override("font_color", Tiers.color(1))
		button.pressed.connect(_choose_weapon.bind(weapon))
		_weapons.add_child(button)
	_show_weapons(true)
	if _weapons.get_child_count() > 0:
		(_weapons.get_child(0) as Button).grab_focus()


func _show_weapons(on: bool) -> void:
	_weapons.visible = on
	_weapon_title.visible = on


func _choose_weapon(weapon: WeaponData) -> void:
	_weapon = weapon
	for child in _dangers.get_children():
		_dangers.remove_child(child)
		child.queue_free()
	var allowed := SaveService.profile.max_difficulty(_chosen.id)
	var levels: Array[DifficultyData] = []
	levels.assign(ContentDB.get_all(&"difficulties"))
	levels.sort_custom(func(a: DifficultyData, b: DifficultyData) -> bool: return a.level < b.level)
	for difficulty in levels:
		var button := Button.new()
		button.text = difficulty.name_key
		button.tooltip_text = difficulty.description_key
		button.custom_minimum_size = Vector2(170, 64)
		button.disabled = difficulty.level > allowed
		button.pressed.connect(_start.bind(difficulty))
		_dangers.add_child(button)
	_show_dangers(true)
	var last := mini(allowed, _dangers.get_child_count() - 1)
	if last >= 0:
		(_dangers.get_child(last) as Button).grab_focus()


func _show_dangers(on: bool) -> void:
	_dangers.visible = on
	_danger_title.visible = on


func _start(difficulty: DifficultyData) -> void:
	var setup := RunSetup.new()
	setup.character = _chosen
	setup.weapon = _weapon
	setup.difficulty = difficulty
	started.emit(setup)
