class_name CoopCharacterSelect
extends Control
## Local coop pick (ADR 0017), one shared screen like the solo one (dev's request, 2026-10-09,
## replaces the split halves of ADR 0022): the hall picture with two floor seals, hunter 1 on the
## cyan seal at the left and hunter 2 on the amber one at the right, each hero standing on his
## seal. A single bar at the bottom lists the classes; each player moves his own cursor on it
## (his color on the head). A press validates the class, then his weapon; once a hunter is ready
## his seal lights up. Both ready: the shared seal screen (SealSelect) opens, either player picks
## the danger and the run starts.
## No Godot focus here (it is one per window): the screen reads each player's devices itself
## (PlayerInput.owns_event) and turns them into the actions of `press`.

signal started(setup: RunSetup)
signal closed

## LIST: the cursor on the bar; LOOK: the left / right arrows turn the hero (his looks and skins);
## WEAPON; READY.
enum Step { LIST, LOOK, WEAPON, READY }

const BACKGROUND := SelectBackdrops.HALL
const SEAL_COLORS: Array[StringName] = [&"cyan", &"amber"]
## Center of each seal as a share of the screen, and the seal width (share of the screen width).
const SEAL_X: Array[float] = [0.33, 0.67]
const SEAL_Y := 0.7
const SEAL_WIDTH := 0.30
## Hero height as a share of the screen height (his feet are on the seal's center).
const HERO_HEIGHT := 0.5
## Info plate of a hunter: width (share of the screen width), margin and top (shares).
const PLATE_WIDTH := 0.21
const PLATE_MARGIN := 0.015
const PLATE_TOP := 0.2
## Heads of the class bar at the top of the screen (dev: 50 % bigger than the first bar, 68 px).
const TILE_SIZE := 102.0
const BAR_BOTTOM := 84.0
## The head stays inside the frame of its tile (dev: the hair went over the ornament).
const HEAD_INSET := 13.0
## Look arrows beside a hero: distance from his seal center (share of the screen width), height above
## the feet (share of the screen height); the dots under the seal.
const ARROW_DX := 0.09
const ARROW_DY := 0.2
const DOTS_DY := 0.085
## Stick push that counts as one step of navigation.
const STICK_THRESHOLD := 0.5
const DIRECTIONS: Array[StringName] = [&"ui_left", &"ui_right", &"ui_up", &"ui_down"]
const PRESSES: Array[StringName] = [&"ui_accept", &"cancel", &"pause", &"switch_variant"]

var _inputs: Array[PlayerInput] = []
var _characters: Array[CharacterData] = []
## Per player (index 0 / 1).
var _step: Array[int] = [Step.LIST, Step.LIST]
var _cursor: Array[int] = [0, 0]
var _weapon_index: Array[int] = [0, 0]
var _weapon: Array[WeaponData] = [null, null]
## Look picked for each class, per player (class id -> look, 0 = the character itself).
var _variants: Array[Dictionary] = [{}, {}]
## Left stick direction last turned into a press, per player and axis (-1, 0, 1).
var _stick_state: Dictionary = {}

var _page: Control
var _backdrop: UiBackdrop
## Top right: picks the background (up / down on the bar cycles it too).
var _picker: BackdropPicker
var _heroes: Control
var _glows: Array[SealGlow] = []
var _hero_art: Array[TextureRect] = []
## Invisible buttons over the heroes: a click validates the class, then the look (dev, 2026-10-10).
var _hero_hit: Array[Button] = []
var _plates: Array[PanelContainer] = []
var _tag: Array[Label] = []
var _devices: Array[Label] = []
var _name: Array[Label] = []
var _rule: Array[Label] = []
var _stats: Array[Label] = []
var _chips: Array[HFlowContainer] = []
## Look turntable of each hunter: two chevrons beside the hero and one dot per look under the seal.
var _arrows: Array[Array] = [[], []]
var _dots: Array[HBoxContainer] = []
var _weapon_box: Array[VBoxContainer] = []
var _ready_label: Array[Label] = []
var _bar_row: HBoxContainer
var _bar: PanelContainer
var _tiles: Array[Tile] = []
var _seals: SealSelect


