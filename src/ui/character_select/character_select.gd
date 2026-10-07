class_name CharacterSelect
extends Control
## Character and starting weapon choice before a run (ADR 0015). Locked
## characters are shown greyed out with the challenge that unlocks them.
## Local coop (ADR 0017): CoopCharacterSelect shows one compact copy per half of the
## screen (`split_index`), both players pick at once; player 1 also picks the seal
## and presses Play without waiting: the run starts as soon as player 2 is ready.
## Emits `started(setup)`; the main menu asks SceneRouter to start the run.

signal started(setup: RunSetup)
signal closed
## Split coop: this half's character and weapon are chosen (`unpicked`: taken back).
signal picked
signal unpicked

## "Portal" layout (dev's mockup): the hero in full on the left with his rule,
## bonuses and stats; on the right the heads of the seven classes, then the
## starting weapons and the seals once a hero is picked.
const HEAD_SIZE := 142.0
## Head and shoulders of a card illustration (512x768): the square shown in a head tile.
const HEAD_REGION := Rect2(72.0, 8.0, 368.0, 368.0)
const HERO_COLUMN := 700.0
const HERO_ART_HEIGHT := 420.0
const PREVIEW_HEIGHT := 170.0
## Half-screen layout (split coop): heads on top, the hero beside his art below.
const COMPACT_HEAD_SIZE := 108.0
const COMPACT_ART := Vector2(230, 290)
const COMPACT_SEAL_SIZE := Vector2(140, 100)
## Six seals must fit the right column.
const SEAL_SIZE := Vector2(168, 116)
const ROMAN: Array[String] = ["I", "II", "III", "IV", "V", "VI"]
const SKULL := "☠"
const LOCK := "🔒"
const REWARD_ICON := 30.0
## Copper -> Astral: sea green, lime, yellow, orange, red, blood red.
const SEAL_HEAT: Array[Color] = [Color("4de0b8"), Color("a6e34d"), Color("ffd84d"),
		Color("ff9a3d"), Color("ff4a3d"), Color("c8102e")]
const FEMALE_COLOR := Color("ff7ab8")
const MALE_COLOR := Color("5fb4ff")
## Bar fill = stat / these values (a full bar is a strong class, not a maximum).
const BAR_HP := 150.0
const BAR_DAMAGE := 1.5
const BAR_SPEED := 400.0
const BAR_RANGE := 1.6
## Fill color of each stat bar.
const STAT_COLORS: Dictionary[StringName, Color] = {
	StatIds.MAX_HP: Color("ff6673"), StatIds.DAMAGE: Color("ffb347"),
	StatIds.MOVE_SPEED: Color("66f2ff"), StatIds.RANGE: Color("b86bff")}

var _character_buttons: Dictionary[StringName, Button] = {}
var _cards: HBoxContainer
## Hero panel (left): illustration, switch, name, rule, bonuses, stat bars.
var _hero_art: TextureRect
var _look_switch: Button
var _hero_name: Label
var _hero_rule: Label
var _hero_chips: HFlowContainer
var _hero_bars: Dictionary[StringName, ProgressBar] = {}
var _hero_values: Dictionary[StringName, Label] = {}
var _hero_plate: PanelContainer
## Hero shown in the panel: the focused head, else the chosen one.
var _shown: CharacterData
var _weapons: HBoxContainer
var _weapon_title: Label
var _dangers: HBoxContainer
## Starts the run with the chosen seal (a seal press only selects it).
var _launch: Button
var _difficulty: DifficultyData
var _danger_title: Label
var _seal_info: Label
var _seal_effects: Label
var _weapon: WeaponData
var _back: Button
var _chosen: CharacterData
var _title: Label
## Which gamepad drives this player (split coop only).
var _devices: Label
## Split coop: 0 = left half (player 1), 1 = right half; -1 = full-screen (solo).
var split_index: int = -1
## Split coop: character and weapon chosen, waiting for the other player.
var is_ready: bool = false
## Split coop: "Ready, waiting for..." under the weapons.
var _ready_label: Label
## Split coop (player 1): the partner's character once picked, for the seals both have unlocked.
var _partner: CharacterData
var _compact: bool = false
var _head_size := HEAD_SIZE
var _seal_size := SEAL_SIZE
## Last key / gamepad event came from a gamepad: focusing a head shows the hero
## (with the keyboard or the mouse, only a click does).
var _pad_focus: bool = false
## Look picked on each card (0 = the character itself, 1 = its second look).
var _variants: Dictionary[StringName, int] = {}


