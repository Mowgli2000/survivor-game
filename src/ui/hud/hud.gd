class_name Hud
extends CanvasLayer
## In-run HUD: XP bar (top), HP bar + level, pending level-ups and materials (top left),
## wave and wave countdown (top center), owned weapon icons framed by tier (bottom left).
## Holding `show_stats` (Tab / gamepad Select) shows the stats panel.
## Read-only: listens to signals and reads state, never changes it.

const WEAPON_ICON := 56.0

## Seconds a toast stays fully visible.
const TOAST_TIME := 2.5

var _weapons: WeaponHolder
var _weapons_box: HBoxContainer
var _hp_bar: ProgressBar
var _hp_label: Label
var _xp_bar: ProgressBar
var _level_label: Label
var _materials_label: Label
## Materials to display; the label is refreshed once per frame (pickups can
## change the amount many times per frame).
var _materials: int = 0
var _shown_materials: int = -1
var _stats_panel: StatsPanel
var _timer_label: Label
var _wave_label: Label
var _waves: WaveDirector
var _progression: Progression
var _last_second: int = -1
var _last_pending: int = -1
var _level: int = 1
var _boss_bar: BossBar
var _toast: Label
var _root: Control
## Player 1's block (top left): gets a "P1" tag in coop.
var _p1_box: VBoxContainer


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
	_stats_panel.setup(player.stats)
	_weapons = player.weapons
	_weapons.weapons_changed.connect(_refresh_weapons)
	_refresh_weapons()


## Coop (ADR 0017): compact block for player 2 (top right) and a tag on player 1's.
func setup_second_player(player: Player, progression: Progression, wallet: Wallet, color: Color) -> void:
	var tag_1 := _make_label(&"SubtitleLabel", 24)
	tag_1.text = tr("UI_PLAYER_N") % 1
	tag_1.add_theme_color_override("font_color", RunPlayer.COLORS[0])
	_p1_box.add_child(tag_1)
	_p1_box.move_child(tag_1, 0)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	box.offset_right = -32
	box.offset_top = 40
	box.add_theme_constant_override("separation", 6)
	_root.add_child(box)
	var tag := _make_label(&"SubtitleLabel", 24)
	tag.text = tr("UI_PLAYER_N") % 2
	tag.add_theme_color_override("font_color", color)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(tag)
	var hp_bar := _make_bar(UiTheme.BAD)
	hp_bar.custom_minimum_size = Vector2(320, 32)
	box.add_child(hp_bar)
	var hp_label := _make_label(&"ValueLabel", 20)
	hp_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_bar.add_child(hp_label)
	var xp_bar := _make_bar(UiTheme.XP)
	xp_bar.custom_minimum_size = Vector2(320, 10)
	box.add_child(xp_bar)
	var info := _make_label(&"ValueLabel", 24)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(info)

	var refresh_hp := func(hp: float, max_hp: float) -> void:
		hp_bar.max_value = max_hp
		hp_bar.value = hp
		hp_label.text = "%d / %d" % [ceili(hp), roundi(max_hp)] if not player.is_dead else tr("UI_PLAYER_DOWN")
	var refresh_xp := func(xp: int, needed: int) -> void:
		xp_bar.max_value = needed
		xp_bar.value = xp
	var refresh_info := func(_value: int = 0) -> void:
		info.text = "%s %d   %s %d" % [tr("UI_LEVEL"), progression.level, tr("UI_MATERIALS"), wallet.amount]
	player.health_changed.connect(refresh_hp)
	player.died.connect(func() -> void: refresh_hp.call(0.0, player.stats.get_value(StatIds.MAX_HP)))
	progression.xp_changed.connect(refresh_xp)
	progression.leveled_up.connect(refresh_info)
	wallet.changed.connect(refresh_info)
	refresh_hp.call(player.hp, player.stats.get_value(StatIds.MAX_HP))
	refresh_xp.call(progression.xp, progression.xp_needed())
	refresh_info.call()


func setup_boss(director: BossDirector) -> void:
	_boss_bar.setup(director)


## Short message under the timer (boss rewards), fades out by itself.
func show_toast(text: String) -> void:
	_toast.text = text
	_toast.visible = true
	_toast.modulate.a = 1.0
	UiFx.pop_in(_toast)
	var tween := _toast.create_tween()
	tween.tween_interval(TOAST_TIME)
	tween.tween_property(_toast, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func() -> void: _toast.visible = false)