## Head of a class in the bar. Draws the cursor of each hunter over it in his color.
class Tile extends Button:
	## Which hunters' cursors are on this head.
	var markers: Array[bool] = [false, false]
	## Frame color: the class's own (muted while locked).
	var accent: Color = Color.WHITE

	func _init() -> void:
		focus_mode = Control.FOCUS_NONE
		flat = true
		var empty := StyleBoxEmpty.new()
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			add_theme_stylebox_override(state, empty)

	func _draw() -> void:
		# The same card frame as the rows of the solo list, in the class color.
		draw_style_box(SelectBackdrops.ghost(UiTheme.card_style(accent, 0.5, SelectBackdrops.hue)), Rect2(Vector2.ZERO, size))
		var rank := 0
		for i in markers.size():
			if not markers[i]:
				continue
			var inset := 5.0 * rank
			draw_style_box(UiTheme.card_focus_style(RunPlayer.COLORS[i]),
					Rect2(Vector2.ONE * inset, size - Vector2.ONE * inset * 2.0))
			rank += 1


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UiTheme.get_theme()
	visible = false
	var backdrop := UiBackdrop.create(BACKGROUND, 0.35)
	# A little closer than "just covers": the floor was still too wide (dev, 2026-10-09).
	backdrop.base_zoom = 1.06
	backdrop.sparks_enabled = false
	backdrop.animated = false
	_backdrop = backdrop
	add_child(backdrop)
	_page = Control.new()
	_page.set_anchors_preset(Control.PRESET_FULL_RECT)
	_page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_page)
	# Seals and heroes, behind everything else.
	_heroes = Control.new()
	_heroes.set_anchors_preset(Control.PRESET_FULL_RECT)
	_heroes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_heroes.resized.connect(_layout)
	_page.add_child(_heroes)
	for i in 2:
		var glow := SealGlow.new(SEAL_COLORS[i])
		_heroes.add_child(glow)
		_glows.append(glow)
	for i in 2:
		var art := TextureRect.new()
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_SCALE
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_heroes.add_child(art)
		_hero_art.append(art)
	for i in 2:
		var hit := Button.new()
		hit.flat = true
		hit.focus_mode = Control.FOCUS_NONE
		var empty := StyleBoxEmpty.new()
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			hit.add_theme_stylebox_override(state, empty)
		hit.pressed.connect(_press_hero.bind(i))
		_heroes.add_child(hit)
		_hero_hit.append(hit)
	for i in 2:
		_build_look_controls(i)
	for i in 2:
		_page.add_child(_build_plate(i))
	_page.add_child(_build_bar())
	_page.add_child(_build_top())
	_page.add_child(ButtonHints.create([[&"A", "UI_HINT_CHOOSE"], [&"B", "UI_HINT_BACK"], [&"L1 R1", "UI_HINT_SWITCH_LOOK"]]))
	_seals = SealSelect.new()
	_seals.chosen.connect(_start)
	_seals.back.connect(_on_seals_back)
	add_child(_seals)


## Back pill (the class bar takes the middle of the top).
func _build_top() -> Control:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 26)
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	margin.add_child(top)
	var back := Button.new()
	back.text = "UI_BACK"
	back.focus_mode = Control.FOCUS_NONE
	back.custom_minimum_size = Vector2(190, 64)
	back.pressed.connect(close)
	top.add_child(back)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(spacer)
	_picker = BackdropPicker.new()
	_picker.custom_minimum_size = Vector2(340, 52)
	_picker.focus_mode = Control.FOCUS_NONE
	_picker.focusable = false
	_picker.themed = true
	_picker.chosen.connect(_on_backdrop_chosen)
	top.add_child(_picker)
	return margin


## The look turntable of hunter `i`: a chevron on each side of his hero (the mouse; a gamepad uses Y)
## and one dot per look under his seal.
func _build_look_controls(i: int) -> void:
	for direction in [-1, 1]:
		var arrow := Button.new()
		arrow.text = "❮" if direction < 0 else "❯"
		arrow.flat = true
		arrow.focus_mode = Control.FOCUS_NONE
		arrow.custom_minimum_size = Vector2(56, 72)
		var empty := StyleBoxEmpty.new()
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			arrow.add_theme_stylebox_override(state, empty)
		arrow.add_theme_font_size_override("font_size", 52)
		arrow.add_theme_color_override("font_color", RunPlayer.COLORS[i])
		arrow.add_theme_color_override("font_hover_color", Color.WHITE)
		arrow.add_theme_color_override("font_pressed_color", Color.WHITE)
		arrow.add_theme_color_override("font_outline_color", Color(RunPlayer.COLORS[i], 0.3))
		arrow.add_theme_constant_override("outline_size", 12)
		arrow.pressed.connect(func() -> void:
			if _step[i] == Step.LIST or _step[i] == Step.LOOK:
				_turn_look(i, direction))
		_heroes.add_child(arrow)
		_arrows[i].append(arrow)
	var dots := HBoxContainer.new()
	dots.add_theme_constant_override("separation", 10)
	dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_heroes.add_child(dots)
	_dots.append(dots)


