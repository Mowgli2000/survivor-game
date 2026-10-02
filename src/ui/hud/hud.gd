class_name Hud
extends CanvasLayer
## In-run HUD: XP bar (top), HP bar + level (top left), timer (top center).
## Read-only: listens to signals and reads state, never changes it.

var _hp_bar: ProgressBar
var _hp_label: Label
var _xp_bar: ProgressBar
var _level_label: Label
var _timer_label: Label
var _state: RunState
var _last_second: int = -1


func setup(player: Player, progression: Progression, state: RunState) -> void:
	_state = state
	player.health_changed.connect(_on_health_changed)
	progression.xp_changed.connect(_on_xp_changed)
	progression.leveled_up.connect(_on_leveled_up)
	_on_health_changed(player.hp, player.stats.get_value(StatIds.MAX_HP))
	_on_xp_changed(progression.xp, progression.xp_needed())
	_on_leveled_up(progression.level)


func _init() -> void:
	layer = 10
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_xp_bar = _make_bar(Color(0.35, 0.75, 1.0))
	_xp_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_xp_bar.offset_bottom = 14
	root.add_child(_xp_bar)

	var box := VBoxContainer.new()
	box.position = Vector2(32, 36)
	box.add_theme_constant_override("separation", 8)
	root.add_child(box)

	_hp_bar = _make_bar(Color(0.9, 0.25, 0.3))
	_hp_bar.custom_minimum_size = Vector2(360, 32)
	box.add_child(_hp_bar)
	_hp_label = _make_label(22)
	_hp_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hp_bar.add_child(_hp_label)

	_level_label = _make_label(28)
	box.add_child(_level_label)

	_timer_label = _make_label(40)
	_timer_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.offset_top = 28
	_timer_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	root.add_child(_timer_label)


func _process(_delta: float) -> void:
	if _state == null:
		return
	var seconds := int(_state.elapsed)
	if seconds != _last_second:
		_last_second = seconds
		_timer_label.text = format_time(_state.elapsed)


static func format_time(seconds: float) -> String:
	var total := int(seconds)
	return "%02d:%02d" % [total / 60, total % 60]


func _on_health_changed(hp: float, max_hp: float) -> void:
	_hp_bar.max_value = max_hp
	_hp_bar.value = hp
	_hp_label.text = "%d / %d" % [ceili(hp), roundi(max_hp)]


func _on_xp_changed(xp: int, needed: int) -> void:
	_xp_bar.max_value = needed
	_xp_bar.value = xp


func _on_leveled_up(level: int) -> void:
	_level_label.text = "%s %d" % [tr("UI_LEVEL"), level]


func _make_bar(fill_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.05, 0.08, 0.85)
	bg.set_corner_radius_all(4)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


func _make_label(size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	return label
