class_name CharacterSelect
extends Control
## Character and starting weapon choice before a run (ADR 0015). Locked
## characters are shown greyed out with the challenge that unlocks them.
## Layout chosen by the dev (mockup C, 2026-10-08), three columns, nothing numbered:
## PERSONNAGES (list with the class names) -> the hero on a stone platform, his looks
## on a turntable (left / right turn it) -> ARMES. A moves to the next column, B back.
## The seal is chosen on its own screen once the weapon is validated (SealSelect,
## dev's choice 2026-10-08: more room for the hero).
## Local coop (ADR 0017): CoopCharacterSelect shows one compact copy per half of the
## screen (`split_index`): the heads, then a column with the hero and the weapons under
## him. Both players pick at once; once both are ready the shared seal screen opens.
## Emits `started(setup)`; the main menu asks SceneRouter to start the run.

signal started(setup: RunSetup)
signal closed
## Split coop: this half's character and weapon are chosen (`unpicked`: taken back).
signal picked
signal unpicked

## Steps (the lit column).
enum Step { LIST, LOOK, WEAPON }

## Head and shoulders of a card illustration (512x768): the square shown in a head tile.
const HEAD_REGION := Rect2(72.0, 8.0, 368.0, 368.0)
const PREVIEW_HEIGHT := 170.0
const LIST_WIDTH := 420.0
const COMPACT_LIST_WIDTH := 200.0
const ROW_HEIGHT := 96.0
## Half screen: a head with the name under it (dev's pick, coop mockup A).
const COMPACT_ROW_HEIGHT := 124.0
## The hero is shown big (dev: room for the looks and future skins).
const STAGE_SIZE := Vector2(760, 600)
const COMPACT_STAGE_SIZE := Vector2(0, 540)
const ARMS_WIDTH := 560.0
## Width the rule and bonus text wrap to in a half screen.
const COMPACT_RULE_WIDTH := 440.0
## Stone platform; PLATFORM_TOP is the middle of its top surface (fractions of the image).
const PLATFORM := preload("res://assets/ui/select/platform_stone.png")
const PLATFORM_TOP := Vector2(0.52, 0.37)
## Platform width for a hero height (the hero's art is mostly empty on the sides).
const PLATFORM_PER_HERO := 0.78
## The look behind on the turntable: smaller, higher, darker (dev: "more behind than beside").
const BACK_SCALE := 0.72
const BACK_TINT := Color(0.3, 0.26, 0.45, 0.9)
const LOCK := "🔒"
## Bar fill = stat / these values (a full bar is a strong class, not a maximum).
const BAR_HP := 150.0
const BAR_DAMAGE := 1.5
const BAR_SPEED := 400.0
const BAR_RANGE := 1.6
## Fill color of each stat bar.
const STAT_COLORS: Dictionary[StringName, Color] = {
	StatIds.MAX_HP: Color("ff6673"), StatIds.DAMAGE: Color("ffb347"),
	StatIds.MOVE_SPEED: Color("66f2ff"), StatIds.RANGE: Color("b86bff")}

## Where the feet are in a card illustration (fractions of its size), measured once.
static var _feet_cache: Dictionary = {}

## One row per class (name and head), by id.
var _character_buttons: Dictionary[StringName, Button] = {}
var _row_heads: Dictionary[StringName, TextureRect] = {}
var _rows: VBoxContainer
var _list_panel: PanelContainer
var _stage_panel: PanelContainer
var _arms_panel: PanelContainer
## Turntable: platform, the other look behind, the shown look in front.
var _stage: Control
var _platform: TextureRect
var _back_art: TextureRect
var _hero_art: TextureRect
var _shadow: ContactShadow
## Covers the stage: holds the focus at the look step (left / right turn, A validates).
var _turn: Button
var _arrow_left: Button
var _arrow_right: Button
var _dots: HBoxContainer
var _hero_name: Label
var _hero_rule: Label
var _hero_chips: HFlowContainer
var _hero_bars: Dictionary[StringName, ProgressBar] = {}
var _hero_values: Dictionary[StringName, Label] = {}
var _hero_deltas: Dictionary[StringName, Label] = {}
var _hero_plate: VBoxContainer
## Hero shown in the middle column: the focused row (gamepad), else the chosen one.
var _shown: CharacterData
var _weapons: VBoxContainer
var _weapon_title: Label
var _weapon: WeaponData
## Shown once a weapon is picked: validates it (dev's request: two steps, not one press).
var _next: Button
## Solo: the seal screen opened once the weapon is validated.
var _seals: SealSelect
## Everything but the seal screen: hidden while it is open, so the gamepad focus cannot
## wander onto the hidden weapons behind it (playtest: right stopped at Obsidian).
var _page: Control
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
var _compact: bool = false
var _step: Step = Step.LIST
## Last key / gamepad event came from a gamepad: focusing a row picks that hero
## (with the keyboard or the mouse, only a click does).
var _pad_focus: bool = false
## Look picked for each class (0 = the character itself, 1 = its second look).
var _variants: Dictionary[StringName, int] = {}


## Soft dark ellipse under the feet, on the platform.
class ContactShadow extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_set_transform(size * 0.5, 0.0, Vector2(1.0, size.y / maxf(size.x, 1.0)))
		draw_circle(Vector2.ZERO, size.x * 0.5, Color(0.02, 0.01, 0.06, 0.45))