## Info plate of hunter `i`: his tag, the class on show, its rule, bonuses, stats, weapons.
func _build_plate(i: int) -> Control:
	var plate := PanelContainer.new()
	# The big frame of the solo columns around the hunter's details and weapons.
	plate.add_theme_stylebox_override("panel", SelectBackdrops.ghost(UiTheme.column_style(false, SelectBackdrops.hue)))
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(column)
	var tag_row := HBoxContainer.new()
	tag_row.add_theme_constant_override("separation", 12)
	tag_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(tag_row)
	var tag := Label.new()
	tag.theme_type_variation = &"SubtitleLabel"
	tag.add_theme_font_size_override("font_size", 26)
	tag.add_theme_color_override("font_color", RunPlayer.COLORS[i])
	tag_row.add_child(tag)
	_tag.append(tag)
	var devices := Label.new()
	devices.theme_type_variation = &"SmallLabel"
	devices.size_flags_vertical = Control.SIZE_SHRINK_END
	tag_row.add_child(devices)
	_devices.append(devices)
	var name_label := Label.new()
	name_label.theme_type_variation = &"TitleLabel"
	name_label.add_theme_font_size_override("font_size", 30)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(name_label)
	_name.append(name_label)
	var rule := Label.new()
	rule.add_theme_font_size_override("font_size", 16)
	rule.add_theme_color_override("font_color", UiTheme.MUTED)
	rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(rule)
	_rule.append(rule)
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 14)
	chips.add_theme_constant_override("v_separation", 2)
	chips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(chips)
	_chips.append(chips)
	var stats := Label.new()
	stats.add_theme_font_size_override("font_size", 15)
	stats.add_theme_color_override("font_color", UiTheme.MUTED)
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(stats)
	_stats.append(stats)
	var weapons_title := Label.new()
	weapons_title.text = "UI_SELECT_WEAPONS"
	weapons_title.theme_type_variation = &"SubtitleLabel"
	weapons_title.add_theme_font_size_override("font_size", 22)
	weapons_title.add_theme_color_override("font_color", UiTheme.MUTED)
	column.add_child(weapons_title)
	var weapons := VBoxContainer.new()
	weapons.add_theme_constant_override("separation", 8)
	weapons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(weapons)
	_weapon_box.append(weapons)
	var ready := Label.new()
	ready.text = "UI_COOP_READY"
	ready.theme_type_variation = &"SubtitleLabel"
	ready.add_theme_font_size_override("font_size", 20)
	ready.add_theme_color_override("font_color", UiTheme.GOOD)
	ready.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ready.visible = false
	column.add_child(ready)
	_ready_label.append(ready)
	_plates.append(plate)
	return plate


## The one bar of the classes, at the bottom.
func _build_bar() -> Control:
	var bar := PanelContainer.new()
	_bar = bar
	_style_bar()
	# At the bottom (dev, 2026-10-10): it no longer hides the portals of the pictures. Above the button hints.
	bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bar.offset_bottom = -BAR_BOTTOM
	_bar_row = HBoxContainer.new()
	_bar_row.add_theme_constant_override("separation", 10)
	bar.add_child(_bar_row)
	return bar


