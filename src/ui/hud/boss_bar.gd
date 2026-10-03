class_name BossBar
extends VBoxContainer
## Boss name + HP bar at the top of the screen (ADR 0014). Shown on
## BossDirector.boss_started, hidden on boss_ended; reads the boss HP each
## frame while visible (UI reads state, never changes it).

const BAR_SIZE := Vector2(720, 26)

var _boss: Enemy
var _name: Label
var _bar: ProgressBar


func _init() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 4)
	_name = Label.new()
	_name.theme_type_variation = &"SubtitleLabel"
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_name)
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.custom_minimum_size = BAR_SIZE
	add_child(_bar)


func setup(director: BossDirector) -> void:
	director.boss_started.connect(_on_boss_started)
	director.boss_ended.connect(_on_boss_ended)


func _process(_delta: float) -> void:
	if visible and _boss != null:
		_bar.value = maxf(_boss.hp, 0.0)


func _on_boss_started(enemy: Enemy) -> void:
	if _boss != null and _boss.is_alive():
		return  # one bar: the first boss keeps it
	_boss = enemy
	_name.text = enemy.data.name_key
	_name.add_theme_color_override("font_color", enemy.data.color)
	var styles := UiTheme.bar_styles(enemy.data.color)
	_bar.add_theme_stylebox_override("background", styles[0])
	_bar.add_theme_stylebox_override("fill", styles[1])
	_bar.max_value = enemy.max_hp
	_bar.value = enemy.hp
	visible = true
	UiFx.pop_in(self)


func _on_boss_ended(enemy: Enemy) -> void:
	if enemy == _boss:
		_boss = null
		visible = false