func _init(p_compact: bool = false) -> void:
	_compact = p_compact
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.get_theme()
	visible = false
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.08, 0.05, 0.17, 1.0)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var margin := MarginContainer.new()
	_page = margin
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 20 if _compact else 40)
	margin.add_theme_constant_override("margin_top", 18 if _compact else 26)
	margin.add_theme_constant_override("margin_bottom", 20 if _compact else 90)
	add_child(margin)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 12)
	margin.add_child(page)
	# Top bar: back pill, title (the co-op devices next to it).
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
	_title.add_theme_font_size_override("font_size", 44 if _compact else 60)
	top.add_child(_title)
	_devices = Label.new()
	_devices.theme_type_variation = &"SmallLabel"
	_devices.size_flags_vertical = Control.SIZE_SHRINK_END
	top.add_child(_devices)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 20 if _compact else 30)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(body)
	body.add_child(_build_list_column())
	body.add_child(_build_stage_column())
	# Half screen: the weapons go under the hero, in the same column.
	var arms := _build_arms()
	if _compact:
		(_stage_panel.get_child(0) as VBoxContainer).add_child(arms)
	else:
		_arms_panel = _column(true)
		_arms_panel.custom_minimum_size.x = ARMS_WIDTH
		_arms_panel.add_child(arms)
		body.add_child(_arms_panel)
	if not _compact:
		add_child(ButtonHints.create([[&"A", "UI_HINT_CHOOSE"], [&"B", "UI_HINT_BACK"], [&"Y", "UI_HINT_SWITCH_LOOK"]]))
		_seals = SealSelect.new()
		_seals.chosen.connect(_start)
		_seals.back.connect(_on_seals_back)
		add_child(_seals)


func _column(expand: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.column_style(false))
	if expand:
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return panel


func _section_label(key: String, size: int = 28) -> Label:
	var label := Label.new()
	label.text = key
	label.theme_type_variation = &"SubtitleLabel"
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", UiTheme.MUTED)
	return label


func _column_title(key: String) -> Label:
	var label := Label.new()
	label.text = key
	label.theme_type_variation = &"TitleLabel"
	label.add_theme_font_size_override("font_size", 30 if _compact else 36)
	return label


## PERSONNAGES: one row per class, head and name.
func _build_list_column() -> Control:
	_list_panel = _column(false)
	_list_panel.custom_minimum_size.x = COMPACT_LIST_WIDTH if _compact else LIST_WIDTH
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_list_panel.add_child(box)
	box.add_child(_column_title("UI_SELECT_CHARACTERS"))
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 10 if _compact else 12)
	box.add_child(_rows)
	return _list_panel


