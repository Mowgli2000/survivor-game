class_name SealSelect
extends Control
## Seal (danger level) choice, its own screen once every player has picked a hunter
## and a weapon (dev's choice, mockup B, 2026-10-08): the dungeon gate behind, the six
## seals in a row, then the details of the focused one (effects, place, the rewards
## still to win as dark silhouettes) and Play. Solo and coop: one screen for everybody;
## a seal is open when every hunter of the party has won the one below it.
## Moving onto an open seal picks it; pressing it moves to Play, Play starts the run
## (two steps, dev's choice: a seal press never launches by mistake).

## The seal to play was confirmed.
signal chosen(difficulty: DifficultyData)
## Back to the hunters.
signal back

const BACKGROUND := preload("res://assets/ui/select/seal_gate.png")
const ROMAN: Array[String] = ["I", "II", "III", "IV", "V", "VI"]
const SKULL := "☠"
const LOCK := "🔒"
## Seal metals, Copper -> Astral: rim (also the seal's text color) and face.
const SEAL_RIM: Array[Color] = [Color("d9874a"), Color("b8c0cc"), Color("eef2f8"), Color("ffd84d"),
		Color("b86bff"), Color("8fe9ff")]
const SEAL_FACE: Array[Color] = [Color("8a4a24"), Color("5a6270"), Color("9aa4b4"), Color("b8860b"),
		Color("241a3a"), Color("2b5c8a")]
## Where the gate's swirl sits in seal_gate.png (share of width, of height).
const PORTAL_CENTER := Vector2(0.508, 0.39)
const ENTER_SECONDS := 1.15
const ENTER_ZOOM := 9.0
const MEDAL_SIZE := Vector2(200, 200)
const REWARD_BOX := 96.0

static var _silhouette: ShaderMaterial

var _levels: Array[DifficultyData] = []
var _buttons: Array[Button] = []
var _medals: Array[Medal] = []
## Highest seal the party may play.
var _allowed: int = 0
var _difficulty: DifficultyData
var _row: HBoxContainer
var _panel: PanelContainer
var _name: Label
var _effects: Label
var _place: Label
var _rewards_title: Label
var _rewards: HBoxContainer
var _launch: Button
var _background: TextureRect
var _page: Control
var _entering: bool = false


## Round seal: metal rim, face, numeral; glowing rings when picked, dark with a padlock
## when locked. A few circles per frame on one screen: plain draw calls are fine.
class Medal extends Control:
	var level: int = 0
	var locked: bool = false
	var picked: bool = false
	var _label: Label

	func _init(p_level: int) -> void:
		level = p_level
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = MEDAL_SIZE
		_label = Label.new()
		_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_label)

	func refresh() -> void:
		var radius := _radius()
		if locked:
			_label.text = LOCK
			_label.add_theme_font_size_override("font_size", roundi(radius * 0.7))
			_label.remove_theme_font_override("font")
		else:
			_label.text = ROMAN[level]
			_label.add_theme_font_override("font", UiTheme.BANGERS)
			_label.add_theme_font_size_override("font_size", roundi(radius * 0.8))
			_label.add_theme_color_override("font_color", SEAL_RIM[level])
			_label.add_theme_color_override("font_outline_color", UiTheme.OUTLINE)
			_label.add_theme_constant_override("outline_size", 10)
		queue_redraw()

	func _radius() -> float:
		return minf(size.x, size.y) * (0.4 if picked else 0.33) if size.x > 0.0 else MEDAL_SIZE.x * 0.33

	func _draw() -> void:
		var center := size * 0.5
		var radius := _radius()
		if locked:
			draw_circle(center, radius, Color("1a1430"))
			draw_arc(center, radius, 0.0, TAU, 64, UiTheme.OUTLINE, 6.0, true)
			draw_arc(center, radius * 0.82, 0.0, TAU, 64, Color(UiTheme.MUTED, 0.25), 3.0, true)
			return
		var rim := SEAL_RIM[level]
		if picked:
			for k in 3:
				draw_arc(center, radius * (1.16 + k * 0.1), 0.0, TAU, 64, Color(rim, 0.35 - k * 0.1), 8.0, true)
		draw_circle(center, radius, rim)
		draw_arc(center, radius, 0.0, TAU, 64, UiTheme.OUTLINE, 6.0, true)
		draw_circle(center, radius * 0.8, SEAL_FACE[level])
		draw_arc(center, radius * 0.8, 0.0, TAU, 64, UiTheme.OUTLINE, 4.0, true)


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.get_theme()
	visible = false
	# Opaque under the picture: nothing of the screen behind shows through.
	var floor_color := ColorRect.new()
	floor_color.color = Color.BLACK
	floor_color.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(floor_color)
	var background := TextureRect.new()
	_background = background
	background.texture = BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var dim := ColorRect.new()
	dim.color = Color(UiTheme.DIM, 0.4)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_bottom", 90)
	add_child(margin)
	_page = margin
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 18)
	margin.add_child(page)
	var top := HBoxContainer.new()
	page.add_child(top)
	var back_button := Button.new()
	back_button.text = "UI_BACK"
	back_button.custom_minimum_size = Vector2(190, 64)
	back_button.focus_mode = Control.FOCUS_NONE
	back_button.pressed.connect(_go_back)
	top.add_child(back_button)
	var title := Label.new()
	title.text = "UI_CHOOSE_DANGER"
	title.theme_type_variation = &"TitleLabel"
	title.add_theme_font_size_override("font_size", 64)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	# Same width as the back pill: the title stays centered on the screen.
	var balance := Control.new()
	balance.custom_minimum_size = Vector2(190, 0)
	top.add_child(balance)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 110)
	page.add_child(spacer)
	_row = HBoxContainer.new()
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", 30)
	page.add_child(_row)
	page.add_child(_build_panel())
	var push := Control.new()
	push.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(push)
	_launch = Button.new()
	_launch.text = "UI_PLAY"
	_launch.theme_type_variation = &"CtaButton"
	_launch.custom_minimum_size = Vector2(460, 100)
	_launch.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_launch.pressed.connect(_confirm)
	page.add_child(_launch)
	add_child(ButtonHints.create([[&"A", "UI_PLAY"], [&"B", "UI_HINT_BACK"]]))


