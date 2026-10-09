class_name SealSelect
extends Control
## Seal (danger level) choice, its own screen once every player has picked a hunter
## and a weapon (dev's choice, mockup B, 2026-10-08): the dungeon gate behind, the six
## seals engraved in the stone around the portal (three each side, Roman numerals; the
## portal takes the color of the pointed seal, heat gradient, the last one red), then the details of the focused one (effects, place, the rewards
## still to win as dark silhouettes) and Play. Solo and coop: one screen for everybody;
## a seal is open when every hunter of the party has won the one below it.
## Moving onto an open seal picks it; pressing it moves to Play, Play starts the run
## (two steps, dev's choice: a seal press never launches by mistake).

## The seal to play was confirmed.
signal chosen(difficulty: DifficultyData)
## Back to the hunters.
signal back

## The gate picture (the dev's own: stone medallions I..VI round the arch, a painted portal).
## The portal is re-drawn animated and recolored in the arch (seal_portal.gdshader).
const BACKGROUND := preload("res://assets/ui/select/seal_gate_v3.png")
## The same gate widened to a native 16:9 by outpainting (tools/art/widen.py): the original sits in the
## middle (CORE_SHARE of the width, starting at SIDE_SHARE), the painted sides are new. Every position
## below is in the original picture's shares; _picture_to_screen maps them onto the wide one.
const WIDE := preload("res://assets/ui/select/seal_gate_wide.png")
const SIDE_SHARE := 120.0 / 1536.0
const CORE_SHARE := 1296.0 / 1536.0
const NUMERAL_SHADER := preload("res://src/ui/character_select/seal_numeral.gdshader")
const PORTAL_SHADER := preload("res://src/ui/character_select/seal_portal.gdshader")
const ROMAN: Array[String] = ["I", "II", "III", "IV", "V", "VI"]
const SKULL := "☠"
const LOCK := "🔒"
## The six medallions painted on the arch, as a share of the picture (center). The picked seal
## lights its medallion; a locked one is covered. Index = seal level (I at the bottom left,
## VI at the bottom right, III and IV at the top).
const MEDALLIONS: Array[Vector2] = [Vector2(0.369, 0.405), Vector2(0.382, 0.288), Vector2(0.430, 0.180),
		Vector2(0.570, 0.180), Vector2(0.617, 0.285), Vector2(0.630, 0.408)]
## Radius of a medallion, as a share of the picture's width.
const MEDALLION_RADIUS := 0.03
## Where the portal lies in the picture, and the part of the picture its quad covers (the
## arch, the light on the stones and the fragments of the red portal).
const PORTAL_CENTER := Vector2(0.5015, 0.415)
const PORTAL_RECT := Rect2(0.22, 0.08, 0.56, 0.66)
## Color of each place's portal (dev, 2026-10-10): stone dungeon pale teal, sunken temple turquoise,
## frozen forest white, infernal citadel orange, hive green, dragon's lair red. The interface frames
## take the same hue (SelectBackdrops.DANGER_HUES).
const PORTAL_COLORS: Array[Color] = [Color("5fd8c0"), Color("22d6e6"), Color("eef6ff"),
		Color("ff7a1a"), Color("5cff2e"), Color("ff2a3a")]
const RUMBLE_LOOP := &"seal_portal_rumble"
const RUMBLE_DB := -6.0
const PANEL_WIDTH := 460.0
const ENTER_SECONDS := 1.4
const ENTER_ZOOM := 9.0
const REWARD_BOX := 70.0

## Debug (capture tool): every seal counts as open.
static var debug_all_open: bool = false
static var _silhouette: ShaderMaterial

var _levels: Array[DifficultyData] = []
var _buttons: Array[Button] = []
var _medals: Array[Medal] = []
## Highest seal the party may play.
var _allowed: int = 0
var _difficulty: DifficultyData
## Full-screen layer over the page that holds the six plaques, placed on the painted arch.
var _gate_layer: Control
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
var _portal_tween: Tween
var _fx: PortalFx
## Hue shift of the frames for the pointed place.
var _hue: float = 0.0
var _top_bar: HBoxContainer
var _flames: UiHotspots
## The vortex quad, child of the background (it zooms with it when the run starts).
var _portal: ColorRect