func _init(p_compact: bool = false) -> void:
	_compact = p_compact
	if _compact:
		_head_size = COMPACT_HEAD_SIZE
		_seal_size = COMPACT_SEAL_SIZE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.get_theme()
	visible = false
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.08, 0.05, 0.17, 1.0)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 24 if _compact else 48)
	margin.add_theme_constant_override("margin_top", 20 if _compact else 28)
	margin.add_theme_constant_override("margin_bottom", 24 if _compact else 96)
	add_child(margin)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 10)
	margin.add_child(page)
	# Top bar: back pill, title (the co-op line next to it).
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 28)
	page.add_child(top)
	_back = Button.new()
	_back.text = "UI_BACK"
	_back.custom_minimum_size = Vector2(150, 52) if _compact else Vector2(190, 64)
	_back.pressed.connect(_go_back)
	top.add_child(_back)
	_title = Label.new()
	_title.text = "UI_CHOOSE_CHARACTER"
	_title.theme_type_variation = &"TitleLabel"
	_title.add_theme_font_size_override("font_size", 44 if _compact else 64)
	top.add_child(_title)
	_devices = Label.new()
	_devices.theme_type_variation = &"SmallLabel"
	_devices.size_flags_vertical = Control.SIZE_SHRINK_END
	top.add_child(_devices)
	# Full screen: hero on the left, heads and rows on the right. Half screen: heads,
	# then the hero, then the rows, from top to bottom.
	var body: BoxContainer = VBoxContainer.new() if _compact else HBoxContainer.new()
	body.add_theme_constant_override("separation", 12 if _compact else 40)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(body)
	_cards = HBoxContainer.new()
	_cards.add_theme_constant_override("separation", 10 if _compact else 12)
	if _compact:
		body.add_child(_cards)
	body.add_child(_build_hero_panel())
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 8 if _compact else 10)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(right)
	if not _compact:
		right.add_child(_cards)
	_weapon_title = _section_label("UI_CHOOSE_WEAPON")
	right.add_child(_weapon_title)
	_weapons = HBoxContainer.new()
	_weapons.add_theme_constant_override("separation", 16)
	right.add_child(_weapons)
	_danger_title = _section_label("UI_CHOOSE_DANGER")
	right.add_child(_danger_title)
	_dangers = HBoxContainer.new()
	_dangers.add_theme_constant_override("separation", 12)
	right.add_child(_dangers)
	# Effects and place of the hovered / focused seal. Two reserved lines as wide
	# as the seal row: a long text wraps inside them instead of shifting the layout.
	_seal_info = Label.new()
	_seal_info.add_theme_font_size_override("font_size", 20)
	_seal_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_seal_info.custom_minimum_size = Vector2(_seal_size.x * 6 + 12 * 5, 28)
	right.add_child(_seal_info)
	_seal_effects = Label.new()
	_seal_effects.add_theme_font_size_override("font_size", 16)
	_seal_effects.add_theme_color_override("font_color", UiTheme.MUTED)
	_seal_effects.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_seal_effects.custom_minimum_size = Vector2(_seal_size.x * 6 + 12 * 5, 24)
	right.add_child(_seal_effects)
	_launch = Button.new()
	_launch.text = "UI_PLAY"
	_launch.theme_type_variation = &"CtaButton"
	_launch.custom_minimum_size = Vector2(280, 72) if _compact else Vector2(340, 84)
	_launch.size_flags_horizontal = Control.SIZE_SHRINK_END
	_launch.visible = false
	_launch.pressed.connect(_start)
	right.add_child(_launch)
	_ready_label = _section_label("UI_COOP_READY")
	_ready_label.add_theme_color_override("font_color", UiTheme.GOOD)
	_ready_label.visible = false
	right.add_child(_ready_label)
	if not _compact:
		add_child(ButtonHints.create([[&"A", "UI_HINT_CHOOSE"], [&"B", "UI_HINT_BACK"], [&"Y", "UI_HINT_SWITCH_LOOK"]]))


func _section_label(key: String) -> Label:
	var label := Label.new()
	label.text = key
	label.theme_type_variation = &"SubtitleLabel"
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", UiTheme.MUTED)
	return label