## Opens the pick: both hunters on the first class.
func open() -> void:
	_inputs = PlayerInput.assign(2, PlayerInput.connected_pads())
	_stick_state.clear()
	_characters.clear()
	_characters.assign(ContentDB.get_all(&"characters"))
	# Starting characters first, then the ones to unlock (stable by id).
	_characters.sort_custom(func(a: CharacterData, b: CharacterData) -> bool:
		return a.locked != b.locked and not a.locked or a.locked == b.locked and String(a.id) < String(b.id))
	_build_tiles()
	var pads := Input.get_connected_joypads().size()
	for i in 2:
		_step[i] = Step.LIST
		_cursor[i] = 0
		_weapon_index[i] = 0
		_weapon[i] = null
		_variants[i] = {}
		_tag[i].text = tr("UI_PLAYER_N") % (i + 1)
		_devices[i].text = CharacterSelect.devices_hint(i, pads)
		_glows[i].set_lit(false)
	_seals.close()
	_picker.refresh()
	SelectBackdrops.apply(_backdrop, true)
	_restyle(false)
	_page.visible = true
	visible = true
	_layout()
	_refresh_all()


func close() -> void:
	if not visible:
		return
	visible = false
	if _seals.visible:
		_seals.close()
	closed.emit()


func _build_tiles() -> void:
	for child in _bar_row.get_children():
		_bar_row.remove_child(child)
		child.queue_free()
	_tiles.clear()
	for index in _characters.size():
		var character := _characters[index]
		var unlocked := SaveService.is_unlocked(&"characters", character)
		var tile := Tile.new()
		tile.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
		tile.clip_contents = true
		tile.accent = _themed(character.color) if unlocked else UiTheme.MUTED
		tile.add_child(_head(character, unlocked))
		if not unlocked:
			tile.tooltip_text = unlock_hint(character)
		# The mouse is player 1's pointer.
		tile.mouse_entered.connect(_on_tile_hovered.bind(index))
		tile.pressed.connect(_on_tile_pressed.bind(index))
		_bar_row.add_child(tile)
		_tiles.append(tile)


## Head and shoulders of a class (its card cropped), a dark silhouette while locked.
func _head(character: CharacterData, unlocked: bool) -> Control:
	var side := TILE_SIZE - 2.0 * HEAD_INSET
	var card_art := character.card_art_for(0)
	var art: Control
	if card_art == null:
		art = SpritePreview.create(CharacterSelect.character_sheet(character, 0), side, not unlocked)
	else:
		var atlas := AtlasTexture.new()
		atlas.atlas = card_art
		atlas.region = CharacterSelect.head_region(card_art)
		var rect := TextureRect.new()
		rect.texture = atlas
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if not unlocked:
			rect.modulate = SpritePreview.SILHOUETTE
		art = rect
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.offset_left = HEAD_INSET
	art.offset_top = HEAD_INSET
	art.offset_right = -HEAD_INSET
	art.offset_bottom = -HEAD_INSET
	return art


## A class color on the current background: pulled toward the background's accent (the hall keeps it).
static func _themed(color: Color) -> Color:
	if is_zero_approx(SelectBackdrops.hue):
		return color
	return UiTheme.accent_color(SelectBackdrops.hue).lerp(color, 0.3)


## The bar of the classes: the frame of the other panels, in the color of the background.
func _style_bar() -> void:
	var hue := SelectBackdrops.hue
	var style := SelectBackdrops.ghost(UiTheme.panel_style(UiTheme.accent_color(hue), 0.7, 16, hue))
	style.set_content_margin_all(18)
	_bar.add_theme_stylebox_override("panel", style)


## The background changed: the interface takes its color.
func _on_backdrop_chosen() -> void:
	SelectBackdrops.apply(_backdrop, true)
	_restyle(true)


## Frames, cards and buttons take the color of the background (SelectBackdrops.hue).
func _restyle(rebuild: bool) -> void:
	theme = UiTheme.get_theme(SelectBackdrops.hue)
	_style_bar()
	for plate in _plates:
		plate.add_theme_stylebox_override("panel", SelectBackdrops.ghost(UiTheme.column_style(false, SelectBackdrops.hue)))
	if rebuild:
		_build_tiles()
		_refresh_all()


