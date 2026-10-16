class_name ChestRewardScreen
extends CanvasLayer
## What a boss chest gave: one card per reward (icon, name, effect), shown until the player validates.
## Display only: Run pauses the game around it and gives the rewards before opening it.

signal closed

const CARD_WIDTH := 300.0
const ICON_SIZE := 110.0

var _title: Label
var _cards: HBoxContainer
var _validate: Button


func _init() -> void:
	layer = 29
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiTheme.get_theme()
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(UiTheme.DIM, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.window_style())
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 26)
	panel.add_child(box)
	_title = Label.new()
	_title.text = "UI_CHEST_REWARDS"
	_title.theme_type_variation = &"TitleLabel"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_color_override("font_color", UiTheme.GOLD)
	box.add_child(_title)
	_cards = HBoxContainer.new()
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards.add_theme_constant_override("separation", 22)
	box.add_child(_cards)
	_validate = Button.new()
	_validate.text = "UI_VALIDATE"
	_validate.theme_type_variation = &"BigButton"
	_validate.custom_minimum_size = Vector2(340, 84)
	_validate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_validate.pressed.connect(close)
	box.add_child(_validate)


## `rewards`: [{"item": ItemData, "title": "" (solo) or "Player 2", "color": Color}, ...].
func open(rewards: Array[Dictionary]) -> void:
	for child in _cards.get_children():
		_cards.remove_child(child)
		child.queue_free()
	var delay := 0.1
	for reward in rewards:
		var card := _card(reward)
		_cards.add_child(card)
		UiFx.pop_in(card, delay)
		delay += 0.15
	visible = true
	UiFx.pop_in(_title)
	_validate.grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func card_count() -> int:
	return _cards.get_child_count()


func _card(reward: Dictionary) -> Control:
	var item: ItemData = reward.item
	var accent := Tiers.color(item.tier)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(CARD_WIDTH, 0.0)
	panel.add_theme_stylebox_override("panel", UiTheme.card_style(accent, 0.9))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	if reward.title != "":
		var who := Label.new()
		who.text = reward.title
		who.theme_type_variation = &"SubtitleLabel"
		who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		who.add_theme_color_override("font_color", reward.color)
		box.add_child(who)
	var icon := IconTile.create(item.icon, item.tier, ICON_SIZE)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(icon)
	var name_label := Label.new()
	name_label.text = item.name_key
	name_label.theme_type_variation = &"SubtitleLabel"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size.x = CARD_WIDTH - 40.0
	name_label.add_theme_color_override("font_color", accent)
	box.add_child(name_label)
	var text := LevelUpScreen.describe_modifiers(item.modifiers)
	if item.effect_key != "":
		text += ("\n" if text != "" else "") + TranslationServer.translate(item.effect_key)
	var effect := Label.new()
	effect.text = text
	effect.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect.custom_minimum_size.x = CARD_WIDTH - 40.0
	box.add_child(effect)
	return panel