## Left column: the illustration of the shown hero (switch top-right), then a plate
## with his name, rule, bonus / malus chips and four stat bars.
## Half screen: the illustration on the left of the plate instead of above it.
func _build_hero_panel() -> Control:
	var column: BoxContainer = HBoxContainer.new() if _compact else VBoxContainer.new()
	if not _compact:
		column.custom_minimum_size.x = HERO_COLUMN
	column.add_theme_constant_override("separation", 8)
	var art_box := Control.new()
	art_box.custom_minimum_size = COMPACT_ART if _compact else Vector2(HERO_COLUMN, HERO_ART_HEIGHT)
	column.add_child(art_box)
	# Width left to the texts of the plate.
	var text_width := 560.0 if _compact else HERO_COLUMN - 64.0
	_hero_art = TextureRect.new()
	_hero_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hero_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hero_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_hero_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_box.add_child(_hero_art)
	_look_switch = Button.new()
	_look_switch.focus_mode = Control.FOCUS_NONE
	_look_switch.flat = true
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		_look_switch.add_theme_stylebox_override(state, empty)
	_look_switch.add_theme_font_size_override("font_size", 46)
	_look_switch.tooltip_text = "UI_SWITCH_LOOK"
	_look_switch.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_look_switch.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_look_switch.offset_left = -64.0
	_look_switch.offset_right = -8.0
	_look_switch.offset_top = 4.0
	_look_switch.offset_bottom = 60.0
	_look_switch.pressed.connect(func() -> void:
		if _shown != null:
			_toggle_variant(_shown))
	art_box.add_child(_look_switch)
	_hero_plate = PanelContainer.new()
	_hero_plate.add_theme_stylebox_override("panel", UiTheme.plate_style())
	_hero_plate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(_hero_plate)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 10)
	_hero_plate.add_child(info)
	_hero_name = Label.new()
	_hero_name.theme_type_variation = &"TitleLabel"
	_hero_name.add_theme_font_size_override("font_size", 40 if _compact else 60)
	info.add_child(_hero_name)
	_hero_rule = Label.new()
	_hero_rule.add_theme_font_size_override("font_size", 18 if _compact else 21)
	_hero_rule.add_theme_color_override("font_color", UiTheme.MUTED)
	_hero_rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hero_rule.custom_minimum_size = Vector2(text_width, 48.0 if _compact else 56.0)
	info.add_child(_hero_rule)
	# Bonuses (green) and maluses (red): two columns of plain text, no frames.
	_hero_chips = HFlowContainer.new()
	_hero_chips.add_theme_constant_override("h_separation", 26)
	_hero_chips.add_theme_constant_override("v_separation", 2)
	_hero_chips.custom_minimum_size = Vector2(text_width, 48.0 if _compact else 56.0)
	info.add_child(_hero_chips)
	# Stats: label, thin bar, value on one line each.
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 8)
	info.add_child(grid)
	for entry in [[StatIds.MAX_HP, "STAT_MAX_HP"], [StatIds.DAMAGE, "STAT_DAMAGE"],
			[StatIds.MOVE_SPEED, "STAT_MOVE_SPEED"], [StatIds.RANGE, "STAT_RANGE"]]:
		var stat: StringName = entry[0]
		var name_label := Label.new()
		name_label.text = entry[1]
		name_label.add_theme_font_size_override("font_size", 18 if _compact else 21)
		name_label.add_theme_color_override("font_color", UiTheme.MUTED)
		name_label.add_theme_constant_override("outline_size", 0)
		name_label.custom_minimum_size.x = 170.0 if _compact else 230.0
		grid.add_child(name_label)
		var bar := ProgressBar.new()
		bar.max_value = 1.0
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(200 if _compact else 250, 12)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var styles := UiTheme.flat_bar_styles(STAT_COLORS[stat])
		bar.add_theme_stylebox_override("background", styles[0])
		bar.add_theme_stylebox_override("fill", styles[1])
		grid.add_child(bar)
		var value_label := Label.new()
		value_label.add_theme_font_size_override("font_size", 23)
		value_label.add_theme_color_override("font_color", STAT_COLORS[stat])
		value_label.add_theme_constant_override("outline_size", 0)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.custom_minimum_size.x = 80.0
		grid.add_child(value_label)
		_hero_bars[stat] = bar
		_hero_values[stat] = value_label
	return column


## `p_split_index` >= 0: one half of the split coop pick (CoopCharacterSelect).
func open(p_split_index: int = -1) -> void:
	split_index = p_split_index
	_partner = null
	_set_ready(false)
	_devices.visible = split_index >= 0
	_devices.text = devices_hint(split_index, Input.get_connected_joypads().size())
	_begin_pick()