## Overlay of one medallion painted in the picture. It adds no shape: the painted numeral itself
## (the light pixels of the medallion, redrawn by seal_numeral.gdshader) takes the seal's color when
## the seal is picked, and darkens when it is locked.
class Medal extends Control:
	var level: int = 0
	var color: Color = Color.WHITE
	var locked: bool = false
	var picked: bool = false
	## Where the medallion is in the picture, in texture pixels.
	var source: Rect2 = Rect2()

	func _init(p_level: int, p_color: Color) -> void:
		level = p_level
		color = p_color
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tint_material := ShaderMaterial.new()
		tint_material.shader = NUMERAL_SHADER
		material = tint_material

	func refresh() -> void:
		var tint_material := material as ShaderMaterial
		tint_material.set_shader_parameter(&"tint", color.lerp(Color.WHITE, 0.15))
		var texel := Vector2(BACKGROUND.get_size())
		tint_material.set_shader_parameter(&"region", Vector4(source.position.x / texel.x, source.position.y / texel.y,
				source.size.x / texel.x, source.size.y / texel.y))
		tint_material.set_shader_parameter(&"dark", 1.0 if locked else 0.0)
		tint_material.set_shader_parameter(&"tint_strength", 0.85 if locked else (1.0 if picked else 0.0))
		queue_redraw()

	func _draw() -> void:
		if source.size.x > 0.0 and (picked or locked):
			draw_texture_rect_region(BACKGROUND, Rect2(Vector2.ZERO, size), source)


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
	background.texture = WIDE
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	# The night veil over the painting (it zooms with it), under the portal so the portal stays bright.
	var dim := ColorRect.new()
	dim.color = Color(UiTheme.DIM, 0.4)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(dim)
	_portal = ColorRect.new()
	_portal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var portal_material := ShaderMaterial.new()
	portal_material.shader = PORTAL_SHADER
	portal_material.set_shader_parameter(&"rect_min", PORTAL_RECT.position)
	portal_material.set_shader_parameter(&"rect_size", PORTAL_RECT.size)
	portal_material.set_shader_parameter(&"vortex", BACKGROUND)
	_portal.material = portal_material
	background.add_child(_portal)
	_fx = PortalFx.new()
	background.add_child(_fx)
	background.resized.connect(_layout_portal)
	# The violet flames of the gate come alive under the mouse (animation + fire sound).
	_flames = UiHotspots.new()
	_flames.picture_rect = _picture_global_rect
	_flames.texture = BACKGROUND
	_flames.add_gate_flames(Color(0.7, 0.3, 1.0), false)
	add_child(_flames)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 90)
	add_child(margin)
	_page = margin
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 18)
	margin.add_child(page)
	var top := HBoxContainer.new()
	page.add_child(top)
	_top_bar = top
	var back_button := Button.new()
	back_button.text = "UI_BACK"
	back_button.custom_minimum_size = Vector2(190, 64)
	back_button.focus_mode = Control.FOCUS_NONE
	back_button.pressed.connect(_go_back)
	top.add_child(back_button)
	# No title (dev, 2026-10-09): the gate speaks for itself.
	# The plaques sit on the painted arch (_gate_layer). The details and "Play" form a column at the
	# right, so the gate and the portal stay in full view (dev's question, 2026-10-10).
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(body)
	var push := Control.new()
	push.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	push.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(push)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	column.alignment = BoxContainer.ALIGNMENT_END
	column.custom_minimum_size.x = PANEL_WIDTH
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(column)
	column.add_child(_build_panel())
	_launch = Button.new()
	_launch.text = "UI_PLAY"
	# The plain button of the theme (it takes the color of the place), not the bright main-action one.
	_launch.custom_minimum_size = Vector2(PANEL_WIDTH, 76)
	_launch.pressed.connect(_confirm)
	column.add_child(_launch)
	_gate_layer = Control.new()
	_gate_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_gate_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gate_layer.resized.connect(_layout_plaques)
	add_child(_gate_layer)
	add_child(ButtonHints.create([[&"A", "UI_PLAY"], [&"B", "UI_HINT_BACK"]]))


## Details of the focused seal: name, effects, place; the rewards at right.
func _build_panel() -> Control:
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	var line := VBoxContainer.new()
	line.add_theme_constant_override("separation", 14)
	_panel.add_child(line)
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override("separation", 8)
	line.add_child(texts)
	_name = Label.new()
	_name.theme_type_variation = &"TitleLabel"
	_name.add_theme_font_size_override("font_size", 36)
	texts.add_child(_name)
	_effects = Label.new()
	_effects.add_theme_font_size_override("font_size", 18)
	_effects.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texts.add_child(_effects)
	_place = Label.new()
	_place.add_theme_font_size_override("font_size", 16)
	_place.add_theme_color_override("font_color", UiTheme.MUTED)
	_place.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texts.add_child(_place)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 8)
	line.add_child(right)
	_rewards_title = Label.new()
	_rewards_title.add_theme_font_size_override("font_size", 16)
	_rewards_title.add_theme_color_override("font_color", UiTheme.GOLD)
	right.add_child(_rewards_title)
	_rewards = HBoxContainer.new()
	_rewards.add_theme_constant_override("separation", 10)
	right.add_child(_rewards)
	return _panel


