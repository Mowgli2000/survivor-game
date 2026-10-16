class_name ChestRewardScreen
extends CanvasLayer
## What a boss chest gave, shown as a light projection: the screen darkens around the open chest (a
## spotlight), a beam of golden light rises from it and the rewards float in it, each with its name and
## effect, until the player validates. Display only: Run pauses the game around it and gives the
## rewards before opening it.

signal closed

const ICON_SIZE := 150.0
const SLOT_WIDTH := 300.0
## Height of the beam above the chest, and how far above the chest the icons float.
const BEAM_HEIGHT := 270.0
## Where the beam's halo ring sits above the chest, as a share of the beam's height (from the painting).
const RING_SHARE := 0.65
const ICON_RISE := 360.0
const SPOT_RADIUS := 640.0
const LOOP_FIRST := 8  # the beam's frames 9-16 loop (frame index 8..15)

var _spot: Control
var _beam: Control
var _slots: Control
var _validate: Button
var _title: Label
var _sheet: EffectSheet
var _anchor := Vector2.ZERO
var _time := 0.0
var _cards := 0
var _gradient: GradientTexture2D
var _scale := 1.0
var _ring_y := 400.0


func _init() -> void:
	layer = 29
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiTheme.get_theme()
	add_child(root)
	_spot = Control.new()
	_spot.set_anchors_preset(Control.PRESET_FULL_RECT)
	_spot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spot.draw.connect(_draw_spot)
	root.add_child(_spot)
	_beam = Control.new()
	_beam.set_anchors_preset(Control.PRESET_FULL_RECT)
	_beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_beam.material = add
	_beam.draw.connect(_draw_beam)
	root.add_child(_beam)
	_slots = Control.new()
	_slots.set_anchors_preset(Control.PRESET_FULL_RECT)
	_slots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_slots)
	_title = Label.new()
	_title.text = "UI_CHEST_REWARDS"
	_title.theme_type_variation = &"TitleLabel"
	_title.add_theme_color_override("font_color", UiTheme.GOLD)
	_title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_title.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_title.offset_top = 24.0
	root.add_child(_title)
	_validate = Button.new()
	_validate.text = "UI_VALIDATE"
	_validate.theme_type_variation = &"BigButton"
	_validate.custom_minimum_size = Vector2(340, 84)
	_validate.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_validate.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_validate.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_validate.offset_bottom = -48.0
	_validate.pressed.connect(close)
	root.add_child(_validate)


## `rewards`: [{"item": ItemData, "title": "" (solo) or "Player 2", "color": Color}, ...].
## `anchor`: where the open chest is on screen; `sheet`: the painted beam (null: a plain glow).
func open(rewards: Array[Dictionary], anchor: Vector2 = Vector2.ZERO, sheet: EffectSheet = null) -> void:
	for child in _slots.get_children():
		_slots.remove_child(child)
		child.queue_free()
	var view := get_viewport().get_visible_rect().size
	_anchor = anchor if anchor != Vector2.ZERO else Vector2(view.x * 0.5, view.y * 0.7)
	# Keep the beam and the cards inside the screen whatever the chest's place.
	_scale = view.y / 1080.0
	_anchor.x = clampf(_anchor.x, 260.0 * _scale, view.x - 260.0 * _scale)
	_anchor.y = clampf(_anchor.y, 300.0 * _scale, view.y - 140.0 * _scale)
	# The icons float above the chest, but never into the title.
	_ring_y = _anchor.y - RING_SHARE * BEAM_HEIGHT * _scale
	_sheet = sheet
	_time = 0.0
	_cards = rewards.size()
	var delay := 0.35
	for i in rewards.size():
		var slot := _slot(rewards[i])
		_slots.add_child(slot)
		var width := minf(SLOT_WIDTH * _scale, (view.x - 200.0) / maxf(rewards.size(), 1.0))
		var x := _anchor.x + (i - (rewards.size() - 1) * 0.5) * width
		slot.scale = Vector2.ONE * _scale
		slot.size = Vector2(SLOT_WIDTH, 0.0)
		# The icon rests just above the halo (its name and effect hang below it, over the beam), under the title.
		var header: float = (slot.get_child(0).get_combined_minimum_size().y + 8.0) if rewards[i].title != "" else 0.0
		var top := maxf(_ring_y - 24.0 * _scale - (ICON_SIZE + header) * _scale, 100.0 * _scale)
		slot.position = Vector2(x - SLOT_WIDTH * _scale * 0.5, top)
		slot.set_meta(&"top", top)
		UiFx.pop_in(slot, delay)
		delay += 0.18
	visible = true
	UiFx.pop_in(_title)
	_validate.grab_focus()
	_spot.queue_redraw()


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func card_count() -> int:
	return _cards


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta / maxf(Engine.time_scale, 0.05)
	_beam.queue_redraw()
	# The floating icons bob gently, each out of step with the next.
	for i in _slots.get_child_count():
		var slot := _slots.get_child(i) as Control
		slot.position.y = float(slot.get_meta(&"top", 0.0)) + 6.0 * sin(_time * 2.2 + i * 1.3)