## Shows the cards.
func _begin_pick() -> void:
	_title.text = tr("UI_PLAYER_N") % (split_index + 1) if split_index >= 0 else tr("UI_CHOOSE_CHARACTER")
	if split_index >= 0:
		_title.add_theme_color_override("font_color", RunPlayer.COLORS[split_index])
	else:
		_title.remove_theme_color_override("font_color")
	_chosen = null
	_build_cards()
	_show_weapons(false)
	_show_dangers(false)
	visible = true
	_focus_first_card()


func _focus_first_card() -> void:
	var first := first_card()
	if first != null:
		first.grab_focus()


## First head that can be picked (null if none).
func first_card() -> Button:
	for button: Button in _character_buttons.values():
		if not button.disabled:
			return button
	return null


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


## Remembers whether the player uses a gamepad (see _pad_focus).
func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) >= 0.5):
		_pad_focus = true
	elif event is InputEventKey or event is InputEventMouseButton:
		_pad_focus = false


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		_go_back()
	elif visible and event.is_action_pressed("switch_variant"):
		# The card under the focus changes look (gamepad Y / keyboard V).
		var focused := get_viewport().gui_get_focus_owner()
		for id in _character_buttons:
			if _character_buttons[id] == focused:
				get_viewport().set_input_as_handled()
				_toggle_variant(ContentDB.get_def(&"characters", id) as CharacterData)
				return


func _go_back() -> void:
	if is_ready:
		# Split coop: take the choice back (player 1: back to his seals and Play).
		_set_ready(false)
		unpicked.emit()
		if _dangers.visible:
			_launch.visible = true
			_launch.grab_focus()
		else:
			_focus_weapon()
	elif _dangers.visible:
		_show_dangers(false)
		_focus_weapon()
	elif _weapons.visible:
		_show_weapons(false)
		_character_buttons[_chosen.id].grab_focus()
	else:
		close()


func _focus_weapon() -> void:
	if _weapons.get_child_count() > 0:
		(_weapons.get_child(0) as Button).grab_focus()


## Devices of player `index` (same rule as PlayerInput.assign) for `pads` connected gamepads.
static func devices_hint(index: int, pads: int) -> String:
	if index == 0:
		return TranslationServer.translate("UI_COOP_DEVICES_P1_PAD" if pads >= 2 else "UI_COOP_DEVICES_P1_KEYBOARD")
	if pads == 0:
		return TranslationServer.translate("UI_COOP_NO_PAD")
	return TranslationServer.translate("UI_COOP_DEVICES_P2" if pads >= 2 else "UI_COOP_DEVICES_P2_PAD")


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
		var look := variant_of(character)
		var button := Button.new()
		button.custom_minimum_size = Vector2(_head_size, _head_size)
		button.disabled = not unlocked
		button.tooltip_text = character.name_key_for(look)
		button.add_theme_stylebox_override("normal", UiTheme.card_style(character.color, 0.6 if unlocked else 0.15))
		button.add_theme_stylebox_override("hover", UiTheme.card_style(UiTheme.ACCENT, 1.0))
		button.add_theme_stylebox_override("focus", UiTheme.card_style(UiTheme.ACCENT, 1.0))
		button.add_theme_stylebox_override("pressed", UiTheme.card_style(UiTheme.ACCENT, 1.0))
		button.add_theme_stylebox_override("disabled", UiTheme.card_style(character.color, 0.1))
		button.add_child(_head(character, unlocked, look))
		if not unlocked:
			var lock := Label.new()
			lock.text = LOCK
			lock.set_anchors_preset(Control.PRESET_FULL_RECT)
			lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lock.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lock.add_theme_font_size_override("font_size", 44)
			lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.add_child(lock)
		button.pressed.connect(_choose_character.bind(character))
		# Gamepad: the hero shows as soon as his head is focused (dev's request).
		button.focus_entered.connect(func() -> void:
			if _pad_focus:
				_show_hero(character))
		UiFx.hover_lift(button)
		_cards.add_child(button)
		_character_buttons[character.id] = button
	_show_hero(_chosen)


## Head and shoulders of a hero (his card illustration cropped), as a tile content.
## Locked heroes are shown as a dark silhouette.
func _head(character: CharacterData, unlocked: bool, look: int) -> Control:
	var card_art := character.card_art_for(look)
	if card_art == null:
		var frame := CenterContainer.new()
		frame.set_anchors_preset(Control.PRESET_FULL_RECT)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(SpritePreview.create(character_sheet(character, look), _head_size - 24.0, not unlocked))
		return frame
	var atlas := AtlasTexture.new()
	atlas.atlas = card_art
	var scale := card_art.get_width() / 512.0
	atlas.region = Rect2(HEAD_REGION.position * scale, HEAD_REGION.size * scale)
	var art := TextureRect.new()
	art.texture = atlas
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.offset_left = 8.0
	art.offset_top = 8.0
	art.offset_right = -8.0
	art.offset_bottom = -8.0
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not unlocked:
		art.modulate = SpritePreview.SILHOUETTE
	return art