## Seals under the heroes, heroes on the seals, plates at the sides.
func _layout() -> void:
	var area := _heroes.size
	if area.x <= 0.0:
		return
	for i in 2:
		var center := Vector2(area.x * SEAL_X[i], area.y * SEAL_Y)
		_glows[i].place(center, area.x * SEAL_WIDTH)
		_place_hero(i, center, area.y * HERO_HEIGHT)
		_arrows[i][0].position = center - Vector2(area.x * ARROW_DX + 28.0, area.y * ARROW_DY + 36.0)
		_arrows[i][1].position = center + Vector2(area.x * ARROW_DX - 28.0, -area.y * ARROW_DY - 36.0)
		_dots[i].position = center + Vector2(-_dots[i].size.x * 0.5, area.y * DOTS_DY)
		var plate := _plates[i]
		plate.custom_minimum_size.x = area.x * PLATE_WIDTH
		plate.size = Vector2(area.x * PLATE_WIDTH, 0.0)
		var left := area.x * PLATE_MARGIN if i == 0 else area.x * (1.0 - PLATE_MARGIN - PLATE_WIDTH)
		plate.position = Vector2(left, area.y * PLATE_TOP)


## The hero's art, feet on `feet`, `height` tall.
func _place_hero(i: int, feet: Vector2, height: float) -> void:
	var art := _hero_art[i]
	if art.texture == null:
		art.size = Vector2.ZERO
		return
	var width := height * art.texture.get_width() / float(art.texture.get_height())
	var anchor := CharacterSelect.feet_anchor(art.texture)
	art.size = Vector2(width, height)
	art.position = feet - Vector2(width * anchor.x, height * anchor.y)
	_hero_hit[i].position = art.position + Vector2(width * 0.2, 0.0)
	_hero_hit[i].size = Vector2(width * 0.6, height)


# --- input -------------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not visible or _seals.visible or _inputs.is_empty():
		return
	if not (event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion):
		return
	var player := owner_of(event)
	if player < 0:
		return
	if event is InputEventJoypadMotion:
		_on_stick(player, event)
		return
	var action := action_of(event)
	if action == &"":
		return
	get_viewport().set_input_as_handled()
	press(player, action)


## Player number whose devices produced `event`, -1 if none.
func owner_of(event: InputEvent) -> int:
	for i in _inputs.size():
		if _inputs[i].owns_event(event):
			return i
	return -1


## The menu action a press of `event` means (&"" when none). Directions repeat when held.
static func action_of(event: InputEvent) -> StringName:
	for action in DIRECTIONS:
		if event.is_action_pressed(action, true):
			return action
	for action in PRESSES:
		if event.is_action_pressed(action):
			return &"cancel" if action == &"pause" else action
	return &""


## The left stick is turned into one direction press each time it is pushed past
## STICK_THRESHOLD; idle noise does nothing.
func _on_stick(player: int, event: InputEventJoypadMotion) -> void:
	if event.axis != JOY_AXIS_LEFT_X and event.axis != JOY_AXIS_LEFT_Y:
		return
	var key := player * 10 + event.axis
	var direction := 0
	if absf(event.axis_value) >= STICK_THRESHOLD:
		direction = 1 if event.axis_value > 0.0 else -1
	if direction == _stick_state.get(key, 0):
		return
	_stick_state[key] = direction
	if direction == 0:
		return
	if event.axis == JOY_AXIS_LEFT_X:
		press(player, &"ui_right" if direction > 0 else &"ui_left")
	else:
		press(player, &"ui_down" if direction > 0 else &"ui_up")


## One menu action of hunter `player`: ui_left / ui_right / ui_up / ui_down, ui_accept, cancel,
## switch_variant.
func press(player: int, action: StringName) -> void:
	match _step[player]:
		Step.LIST:
			_press_list(player, action)
		Step.LOOK:
			_press_look(player, action)
		Step.WEAPON:
			_press_weapon(player, action)
		_:
			if action == &"cancel":
				_unready(player)


func _press_list(player: int, action: StringName) -> void:
	match action:
		&"ui_left":
			_move_cursor(player, -1)
		&"ui_right":
			_move_cursor(player, 1)
		&"ui_accept":
			_validate_character(player)
		&"switch_variant":
			_turn_look(player, 1)
		&"ui_up", &"ui_down":
			# Nothing else to do up or down on the bar: the background changes.
			_picker.cycle(-1 if action == &"ui_up" else 1)
		&"cancel":
			close()


## Left / right turn the hero on his seal (looks and skins), a press validates the look.
func _press_look(player: int, action: StringName) -> void:
	match action:
		&"ui_left":
			_turn_look(player, -1)
		&"ui_right", &"switch_variant":
			_turn_look(player, 1)
		&"ui_accept":
			_step[player] = Step.WEAPON
			Audio.play(Sounds.UI_SELECT, -6.0)
			_refresh_all()
		&"cancel":
			_step[player] = Step.LIST
			Audio.play(Sounds.UI_CLICK, -8.0)
			_refresh_all()


