class_name LevelUpScreen
extends CanvasLayer
## Shown while the game is paused: one card (button) per upgrade choice.
## Keyboard/gamepad navigable; emits `upgrade_chosen` and lets run.gd apply it.

signal upgrade_chosen(upgrade: UpgradeData)

## Short delay before cards accept input, to avoid accidental picks.
const INPUT_DELAY := 0.35

var _cards: HBoxContainer
var _choices: Array[UpgradeData] = []


func _init() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
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


func open(choices: Array[UpgradeData]) -> void:
	_choices = choices
	for child in _cards.get_children():
		child.queue_free()
	var buttons: Array[Button] = []
	for i in choices.size():
		var button := _make_card(choices[i])
		button.disabled = true
		button.pressed.connect(_on_card_pressed.bind(i))
		_cards.add_child(button)
		buttons.append(button)
	visible = true
	await get_tree().create_timer(INPUT_DELAY, true).timeout
	for button in buttons:
		button.disabled = false
	if not buttons.is_empty():
		buttons[0].grab_focus()


func close() -> void:
	visible = false


static func describe(upgrade: UpgradeData) -> String:
	var lines: PackedStringArray = []
	for mod in upgrade.modifiers:
		var stat_name := TranslationServer.translate(StatIds.localization_key(mod.stat))
		if mod.flat != 0.0:
			lines.append("%s %s" % [_format_flat(mod.stat, mod.flat), stat_name])
		if mod.percent != 0.0:
			lines.append("%+d%% %s" % [roundi(mod.percent * 100.0), stat_name])
	return "\n".join(lines)


static func _format_flat(stat: StringName, value: float) -> String:
	if stat in StatIds.SHOWN_AS_PERCENT:
		return "%+d%%" % roundi(value * 100.0)
	if is_equal_approx(value, roundf(value)):
		return "%+d" % roundi(value)
	return "%+.1f" % value


func _make_card(upgrade: UpgradeData) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(340, 300)
	button.text = "%s\n\n%s" % [tr(upgrade.name_key), describe(upgrade)]
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", 28)
	return button


func _on_card_pressed(index: int) -> void:
	if index < _choices.size():
		upgrade_chosen.emit(_choices[index])