## Fills the hero panel with `character` (focused head, else the chosen one).
func _show_hero(character: CharacterData) -> void:
	_shown = character
	_hero_plate.visible = character != null
	_look_switch.visible = false
	if character == null:
		_hero_art.texture = null
		return
	var unlocked := SaveService.is_unlocked(&"characters", character)
	var look := variant_of(character)
	_hero_art.texture = character.card_art_for(look)
	_hero_art.modulate = Color.WHITE if unlocked else SpritePreview.SILHOUETTE
	_hero_name.text = character.name_key_for(look)
	_hero_name.add_theme_color_override("font_color", character.color if unlocked else UiTheme.MUTED)
	_hero_rule.text = character.description_key if unlocked else _unlock_hint(character)
	_hero_rule.add_theme_color_override("font_color", UiTheme.TEXT if unlocked else UiTheme.MUTED)
	_look_switch.visible = unlocked and character.has_alt_look()
	# The sign shown is the look it switches to: blue male sign while the female look shows.
	var male_next := look == 0
	_look_switch.text = "♂" if male_next else "♀"
	var sign_color := MALE_COLOR if male_next else FEMALE_COLOR
	_look_switch.add_theme_color_override("font_color", sign_color)
	_look_switch.add_theme_color_override("font_hover_color", sign_color.lightened(0.35))
	for chip in _hero_chips.get_children():
		_hero_chips.remove_child(chip)
		chip.queue_free()
	if unlocked:
		for line in LevelUpScreen.describe_modifiers(character.modifiers).split("\n", false):
			_hero_chips.add_child(_chip(line))
	var stats := stat_preview(character)
	var values := stat_values(character)
	for stat in _hero_bars:
		_hero_bars[stat].value = stats[stat] if unlocked else 0.0
		_hero_values[stat].text = values[stat] if unlocked else ""


## A bonus (green, up arrow) or malus (red, down arrow) as plain colored text.
func _chip(text: String) -> Label:
	var bad := text.begins_with("-")
	var label := Label.new()
	label.text = ("▼ " if bad else "▲ ") + text
	label.add_theme_font_size_override("font_size", 21)
	label.add_theme_color_override("font_color", UiTheme.BAD if bad else UiTheme.GOOD)
	label.add_theme_constant_override("outline_size", 0)
	return label


## Text next to each bar: the class's starting HP and speed, damage and range as percents.
static func stat_values(character: CharacterData) -> Dictionary:
	var block := StatBlock.from_defaults(character.stat_overrides)
	for mod in character.modifiers:
		block.add_modifier(mod)
	return {
		StatIds.MAX_HP: "%d" % roundi(block.get_value(StatIds.MAX_HP)),
		StatIds.DAMAGE: "%d%%" % roundi(block.get_value(StatIds.DAMAGE) * 100.0),
		StatIds.MOVE_SPEED: "%d" % roundi(block.get_value(StatIds.MOVE_SPEED)),
		StatIds.RANGE: "%d%%" % roundi(block.get_value(StatIds.RANGE) * 100.0),
	}


## Bar fill (0..1) of the four stats shown for a class: its base stats and its
## own modifiers (what the player starts with).
static func stat_preview(character: CharacterData) -> Dictionary:
	var block := StatBlock.from_defaults(character.stat_overrides)
	for mod in character.modifiers:
		block.add_modifier(mod)
	return {
		StatIds.MAX_HP: clampf(block.get_value(StatIds.MAX_HP) / BAR_HP, 0.0, 1.0),
		StatIds.DAMAGE: clampf(block.get_value(StatIds.DAMAGE) / BAR_DAMAGE, 0.0, 1.0),
		StatIds.MOVE_SPEED: clampf(block.get_value(StatIds.MOVE_SPEED) / BAR_SPEED, 0.0, 1.0),
		StatIds.RANGE: clampf(block.get_value(StatIds.RANGE) / BAR_RANGE, 0.0, 1.0),
	}


