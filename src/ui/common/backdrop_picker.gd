class_name BackdropPicker
extends Button
## Picks the background of the character select screens (setting `select_background`, see
## SelectBackdrops): a button showing the current picture; pressing it opens a block of pictures
## stuck together, no ornament, the hovered or current one outlined: the hunters' hall and "random"
## in the first column, then dangers 1 2 3 on the first line and 4 5 6 under them (dev's layout,
## 2026-10-09). A danger not won yet is dark with a lock. Used by the settings screen and, top right, by the select screens, which listen
## to `chosen` to show the new picture at once. It writes through Settings.set_value.
## `themed`: the frames take the color of the background (the select screens).
## `focusable`: the pictures can be reached with a gamepad or the keys (not in the split coop pick,
## where the screen reads the devices itself and cycles with `cycle`).

signal chosen

const THUMB_SIZE := Vector2(216.0, 122.0)
## Order of the pictures in the block, as indexes of SettingsData.background_ids()
## (hall, dangers 1-6, random): hall 1 2 3 / random 4 5 6.
const BLOCK_ORDER: Array[int] = [0, 1, 2, 3, 7, 4, 5, 6]
const SHOWN_HEIGHT := 52.0
## Thickness of the dark line between pictures, and of the white outline of the hovered one.
const OUTLINE_WIDTH := 5

var themed: bool = false
var focusable: bool = true

var _strip: PanelContainer
var _row: GridContainer
var _items: Array[Button] = []


func _init() -> void:
	tooltip_text = "SET_SELECT_BACKGROUND"
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	expand_icon = true
	icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_theme_constant_override("icon_max_width", 84)
	pressed.connect(toggle)
	_strip = PanelContainer.new()
	_strip.top_level = true
	_strip.visible = false
	_strip.z_index = 100
	_row = GridContainer.new()
	_row.columns = 4
	_row.add_theme_constant_override("h_separation", 0)
	_row.add_theme_constant_override("v_separation", 0)
	_strip.add_child(_row)
	add_child(_strip)


## Rebuilds the row (a danger may have been won) and shows the current setting.
func refresh() -> void:
	for child in _row.get_children():
		_row.remove_child(child)
		child.queue_free()
	_items.clear()
	var hue := SelectBackdrops.hue if themed else 0.0
	var backing := StyleBoxFlat.new()
	backing.bg_color = Color(0.02, 0.03, 0.08, 0.9)
	_strip.add_theme_stylebox_override("panel", backing)
	var ids := SettingsData.background_ids()
	for index in ids.size():
		_items.append(_make_item(ids[index], hue))
	for index in BLOCK_ORDER:
		_row.add_child(_items[index])
	_show_current()


## Opens or closes the row.
func toggle() -> void:
	if _strip.visible:
		close()
		return
	_strip.visible = true
	_place_strip.call_deferred()
	if focusable:
		_focus_current.call_deferred()


func close() -> void:
	if not _strip.visible:
		return
	_strip.visible = false
	if focusable and is_visible_in_tree():
		grab_focus()


func is_open() -> bool:
	return _strip.visible


## The pictures of the row (tests).
func items() -> Array[Button]:
	return _items


## Next (or previous) background on offer, skipping the locked ones.
func cycle(direction: int = 1) -> void:
	var ids := SettingsData.background_ids()
	var current := maxi(ids.find(Settings.data.select_background), 0)
	for step in range(1, ids.size()):
		var index := posmod(current + direction * step, ids.size())
		if not _items[index].disabled:
			_pick(index)
			return


