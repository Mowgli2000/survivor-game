class_name LevelUpScreen
extends CanvasLayer
## Shown while the game is paused: one neon card per offer (stat upgrade, new
## weapon, weapon level). Keyboard/gamepad navigable; emits `offer_chosen` and
## lets run.gd apply it.

signal offer_chosen(offer: UpgradeOffer)

## Short delay before cards accept input, to avoid accidental picks.
const INPUT_DELAY := 0.35
const CARD_SIZE := Vector2(360, 340)
const STAT_ACCENT := Color(0.55, 0.65, 0.9)
const CARD_BG := Color(0.05, 0.05, 0.1, 0.96)

var _cards: HBoxContainer
var _offers: Array[UpgradeOffer] = []


func _init() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 40)
	center.add_child(box)

	var title := Label.new()
	title.text = "UI_LEVEL_UP"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.4, 0.95, 1.0))
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "UI_CHOOSE_UPGRADE"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 28)
	box.add_child(subtitle)

	_cards = HBoxContainer.new()
	_cards.add_theme_constant_override("separation", 32)
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(_cards)


func open(offers: Array[UpgradeOffer]) -> void:
	_offers = offers
	for child in _cards.get_children():
		child.queue_free()
	var buttons: Array[Button] = []
	for i in offers.size():
		var button := _make_card(offers[i])
		button.disabled = true
		button.pressed.connect(_on_card_pressed.bind(i))
		_cards.add_child(button)
		buttons.append(button)
	visible = true
	await get_tree().create_timer(INPUT_DELAY, true).timeout
	# A newer open() may have replaced these cards during the delay.
	if buttons.is_empty() or not is_instance_valid(buttons[0]) or buttons[0].is_queued_for_deletion():
		return
	for button in buttons:
		button.disabled = false
	buttons[0].grab_focus()


func close() -> void:
	visible = false


## Card texts: [tag, title, description].
static func describe_offer(offer: UpgradeOffer) -> PackedStringArray:
	match offer.kind:
		UpgradeOffer.Kind.NEW_WEAPON:
			return PackedStringArray([TranslationServer.translate("UI_NEW_WEAPON"),
				TranslationServer.translate(offer.weapon.name_key),
				TranslationServer.translate(offer.weapon.description_key)])
		UpgradeOffer.Kind.WEAPON_LEVEL:
			return PackedStringArray(["%s %d" % [TranslationServer.translate("UI_LEVEL"), offer.level],
				TranslationServer.translate(offer.weapon.name_key),
				describe_weapon_level(offer.weapon.levels[offer.level - 2])])
		_:
			return PackedStringArray([TranslationServer.translate("UI_STAT_UPGRADE"),
				TranslationServer.translate(offer.upgrade.name_key), describe(offer.upgrade)])


static func describe(upgrade: UpgradeData) -> String:
	var lines: PackedStringArray = []
	for mod in upgrade.modifiers:
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
	var accent := STAT_ACCENT if offer.weapon == null else offer.weapon.color
	var texts := describe_offer(offer)

	var button := Button.new()
	button.custom_minimum_size = CARD_SIZE
	button.add_theme_stylebox_override("normal", _card_style(accent, 0.6, 3))
	button.add_theme_stylebox_override("hover", _card_style(accent, 1.0, 4))
	button.add_theme_stylebox_override("pressed", _card_style(accent, 1.0, 4))
	button.add_theme_stylebox_override("disabled", _card_style(accent, 0.35, 3))
	var focus := _card_style(Color.WHITE, 1.0, 5)
	focus.draw_center = false
	button.add_theme_stylebox_override("focus", focus)

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

	box.add_child(_card_label(texts[0].to_upper(), 20, Color(accent, 0.85)))
	box.add_child(_card_label(texts[1], 34, accent))
	box.add_child(_card_label(texts[2], 24, Color(0.92, 0.94, 1.0)))
	return button


func _card_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = CARD_SIZE.x - 40.0
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _card_style(accent: Color, strength: float, border: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = CARD_BG.lerp(Color(accent, 1.0), 0.08 * strength)
	style.border_color = Color(accent, strength)
	style.set_border_width_all(border)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(accent, 0.25 * strength)
	style.shadow_size = 12
	return style


func _on_card_pressed(index: int) -> void:
	if index < _offers.size():
		offer_chosen.emit(_offers[index])