## Card illustration when the character has one, else its animated sprite.
## Locked characters are shown as a dark silhouette.
func _portrait(character: CharacterData, unlocked: bool, look: int = 0) -> Control:
	var card_art := character.card_art_for(look)
	if card_art == null:
		# Same height as an illustration so the names line up across cards.
		var frame := CenterContainer.new()
		frame.custom_minimum_size = Vector2(0.0, PREVIEW_HEIGHT)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(SpritePreview.create(character_sheet(character, look), PREVIEW_HEIGHT, not unlocked))
		return frame
	var art := TextureRect.new()
	art.texture = card_art
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.custom_minimum_size = Vector2(0.0, PREVIEW_HEIGHT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not unlocked:
		art.modulate = SpritePreview.SILHOUETTE
	return art


## Sprite sheet of a character (same path rule as Player), or null.
static func character_sheet(character: CharacterData, look: int = 0) -> SpriteSheet:
	var sprite_id := character.sprite_id_for(look)
	var path := "res://assets/sprites/%s.tres" % sprite_id
	return load(path) as SpriteSheet if sprite_id != &"" and ResourceLoader.exists(path) else null


## Look picked on `character`'s card (0 = the character itself).
func variant_of(character: CharacterData) -> int:
	return _variants.get(character.id, 0) if character.has_alt_look() else 0


func _toggle_variant(character: CharacterData) -> void:
	_variants[character.id] = 1 - variant_of(character)
	Audio.play(Sounds.UI_SELECT, -6.0)
	_build_cards()
	_show_hero(character)
	var focused := get_viewport().gui_get_focus_owner()
	if _character_buttons.has(character.id) and not _character_buttons[character.id].disabled \
			and (focused == null or focused == _look_switch):
		_character_buttons[character.id].grab_focus()


## "Locked: <challenge description>" for the challenge that unlocks `character`.
func _unlock_hint(character: CharacterData) -> String:
	for challenge in SaveService.all_challenges():
		if challenge.unlock_category == &"characters" and challenge.unlock_id == character.id:
			return tr("UI_LOCKED") % tr(challenge.description_key)
	return tr("UI_LOCKED") % "?"


func _choose_character(character: CharacterData) -> void:
	if is_ready:
		# Split coop: another hero takes the previous choice back.
		_set_ready(false)
		unpicked.emit()
	_chosen = character
	_show_hero(character)
	# Feedback: the hunter's first weapon rings out.
	if not character.starting_weapons.is_empty() and character.starting_weapons[0].fire_sound != null:
		Audio.play(character.starting_weapons[0].fire_sound, -4.0)
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
		# Fixed icon size: with expand_icon a long name squeezed the icon to nothing.
		button.add_theme_constant_override("icon_max_width", 64)
		# Name right after the icon (centered, a short name left a wide gap: playtest).
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(260, 64) if _compact else Vector2(300, 72)
		button.add_theme_color_override("font_color", Tiers.color(1))
		button.pressed.connect(_choose_weapon.bind(weapon))
		button.focus_entered.connect(func() -> void:
			if _shown != _chosen:
				_show_hero(_chosen))
		_weapons.add_child(button)
	_show_weapons(true)
	if _weapons.get_child_count() > 0:
		(_weapons.get_child(0) as Button).grab_focus()


func _show_weapons(on: bool) -> void:
	_weapons.visible = on
	_weapon_title.visible = on


func _choose_weapon(weapon: WeaponData) -> void:
	_weapon = weapon
	if weapon.fire_sound != null:
		Audio.play(weapon.fire_sound, weapon.fire_volume_db)
	if split_index == 1:
		# Split coop, player 2: done (player 1 picks the seal).
		_set_ready(true)
		picked.emit()
		return
	_show_seal_row()


## Split coop, player 1's half: player 2's character (null: not picked yet). The seal
## row shown keeps its locks; CoopCharacterSelect lowers the seal at launch if needed.
func set_partner(partner: CharacterData) -> void:
	_partner = partner


func _set_ready(on: bool) -> void:
	is_ready = on
	_ready_label.visible = on
	_ready_label.text = "UI_COOP_WAIT_P2" if split_index == 0 else "UI_COOP_READY"


## Seal picked by player 1 (split coop).
func chosen_difficulty() -> DifficultyData:
	return _difficulty


## Character, weapon and look picked in this half (split coop).
func chosen_character() -> CharacterData:
	return _chosen


func chosen_weapon() -> WeaponData:
	return _weapon


func chosen_variant() -> int:
	return variant_of(_chosen) if _chosen != null else 0


func _show_seal_row() -> void:
	for child in _dangers.get_children():
		_dangers.remove_child(child)
		child.queue_free()
	var allowed := SaveService.profile.max_difficulty(_chosen.id)
	if _partner != null:
		allowed = mini(allowed, SaveService.profile.max_difficulty(_partner.id))
	var levels: Array[DifficultyData] = []
	levels.assign(ContentDB.get_all(&"difficulties"))
	levels.sort_custom(func(a: DifficultyData, b: DifficultyData) -> bool: return a.level < b.level)
	for difficulty in levels:
		var button := _seal_button(difficulty, difficulty.level <= allowed)
		button.pressed.connect(_select_seal.bind(difficulty))
		var info := _seal_info_text(difficulty, levels, difficulty.level <= allowed)
		button.focus_entered.connect(_show_seal_info.bind(info))
		button.mouse_entered.connect(_show_seal_info.bind(info))
		_dangers.add_child(button)
	_show_dangers(true)
	# The hardest seal the player may take is selected; "Play" starts the run.
	var last := mini(allowed, _dangers.get_child_count() - 1)
	if last >= 0:
		_select_seal(levels[last], false)
		(_dangers.get_child(last) as Button).grab_focus()
		_show_seal_info(_seal_info_text(levels[last], levels, true))


## Seal button: big roman numeral and skulls in the seal's heat color, metal-colored
## name. Locked seals are greyed out with a padlock.
func _seal_button(difficulty: DifficultyData, unlocked: bool) -> Button:
	var heat := seal_heat(difficulty.level)
	var button := Button.new()
	button.custom_minimum_size = _seal_size
	button.disabled = not unlocked
	button.add_theme_stylebox_override("normal", UiTheme.card_style(heat, 0.6))
	button.add_theme_stylebox_override("hover", UiTheme.card_style(heat, 1.0))
	button.add_theme_stylebox_override("pressed", UiTheme.card_style(heat, 1.0))
	button.add_theme_stylebox_override("disabled", UiTheme.card_style(UiTheme.MUTED, 0.1))
	button.add_theme_stylebox_override("focus", UiTheme.card_focus_style())
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 0)
	button.add_child(box)
	var numeral := _seal_label(ROMAN[difficulty.level], 34 if _compact else 44, heat if unlocked else UiTheme.MUTED)
	numeral.add_theme_font_override("font", UiTheme.BANGERS)
	box.add_child(numeral)
	# Locked: a padlock instead of the skulls. Copper (0 skulls) keeps an empty line.
	var marks := LOCK if not unlocked else SKULL.repeat(difficulty.level)
	box.add_child(_seal_label(marks if marks != "" else " ", 18, heat if unlocked else UiTheme.MUTED))
	# The seal's rewards: silhouettes until won, in color once unlocked (the name
	# of the seal is in the info line under the row).
	var rewards := HBoxContainer.new()
	rewards.alignment = BoxContainer.ALIGNMENT_CENTER
	rewards.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rewards.add_theme_constant_override("separation", 6)
	for target in seal_rewards(difficulty.level):
		var icon := TextureRect.new()
		icon.texture = target.get(&"icon")
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(REWARD_ICON, REWARD_ICON)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var category: StringName = &"weapons" if target is WeaponData else &"items"
		if not SaveService.is_unlocked(category, target):
			icon.material = _silhouette_material()
		rewards.add_child(icon)
	box.add_child(rewards)
	return button


