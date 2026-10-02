class_name Hud
extends CanvasLayer
## In-run HUD: XP bar (top), HP bar + level, pending level-ups and materials (top left),
## wave and wave countdown (top center), owned weapons with their tier (bottom left).
## Read-only: listens to signals and reads state, never changes it.

var _weapons: WeaponHolder
var _weapons_box: VBoxContainer
var _hp_bar: ProgressBar
var _hp_label: Label
var _xp_bar: ProgressBar
var _level_label: Label
var _materials_label: Label
var _timer_label: Label
var _wave_label: Label
var _waves: WaveDirector
var _progression: Progression
var _last_second: int = -1
var _last_pending: int = -1
var _level: int = 1


func setup(player: Player, progression: Progression, waves: WaveDirector, wallet: Wallet) -> void:
	_waves = waves
	_progression = progression
	player.health_changed.connect(_on_health_changed)
	progression.xp_changed.connect(_on_xp_changed)
	progression.leveled_up.connect(_on_leveled_up)
	_on_health_changed(player.hp, player.stats.get_value(StatIds.MAX_HP))
	_on_xp_changed(progression.xp, progression.xp_needed())
	_on_leveled_up(progression.level)
	wallet.changed.connect(_on_materials_changed)
	_on_materials_changed(wallet.amount)
	_weapons = player.weapons
	_weapons.weapons_changed.connect(_refresh_weapons)
	_refresh_weapons()


func _refresh_weapons() -> void:
	for child in _weapons_box.get_children():
		child.queue_free()
	for slot in _weapons.get_slots():
		var label := _make_label(24)
		label.text = "%s  %s" % [tr(slot.data.name_key), Tiers.roman(slot.level)]
		label.add_theme_color_override("font_color", slot.data.color)
		_weapons_box.add_child(label)


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

	_materials_label = _make_label(28)
	_materials_label.add_theme_color_override("font_color", Color(0.45, 1.0, 0.55))
	box.add_child(_materials_label)

	_wave_label = _make_label(28)
	_wave_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wave_label.offset_top = 24
	_wave_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	root.add_child(_wave_label)

	_timer_label = _make_label(40)
	_timer_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.offset_top = 60
	_timer_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	root.add_child(_timer_label)

	_weapons_box = VBoxContainer.new()
	_weapons_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_weapons_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_weapons_box.offset_left = 32
	_weapons_box.offset_bottom = -32
	_weapons_box.add_theme_constant_override("separation", 2)
	root.add_child(_weapons_box)


func _process(_delta: float) -> void:
	if _waves == null:
		return
	var seconds := ceili(_waves.time_left)
	if seconds != _last_second:
		_last_second = seconds
		_timer_label.text = format_time(seconds)
		_wave_label.text = "%s %d/%d" % [tr("UI_WAVE"), _waves.wave, _waves.wave_count()]
	if _progression.pending_level_ups != _last_pending:
		_last_pending = _progression.pending_level_ups
		_refresh_level()


static func format_time(seconds: float) -> String:
	var total := int(seconds)
	return "%02d:%02d" % [total / 60, total % 60]


func _on_health_changed(hp: float, max_hp: float) -> void:
	_hp_bar.max_value = max_hp
	_hp_bar.value = hp
	_hp_label.text = "%d / %d" % [ceili(hp), roundi(max_hp)]


func _on_materials_changed(amount: int) -> void:
	_materials_label.text = "%s %d" % [tr("UI_MATERIALS"), amount]


func _on_xp_changed(xp: int, needed: int) -> void:
	_xp_bar.max_value = needed
	_xp_bar.value = xp


func _on_leveled_up(level: int) -> void:
	_level = level
	_refresh_level()


func _refresh_level() -> void:
	var pending := _progression.pending_level_ups if _progression != null else 0
	_level_label.text = "%s %d" % [tr("UI_LEVEL"), _level]
	if pending > 0:
		_level_label.text += "  (+%d)" % pending


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
