class_name BossBar
extends VBoxContainer
## Boss name + HP bar at the top of the screen (ADR 0014): one row per living boss
## (a double boss shows two). A row is added on BossDirector.boss_started and removed on
## boss_ended; HP is read each frame while visible (UI reads state, never changes it).

const BAR_SIZE := Vector2(720, 26)
## Rows shrink when several bosses share the screen.
const BAR_SIZE_MULTI := Vector2(560, 18)

class Row:
	var boss: Enemy
	var box: VBoxContainer
	var name_label: Label
	var bar: ProgressBar


var _rows: Array[Row] = []


func _init() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 6)


func setup(director: BossDirector) -> void:
	director.boss_started.connect(_on_boss_started)
	director.boss_ended.connect(_on_boss_ended)


func _process(_delta: float) -> void:
	for row in _rows:
		row.bar.value = maxf(row.boss.hp, 0.0)


func _on_boss_started(enemy: Enemy) -> void:
	var row := Row.new()
	row.boss = enemy
	row.box = VBoxContainer.new()
	row.box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.box.add_theme_constant_override("separation", 2)
	row.name_label = Label.new()
	row.name_label.theme_type_variation = &"SubtitleLabel"
	row.name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.name_label.text = enemy.data.name_key
	row.name_label.add_theme_color_override("font_color", enemy.data.color)
	row.box.add_child(row.name_label)
	row.bar = ProgressBar.new()
	row.bar.show_percentage = false
	row.bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var styles := UiTheme.bar_styles(enemy.data.color)
	row.bar.add_theme_stylebox_override("background", styles[0])
	row.bar.add_theme_stylebox_override("fill", styles[1])
	row.bar.max_value = enemy.max_hp
	row.bar.value = enemy.hp
	row.box.add_child(row.bar)
	add_child(row.box)
	_rows.append(row)
	_layout()
	if not visible:
		visible = true
		UiFx.pop_in(self)
	else:
		UiFx.pop_in(row.box)


func _on_boss_ended(enemy: Enemy) -> void:
	for i in _rows.size():
		if _rows[i].boss == enemy:
			_rows[i].box.queue_free()
			_rows.remove_at(i)
			break
	_layout()
	visible = not _rows.is_empty()


func _layout() -> void:
	var multi := _rows.size() > 1
	for row in _rows:
		row.bar.custom_minimum_size = BAR_SIZE_MULTI if multi else BAR_SIZE
		row.name_label.add_theme_font_size_override("font_size", 16 if multi else 20)