## The screen goes dark except around the chest: a radial gradient (clear in the middle, dark at the
## edge) centered on the chest, and plain shade outside its square.
func _draw_spot() -> void:
	var shade := Color(UiTheme.DIM, 0.8)
	var size := _spot.size
	var square := Rect2(_anchor - Vector2.ONE * SPOT_RADIUS * _scale, Vector2.ONE * SPOT_RADIUS * _scale * 2.0)
	if _gradient == null:
		var gradient := Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
		gradient.colors = PackedColorArray([Color(shade, 0.0), Color(shade, 0.25), shade])
		_gradient = GradientTexture2D.new()
		_gradient.gradient = gradient
		_gradient.fill = GradientTexture2D.FILL_RADIAL
		_gradient.fill_from = Vector2(0.5, 0.5)
		_gradient.fill_to = Vector2(1.0, 0.5)
		_gradient.width = 256
		_gradient.height = 256
	_spot.draw_texture_rect(_gradient, square, false)
	for rect in [Rect2(0.0, 0.0, size.x, square.position.y), Rect2(0.0, square.end.y, size.x, size.y - square.end.y),
			Rect2(0.0, square.position.y, square.position.x, square.size.y),
			Rect2(square.end.x, square.position.y, size.x - square.end.x, square.size.y)]:
		if rect.size.x > 0.0 and rect.size.y > 0.0:
			_spot.draw_rect(rect, shade)


func _draw_beam() -> void:
	var height := BEAM_HEIGHT * _scale
	var box := Rect2(_anchor.x - height * 0.5, _anchor.y - height * 0.92, height, height)
	if _sheet == null:
		_beam.draw_circle(_anchor + Vector2(0, -ICON_RISE), 120.0, Color(1.0, 0.85, 0.4, 0.25))
		return
	var frames := maxi(_sheet.frames, 1)
	var fps := frames / maxf(_sheet.duration, 0.1)
	var raw := int(_time * fps)
	var index := raw if raw < LOOP_FIRST + (frames - LOOP_FIRST) else LOOP_FIRST + (raw - LOOP_FIRST) % maxi(frames - LOOP_FIRST, 1)
	_beam.draw_texture_rect_region(_sheet.texture, box, _sheet.frame_region(mini(index, frames - 1)), Color(1, 1, 1, 0.95))


func _slot(reward: Dictionary) -> Control:
	var item: ItemData = reward.item
	var accent := Tiers.color(item.tier)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.custom_minimum_size = Vector2(SLOT_WIDTH, 0.0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if reward.title != "":
		var who := Label.new()
		who.text = reward.title
		who.theme_type_variation = &"SubtitleLabel"
		who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		who.add_theme_color_override("font_color", reward.color)
		box.add_child(who)
	var icon := IconTile.create(item.icon, item.tier, ICON_SIZE)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(icon)
	var name_label := Label.new()
	name_label.text = item.name_key
	name_label.theme_type_variation = &"SubtitleLabel"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size.x = SLOT_WIDTH - 30.0
	name_label.add_theme_color_override("font_color", accent)
	box.add_child(name_label)
	return box