## Middle column: the turntable on its platform, then name, rule, bonuses, stats.
## Half screen: the weapons are added under it (see _init).
func _build_stage_column() -> Control:
	_stage_panel = _column(true)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6 if _compact else 10)
	_stage_panel.add_child(box)
	var stage_row := HBoxContainer.new()
	stage_row.add_theme_constant_override("separation", 12)
	box.add_child(stage_row)
	_stage = Control.new()
	_stage.custom_minimum_size = COMPACT_STAGE_SIZE if _compact else STAGE_SIZE
	_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stage.clip_contents = true
	_stage.resized.connect(_layout_stage)
	stage_row.add_child(_stage)
	_platform = _art_rect(PLATFORM)
	_stage.add_child(_platform)
	_back_art = _art_rect(null)
	_back_art.modulate = BACK_TINT
	_stage.add_child(_back_art)
	_shadow = ContactShadow.new()
	_stage.add_child(_shadow)
	_hero_art = _art_rect(null)
	_stage.add_child(_hero_art)
	_turn = Button.new()
	_turn.flat = true
	_turn.set_anchors_preset(Control.PRESET_FULL_RECT)
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "disabled"]:
		_turn.add_theme_stylebox_override(state, empty)
	_turn.add_theme_stylebox_override("focus", UiTheme.focus_style(UiTheme.ACCENT, 22))
	_turn.pressed.connect(_confirm_look)
	_turn.gui_input.connect(_on_turn_input)
	_stage.add_child(_turn)
	_arrow_left = _arrow("❮", -1)
	_arrow_right = _arrow("❯", 1)
	_stage.add_child(_arrow_left)
	_stage.add_child(_arrow_right)
	_dots = HBoxContainer.new()
	_dots.add_theme_constant_override("separation", 10)
	_dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_dots)
	# Name and stats under the stage (half screen too: the stage gets the full width).
	_hero_plate = VBoxContainer.new()
	box.add_child(_hero_plate)
	_hero_plate.add_theme_constant_override("separation", 6 if _compact else 8)
	_hero_name = Label.new()
	_hero_name.theme_type_variation = &"TitleLabel"
	_hero_name.add_theme_font_size_override("font_size", 28 if _compact else 54)
	_hero_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hero_plate.add_child(_hero_name)
	_hero_rule = Label.new()
	_hero_rule.add_theme_font_size_override("font_size", 16 if _compact else 20)
	_hero_rule.add_theme_color_override("font_color", UiTheme.MUTED)
	_hero_rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# The class rule (passive) is shown in coop too (playtest: the berserker's was not).
	_hero_rule.custom_minimum_size = Vector2(COMPACT_RULE_WIDTH if _compact else STAGE_SIZE.x - 40.0, 0.0)
	_hero_plate.add_child(_hero_rule)
	# Bonuses (green) and maluses (red) as plain text.
	_hero_chips = HFlowContainer.new()
	_hero_chips.add_theme_constant_override("h_separation", 14 if _compact else 26)
	_hero_chips.add_theme_constant_override("v_separation", 2)
	_hero_chips.custom_minimum_size = Vector2(COMPACT_RULE_WIDTH if _compact else STAGE_SIZE.x - 40.0, 0.0)
	_hero_plate.add_child(_hero_chips)
	# Stats: name, bar (scaled on the roster: a full bar = the best class), the value and
	# its difference with the base hero (+30 / -15).
	var grid := GridContainer.new()
	grid.columns = 6 if _compact else 3
	grid.add_theme_constant_override("h_separation", 10 if _compact else 14)
	grid.add_theme_constant_override("v_separation", 4 if _compact else 8)
	_hero_plate.add_child(grid)
	for entry in [[StatIds.MAX_HP, "STAT_MAX_HP", "STAT_SHORT_MAX_HP"], [StatIds.DAMAGE, "STAT_DAMAGE", "STAT_SHORT_DAMAGE"],
			[StatIds.MOVE_SPEED, "STAT_MOVE_SPEED", "STAT_SHORT_MOVE_SPEED"], [StatIds.RANGE, "STAT_RANGE", "STAT_SHORT_RANGE"]]:
		var stat: StringName = entry[0]
		var name_label := Label.new()
		name_label.text = entry[2] if _compact else entry[1]
		name_label.add_theme_font_size_override("font_size", 15 if _compact else 20)
		name_label.add_theme_color_override("font_color", UiTheme.MUTED)
		name_label.add_theme_constant_override("outline_size", 0)
		name_label.custom_minimum_size.x = 0.0 if _compact else 230.0
		grid.add_child(name_label)
		var bar := ProgressBar.new()
		bar.max_value = 1.0
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(56 if _compact else 260, 12)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var styles := UiTheme.flat_bar_styles(STAT_COLORS[stat])
		bar.add_theme_stylebox_override("background", styles[0])
		bar.add_theme_stylebox_override("fill", styles[1])
		grid.add_child(bar)
		var numbers := HBoxContainer.new()
		numbers.add_theme_constant_override("separation", 6)
		numbers.custom_minimum_size.x = 96 if _compact else 170
		grid.add_child(numbers)
		var value_label := Label.new()
		value_label.add_theme_font_size_override("font_size", 16 if _compact else 22)
		value_label.add_theme_color_override("font_color", STAT_COLORS[stat])
		value_label.add_theme_constant_override("outline_size", 0)
		numbers.add_child(value_label)
		var delta_label := Label.new()
		delta_label.add_theme_font_size_override("font_size", 13 if _compact else 18)
		delta_label.add_theme_constant_override("outline_size", 0)
		numbers.add_child(delta_label)
		_hero_bars[stat] = bar
		_hero_values[stat] = value_label
		_hero_deltas[stat] = delta_label
	return _stage_panel


func _art_rect(texture: Texture2D) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


## Turntable arrow: a glowing chevron, no plate (dev's pick A). Mouse; the gamepad uses
## left / right on the stage.
func _arrow(text: String, direction: int) -> Button:
	var button := Button.new()
	button.text = text
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(56, 72)
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, empty)
	button.add_theme_font_size_override("font_size", 46 if _compact else 60)
	button.add_theme_color_override("font_color", UiTheme.ACCENT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_outline_color", Color(UiTheme.ACCENT, 0.3))
	button.add_theme_constant_override("outline_size", 12)
	button.pressed.connect(func() -> void:
		if _chosen != null:
			_turn_look(direction))
	return button


## ARMES: weapon cards (a press picks one), "Next" once one is picked, then "ready" in
## split coop.
func _build_arms() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8 if _compact else 12)
	_weapon_title = _column_title("UI_SELECT_WEAPONS")
	box.add_child(_weapon_title)
	_weapons = VBoxContainer.new()
	_weapons.add_theme_constant_override("separation", 8 if _compact else 12)
	box.add_child(_weapons)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	_next = Button.new()
	_next.text = "UI_NEXT"
	_next.theme_type_variation = &"CtaButton"
	_next.custom_minimum_size = Vector2(300, 76) if _compact else Vector2(440, 100)
	_next.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_next.visible = false
	_next.pressed.connect(_validate_weapon)
	box.add_child(_next)
	_ready_label = _section_label("UI_COOP_READY")
	_ready_label.add_theme_color_override("font_color", UiTheme.GOOD)
	_ready_label.visible = false
	box.add_child(_ready_label)
	return box


## `p_split_index` >= 0: one half of the split coop pick (CoopCharacterSelect).
func open(p_split_index: int = -1) -> void:
	split_index = p_split_index
	_set_ready(false)
	_devices.visible = split_index >= 0
	_devices.text = devices_hint(split_index, Input.get_connected_joypads().size())
	_begin_pick()
	UiFx.breathe(_hero_art)


