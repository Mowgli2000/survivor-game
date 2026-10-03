class_name LevelUpScreen
extends CanvasLayer
## Shown while the game is paused: one neon card per offer (stat upgrade, tier
## colored) and a paid reroll button.
## Keyboard/gamepad navigable; emits `offer_chosen` and lets run.gd apply it.

signal offer_chosen(offer: UpgradeOffer)
## Paid reroll of the cards (Run checks and spends the materials).
signal reroll_requested

## Short delay before cards accept input, to avoid accidental picks.
const INPUT_DELAY := 0.35
const CARD_SIZE := Vector2(360, 340)
## Delay between two cards appearing.
const CARD_STAGGER := 0.04

var _cards: HBoxContainer
var _reroll: Button
var _offers: Array[UpgradeOffer] = []
var _title: Label


func _init() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiTheme.get_theme()
	add_child(root)

	var dim := ColorRect.new()
	dim.color = UiTheme.DIM
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 40)
	center.add_child(box)

	var title := Label.new()
	title.text = "UI_LEVEL_UP"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_type_variation = &"TitleLabel"
	box.add_child(title)
	_title = title

	var subtitle := Label.new()
	subtitle.text = "UI_CHOOSE_UPGRADE"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.theme_type_variation = &"SubtitleLabel"
	box.add_child(subtitle)

	_cards = HBoxContainer.new()
	_cards.add_theme_constant_override("separation", 32)
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(_cards)

	_reroll = Button.new()
	_reroll.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_reroll.pressed.connect(func() -> void: reroll_requested.emit())
	box.add_child(_reroll)


## `reroll_cost` < 0 hides the reroll button.
func open(offers: Array[UpgradeOffer], reroll_cost: int = -1, can_reroll: bool = false) -> void:
	_reroll.visible = reroll_cost >= 0
	_reroll.text = tr("UI_SHOP_REROLL") % maxi(reroll_cost, 0)
	_reroll.disabled = true
	_offers = offers
	for child in _cards.get_children():
		child.queue_free()
	var buttons: Array[Button] = []
	for i in offers.size():
		var button := _make_card(offers[i])
		button.disabled = true
		button.pressed.connect(_on_card_pressed.bind(i))
		_cards.add_child(button)
		UiFx.pop_in(button, CARD_STAGGER * i)
		buttons.append(button)
	if not visible:
		UiFx.pop_in(_title)
	visible = true
	await get_tree().create_timer(INPUT_DELAY, true).timeout
	# A newer open() may have replaced these cards during the delay.
	if buttons.is_empty() or not is_instance_valid(buttons[0]) or buttons[0].is_queued_for_deletion():
		return
	for button in buttons:
		button.disabled = false
	_reroll.disabled = not can_reroll
	buttons[0].grab_focus()


func close() -> void:
	visible = false


## Card texts: [tag, title, description].
static func describe_offer(offer: UpgradeOffer) -> PackedStringArray:
	return PackedStringArray(["%s · %s" % [TranslationServer.translate("UI_STAT_UPGRADE"), Tiers.roman(offer.tier)],
		TranslationServer.translate(offer.upgrade.name_key), describe_modifiers(offer.scaled_modifiers())])


static func describe(upgrade: UpgradeData) -> String:
	return describe_modifiers(upgrade.modifiers)


## One line per non-zero part of each modifier ("+8% Damage", "-2 Armor").
static func describe_modifiers(mods: Array[StatModifier]) -> String:
	var lines: PackedStringArray = []
	for mod in mods:
		var stat_name := TranslationServer.translate(StatIds.localization_key(mod.stat))
		if mod.flat != 0.0:
			lines.append("%s %s" % [_format_flat(mod.stat, mod.flat), stat_name])
		if mod.percent != 0.0:
			lines.append("%+d%% %s" % [roundi(mod.percent * 100.0), stat_name])
	return "\n".join(lines)


static func describe_weapon_level(bonus: WeaponLevel) -> String:
	var lines: PackedStringArray = []
	if bonus.damage_percent != 0.0:
		lines.append(_percent_line(bonus.damage_percent, "STAT_DAMAGE"))
	if bonus.fire_rate_percent != 0.0:
		lines.append(_percent_line(bonus.fire_rate_percent, "WSTAT_FIRE_RATE"))
	if bonus.area_percent != 0.0:
		lines.append(_percent_line(bonus.area_percent, "STAT_AREA"))
	if bonus.projectile_count != 0:
		lines.append("%+d %s" % [bonus.projectile_count, TranslationServer.translate("STAT_PROJECTILE_COUNT")])
	if bonus.pierce != 0:
		lines.append("%+d %s" % [bonus.pierce, TranslationServer.translate("STAT_PIERCE")])
	if bonus.bounces != 0:
		lines.append("%+d %s" % [bonus.bounces, TranslationServer.translate("WSTAT_BOUNCES")])
	return "\n".join(lines)


static func _percent_line(value: float, key: String) -> String:
	return "%+d%% %s" % [roundi(value * 100.0), TranslationServer.translate(key)]


static func _format_flat(stat: StringName, value: float) -> String:
	if stat in StatIds.SHOWN_AS_PERCENT:
		return "%+d%%" % roundi(value * 100.0)
	if is_equal_approx(value, roundf(value)):
		return "%+d" % roundi(value)
	return "%+.1f" % value


func _make_card(offer: UpgradeOffer) -> Button:
	var accent := Tiers.color(offer.tier)
	var texts := describe_offer(offer)

	var button := Button.new()
	button.custom_minimum_size = CARD_SIZE
	button.add_theme_stylebox_override("normal", UiTheme.card_style(accent, 0.6))
	button.add_theme_stylebox_override("hover", UiTheme.card_style(accent, 1.0))
	button.add_theme_stylebox_override("pressed", UiTheme.card_style(accent, 1.0))
	button.add_theme_stylebox_override("disabled", UiTheme.card_style(accent, 0.6))
	button.add_theme_stylebox_override("focus", UiTheme.focus_style(Color.WHITE))
	UiFx.hover_lift(button)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	button.add_child(margin)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 18)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(box)

	box.add_child(_card_label(texts[0].to_upper(), &"SmallLabel", 18, accent))
	box.add_child(_card_label(texts[1], &"SubtitleLabel", 36, UiTheme.TEXT))
	box.add_child(_card_label(texts[2], &"", 24, UiTheme.TEXT))
	return button


func _card_label(text: String, variation: StringName, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = CARD_SIZE.x - 40.0
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _on_card_pressed(index: int) -> void:
	if index < _offers.size():
		offer_chosen.emit(_offers[index])