## Details of the focused seal: name, effects, place; the rewards at right.
func _build_panel() -> Control:
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(1100, 0)
	_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 30)
	_panel.add_child(line)
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override("separation", 8)
	line.add_child(texts)
	_name = Label.new()
	_name.theme_type_variation = &"TitleLabel"
	_name.add_theme_font_size_override("font_size", 52)
	texts.add_child(_name)
	_effects = Label.new()
	_effects.add_theme_font_size_override("font_size", 26)
	_effects.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texts.add_child(_effects)
	_place = Label.new()
	_place.add_theme_font_size_override("font_size", 24)
	_place.add_theme_color_override("font_color", UiTheme.MUTED)
	_place.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texts.add_child(_place)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 8)
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	line.add_child(right)
	_rewards_title = Label.new()
	_rewards_title.add_theme_font_size_override("font_size", 22)
	_rewards_title.add_theme_color_override("font_color", UiTheme.GOLD)
	_rewards_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right.add_child(_rewards_title)
	_rewards = HBoxContainer.new()
	_rewards.add_theme_constant_override("separation", 10)
	right.add_child(_rewards)
	return _panel


## Opens for the party's hunters: a seal is open when every one of them may play it.
func open(hunters: Array[CharacterData]) -> void:
	_allowed = allowed_level(hunters)
	_levels = all_levels()
	for child in _row.get_children():
		_row.remove_child(child)
		child.queue_free()
	_buttons.clear()
	_medals.clear()
	for difficulty in _levels:
		var button := _seal_button(difficulty)
		_row.add_child(button)
		# Down from any seal: Play.
		button.focus_neighbor_bottom = button.get_path_to(_launch)
	visible = true
	# The hardest open seal is picked; the focus is on it.
	var last := mini(_allowed, _buttons.size() - 1)
	if last >= 0:
		_buttons[last].grab_focus()
		_point(last)
	HintBanner.show_once(self, &"seals", HintBanner.TOP_CENTER, Vector2(0.0, 4.0), 1500.0)


func close() -> void:
	visible = false


## Highest seal every hunter of the party has opened.
static func allowed_level(hunters: Array[CharacterData]) -> int:
	var allowed := 999
	for hunter in hunters:
		allowed = mini(allowed, SaveService.profile.max_difficulty(hunter.id))
	return 0 if hunters.is_empty() else allowed