## First-time tip at the top of the HUD (HintBanner).
func show_hint(key: StringName) -> void:
	HintBanner.show_once(_root, key)


func toast_text() -> String:
	return _toast.text if _toast.visible else ""


## Weapon family lines in the Tab stats panel.
func setup_families(families: WeaponFamilies) -> void:
	_stats_panel.setup_families(families)


func _refresh_weapons() -> void:
	for child in _weapons_box.get_children():
		_weapons_box.remove_child(child)
		child.queue_free()
	for slot in _weapons.get_slots():
		if slot.data.icon == null:
			var label := _make_label(&"ValueLabel", 24)
			label.text = "%s  %s" % [tr(slot.data.name_key), Tiers.roman(slot.level)]
			label.add_theme_color_override("font_color", Tiers.color(slot.level))
			_weapons_box.add_child(label)
			continue
		var tile := IconTile.create(slot.data.icon, slot.level, WEAPON_ICON)
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_weapons_box.add_child(tile)


func _init() -> void:
	layer = 10
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiTheme.get_theme()
	add_child(root)
	_root = root

	_xp_bar = _make_bar(UiTheme.XP)
	_xp_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_xp_bar.offset_left = 8
	_xp_bar.offset_right = -8
	_xp_bar.offset_top = 6
	_xp_bar.offset_bottom = 22
	root.add_child(_xp_bar)

	var box := VBoxContainer.new()
	box.position = Vector2(32, 40)
	box.add_theme_constant_override("separation", 8)
	root.add_child(box)
	_p1_box = box

	_hp_bar = _make_bar(UiTheme.BAD)
	_hp_bar.custom_minimum_size = Vector2(380, 38)
	box.add_child(_hp_bar)
	_hp_label = _make_label(&"ValueLabel", 22)
	_hp_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hp_bar.add_child(_hp_label)

	_level_label = _make_label(&"ValueLabel", 28)
	box.add_child(_level_label)

	_materials_label = _make_label(&"ValueLabel", 28)
	_materials_label.add_theme_color_override("font_color", UiTheme.GOOD)
	box.add_child(_materials_label)

	_wave_label = _make_label(&"SubtitleLabel", 30)
	_wave_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wave_label.offset_top = 28
	_wave_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	root.add_child(_wave_label)

	_timer_label = _make_label(&"TitleLabel", 48)
	_timer_label.add_theme_color_override("font_color", UiTheme.TEXT)
	_timer_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.offset_top = 64
	_timer_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	root.add_child(_timer_label)

	_boss_bar = BossBar.new()
	_boss_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_boss_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_boss_bar.offset_top = 128
	root.add_child(_boss_bar)

	_toast = _make_label(&"SubtitleLabel", 34)
	_toast.add_theme_color_override("font_color", UiTheme.GOLD)
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.offset_top = 210
	_toast.visible = false
	root.add_child(_toast)

	_weapons_box = HBoxContainer.new()
	_weapons_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_weapons_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_weapons_box.offset_left = 32
	_weapons_box.offset_bottom = -32
	_weapons_box.add_theme_constant_override("separation", 8)
	root.add_child(_weapons_box)

	_stats_panel = StatsPanel.new()
	_stats_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	_stats_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_stats_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_stats_panel.offset_right = -32
	_stats_panel.visible = false
	root.add_child(_stats_panel)

	var hint := _make_label(&"SmallLabel", 18)
	hint.text = "UI_STATS_HINT"
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hint.offset_right = -24
	hint.offset_bottom = -16
	root.add_child(hint)


func _process(_delta: float) -> void:
	_stats_panel.visible = Input.is_action_pressed("show_stats")
	if _materials != _shown_materials:
		var from := maxi(_shown_materials, 0)
		_shown_materials = _materials
		UiFx.count_to(_materials_label, from, _materials, tr("UI_MATERIALS") + " %d")
	if _waves == null:
		return
	var seconds := ceili(_waves.time_left)
	if seconds != _last_second:
		_last_second = seconds
		_timer_label.text = format_time(seconds)
		if _waves.wave > _waves.wave_count():
			_wave_label.text = tr("UI_WAVE_ENDLESS") % _waves.wave
		else:
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
	_materials = amount


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
	var styles := UiTheme.bar_styles(fill_color)
	bar.add_theme_stylebox_override("background", styles[0])
	bar.add_theme_stylebox_override("fill", styles[1])
	return bar


func _make_label(variation: StringName, size: int) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.add_theme_font_size_override("font_size", size)
	return label
