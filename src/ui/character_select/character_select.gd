class_name CharacterSelect
extends Control
## Character and starting weapon choice before a run (ADR 0015). Locked
## characters are shown greyed out with the challenge that unlocks them.
## Local coop (ADR 0017): player 1 then player 2 pick a character and a weapon,
## then the Danger (the lower one both characters have unlocked).
## Emits `started(setup)`; the main menu asks SceneRouter to start the run.

signal started(setup: RunSetup)
signal closed

## Seven characters must fit a 1920 px row.
const CARD_SIZE := Vector2(250, 460)
const PREVIEW_HEIGHT := 170.0
## Height of a card illustration (CharacterData.card_art, 2:3 portrait).
const ART_HEIGHT := 176.0
## Six seals must fit a 1920 px row.
const SEAL_SIZE := Vector2(200, 116)
const ROMAN: Array[String] = ["I", "II", "III", "IV", "V", "VI"]
const SKULL := "☠"
const LOCK := "🔒"
const REWARD_ICON := 30.0
## Copper -> Astral: sea green, lime, yellow, orange, red, blood red.
const SEAL_HEAT: Array[Color] = [Color("4de0b8"), Color("a6e34d"), Color("ffd84d"),
		Color("ff9a3d"), Color("ff4a3d"), Color("c8102e")]

var _character_buttons: Dictionary[StringName, Button] = {}
var _cards: HBoxContainer
var _weapons: HBoxContainer
var _weapon_title: Label
var _dangers: HBoxContainer
var _danger_title: Label
var _seal_info: Label
var _seal_effects: Label
var _weapon: WeaponData
var _back: Button
var _chosen: CharacterData
var _title: Label
## Which gamepad drives which player (coop only).
var _devices: Label
## True for a local coop pick (two players).
var coop: bool = false
## Coop: 0 while player 1 picks, 1 for player 2.
var _picking: int = 0
## Coop: player 1's choice, kept while player 2 picks.
var _first_character: CharacterData
var _first_weapon: WeaponData


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
	box.add_theme_constant_override("separation", 10)
	center.add_child(box)
	var title := Label.new()
	title.text = "UI_CHOOSE_CHARACTER"
	title.theme_type_variation = &"TitleLabel"
	# A bit smaller than other titles: cards, weapons and seals share the screen.
	title.add_theme_font_size_override("font_size", 66)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_title = title
	_devices = Label.new()
	_devices.theme_type_variation = &"SmallLabel"
	_devices.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_devices)
	_cards = HBoxContainer.new()
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards.add_theme_constant_override("separation", 14)
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
	# Effects and place of the hovered / focused seal.
	_seal_info = Label.new()
	_seal_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_seal_info.add_theme_font_size_override("font_size", 18)
	# Two reserved lines as wide as the seal row: a long text wraps inside them
	# instead of widening the screen and shifting the layout (dev's playtest).
	_seal_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_seal_info.custom_minimum_size = Vector2(SEAL_SIZE.x * 6 + 12 * 5, 26)
	_seal_info.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(_seal_info)
	# Second line: the seal's numbers, smaller and muted (details for the curious).
	_seal_effects = Label.new()
	_seal_effects.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_seal_effects.add_theme_font_size_override("font_size", 15)
	_seal_effects.add_theme_color_override("font_color", UiTheme.MUTED)
	_seal_effects.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(_seal_effects)
	_back = Button.new()
	_back.text = "UI_BACK"
	_back.custom_minimum_size = Vector2(260, 64)
	_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_back.pressed.connect(_go_back)
	box.add_child(_back)


func open(p_coop: bool = false) -> void:
	coop = p_coop
	_picking = 0
	_first_character = null
	_first_weapon = null
	_devices.visible = coop
	_devices.text = _devices_hint()
	_begin_pick()


## Shows the cards for the player who picks now.
func _begin_pick() -> void:
	_title.text = tr("UI_COOP_PICK") % (_picking + 1) if coop else tr("UI_CHOOSE_CHARACTER")
	if coop:
		_title.add_theme_color_override("font_color", RunPlayer.COLORS[_picking])
	else:
		_title.remove_theme_color_override("font_color")
	_build_cards()
	_show_weapons(false)
	_show_dangers(false)
	visible = true
	_focus_first_card()


func _focus_first_card() -> void:
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
	elif coop and _picking == 1:
		# Back to player 1's weapon choice.
		_picking = 0
		_begin_pick()
		_choose_character(_first_character)
	else:
		close()