static func all_levels() -> Array[DifficultyData]:
	var levels: Array[DifficultyData] = []
	levels.assign(ContentDB.get_all(&"difficulties"))
	levels.sort_custom(func(a: DifficultyData, b: DifficultyData) -> bool: return a.level < b.level)
	return levels


## The picked seal (null before open).
func chosen_difficulty() -> DifficultyData:
	return _difficulty


## The seal buttons, Copper first (tests).
func seal_buttons() -> Array[Button]:
	return _buttons


func is_open(level: int) -> bool:
	return level <= _allowed


func _seal_button(difficulty: DifficultyData) -> Button:
	var level := difficulty.level
	var button := Button.new()
	button.flat = true
	button.set_meta(&"locked", not is_open(level))
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, empty)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 0)
	button.add_child(box)
	var medal := Medal.new(level)
	medal.locked = not is_open(level)
	medal.resized.connect(medal.refresh)
	box.add_child(medal)
	var label := Label.new()
	label.text = seal_short_name(level) if is_open(level) else "???"
	label.theme_type_variation = &"SubtitleLabel"
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", SEAL_RIM[level] if is_open(level) else UiTheme.MUTED)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(label)
	button.custom_minimum_size = MEDAL_SIZE + Vector2(0, 44)
	button.focus_entered.connect(_point.bind(level))
	button.mouse_entered.connect(button.grab_focus)
	button.pressed.connect(func() -> void:
		if is_open(level):
			Audio.play(Sounds.UI_SELECT, -6.0)
			_launch.grab_focus()
		else:
			Audio.play(Sounds.UI_ERROR, -8.0))
	_buttons.append(button)
	_medals.append(medal)
	return button


## The pointer (focus or mouse) is on seal `level`: shows it; an open seal is picked.
func _point(level: int) -> void:
	if is_open(level):
		if _difficulty == null or _difficulty.level != level:
			Audio.play(Sounds.UI_HOVER, -10.0)
		_difficulty = _levels[level]
		# Up from Play: back on the picked seal.
		_launch.focus_neighbor_top = _launch.get_path_to(_buttons[level])
	for i in _medals.size():
		_medals[i].picked = i == level
		_medals[i].refresh()
	_show_info(_levels[level])


func _show_info(difficulty: DifficultyData) -> void:
	var level := difficulty.level
	var open_seal := is_open(level)
	_panel.add_theme_stylebox_override("panel", UiTheme.card_style(SEAL_RIM[level] if open_seal else UiTheme.MUTED, 0.8))
	_name.text = tr(difficulty.name_key)
	_name.add_theme_color_override("font_color", SEAL_RIM[level] if open_seal else UiTheme.MUTED)
	_effects.text = SKULL + " " + seal_effects(difficulty)
	_place.text = tr("SEAL_PLACE") % seal_place(difficulty, _levels)
	if not open_seal:
		_place.text += "  ·  " + LOCK + " " + tr("SEAL_LOCKED_HINT")
	for child in _rewards.get_children():
		_rewards.remove_child(child)
		child.queue_free()
	var rewards := seal_rewards(level)
	var to_win := 0
	for target in rewards:
		var won := SaveService.is_unlocked(&"weapons" if target is WeaponData else &"items", target)
		if not won:
			to_win += 1
		_rewards.add_child(_reward_box(target.get(&"icon"), won))
	_rewards_title.text = tr("SEAL_TO_WIN") if to_win > 0 else tr("SEAL_WON")
	_rewards_title.visible = not rewards.is_empty()


## One reward: its icon in color once won, a dark silhouette with a "?" until then.
func _reward_box(icon: Texture2D, won: bool) -> Control:
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(REWARD_BOX, REWARD_BOX)
	var style := UiTheme.card_style(UiTheme.GOLD, 0.4 if won else 0.25)
	style.set_content_margin_all(10)
	box.add_theme_stylebox_override("panel", style)
	var art := TextureRect.new()
	art.texture = icon
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not won:
		art.material = silhouette_material()
	box.add_child(art)
	if not won:
		var mark := Label.new()
		mark.text = "?"
		mark.theme_type_variation = &"TitleLabel"
		mark.add_theme_font_size_override("font_size", 36)
		mark.add_theme_color_override("font_color", UiTheme.GOLD)
		mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		box.add_child(mark)
	return box


func _confirm() -> void:
	if _difficulty == null or not visible or _entering:
		return
	if DisplayServer.get_name() == "headless":
		chosen.emit(_difficulty)
		return
	_enter_portal()