## Weapon and items unlocked by winning seal `level` (WIN_SEAL challenges).
static func seal_rewards(level: int) -> Array[Resource]:
	var list: Array[Resource] = []
	for challenge in SaveService.all_challenges():
		if challenge.kind == ChallengeData.Kind.WIN_SEAL and challenge.threshold == level:
			var target := ContentDB.get_def(challenge.unlock_category, challenge.unlock_id)
			if target != null:
				list.append(target)
	return list


static var _silhouette: ShaderMaterial


## Flat shape of an icon (a mystery reward): its alpha, one muted color.
static func _silhouette_material() -> ShaderMaterial:
	if _silhouette == null:
		var shader := Shader.new()
		shader.code = "shader_type canvas_item;
uniform vec4 tint : source_color = vec4(0.32, 0.27, 0.45, 0.9);
void fragment() { COLOR = vec4(tint.rgb, texture(TEXTURE, UV).a * tint.a); }"
		_silhouette = ShaderMaterial.new()
		_silhouette.shader = shader
	return _silhouette


func _seal_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


## Seal color that "heats up" from sea green (Copper) to blood red (Astral).
static func seal_heat(level: int) -> Color:
	return SEAL_HEAT[clampi(level, 0, SEAL_HEAT.size() - 1)]


## "<seal> · <place>" then, on a second line, its effects (a seal stacks the ones below it).
## A seal sharing a lower seal's place has no place of its own yet.
func _seal_info_text(difficulty: DifficultyData, levels: Array[DifficultyData], unlocked: bool) -> String:
	var place := tr("BIOME_DUNGEON") if difficulty.biome == null else tr(difficulty.biome.name_key)
	for other in levels:
		if other.level < difficulty.level and other.biome == difficulty.biome:
			place = tr("SEAL_PLACE_COMING")
			break
	var effects: Array[String] = []
	if difficulty.steady_elite_chance > 0.0:
		effects.append(tr("SEAL_FX_ELITES") % roundi(difficulty.steady_elite_chance * 100.0))
	if difficulty.hp_multiplier > 1.0:
		effects.append(tr("SEAL_FX_HP_DAMAGE") % roundi((difficulty.hp_multiplier - 1.0) * 100.0))
	if difficulty.spawn_rate_multiplier > 1.0 or difficulty.group_size_bonus > 0:
		effects.append(tr("SEAL_FX_SPAWN") % roundi((difficulty.spawn_rate_multiplier - 1.0) * 100.0))
	if difficulty.double_final_boss:
		effects.append(tr("SEAL_FX_DOUBLE_BOSS"))
	if effects.is_empty():
		effects.append(tr("SEAL_FX_NONE"))
	# Line 1: seal, place, reward still to win (and how to unlock it); line 2: its effects.
	var text := "%s · %s" % [tr(difficulty.name_key), place]
	if not unlocked:
		text += " — " + tr("SEAL_LOCKED_HINT")
	return text + "