func _press_weapon(player: int, action: StringName) -> void:
	var count := _weapons_of(_characters[_cursor[player]]).size()
	match action:
		&"ui_up", &"ui_left":
			_move_weapon(player, -1, count)
		&"ui_down", &"ui_right":
			_move_weapon(player, 1, count)
		&"ui_accept":
			_validate_weapon(player)
		&"switch_variant":
			_turn_look(player, 1)
		&"cancel":
			_step[player] = Step.LOOK if _has_looks(player) else Step.LIST
			_weapon[player] = null
			Audio.play(Sounds.UI_CLICK, -8.0)
			_refresh_all()


## True when the class under hunter `player`'s cursor has looks to choose from.
func _has_looks(player: int) -> bool:
	return _characters[_cursor[player]].look_count() > 1


func _move_cursor(player: int, direction: int) -> void:
	var next := clampi(_cursor[player] + direction, 0, _characters.size() - 1)
	if next == _cursor[player]:
		return
	_cursor[player] = next
	_weapon_index[player] = 0
	Audio.play(Sounds.UI_HOVER, -10.0)
	_refresh_all()


func _move_weapon(player: int, direction: int, count: int) -> void:
	var next := clampi(_weapon_index[player] + direction, 0, maxi(count - 1, 0))
	if next == _weapon_index[player]:
		return
	_weapon_index[player] = next
	Audio.play(Sounds.UI_HOVER, -10.0)
	_refresh(player)


## A press on the class under the cursor: on to the weapons (a locked class only complains).
func _validate_character(player: int) -> void:
	var character := _characters[_cursor[player]]
	if not SaveService.is_unlocked(&"characters", character):
		Audio.play(Sounds.UI_ERROR, -8.0)
		return
	# The look comes first (left / right on the hero), then the weapon.
	_step[player] = Step.LOOK if _has_looks(player) else Step.WEAPON
	_weapon_index[player] = 0
	Audio.play(Sounds.UI_SELECT, -6.0)
	var weapons := _weapons_of(character)
	if not weapons.is_empty() and weapons[0].fire_sound != null:
		Audio.play(weapons[0].fire_sound, -4.0)
	_refresh_all()


## A press on the weapon: this hunter is ready, his seal lights up.
func _validate_weapon(player: int) -> void:
	var weapons := _weapons_of(_characters[_cursor[player]])
	if weapons.is_empty():
		return
	var weapon := weapons[clampi(_weapon_index[player], 0, weapons.size() - 1)]
	_weapon[player] = weapon
	_step[player] = Step.READY
	Audio.play(Sounds.UI_SELECT, -6.0)
	if weapon.fire_sound != null:
		Audio.play(weapon.fire_sound, weapon.fire_volume_db)
	_refresh_all()
	if _step[0] == Step.READY and _step[1] == Step.READY:
		_page.visible = false
		_seals.open([chosen_character(0), chosen_character(1)] as Array[CharacterData])


## B on a ready hunter: his weapon can be chosen again.
func _unready(player: int) -> void:
	_step[player] = Step.WEAPON
	_weapon[player] = null
	Audio.play(Sounds.UI_CLICK, -8.0)
	_refresh_all()


## Back from the seals: both hunters are back on their weapons.
func _on_seals_back() -> void:
	_page.visible = true
	for i in 2:
		_step[i] = Step.WEAPON
		_weapon[i] = null
	_refresh_all()


## Turns the look of the class under hunter `player`'s cursor.
func _turn_look(player: int, direction: int) -> void:
	var character := _characters[_cursor[player]]
	var looks := character.look_count()
	if looks <= 1 or not SaveService.is_unlocked(&"characters", character):
		return
	_variants[player][character.id] = posmod(variant_of(player, character) + direction, looks)
	Audio.play(Sounds.UI_SWOOSH, -4.0)
	_refresh(player)


func variant_of(player: int, character: CharacterData) -> int:
	return mini(_variants[player].get(character.id, 0), character.look_count() - 1)