func _make_item(id: String, hue: float) -> Button:
	var item := Button.new()
	item.custom_minimum_size = THUMB_SIZE
	item.focus_mode = Control.FOCUS_ALL if focusable else Control.FOCUS_NONE
	var level := -1
	if id.begins_with("danger_"):
		level = int(id.trim_prefix("danger_"))
	var unlocked := level < 0 or SelectBackdrops.is_unlocked(level)
	item.disabled = not unlocked
	var name_text := tr("BG_RANDOM") if id == "random" else (tr("BG_DEFAULT") if id == "default" else SelectBackdrops.place_name(level))
	item.tooltip_text = name_text if unlocked else "🔒 " + name_text
	if id == "random":
		var mark := Label.new()
		mark.text = "?"
		mark.theme_type_variation = &"TitleLabel"
		mark.add_theme_font_size_override("font_size", 44)
		mark.set_anchors_preset(Control.PRESET_FULL_RECT)
		mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.add_child(mark)
		var name_label := Label.new()
		name_label.text = tr("BG_RANDOM_SHORT")
		name_label.theme_type_variation = &"SmallLabel"
		name_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.add_child(name_label)
	else:
		var picture := TextureRect.new()
		picture.texture = SelectBackdrops.picture(level, true)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		picture.set_anchors_preset(Control.PRESET_FULL_RECT)
		# Inset: the outline of the hovered picture is drawn under it and must stay visible.
		picture.offset_left = OUTLINE_WIDTH
		picture.offset_top = OUTLINE_WIDTH
		picture.offset_right = -OUTLINE_WIDTH
		picture.offset_bottom = -OUTLINE_WIDTH
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		picture.modulate = Color.WHITE if unlocked else Color(0.25, 0.25, 0.3)
		item.add_child(picture)
		if not unlocked:
			var lock := Label.new()
			lock.text = "🔒"
			lock.add_theme_font_size_override("font_size", 30)
			lock.set_anchors_preset(Control.PRESET_FULL_RECT)
			lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lock.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
			item.add_child(lock)
	var accent := UiTheme.accent_color(hue)
	var current := id == Settings.data.select_background
	# No ornament: only an outline on the hovered, focused or current picture.
	# A thin dark line separates the pictures; the hovered, focused or current one gets a thick
	# bright outline over a light veil.
	var line := UiTheme.outline_style(Color(0.01, 0.02, 0.06, 0.95), OUTLINE_WIDTH)
	var strong := UiTheme.outline_style(Color.WHITE, OUTLINE_WIDTH)
	item.add_theme_stylebox_override("normal", strong if current else line)
	item.add_theme_stylebox_override("disabled", line)
	for state in ["hover", "pressed", "focus"]:
		item.add_theme_stylebox_override(state, strong)
	var index := _items.size()
	item.pressed.connect(func() -> void: _pick(index))
	return item


func _pick(index: int) -> void:
	Settings.set_value(&"select_background", SettingsData.background_ids()[index])
	refresh()
	chosen.emit()
	close()


## The button shows the picture and the name of the current setting.
func _show_current() -> void:
	var id := Settings.data.select_background
	var level := -1
	if id.begins_with("danger_"):
		level = int(id.trim_prefix("danger_"))
	if id == "random":
		text = tr("BG_RANDOM")
		icon = null
	else:
		text = tr("BG_DEFAULT") if level < 0 else SelectBackdrops.place_name(level)
		icon = SelectBackdrops.picture(level, true)


func _place_strip() -> void:
	_strip.reset_size()
	var screen := get_viewport().get_visible_rect().size
	var at := global_position + Vector2(size.x - _strip.size.x, size.y + 8.0)
	at.x = clampf(at.x, 8.0, maxf(screen.x - _strip.size.x - 8.0, 8.0))
	_strip.global_position = at


func _focus_current() -> void:
	var index := maxi(SettingsData.background_ids().find(Settings.data.select_background), 0)
	if index < _items.size() and not _items[index].disabled:
		_items[index].grab_focus()


func _input(event: InputEvent) -> void:
	if not _strip.visible:
		return
	if event.is_action_pressed("cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()
	elif event is InputEventMouseButton and event.pressed and not _strip.get_global_rect().has_point(event.global_position) \
			and not get_global_rect().has_point(event.global_position):
		close()