## Shows the list; the first class is shown on the platform at once (dev's choice:
## the screen is never empty on arrival).
func _begin_pick() -> void:
	_title.text = tr("UI_PLAYER_N") % (split_index + 1) if split_index >= 0 else tr("UI_CHOOSE_CHARACTER")
	if split_index >= 0:
		_title.add_theme_color_override("font_color", RunPlayer.COLORS[split_index])
	else:
		_title.remove_theme_color_override("font_color")
	_chosen = null
	_build_cards()
	_show_weapons(false)
	if _seals != null:
		_seals.close()
	_page.visible = true
	visible = true
	var first := first_card()
	if first != null:
		_choose_character(_character_of(first), false)
	_set_step(Step.LIST)
	_focus_first_card()


func _focus_first_card() -> void:
	var first := first_card()
	if first != null:
		first.grab_focus()


## First row that can be picked (null if none).
func first_card() -> Button:
	for id in _character_buttons:
		if not _character_buttons[id].disabled:
			return _character_buttons[id]
	return null


func _character_of(button: Button) -> CharacterData:
	for id in _character_buttons:
		if _character_buttons[id] == button:
			return ContentDB.get_def(&"characters", id) as CharacterData
	return null


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


## Lights the column of `step`.
func _set_step(step: Step) -> void:
	_step = step
	_apply_focus_modes()
	# No big frame around the active column (dev: it only said "we change screen"): the
	# focus frame of the control being used is enough.
	_arrow_left.modulate = Color.WHITE if step == Step.LOOK else Color(1, 1, 1, 0.55)
	_arrow_right.modulate = _arrow_left.modulate


## Only the controls of the current step can take the focus: the arrows never move it to
## another column, a validation press changes the step (dev's request).
func _apply_focus_modes() -> void:
	var list_mode := Control.FOCUS_ALL if _step == Step.LIST else Control.FOCUS_NONE
	for button in _character_buttons.values():
		button.focus_mode = list_mode
	_turn.focus_mode = Control.FOCUS_ALL if _step == Step.LOOK else Control.FOCUS_NONE
	# Split coop, ready: nothing to focus until the choice is taken back (B).
	var weapon_mode := Control.FOCUS_ALL if _step == Step.WEAPON and not is_ready else Control.FOCUS_NONE
	for child in _weapons.get_children():
		(child as Control).focus_mode = weapon_mode
	_next.focus_mode = weapon_mode


## Remembers whether the player uses a gamepad (see _pad_focus).
func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) >= 0.5):
		_pad_focus = true
	elif event is InputEventKey or event is InputEventMouseButton:
		_pad_focus = false