## Mouse (player 1's pointer): over a head, his cursor goes there; a click presses it.
func _on_tile_hovered(index: int) -> void:
	if _step[0] != Step.LIST or _cursor[0] == index:
		return
	_cursor[0] = index
	_weapon_index[0] = 0
	Audio.play(Sounds.UI_HOVER, -10.0)
	_refresh_all()


## A click on a hero: the class under his cursor is locked, then his look is validated, as in solo.
func _press_hero(player: int) -> void:
	match _step[player]:
		Step.LIST:
			_validate_character(player)
		Step.LOOK:
			_press_look(player, &"ui_accept")


func _on_tile_pressed(index: int) -> void:
	if _step[0] != Step.LIST:
		return
	_cursor[0] = index
	_validate_character(0)


# --- display -----------------------------------------------------------------------------

func _refresh_all() -> void:
	for i in 2:
		_refresh(i)
	for index in _tiles.size():
		for i in 2:
			_tiles[index].markers[i] = _cursor[i] == index
		_tiles[index].queue_redraw()


## Hunter `player`'s hero, plate and seal for his cursor and step.
func _refresh(player: int) -> void:
	var character := _characters[_cursor[player]]
	var unlocked := SaveService.is_unlocked(&"characters", character)
	var look := variant_of(player, character)
	var art := _hero_art[player]
	art.texture = character.card_art_for(look)
	art.modulate = Color.WHITE if unlocked else SpritePreview.SILHOUETTE
	_place_hero(player, _heroes.size * Vector2(SEAL_X[player], SEAL_Y), _heroes.size.y * HERO_HEIGHT)
	var looks := character.look_count() if unlocked else 1
	for arrow in _arrows[player]:
		arrow.visible = looks > 1
		arrow.modulate.a = 1.0 if _step[player] == Step.LOOK else 0.5
	for dot in _dots[player].get_children():
		_dots[player].remove_child(dot)
		dot.queue_free()
	if looks > 1:
		for k in looks:
			var dot := Label.new()
			dot.text = "●" if k == look else "○"
			dot.add_theme_font_size_override("font_size", 18)
			dot.add_theme_color_override("font_color", RunPlayer.COLORS[player] if k == look else UiTheme.MUTED)
			_dots[player].add_child(dot)
	_dots[player].reset_size()
	_name[player].text = character.name_key_for(look)
	_name[player].add_theme_color_override("font_color", character.color if unlocked else UiTheme.MUTED)
	_rule[player].text = character.description_key if unlocked else unlock_hint(character)
	_rule[player].add_theme_color_override("font_color", UiTheme.TEXT if unlocked else UiTheme.MUTED)
	for chip in _chips[player].get_children():
		_chips[player].remove_child(chip)
		chip.queue_free()
	_stats[player].text = ""
	if unlocked:
		for line in LevelUpScreen.describe_modifiers(character.modifiers).split("\n", false):
			_chips[player].add_child(_chip(line))
		var values := CharacterSelect.stat_values(character)
		_stats[player].text = "%s %s · %s %s · %s %s · %s %s" % [
			tr("STAT_SHORT_MAX_HP"), values[StatIds.MAX_HP], tr("STAT_SHORT_DAMAGE"), values[StatIds.DAMAGE],
			tr("STAT_SHORT_MOVE_SPEED"), values[StatIds.MOVE_SPEED], tr("STAT_SHORT_RANGE"), values[StatIds.RANGE]]
	_fill_weapons(player, character, unlocked)
	_ready_label[player].visible = _step[player] == Step.READY
	_glows[player].set_lit(_step[player] == Step.READY)


## The weapon cards of the class on show: the one under the cursor is outlined in the hunter's
## color while he chooses, the picked one stays lit.
func _fill_weapons(player: int, character: CharacterData, unlocked: bool) -> void:
	var box := _weapon_box[player]
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()
	if not unlocked:
		return
	var weapons := _weapons_of(character)
	for index in weapons.size():
		var weapon := weapons[index]
		var on_cursor := _step[player] == Step.WEAPON and _weapon_index[player] == index
		var picked := _step[player] == Step.READY and _weapon[player] == weapon
		box.add_child(_weapon_card(player, index, weapon, on_cursor, picked))