" + " · ".join(effects)


## "Reward: <weapon> + N items" still locked behind winning seal `level`, or "".
func seal_reward_text(level: int) -> String:
	var first := ""
	var others := 0
	for challenge in SaveService.all_challenges():
		if challenge.kind != ChallengeData.Kind.WIN_SEAL or challenge.threshold != level:
			continue
		var target := ContentDB.get_def(challenge.unlock_category, challenge.unlock_id)
		if target == null or SaveService.is_unlocked(challenge.unlock_category, target):
			continue
		if first == "" and challenge.unlock_category == &"weapons":
			first = tr(target.get(&"name_key"))
		else:
			others += 1
	if first == "" and others == 0:
		return ""
	if first == "":
		return tr("SEAL_REWARD") % (tr("SEAL_REWARD_MORE") % ["", others]).trim_prefix(" + ")
	return tr("SEAL_REWARD") % (tr("SEAL_REWARD_MORE") % [first, others] if others > 0 else first)


func _show_seal_info(text: String) -> void:
	var lines := text.split("
", true, 1)
	_seal_info.text = lines[0]
	_seal_effects.text = lines[1] if lines.size() > 1 else ""


## Marks `difficulty` as the seal to play (bright frame) and moves the focus to "Play".
func _select_seal(difficulty: DifficultyData, focus_launch: bool = true) -> void:
	_difficulty = difficulty
	for i in _dangers.get_child_count():
		var button := _dangers.get_child(i) as Button
		var chosen := i == difficulty.level
		var style := UiTheme.card_style(seal_heat(i), 1.0 if chosen else 0.6)
		if chosen:
			style.border_color = Color.WHITE
			style.set_border_width_all(6)
		button.add_theme_stylebox_override("normal", style)
	if focus_launch:
		Audio.play(Sounds.UI_SELECT, -6.0)
		if _launch.visible:
			_launch.grab_focus()


func _show_dangers(on: bool) -> void:
	_launch.visible = on
	_dangers.visible = on
	_danger_title.visible = on
	_seal_info.visible = on
	_seal_effects.visible = on
	if on:
		_ready_label.visible = is_ready
		# Over the title: the cards and the seals row stay visible.
		HintBanner.show_once(self, &"seals", HintBanner.TOP_CENTER, Vector2(0.0, 4.0), 1500.0)


func _start() -> void:
	if _difficulty == null:
		return
	if split_index == 0:
		# Split coop: player 1 is done too; CoopCharacterSelect starts once both are.
		Audio.play(Sounds.UI_SELECT, -6.0)
		_launch.visible = false
		_set_ready(true)
		(_dangers.get_child(_difficulty.level) as Button).grab_focus()
		picked.emit()
		return
	Audio.play(Sounds.PORTAL_OPEN, -4.0)
	var setup := RunSetup.new()
	setup.difficulty = _difficulty
	setup.character = _chosen
	setup.weapon = _weapon
	setup.variant = variant_of(_chosen)
	started.emit(setup)