## Opens for the party's hunters: a seal is open when every one of them may play it.
func open(hunters: Array[CharacterData]) -> void:
	_allowed = allowed_level(hunters)
	_levels = all_levels()
	for child in _gate_layer.get_children():
		_gate_layer.remove_child(child)
		child.queue_free()
	_buttons.clear()
	_medals.clear()
	for difficulty in _levels:
		_gate_layer.add_child(_seal_button(difficulty))
	_link_seals()
	_layout_plaques()
	_layout_portal()
	visible = true
	# The hardest open seal is picked; the focus is on it.
	var last := mini(_allowed, _buttons.size() - 1)
	if last >= 0:
		_buttons[last].grab_focus()
		_point(last)
	HintBanner.show_once(self, &"seals", HintBanner.TOP_CENTER, Vector2(0.0, 4.0), 1500.0)


func close() -> void:
	visible = false
	_update_rumble(false)


## Highest seal open: one above the best win of any hunter (global unlock).
static func allowed_level(hunters: Array[CharacterData]) -> int:
	return 0 if hunters.is_empty() else SaveService.profile.max_difficulty()


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
	return debug_all_open or level <= _allowed


func _seal_button(difficulty: DifficultyData) -> Button:
	var level := difficulty.level
	var button := Button.new()
	button.flat = true
	button.set_meta(&"locked", not is_open(level))
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, empty)
	var medal := Medal.new(level, PORTAL_COLORS[clampi(level, 0, PORTAL_COLORS.size() - 1)])
	medal.locked = not is_open(level)
	medal.resized.connect(medal.refresh)
	medal.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.add_child(medal)
	button.set_meta(&"medal", medal)
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


## Row (0 = top .. 2 = bottom) of seal `i` in its column: the levels climb on the left (I at the
## bottom), and on the right VI is at the bottom, IV at the top.
static func slot_row(i: int) -> int:
	return 2 - i % 3 if i < 3 else i % 3


## Up / down inside a column, left / right to the same row of the other column; down from the
## lowest plaque goes to Play.
func _link_seals() -> void:
	var grid: Array = [[null, null], [null, null], [null, null]]
	for i in _buttons.size():
		grid[slot_row(i)][0 if i < 3 else 1] = _buttons[i]
	for row in 3:
		for column in 2:
			var button: Button = grid[row][column]
			if button == null:
				continue
			var above: Button = grid[row - 1][column] if row > 0 else null
			var below: Button = grid[row + 1][column] if row < 2 else null
			var across: Button = grid[row][1 - column]
			button.focus_neighbor_top = button.get_path_to(above if above != null else button)
			button.focus_neighbor_bottom = button.get_path_to(below if below != null else _launch)
			button.focus_neighbor_left = button.get_path_to(button if column == 0 or across == null else across)
			button.focus_neighbor_right = button.get_path_to(button if column == 1 or across == null else across)


## Size of the wide picture on screen: it covers the whole screen (no black bars, like the other
## select screens); a screen wider than 16:9 cuts a little of the top and bottom.
func _drawn() -> Vector2:
	var scale := maxf(size.x / WIDE.get_width(), size.y / WIDE.get_height())
	return Vector2(WIDE.get_size()) * scale


## Where the original picture (the middle of the wide one) lies on screen, for the hover spots.
func _picture_global_rect() -> Rect2:
	var drawn := _drawn()
	var origin := (size - drawn) * 0.5 + Vector2(drawn.x * SIDE_SHARE, 0.0)
	return Rect2(global_position + origin, Vector2(drawn.x * CORE_SHARE, drawn.y))


## Puts the portal quad over the arch of the picture.
func _layout_portal() -> void:
	if _portal == null:
		return
	var drawn := _drawn()
	var core := Vector2(drawn.x * CORE_SHARE, drawn.y)
	_portal.position = _picture_to_screen(PORTAL_RECT.position)
	_portal.size = core * PORTAL_RECT.size
	_fx.place(_picture_to_screen(Vector2(PORTAL_CENTER.x, PORTAL_CENTER.y)), Vector2(0.0935, 0.215) * core)


## Where a point of the original picture (0..1) lies on screen.
func _picture_to_screen(uv: Vector2) -> Vector2:
	var drawn := _drawn()
	return (size - drawn) * 0.5 + drawn * Vector2(SIDE_SHARE + uv.x * CORE_SHARE, uv.y)


## Puts the six overlays on the medallions painted in the picture.
func _layout_plaques() -> void:
	if _gate_layer == null:
		return
	var drawn := _drawn()
	var cell := Vector2.ONE * MEDALLION_RADIUS * 2.0 * drawn.x * CORE_SHARE
	for i in _buttons.size():
		_buttons[i].size = cell
		_buttons[i].pivot_offset = cell * 0.5
		_buttons[i].position = _picture_to_screen(MEDALLIONS[i]) - cell * 0.5
		var medal := _buttons[i].get_meta(&"medal") as Medal
		var texel := Vector2(BACKGROUND.get_size())
		medal.source = Rect2((MEDALLIONS[i] - Vector2.ONE * MEDALLION_RADIUS * Vector2(1.0, 1.5)) * texel,
				Vector2.ONE * MEDALLION_RADIUS * 2.0 * Vector2(1.0, 1.5) * texel)
		medal.refresh()


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
	_apply_look(level)
	_tint_portal(PORTAL_COLORS[clampi(level, 0, PORTAL_COLORS.size() - 1)])
	_set_grandeur(level)
	_show_info(_levels[level])


