class_name StatsPanel
extends PanelContainer
## Current player stats, one line per stat (StatIds order): bonus percent for
## multipliers, value otherwise. Green above the base value, red below.
## Read-only: listens to StatBlock.changed. Used by the shop and the HUD (Tab).

## Stats stored as multipliers (1.0 = +0 %): shown as a bonus percent.
const MULTIPLIER_STATS: Array[StringName] = [StatIds.DAMAGE, StatIds.ATTACK_SPEED,
	StatIds.PROJECTILE_SPEED, StatIds.KNOCKBACK, StatIds.RANGE, StatIds.AREA]
const BETTER := Color(0.45, 1.0, 0.55)
const WORSE := Color(1.0, 0.4, 0.4)
const NEUTRAL := Color(0.92, 0.94, 1.0)

var _stats: StatBlock
var _grid: GridContainer
var _values: Dictionary[StringName, Label] = {}


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1, 0.92)
	style.border_color = Color(0.4, 0.95, 1.0, 0.6)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(16)
	add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	var title := Label.new()
	title.text = "UI_STATS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.4, 0.95, 1.0))
	box.add_child(title)
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 24)
	_grid.add_theme_constant_override("v_separation", 4)
	box.add_child(_grid)


func setup(stats: StatBlock) -> void:
	_stats = stats
	for stat: StringName in StatIds.DEFAULTS:
		var name_label := _label(NEUTRAL)
		name_label.text = StatIds.localization_key(stat)
		_grid.add_child(name_label)
		var value_label := _label(NEUTRAL)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_grid.add_child(value_label)
		_values[stat] = value_label
		_refresh(stat)
	stats.changed.connect(_refresh)


func line_count() -> int:
	return _values.size()


func value_text(stat: StringName) -> String:
	return _values[stat].text


static func format_value(stat: StringName, value: float) -> String:
	if stat in MULTIPLIER_STATS:
		return "%+d%%" % roundi((value - 1.0) * 100.0)
	if stat in StatIds.SHOWN_AS_PERCENT:
		return "%d%%" % roundi(value * 100.0)
	if stat == StatIds.CRIT_DAMAGE:
		return "x" + _short(value)
	if stat in StatIds.INTEGER_STATS:
		return "%+d" % roundi(value)
	return _short(value)


static func _short(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return "%d" % roundi(value)
	return "%.1f" % value


func _refresh(stat: StringName) -> void:
	if not _values.has(stat):
		return
	var value := _stats.get_value(stat)
	var base := _stats.get_base(stat)
	var label := _values[stat]
	label.text = format_value(stat, value)
	var color := NEUTRAL
	if value > base + 0.0001:
		color = BETTER
	elif value < base - 0.0001:
		color = WORSE
	label.add_theme_color_override("font_color", color)


func _label(color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", color)
	return label