func _devices_hint() -> String:
	var pads := Input.get_connected_joypads().size()
	if pads >= 2:
		return tr("UI_COOP_PADS")
	return tr("UI_COOP_ONE_PAD") if pads == 1 else tr("UI_COOP_NO_PAD")


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
		text.add_theme_constant_override("separation", 6)
		button.add_child(text)
		text.add_child(_portrait(character, unlocked))
		var name_label := Label.new()
		name_label.text = character.name_key
		name_label.theme_type_variation = &"SubtitleLabel"
		name_label.add_theme_color_override("font_color", character.color if unlocked else UiTheme.MUTED)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		# Long names and bonus lines wrap: otherwise they widen the text box past
		# the card and push the description off center (dev's playtest).
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.add_theme_font_size_override("font_size", 26)
		text.add_child(name_label)
		var rule := Label.new()
		rule.text = character.description_key if unlocked else _unlock_hint(character)
		rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rule.add_theme_font_size_override("font_size", 16)
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
			mods.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			text.add_child(mods)
		button.pressed.connect(_choose_character.bind(character))
		UiFx.hover_lift(button)
		_cards.add_child(button)
		_character_buttons[character.id] = button


## Card illustration when the character has one, else its animated sprite.
## Locked characters are shown as a dark silhouette.
func _portrait(character: CharacterData, unlocked: bool) -> Control:
	if character.card_art == null:
		# Same height as an illustration so the names line up across cards.
		var frame := CenterContainer.new()
		frame.custom_minimum_size = Vector2(0.0, ART_HEIGHT)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(SpritePreview.create(character_sheet(character), PREVIEW_HEIGHT, not unlocked))
		return frame
	var art := TextureRect.new()
	art.texture = character.card_art
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.custom_minimum_size = Vector2(0.0, ART_HEIGHT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not unlocked:
		art.modulate = SpritePreview.SILHOUETTE
	return art


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
		button.custom_minimum_size = Vector2(300, 72)
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
	if weapon.fire_sound != null:
		Audio.play(weapon.fire_sound, weapon.fire_volume_db)
	if coop and _picking == 0:
		# Player 1 is done: player 2's turn.
		_first_character = _chosen
		_first_weapon = weapon
		_picking = 1
		_show_weapons(false)
		_begin_pick()
		_focus_first_card()
		return
	for child in _dangers.get_children():
		_dangers.remove_child(child)
		child.queue_free()
	var allowed := SaveService.profile.max_difficulty(_chosen.id)
	if coop:
		allowed = mini(allowed, SaveService.profile.max_difficulty(_first_character.id))
	var levels: Array[DifficultyData] = []
	levels.assign(ContentDB.get_all(&"difficulties"))
	levels.sort_custom(func(a: DifficultyData, b: DifficultyData) -> bool: return a.level < b.level)
	for difficulty in levels:
		var button := _seal_button(difficulty, difficulty.level <= allowed)
		button.pressed.connect(_start.bind(difficulty))
		var info := _seal_info_text(difficulty, levels, difficulty.level <= allowed)
		button.focus_entered.connect(_show_seal_info.bind(info))
		button.mouse_entered.connect(_show_seal_info.bind(info))
		_dangers.add_child(button)
	_show_dangers(true)
	var last := mini(allowed, _dangers.get_child_count() - 1)
	if last >= 0:
		(_dangers.get_child(last) as Button).grab_focus()
		_show_seal_info(_seal_info_text(levels[last], levels, true))


## Seal button: big roman numeral and skulls in the seal's heat color, metal-colored
## name. Locked seals are greyed out with a padlock.
func _seal_button(difficulty: DifficultyData, unlocked: bool) -> Button:
	var heat := seal_heat(difficulty.level)
	var button := Button.new()
	button.custom_minimum_size = SEAL_SIZE
	button.disabled = not unlocked
	button.add_theme_stylebox_override("normal", UiTheme.card_style(heat, 0.6))
	button.add_theme_stylebox_override("hover", UiTheme.card_style(heat, 1.0))
	button.add_theme_stylebox_override("pressed", UiTheme.card_style(heat, 1.0))
	button.add_theme_stylebox_override("disabled", UiTheme.card_style(UiTheme.MUTED, 0.1))
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 0)
	button.add_child(box)
	var numeral := _seal_label(ROMAN[difficulty.level], 44, heat if unlocked else UiTheme.MUTED)
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


func _show_dangers(on: bool) -> void:
	_dangers.visible = on
	_danger_title.visible = on
	_seal_info.visible = on
	_seal_effects.visible = on
	if on:
		# Over the title: the cards and the seals row stay visible.
		HintBanner.show_once(self, &"seals", HintBanner.TOP_CENTER, Vector2(0.0, 4.0), 1500.0)


func _start(difficulty: DifficultyData) -> void:
	Audio.play(Sounds.PORTAL_OPEN, -4.0)
	var setup := RunSetup.new()
	setup.difficulty = difficulty
	if coop:
		setup.character = _first_character
		setup.weapon = _first_weapon
		setup.character_2 = _chosen
		setup.weapon_2 = _weapon
	else:
		setup.character = _chosen
		setup.weapon = _weapon
	started.emit(setup)