## The frames and buttons of the screen take the color of the pointed place.
func _apply_look(level: int) -> void:
	var index := clampi(level, 0, PORTAL_COLORS.size() - 1)
	UiTheme.shift_saturation = SelectBackdrops.DANGER_SATURATIONS[index]
	UiTheme.shift_value = SelectBackdrops.DANGER_VALUES[index]
	_hue = SelectBackdrops.DANGER_HUES[index]
	theme = UiTheme.get_theme(_hue)


## The portal takes the color of the pointed seal (a short fade).
func _tint_portal(color: Color) -> void:
	var material := _portal.material as ShaderMaterial
	var current: Variant = material.get_shader_parameter(&"mid")
	var from: Color = Color(current.x, current.y, current.z) if current is Vector3 else color
	if _portal_tween != null and _portal_tween.is_valid():
		_portal_tween.kill()
	if UiFx.reduce_motion or from.is_equal_approx(color):
		_set_portal_color(color)
		return
	_portal_tween = create_tween()
	_portal_tween.tween_method(func(value: Color) -> void: _set_portal_color(value), from, color, 0.35)


## The last seal's portal is the imposing one: lightning comes slowly out of it.
func _set_grandeur(level: int) -> void:
	var grand := level >= _levels.size() - 1 and level > 0
	_fx.intensity = 1.0 if grand else 0.0
	_update_rumble(grand)


## The last seal's portal rumbles, a constant deep sound, for as long as it is pointed and the screen
## is shown; it never goes on under another screen.
func _update_rumble(grand: bool) -> void:
	if grand and is_visible_in_tree() and not _entering:
		Audio.loop_start(RUMBLE_LOOP, Sounds.PORTAL_RUMBLE, RUMBLE_DB)
	else:
		Audio.loop_stop(RUMBLE_LOOP, 0.4)


## Sets the vortex palette (bright bands, body, shade) from the seal color.
func _set_portal_color(color: Color) -> void:
	var palette := ArrivalGate.palette_for(color)
	var material := _portal.material as ShaderMaterial
	material.set_shader_parameter(&"mid", Vector3(palette[0].r, palette[0].g, palette[0].b))
	material.set_shader_parameter(&"outer", Vector3(palette[1].r, palette[1].g, palette[1].b))
	material.set_shader_parameter(&"deep", Vector3(palette[2].r, palette[2].g, palette[2].b))


func _show_info(difficulty: DifficultyData) -> void:
	var level := difficulty.level
	var open_seal := is_open(level)
	var portal := PORTAL_COLORS[clampi(level, 0, PORTAL_COLORS.size() - 1)]
	_panel.add_theme_stylebox_override("panel", SelectBackdrops.ghost(UiTheme.panel_style(UiTheme.accent_color(_hue), 0.9, 16, _hue)))
	_name.text = tr(difficulty.name_key)
	_name.add_theme_color_override("font_color", portal if open_seal else UiTheme.MUTED)
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
		mark.add_theme_font_size_override("font_size", 26)
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
	_update_rumble(false)
	_flames.visible = false
	Audio.play(Sounds.PORTAL_OPEN, -4.0)
	# Scale around the swirl: where it lies on screen once the picture is "covered".
	_background.pivot_offset = _picture_to_screen(PORTAL_CENTER)
	var flash := ColorRect.new()
	flash.color = PortalArrival.cover_color(PORTAL_COLORS[clampi(_difficulty.level, 0, PORTAL_COLORS.size() - 1)])
	flash.modulate.a = 0.0
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_page, "modulate:a", 0.0, ENTER_SECONDS * 0.3)
	tween.tween_property(_gate_layer, "modulate:a", 0.0, ENTER_SECONDS * 0.3)
	tween.tween_property(_background, "scale", Vector2.ONE * ENTER_ZOOM, ENTER_SECONDS) 		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_method(_set_pull, 0.0, 1.0, ENTER_SECONDS * 0.8)
	tween.tween_property(flash, "modulate:a", 1.0, ENTER_SECONDS * 0.35).set_delay(ENTER_SECONDS * 0.65)
	tween.chain().tween_callback(_finish_enter)


func _set_pull(value: float) -> void:
	(_portal.material as ShaderMaterial).set_shader_parameter(&"pull", value)


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