func _weapon_card(player: int, index: int, weapon: WeaponData, on_cursor: bool, picked: bool) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0.0, 84.0)
	var color: Color = RunPlayer.COLORS[player]
	var lit := on_cursor or picked
	# The same card frame as the rows of the hunters, in the hunter's color.
	var style := SelectBackdrops.ghost(UiTheme.card_style(color, 1.0 if lit else 0.5, SelectBackdrops.hue))
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, style)
	var line := HBoxContainer.new()
	line.set_anchors_preset(Control.PRESET_FULL_RECT)
	line.offset_left = 10.0
	line.offset_right = -10.0
	line.add_theme_constant_override("separation", 12)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(line)
	var icon := TextureRect.new()
	icon.texture = weapon.icon
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(56, 56)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(icon)
	var texts := VBoxContainer.new()
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override("separation", 0)
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(texts)
	var name_label := Label.new()
	name_label.text = weapon.name_key
	name_label.add_theme_font_size_override("font_size", 21)
	name_label.add_theme_color_override("font_color", Tiers.color(1))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_child(name_label)
	var description := Label.new()
	description.text = weapon.description_key
	description.add_theme_font_size_override("font_size", 14)
	description.add_theme_color_override("font_color", UiTheme.MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.max_lines_visible = 2
	description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_child(description)
	# The mouse acts for the hunter whose weapon it clicks, once he is on his weapons.
	button.pressed.connect(func() -> void:
		if _step[player] == Step.WEAPON:
			_weapon_index[player] = index
			_validate_weapon(player))
	# The mouse over a weapon puts that hunter's cursor on it (dev, 2026-10-10: the hover did not work
	# once the class was locked by a click).
	button.mouse_entered.connect(func() -> void:
		if _step[player] == Step.WEAPON and _weapon_index[player] != index:
			_weapon_index[player] = index
			Audio.play(Sounds.UI_HOVER, -10.0)
			_refresh.call_deferred(player))
	return button


## A bonus (green, up arrow) or malus (red, down arrow) as plain colored text.
func _chip(text: String) -> Label:
	var bad := text.begins_with("-")
	var label := Label.new()
	label.text = ("▼ " if bad else "▲ ") + text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", UiTheme.BAD if bad else UiTheme.GOOD)
	label.add_theme_constant_override("outline_size", 0)
	return label


# --- results -----------------------------------------------------------------------------

## Weapons a hunter of `character` may start with (the unlocked ones).
static func _weapons_of(character: CharacterData) -> Array[WeaponData]:
	var choices: Array[WeaponData] = []
	for weapon in character.starting_weapons:
		if SaveService.is_unlocked(&"weapons", weapon):
			choices.append(weapon)
	if choices.is_empty() and character.starting_weapon != null:
		choices.append(character.starting_weapon)
	return choices


## "Locked: <challenge description>" for the challenge that unlocks `character`.
static func unlock_hint(character: CharacterData) -> String:
	for challenge in SaveService.all_challenges():
		if challenge.unlock_category == &"characters" and challenge.unlock_id == character.id:
			return TranslationServer.translate("UI_LOCKED") % TranslationServer.translate(challenge.description_key)
	return TranslationServer.translate("UI_LOCKED") % "?"


func chosen_character(player: int) -> CharacterData:
	return _characters[_cursor[player]]


func chosen_weapon(player: int) -> WeaponData:
	return _weapon[player]


func chosen_variant(player: int) -> int:
	return variant_of(player, _characters[_cursor[player]])


func step_of(player: int) -> int:
	return _step[player]


func cursor_of(player: int) -> int:
	return _cursor[player]


## Puts hunter `player`'s cursor on class `id` (tests and the capture tool).
func cursor_to(player: int, id: StringName) -> void:
	for index in _characters.size():
		if _characters[index].id == id:
			_cursor[player] = index
			_weapon_index[player] = 0
	_refresh_all()


func seal_glow_of(player: int) -> SealGlow:
	return _glows[player]


## The seal screen (tests and the capture tool).
func seals() -> SealSelect:
	return _seals


func _start(difficulty: DifficultyData) -> void:
	var setup := RunSetup.new()
	setup.character = chosen_character(0)
	setup.weapon = chosen_weapon(0)
	setup.variant = chosen_variant(0)
	setup.character_2 = chosen_character(1)
	setup.weapon_2 = chosen_weapon(1)
	setup.variant_2 = chosen_variant(1)
	setup.difficulty = difficulty
	setup.portal_intro = true
	started.emit(setup)