func _unhandled_input(event: InputEvent) -> void:
	if _seals != null and _seals.visible:
		return
	if visible and (event.is_action_pressed("cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		_go_back()
	elif visible and event.is_action_pressed("switch_variant") and _chosen != null:
		# Gamepad Y / keyboard V turns the turntable from the list or the platform.
		var focused := get_viewport().gui_get_focus_owner()
		if focused == _turn or _character_buttons.values().has(focused):
			get_viewport().set_input_as_handled()
			_turn_look(1)


## Left / right on the platform turn it; the focus stays on it.
func _on_turn_input(event: InputEvent) -> void:
	if _chosen == null:
		return
	if event.is_action_pressed("ui_left", true):
		_turn.accept_event()
		_turn_look(-1)
	elif event.is_action_pressed("ui_right", true):
		_turn.accept_event()
		_turn_look(1)


func _go_back() -> void:
	if is_ready:
		# Split coop: take the choice back, the weapons can be chosen again.
		_set_ready(false)
		unpicked.emit()
		_apply_focus_modes()
		_next.grab_focus()
	elif _step == Step.WEAPON and get_viewport().gui_get_focus_owner() == _next:
		# B on "Next": back on the picked weapon.
		_focus_weapon()
	elif _step == Step.WEAPON:
		_pick_weapon(null)
		_set_step(Step.LOOK)
		_turn.grab_focus()
	elif _step == Step.LOOK:
		_set_step(Step.LIST)
		if _chosen != null:
			_character_buttons[_chosen.id].grab_focus()
	else:
		close()


## Focuses the picked weapon's card, else the first one.
func _focus_weapon() -> void:
	for child in _weapons.get_children():
		if child.get_meta(&"weapon") == _weapon:
			(child as Button).grab_focus()
			return
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
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	_character_buttons.clear()
	_row_heads.clear()
	var characters: Array[CharacterData] = []
	characters.assign(ContentDB.get_all(&"characters"))
	# Starting characters first, then the ones to unlock (stable by id).
	characters.sort_custom(func(a: CharacterData, b: CharacterData) -> bool:
		return a.locked != b.locked and not a.locked or a.locked == b.locked and String(a.id) < String(b.id))
	for character in characters:
		var button := _row(character)
		_rows.add_child(button)
		_character_buttons[character.id] = button
	_apply_focus_modes()
	_show_hero(_chosen)


## Row of the list: head and class name (a long name on two lines).
func _row(character: CharacterData) -> Button:
	var unlocked := SaveService.is_unlocked(&"characters", character)
	var look := variant_of(character)
	var height := COMPACT_ROW_HEIGHT if _compact else ROW_HEIGHT
	var button := Button.new()
	button.custom_minimum_size = Vector2(0.0, height)
	button.disabled = not unlocked
	button.add_theme_stylebox_override("normal", UiTheme.card_style(character.color, 0.5 if unlocked else 0.12))
	button.add_theme_stylebox_override("hover", UiTheme.card_style(UiTheme.ACCENT, 1.0))
	button.add_theme_stylebox_override("pressed", UiTheme.card_style(UiTheme.ACCENT, 1.0))
	button.add_theme_stylebox_override("disabled", UiTheme.card_style(character.color, 0.1))
	button.add_theme_stylebox_override("focus", UiTheme.card_focus_style())
	var line: BoxContainer = VBoxContainer.new() if _compact else HBoxContainer.new()
	line.set_anchors_preset(Control.PRESET_FULL_RECT)
	line.offset_left = 8.0
	line.offset_right = -8.0
	line.offset_top = 4.0 if _compact else 0.0
	line.add_theme_constant_override("separation", 0 if _compact else 14)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(line)
	# Half screen: the head on top, the name under it (coop mockup A).
	var head := _head(character, unlocked, look, 86.0 if _compact else height - 16.0)
	head.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	line.add_child(head)
	_row_heads[character.id] = head as TextureRect if head is TextureRect else null
	var name_label := Label.new()
	name_label.text = character.name_key_for(look) if unlocked else LOCK + " ???"
	name_label.add_theme_font_size_override("font_size", 17 if _compact else 28)
	name_label.add_theme_color_override("font_color", UiTheme.TEXT if unlocked else UiTheme.MUTED)
	# Two lines at most, never a cut inside a word.
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	name_label.max_lines_visible = 2
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.size_flags_vertical = Control.SIZE_FILL
	if _compact:
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.max_lines_visible = 1
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(name_label)
	if not unlocked:
		button.tooltip_text = _unlock_hint(character)
	button.pressed.connect(_choose_character.bind(character))
	# Gamepad: moving onto a row shows that hero at once (art, stats and starting
	# weapons), the focus stays on the list (dev's request).
	button.focus_entered.connect(func() -> void:
		if not _pad_focus:
			return
		if unlocked and character != _chosen:
			_choose_character(character, false)
		elif not unlocked:
			_show_hero(character))
	UiFx.hover_lift(button)
	return button


## Head and shoulders of a hero (his card illustration cropped), `side` px square.
## Locked heroes are shown as a dark silhouette.
func _head(character: CharacterData, unlocked: bool, look: int, side: float) -> Control:
	var card_art := character.card_art_for(look)
	if card_art == null:
		var frame := CenterContainer.new()
		frame.custom_minimum_size = Vector2(side, side)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(SpritePreview.create(character_sheet(character, look), side - 8.0, not unlocked))
		return frame
	var art := TextureRect.new()
	art.texture = _head_texture(card_art)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.custom_minimum_size = Vector2(side, side)
	art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not unlocked:
		art.modulate = SpritePreview.SILHOUETTE
	return art


static func _head_texture(card_art: Texture2D) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = card_art
	var scale := card_art.get_width() / 512.0
	atlas.region = Rect2(HEAD_REGION.position * scale, HEAD_REGION.size * scale)
	return atlas


## Fills the middle column with `character` (focused row, else the chosen one).
func _show_hero(character: CharacterData) -> void:
	_shown = character
	_hero_plate.visible = character != null
	if character == null:
		_hero_art.texture = null
		_back_art.texture = null
		_layout_stage()
		return
	var unlocked := SaveService.is_unlocked(&"characters", character)
	var look := variant_of(character)
	_hero_art.texture = character.card_art_for(look)
	_hero_art.modulate = Color.WHITE if unlocked else SpritePreview.SILHOUETTE
	var looks := look_count(character) if unlocked else 1
	_back_art.texture = character.card_art_for((look + 1) % looks) if looks > 1 else null
	_arrow_left.visible = looks > 1
	_arrow_right.visible = looks > 1
	for dot in _dots.get_children():
		_dots.remove_child(dot)
		dot.queue_free()
	if looks > 1:
		for i in looks:
			var dot := Label.new()
			dot.text = "●" if i == look else "○"
			dot.add_theme_font_size_override("font_size", 18)
			dot.add_theme_color_override("font_color", UiTheme.ACCENT if i == look else UiTheme.MUTED)
			_dots.add_child(dot)
	_hero_name.text = character.name_key_for(look)
	_hero_name.add_theme_color_override("font_color", character.color if unlocked else UiTheme.MUTED)
	_hero_rule.text = character.description_key if unlocked else _unlock_hint(character)
	_hero_rule.add_theme_color_override("font_color", UiTheme.TEXT if unlocked else UiTheme.MUTED)
	for chip in _hero_chips.get_children():
		_hero_chips.remove_child(chip)
		chip.queue_free()
	if unlocked:
		for line in LevelUpScreen.describe_modifiers(character.modifiers).split("\n", false):
			_hero_chips.add_child(_chip(line))
	var stats := stat_preview(character)
	var values := stat_values(character)
	var deltas := stat_deltas(character)
	for stat in _hero_bars:
		_hero_bars[stat].value = stats[stat] if unlocked else 0.0
		_hero_values[stat].text = values[stat] if unlocked else ""
		var delta: String = deltas[stat][0]
		_hero_deltas[stat].text = delta if unlocked else ""
		_hero_deltas[stat].add_theme_color_override("font_color", UiTheme.GOOD if deltas[stat][1] > 0.0 else UiTheme.BAD)
	_layout_stage()


## Places the platform, the two looks and the arrows: the feet of the front look stand
## in the middle of the platform's top surface; the other look stands behind, higher
## and smaller.
func _layout_stage() -> void:
	var area := _stage.size
	if area.x <= 0.0:
		return
	# The hero fills the height above his feet; the platform is sized on him (a bit
	# wider than the broadest hero, the male berserker), the dots under it.
	var dots_room := 26.0
	var ratio := PLATFORM.get_height() / float(PLATFORM.get_width())
	var below := (1.0 - PLATFORM_TOP.y) * ratio * PLATFORM_PER_HERO
	var hero_h := (area.y - dots_room - 6.0) / (1.0 + below)
	var platform_w := minf(hero_h * PLATFORM_PER_HERO, area.x * 0.8)
	var platform_h := platform_w * ratio
	var feet := Vector2(area.x * 0.5, area.y - dots_room - platform_h * (1.0 - PLATFORM_TOP.y))
	hero_h = feet.y - 6.0
	_platform.position = feet - Vector2(platform_w * PLATFORM_TOP.x, platform_h * PLATFORM_TOP.y)
	_platform.size = Vector2(platform_w, platform_h)
	_place_on_feet(_hero_art, feet, hero_h)
	# Behind: up toward the back of the platform, off to the right of the hero's
	# shoulder, so it reads as the next look waiting its turn.
	_place_on_feet(_back_art, feet + Vector2(platform_w * 0.27, -platform_h * 0.24), hero_h * BACK_SCALE)
	_shadow.size = Vector2(platform_w * 0.34, platform_h * 0.14)
	_shadow.position = feet - _shadow.size * 0.5
	var arrow_y := feet.y - hero_h * 0.5
	_arrow_left.position = Vector2(area.x * 0.5 - platform_w * 0.62 - 28.0, arrow_y - 36.0)
	_arrow_right.position = Vector2(area.x * 0.5 + platform_w * 0.62 - 28.0, arrow_y - 36.0)
	_dots.position = Vector2(area.x * 0.5 - _dots.size.x * 0.5, area.y - dots_room)


## Sizes `rect` to `height` (its texture's aspect) with the art's feet on `feet`.
func _place_on_feet(rect: TextureRect, feet: Vector2, height: float) -> void:
	if rect.texture == null:
		rect.size = Vector2.ZERO
		return
	var width := height * rect.texture.get_width() / float(rect.texture.get_height())
	var anchor := feet_anchor(rect.texture)
	rect.size = Vector2(width, height)
	rect.position = feet - Vector2(width * anchor.x, height * anchor.y)


## Where the hero stands in a card illustration, as fractions of its size: the middle
## between his two feet (not one foot: in a three-quarter view the front foot is lower).
## The feet are the two widest groups of columns reaching the bottom band of the
## figure; the anchor is between their centers, at the mean of their lowest points.
## Measured once per texture (the art is not always centered).
static func feet_anchor(texture: Texture2D) -> Vector2:
	if _feet_cache.has(texture):
		return _feet_cache[texture]
	var anchor := Vector2(0.5, 0.97)
	var image := texture.get_image()
	if image != null:
		if image.is_compressed():
			image.decompress()
		anchor = _feet_of(image)
	_feet_cache[texture] = anchor
	return anchor


## The two feet of `image` as [Vector2 left, Vector2 right] in pixels (one twice if only one
## is found), then their middle as fractions: see feet_anchor.
static func feet_points(image: Image) -> Array[Vector2]:
	var w := image.get_width()
	var h := image.get_height()
	var bottom := -1
	for y in range(h - 1, -1, -1):
		for x in range(0, w, 2):
			if image.get_pixel(x, y).a > 0.6:
				bottom = y
				break
		if bottom >= 0:
			break
	var result: Array[Vector2] = [Vector2(w * 0.5, h), Vector2(w * 0.5, h)]
	if bottom < 0:
		return result
	# Lowest opaque pixel of each column within the bottom band of the figure.
	var band_top := maxi(bottom - roundi(h * 0.16), 0)
	var lowest := PackedInt32Array()
	lowest.resize(w)
	for x in w:
		lowest[x] = -1
		for y in range(bottom, band_top - 1, -1):
			if image.get_pixel(x, y).a > 0.6:
				lowest[x] = y
				break
	# Groups of neighbouring columns = feet (and bits of cloth); keep the two widest.
	var groups: Array[Vector3i] = []  # start x, end x, lowest y
	var start := -1
	var low := 0
	for x in w + 1:
		var on := x < w and lowest[x] >= 0
		if on and start < 0:
			start = x
			low = lowest[x]
		elif on:
			low = maxi(low, lowest[x])
		elif start >= 0:
			groups.append(Vector3i(start, x - 1, low))
			start = -1
	groups.sort_custom(func(a: Vector3i, b: Vector3i) -> bool: return a.y - a.x > b.y - b.x)
	if groups.is_empty():
		result[0] = Vector2(w * 0.5, bottom)
		result[1] = result[0]
		return result
	var first := groups[0]
	var second := groups[1] if groups.size() > 1 and groups[1].y - groups[1].x > (first.y - first.x) * 0.3 else first
	var a := Vector2((first.x + first.y) * 0.5, first.z)
	var b := Vector2((second.x + second.y) * 0.5, second.z)
	result[0] = a if a.x <= b.x else b
	result[1] = b if a.x <= b.x else a
	return result


static func _feet_of(image: Image) -> Vector2:
	var feet := feet_points(image)
	var middle := (feet[0] + feet[1]) * 0.5
	return Vector2(middle.x / image.get_width(), middle.y / image.get_height())


## A bonus (green, up arrow) or malus (red, down arrow) as plain colored text.
func _chip(text: String) -> Label:
	var bad := text.begins_with("-")
	var label := Label.new()
	label.text = ("▼ " if bad else "▲ ") + text
	label.add_theme_font_size_override("font_size", 16 if _compact else 20)
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


const SHOWN_STATS: Array[StringName] = [StatIds.MAX_HP, StatIds.DAMAGE, StatIds.MOVE_SPEED, StatIds.RANGE]


## The four stats shown for a class, as raw numbers (base stats and own modifiers).
static func stat_numbers(character: CharacterData) -> Dictionary:
	var block := StatBlock.from_defaults(character.stat_overrides)
	for mod in character.modifiers:
		block.add_modifier(mod)
	var result := {}
	for stat: StringName in SHOWN_STATS:
		result[stat] = block.get_value(stat)
	return result


## Bar fill (0..1) of the four stats of a class, scaled on the whole roster so the
## bars tell the classes apart: the best class has a full bar, the weakest 25 %.
static func stat_preview(character: CharacterData) -> Dictionary:
	var mine := stat_numbers(character)
	var low := {}
	var high := {}
	for other: CharacterData in ContentDB.get_all(&"characters"):
		var numbers := stat_numbers(other)
		for stat: StringName in SHOWN_STATS:
			low[stat] = minf(low.get(stat, INF), numbers[stat])
			high[stat] = maxf(high.get(stat, -INF), numbers[stat])
	var result := {}
	for stat: StringName in SHOWN_STATS:
		var span: float = high[stat] - low[stat]
		result[stat] = 1.0 if span <= 0.0001 else lerpf(0.25, 1.0, (mine[stat] - low[stat]) / span)
	return result


## Difference with the base hero (the stat defaults) for each shown stat:
## [text such as "(+30)" or "(-15%)", signed amount]; an empty text when equal.
static func stat_deltas(character: CharacterData) -> Dictionary:
	var mine := stat_numbers(character)
	var result := {}
	for stat: StringName in SHOWN_STATS:
		var amount: float = mine[stat] - float(StatIds.DEFAULTS[stat])
		var as_percent := stat == StatIds.DAMAGE or stat == StatIds.RANGE
		var shown := roundi(amount * 100.0) if as_percent else roundi(amount)
		var text := ""
		if shown != 0:
			text = "(%s%d%s)" % ["+" if shown > 0 else "", shown, "%" if as_percent else ""]
		result[stat] = [text, amount]
	return result


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


## Look picked for `character` (0 = the character itself).
func variant_of(character: CharacterData) -> int:
	return _variants.get(character.id, 0) if character.has_alt_look() else 0


## Looks on the turntable: the character and its second look (skins later).
static func look_count(character: CharacterData) -> int:
	return 2 if character.has_alt_look() else 1


## Turns the turntable of the chosen class by `direction` looks.
func _turn_look(direction: int) -> void:
	var looks := look_count(_chosen)
	if looks <= 1:
		return
	_variants[_chosen.id] = posmod(variant_of(_chosen) + direction, looks)
	Audio.play(Sounds.UI_SWOOSH, -4.0)
	var head := _row_heads.get(_chosen.id) as TextureRect
	var art := _chosen.card_art_for(variant_of(_chosen))
	if head != null and art != null:
		head.texture = _head_texture(art)
	var label := (_character_buttons[_chosen.id].get_child(0).get_child(1)) as Label
	label.text = _chosen.name_key_for(variant_of(_chosen))
	_show_hero(_chosen)
	if not UiFx.reduce_motion:
		_hero_art.modulate.a = 0.0
		create_tween().tween_property(_hero_art, "modulate:a", 1.0, 0.18)


## Kept for the Y shortcut and the tests: the other look of `character`.
func _toggle_variant(character: CharacterData) -> void:
	if character != _chosen:
		_choose_character(character, false)
	_turn_look(1)


## The look is chosen: on to the weapons.
func _confirm_look() -> void:
	if _chosen == null:
		return
	Audio.play(Sounds.UI_SELECT, -6.0)
	_set_step(Step.WEAPON)
	_focus_weapon()


## "Locked: <challenge description>" for the challenge that unlocks `character`.
func _unlock_hint(character: CharacterData) -> String:
	for challenge in SaveService.all_challenges():
		if challenge.unlock_category == &"characters" and challenge.unlock_id == character.id:
			return tr("UI_LOCKED") % tr(challenge.description_key)
	return tr("UI_LOCKED") % "?"


## `confirm`: the player pressed the row (sound, on to the look); false when a gamepad
## only moved onto it, or for the first class shown on arrival.
func _choose_character(character: CharacterData, confirm: bool = true) -> void:
	if is_ready:
		# Split coop: another hero takes the previous choice back.
		_set_ready(false)
		unpicked.emit()
	_chosen = character
	_show_hero(character)
	# Feedback: the hunter's first weapon rings out.
	if confirm and not character.starting_weapons.is_empty() and character.starting_weapons[0].fire_sound != null:
		Audio.play(character.starting_weapons[0].fire_sound, -4.0)
	# The previous character's weapon belongs to him: forget it.
	_weapon = null
	_next.visible = false
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
		_weapons.add_child(_weapon_card(weapon))
	_apply_focus_modes()
	_show_weapons(true)
	if confirm:
		_set_step(Step.LOOK)
		_turn.grab_focus()


## Weapon card: icon, name, one-line description.
func _weapon_card(weapon: WeaponData) -> Button:
	var height := 80.0 if _compact else 104.0
	var button := Button.new()
	button.custom_minimum_size = Vector2(0.0, height)
	button.add_theme_stylebox_override("normal", UiTheme.card_style(Tiers.color(1), 0.4))
	button.add_theme_stylebox_override("hover", UiTheme.card_style(UiTheme.ACCENT, 1.0))
	button.add_theme_stylebox_override("pressed", UiTheme.card_style(UiTheme.ACCENT, 1.0))
	button.add_theme_stylebox_override("focus", UiTheme.card_focus_style())
	var line := HBoxContainer.new()
	line.set_anchors_preset(Control.PRESET_FULL_RECT)
	line.offset_left = 12.0
	line.offset_right = -12.0
	line.add_theme_constant_override("separation", 14)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(line)
	var icon := TextureRect.new()
	icon.texture = weapon.icon
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(height - 20.0, height - 20.0)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(icon)
	var texts := VBoxContainer.new()
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_theme_constant_override("separation", 2)
	line.add_child(texts)
	var name_label := Label.new()
	name_label.text = weapon.name_key
	name_label.add_theme_font_size_override("font_size", 22 if _compact else 26)
	name_label.add_theme_color_override("font_color", Tiers.color(1))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_child(name_label)
	if not _compact:
		var description := Label.new()
		description.text = weapon.description_key
		description.add_theme_font_size_override("font_size", 17)
		description.add_theme_color_override("font_color", UiTheme.MUTED)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.max_lines_visible = 2
		description.mouse_filter = Control.MOUSE_FILTER_IGNORE
		texts.add_child(description)
	else:
		button.tooltip_text = weapon.description_key
	button.set_meta(&"weapon", weapon)
	button.pressed.connect(_choose_weapon.bind(weapon))
	button.focus_entered.connect(func() -> void:
		if _step != Step.WEAPON:
			_set_step(Step.WEAPON)
		if _shown != _chosen:
			_show_hero(_chosen))
	return button


func _show_weapons(on: bool) -> void:
	_weapons.visible = on
	_weapon_title.visible = on or not _compact


## A weapon card is pressed: it is the picked one, "Next" shows and takes the focus.
func _choose_weapon(weapon: WeaponData) -> void:
	_set_step(Step.WEAPON)
	if weapon.fire_sound != null:
		Audio.play(weapon.fire_sound, weapon.fire_volume_db)
	_pick_weapon(weapon)
	_next.grab_focus()


## Marks `weapon` as picked (its card lit; null: none) and shows "Next" with it.
func _pick_weapon(weapon: WeaponData) -> void:
	_weapon = weapon
	_next.visible = weapon != null
	for child in _weapons.get_children():
		var picked_card: bool = weapon != null and child.get_meta(&"weapon") == weapon
		(child as Button).add_theme_stylebox_override("normal",
			UiTheme.card_style(UiTheme.ACCENT if picked_card else Tiers.color(1), 1.0 if picked_card else 0.4))


## "Next": the weapon is validated. Split coop, this player is ready (the shared seal
## screen opens once both are); solo, the seal screen opens.
func _validate_weapon() -> void:
	if _weapon == null:
		return
	Audio.play(Sounds.UI_SELECT, -6.0)
	if split_index >= 0:
		_set_ready(true)
		_apply_focus_modes()
		picked.emit()
		return
	_page.visible = false
	_seals.open([_chosen] as Array[CharacterData])


## Back from the seal screen: the weapons can be chosen again.
func _on_seals_back() -> void:
	_page.visible = true
	_set_step(Step.WEAPON)
	_next.grab_focus()


## Split coop: back from the shared seal screen (CoopCharacterSelect), weapons again.
func unready() -> void:
	if is_ready:
		_go_back()


func _set_ready(on: bool) -> void:
	is_ready = on
	_ready_label.visible = on


## Character, weapon and look picked in this half (split coop).
func chosen_character() -> CharacterData:
	return _chosen


func chosen_weapon() -> WeaponData:
	return _weapon


func chosen_variant() -> int:
	return variant_of(_chosen) if _chosen != null else 0


## Solo: the seal is chosen, the run starts.
func _start(difficulty: DifficultyData) -> void:
	Audio.play(Sounds.PORTAL_OPEN, -4.0)
	var setup := RunSetup.new()
	setup.difficulty = difficulty
	setup.character = _chosen
	setup.weapon = _weapon
	setup.variant = variant_of(_chosen)
	started.emit(setup)
