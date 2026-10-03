class_name StatsPanel
extends PanelContainer
## Current player stats, one line per stat (StatIds order): bonus percent for
## multipliers, value otherwise. Green above the base value, red below.
## Read-only: listens to StatBlock.changed. Used by the shop and the HUD (Tab).

## Stats stored as multipliers (1.0 = +0 %): shown as a bonus percent.
const MULTIPLIER_STATS: Array[StringName] = [StatIds.DAMAGE, StatIds.ATTACK_SPEED,
	StatIds.PROJECTILE_SPEED, StatIds.KNOCKBACK, StatIds.RANGE, StatIds.AREA]
const BETTER := UiTheme.GOOD
const WORSE := UiTheme.BAD
const NEUTRAL := UiTheme.TEXT

var _stats: StatBlock
var _grid: GridContainer
var _values: Dictionary[StringName, Label] = {}
var _families: WeaponFamilies
var _family_box: VBoxContainer
var _family_values: Dictionary[StringName, Label] = {}
var _family_active: Dictionary[StringName, Label] = {}
var _family_next: Dictionary[StringName, Label] = {}


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UiTheme.get_theme()

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	var title := Label.new()
	title.text = "UI_STATS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_type_variation = &"SubtitleLabel"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", UiTheme.ACCENT)
	box.add_child(title)
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 24)
	_grid.add_theme_constant_override("v_separation", 4)
	box.add_child(_grid)
	_family_box = VBoxContainer.new()
	_family_box.add_theme_constant_override("separation", 2)
	box.add_child(_family_box)


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


## Adds one line per weapon family: owned count / next tier (green when a bonus
## is active), then the active bonus and the next tier's bonus.
func setup_families(families: WeaponFamilies) -> void:
	_families = families
	var title := Label.new()
	title.text = "UI_FAMILIES"
	title.theme_type_variation = &"SmallLabel"
	_family_box.add_child(title)
	for family in families.get_families():
		var row := HBoxContainer.new()
		_family_box.add_child(row)
		var name_label := _label(family.color)
		name_label.text = family.name_key
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		var value_label := _label(NEUTRAL)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(value_label)
		_family_values[family.id] = value_label
		_family_active[family.id] = _detail_label(BETTER)
		_family_next[family.id] = _detail_label(UiTheme.MUTED)
	families.changed.connect(_refresh_families)
	_refresh_families()


func family_text(family_id: StringName) -> String:
	return _family_values[family_id].text


func family_active_text(family_id: StringName) -> String:
	return _family_active[family_id].text


func family_next_text(family_id: StringName) -> String:
	return _family_next[family_id].text


## "Active: +5% Crit Chance" for the reached tier, "" when none.
static func active_bonus_text(family: FamilyData, owned: int) -> String:
	var bonus := family.bonus_for(owned)
	if bonus == null:
		return ""
	return TranslationServer.translate("UI_FAMILY_ACTIVE") % _modifiers_inline(bonus.modifiers)


## "At 4: +10% Crit Chance, +20% Crit Damage" for the next tier, "" at max.
static func next_bonus_text(family: FamilyData, owned: int) -> String:
	for bonus in family.bonuses:
		if bonus.count > owned:
			return TranslationServer.translate("UI_FAMILY_NEXT") % [bonus.count, _modifiers_inline(bonus.modifiers)]
	return ""


static func _modifiers_inline(mods: Array[StatModifier]) -> String:
	return LevelUpScreen.describe_modifiers(mods).replace("\n", ", ")


func _refresh_families() -> void:
	for family in _families.get_families():
		var owned := _families.count(family.id)
		var next := 0
		for bonus in family.bonuses:
			if bonus.count > owned:
				next = bonus.count
				break
		var label := _family_values[family.id]
		label.text = "%d/%d" % [owned, next] if next > 0 else "%d MAX" % owned
		label.add_theme_color_override("font_color", BETTER if _families.active_bonus(family) != null else NEUTRAL)
		_set_detail(_family_active[family.id], active_bonus_text(family, owned))
		_set_detail(_family_next[family.id], next_bonus_text(family, owned))


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


## Detail line under a family; wraps so it never widens the panel.
func _detail_label(color: Color) -> Label:
	var label := _label(color)
	label.add_theme_font_size_override("font_size", 15)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_family_box.add_child(label)
	return label


func _set_detail(label: Label, text: String) -> void:
	label.text = text
	label.visible = text != ""


func _label(color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 19)
	label.add_theme_color_override("font_color", color)
	return label
