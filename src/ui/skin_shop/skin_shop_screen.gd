class_name SkinShopScreen
extends Control
## Skin shop (ADR 0023): one tab per class, the skins of that class with their price
## in portal shards, buy or "Owned". Shards come from collection challenges only.
## Buying goes through SaveService.buy_skin; this screen only displays and asks.

signal closed

const CARD_ART_SIZE := Vector2(210, 300)
const TAB_SIZE := Vector2(190, 64)

var _shards: Label
var _tabs: HBoxContainer
var _cards: HBoxContainer
var _empty: Label
var _back: Button
var _character_id: StringName = &""
var _tab_buttons: Dictionary[StringName, Button] = {}


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.get_theme()
	visible = false
	var dim := ColorRect.new()
	dim.color = UiTheme.DIM
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	var title := Label.new()
	title.text = "UI_SKIN_SHOP"
	title.theme_type_variation = &"SubtitleLabel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_shards = Label.new()
	_shards.theme_type_variation = &"ValueLabel"
	_shards.add_theme_color_override("font_color", UiTheme.VIOLET)
	_shards.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_shards)
	_tabs = HBoxContainer.new()
	_tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	_tabs.add_theme_constant_override("separation", 10)
	box.add_child(_tabs)
	var area := CenterContainer.new()
	area.custom_minimum_size = Vector2(1100, 470)
	box.add_child(area)
	_cards = HBoxContainer.new()
	_cards.add_theme_constant_override("separation", 22)
	area.add_child(_cards)
	_empty = Label.new()
	_empty.text = "UI_SKIN_SHOP_EMPTY"
	_empty.theme_type_variation = &"SmallLabel"
	_empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	area.add_child(_empty)
	_back = Button.new()
	_back.text = "UI_BACK"
	_back.custom_minimum_size = Vector2(260, 64)
	_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_back.pressed.connect(close)
	box.add_child(_back)
	SaveService.profile_changed.connect(_refresh_shards)


func open() -> void:
	_build_tabs()
	_refresh_shards()
	visible = true
	var first: Button = _tab_buttons.get(_character_id)
	(first if first != null else _back).grab_focus()
	UiFx.pop_in(self)


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


## The class shown (tests).
func character_id() -> StringName:
	return _character_id


## The skin cards on screen, in order (tests).
func card_count() -> int:
	return _cards.get_child_count()


## Buy buttons of the skins on screen, in order (tests).
func buy_buttons() -> Array[Button]:
	var buttons: Array[Button] = []
	for card in _cards.get_children():
		buttons.append(card.get_meta(&"buy") as Button)
	return buttons


## Skins of a class, cheapest first.
static func skins_of(character_id: StringName) -> Array[SkinData]:
	var skins: Array[SkinData] = []
	for def in ContentDB.get_all(&"skins"):
		var skin := def as SkinData
		if skin != null and skin.character_id == character_id:
			skins.append(skin)
	skins.sort_custom(func(a: SkinData, b: SkinData) -> bool:
		return a.price < b.price or (a.price == b.price and a.id < b.id))
	return skins


func _build_tabs() -> void:
	for child in _tabs.get_children():
		_tabs.remove_child(child)
		child.queue_free()
	_tab_buttons.clear()
	var classes: Array[CharacterData] = []
	for def in ContentDB.get_all(&"characters"):
		classes.append(def as CharacterData)
	for character in classes:
		var button := Button.new()
		button.text = character.name_key
		button.toggle_mode = true
		button.custom_minimum_size = TAB_SIZE
		button.pressed.connect(_show_class.bind(character.id))
		_tabs.add_child(button)
		_tab_buttons[character.id] = button
	if not _tab_buttons.has(_character_id) and not classes.is_empty():
		_character_id = classes[0].id
	_show_class(_character_id)


func _show_class(character_id: StringName) -> void:
	_character_id = character_id
	for id in _tab_buttons:
		_tab_buttons[id].button_pressed = id == character_id
	for child in _cards.get_children():
		_cards.remove_child(child)
		child.queue_free()
	var skins := skins_of(character_id)
	_empty.visible = skins.is_empty()
	for skin in skins:
		_cards.add_child(_card(skin))


func _card(skin: SkinData) -> Control:
	var owned := SaveService.profile.is_unlocked(&"skins", skin.id)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.card_style(Tiers.color(skin.rarity)))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var rarity := Label.new()
	rarity.text = "UI_SKIN_RARITY_%d" % skin.rarity
	rarity.theme_type_variation = &"SmallLabel"
	rarity.add_theme_color_override("font_color", Tiers.color(skin.rarity))
	rarity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(rarity)
	var art := TextureRect.new()
	art.texture = skin.card_art
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.custom_minimum_size = CARD_ART_SIZE
	box.add_child(art)
	var name_label := Label.new()
	name_label.text = skin.name_key
	name_label.theme_type_variation = &"SubtitleLabel"
	name_label.add_theme_font_size_override("font_size", 26)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name_label)
	var buy := Button.new()
	buy.custom_minimum_size = Vector2(0, 60)
	if owned:
		buy.text = "UI_SKIN_OWNED"
		buy.disabled = true
	elif not SaveService.is_skin_available(skin):
		buy.text = tr("UI_SKIN_NEEDS_SEAL") % tr("DANGER_%d" % skin.required_seal)
		buy.disabled = true
	else:
		buy.text = tr("UI_SKIN_BUY") % skin.price
		if SaveService.profile.shards < skin.price:
			buy.add_theme_color_override("font_color", UiTheme.BAD)
		buy.pressed.connect(_buy.bind(skin))
	box.add_child(buy)
	panel.set_meta(&"buy", buy)
	return panel


func _buy(skin: SkinData) -> void:
	if SaveService.buy_skin(skin):
		Audio.play(Sounds.UI_BUY, -4.0)
		_show_class(_character_id)
		var buttons := buy_buttons()
		if not buttons.is_empty():
			buttons[0].grab_focus()
	else:
		Audio.play(Sounds.UI_ERROR, -8.0)


func _refresh_shards() -> void:
	_shards.text = tr("UI_SKIN_SHARDS") % SaveService.profile.shards


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		close()