## Only the gate moves: the picture zooms and turns into the swirl while the menu
## fades, then the run starts with a violet screen (PortalArrival) that clears.
func _enter_portal() -> void:
	_entering = true
	Audio.play(Sounds.PORTAL_OPEN, -4.0)
	# Scale around the swirl: where it lies on screen once the picture is "covered".
	var cover := maxf(size.x / BACKGROUND.get_width(), size.y / BACKGROUND.get_height())
	var drawn := Vector2(BACKGROUND.get_size()) * cover
	_background.pivot_offset = (size - drawn) * 0.5 + drawn * PORTAL_CENTER
	var flash := ColorRect.new()
	flash.color = PortalArrival.COLOR
	flash.modulate.a = 0.0
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_page, "modulate:a", 0.0, ENTER_SECONDS * 0.3)
	tween.tween_property(_background, "scale", Vector2.ONE * ENTER_ZOOM, ENTER_SECONDS) 		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(_background, "rotation", 0.35, ENTER_SECONDS) 		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(flash, "modulate:a", 1.0, ENTER_SECONDS * 0.35).set_delay(ENTER_SECONDS * 0.65)
	tween.chain().tween_callback(_finish_enter)


## The violet cover stays up: the scene changes right after "chosen".
func _finish_enter() -> void:
	chosen.emit(_difficulty)


func _go_back() -> void:
	Audio.play(Sounds.UI_CLICK, -6.0)
	close()
	back.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		_go_back()


# --- seal texts and rewards (also used by the progression screen) -------------------

## "Cuivre", "Fer"... : the seal's name without "Sceau".
static func seal_short_name(level: int) -> String:
	return TranslationServer.translate("DANGER_%d_SHORT" % level)


## Everything a seal adds, joined (a seal stacks the effects of the ones below it).
static func seal_effects(difficulty: DifficultyData) -> String:
	var effects: Array[String] = []
	if difficulty.steady_elite_chance > 0.0:
		effects.append(TranslationServer.translate("SEAL_FX_ELITES") % roundi(difficulty.steady_elite_chance * 100.0))
	if difficulty.hp_multiplier > 1.0:
		effects.append(TranslationServer.translate("SEAL_FX_HP_DAMAGE") % roundi((difficulty.hp_multiplier - 1.0) * 100.0))
	if difficulty.spawn_rate_multiplier > 1.0 or difficulty.group_size_bonus > 0:
		effects.append(TranslationServer.translate("SEAL_FX_SPAWN") % roundi((difficulty.spawn_rate_multiplier - 1.0) * 100.0))
	if difficulty.double_final_boss:
		effects.append(TranslationServer.translate("SEAL_FX_DOUBLE_BOSS"))
	if effects.is_empty():
		effects.append(TranslationServer.translate("SEAL_FX_NONE"))
	return " · ".join(effects)


## The seal's place; a seal sharing a lower seal's place has none of its own yet.
static func seal_place(difficulty: DifficultyData, levels: Array[DifficultyData]) -> String:
	for other in levels:
		if other.level < difficulty.level and other.biome == difficulty.biome:
			return TranslationServer.translate("SEAL_PLACE_COMING")
	return TranslationServer.translate("BIOME_DUNGEON" if difficulty.biome == null else difficulty.biome.name_key)


## Weapon and items unlocked by winning seal `level` (WIN_SEAL challenges).
static func seal_rewards(level: int) -> Array[Resource]:
	var list: Array[Resource] = []
	for challenge in SaveService.all_challenges():
		if challenge.kind == ChallengeData.Kind.WIN_SEAL and challenge.threshold == level:
			var target := ContentDB.get_def(challenge.unlock_category, challenge.unlock_id)
			if target != null:
				list.append(target)
	return list


## Flat shape of an icon (a mystery reward): its alpha, one muted color.
static func silhouette_material() -> ShaderMaterial:
	if _silhouette == null:
		var shader := Shader.new()
		shader.code = "shader_type canvas_item;
uniform vec4 tint : source_color = vec4(0.32, 0.27, 0.45, 0.9);
void fragment() { COLOR = vec4(tint.rgb, texture(TEXTURE, UV).a * tint.a); }"
		_silhouette = ShaderMaterial.new()
		_silhouette.shader = shader
	return _silhouette
