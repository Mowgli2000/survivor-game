class_name ShopScreen
extends CanvasLayer
## Between waves, after the level-ups: shop slots (buy, lock), reroll, owned
## weapons (sell, merge), owned items, player stats and the "Next wave" button.
## Reads Shop / Wallet / Inventory / WeaponHolder and only calls Shop's API.
## Keyboard/gamepad navigable; focus is restored after each rebuild.

signal next_wave_requested

## Ignores presses right after opening (a held confirm key must not buy).
const INPUT_DELAY_MS := 350
const CARD_SIZE := Vector2(300, 400)
const CARD_ICON := 96.0
const ITEM_ICON := 60.0
const WEAPON_ICON := 40
const CARD_BG := Color(0.05, 0.05, 0.1, 0.96)
const TEXT_COLOR := Color(0.92, 0.94, 1.0)
const TOO_EXPENSIVE := Color(1.0, 0.35, 0.35)

var _shop: Shop
var _wallet: Wallet
var _inventory: Inventory
var _weapons: WeaponHolder
var stats_panel: StatsPanel
var _title: Label
var _materials: Label
var _cards: HBoxContainer
var _reroll: Button
var _weapon_row: HBoxContainer
var _weapon_actions: HBoxContainer
var _items_label: Label
var _items_row: HFlowContainer
var _next: Button
var _selected_weapon: int = -1
## Identifies the focused control across rebuilds ("buy:2", "weapon:1", "next"...).
var _focus_key: String = ""
## True when _focus_key was chosen by code: the next rebuild must not overwrite it
## with the control that happens to be focused.
var _focus_forced: bool = false
var _accept_after: int = 0
var _controls: Dictionary[String, Control] = {}


func setup(shop: Shop, wallet: Wallet, inventory: Inventory, weapons: WeaponHolder,
		stats: StatBlock) -> void:
	stats_panel.setup(stats)
	_shop = shop
	_wallet = wallet
	_inventory = inventory
	_weapons = weapons
	_shop.changed.connect(_rebuild)


func _init() -> void:
	layer = 18
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiTheme.get_theme()
	add_child(root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0.02, 0.06, 0.85)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 24)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 40)
	center.add_child(row)
	row.add_child(box)
	stats_panel = StatsPanel.new()
	stats_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(stats_panel)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 48)
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(header)
	_title = _label(56, Color(0.4, 0.95, 1.0))
	header.add_child(_title)
	_materials = _label(40, Color(0.45, 1.0, 0.55))
	header.add_child(_materials)

	_cards = HBoxContainer.new()
	_cards.add_theme_constant_override("separation", 24)
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(_cards)

	_reroll = _button("", 28)
	_reroll.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_reroll.pressed.connect(_on_reroll)
	box.add_child(_reroll)

	var weapons_title := _label(26, TEXT_COLOR)
	weapons_title.text = "UI_SHOP_WEAPONS"
	box.add_child(weapons_title)
	_weapon_row = HBoxContainer.new()
	_weapon_row.add_theme_constant_override("separation", 12)
	_weapon_row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(_weapon_row)
	_weapon_actions = HBoxContainer.new()
	_weapon_actions.add_theme_constant_override("separation", 12)
	_weapon_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(_weapon_actions)

	var items_box := HBoxContainer.new()
	items_box.add_theme_constant_override("separation", 16)
	items_box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(items_box)
	_items_label = _label(22, TEXT_COLOR)
	_items_label.text = "UI_SHOP_ITEMS"
	items_box.add_child(_items_label)
	_items_row = HFlowContainer.new()
	_items_row.custom_minimum_size.x = 1100
	_items_row.add_theme_constant_override("h_separation", 8)
	_items_row.add_theme_constant_override("v_separation", 8)
	items_box.add_child(_items_row)

	_next = _button("UI_NEXT_WAVE", 36)
	_next.custom_minimum_size = Vector2(380, 80)
	_next.size_flags_horizontal = Control.SIZE_SHRINK_END
	_next.pressed.connect(_on_next)
	box.add_child(_next)


func open() -> void:
	_selected_weapon = -1
	_focus_key = "buy:0"
	_focus_forced = true
	_accept_after = Time.get_ticks_msec() + INPUT_DELAY_MS
	visible = true
	_rebuild()


func close() -> void:
	visible = false


## Card texts: [type · tier, name, effects].
static func describe(offer: ShopOffer) -> PackedStringArray:
	var kind := "UI_SHOP_WEAPON" if offer.is_weapon() else "UI_SHOP_ITEM"
	var tag := "%s · %s" % [TranslationServer.translate(kind), Tiers.roman(offer.tier)]
	if offer.is_weapon():
		return PackedStringArray([tag, TranslationServer.translate(offer.weapon.name_key),
			TranslationServer.translate(offer.weapon.description_key)])
	return PackedStringArray([tag, TranslationServer.translate(offer.item.name_key),
		LevelUpScreen.describe_modifiers(offer.item.modifiers)])


func _rebuild() -> void:
	if not visible or _shop == null:
		return
	if not _focus_forced:
		var focused := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
		for key in _controls:
			if _controls[key] == focused:
				_focus_key = key
	_focus_forced = false
	_controls.clear()
	_title.text = tr("UI_SHOP_TITLE") % _shop.wave
	_materials.text = "%s %d" % [tr("UI_MATERIALS"), _wallet.amount]
	_reroll.text = tr("UI_SHOP_REROLL") % _shop.reroll_cost()
	_reroll.disabled = not _wallet.can_afford(_shop.reroll_cost())
	_controls["reroll"] = _reroll
	_controls["next"] = _next
	_rebuild_cards()
	_rebuild_weapons()
	_rebuild_items()
	_focus_target().grab_focus()


## The control named by _focus_key, or the nearest sensible one. "Next wave" is
## the last resort: a stray confirm press there would skip the whole shop.
func _focus_target() -> Control:
	if _is_focusable(_controls.get(_focus_key)):
		return _controls[_focus_key]
	var card := 0
	if _focus_key.begins_with("buy:") or _focus_key.begins_with("lock:"):
		card = int(_focus_key.get_slice(":", 1))
	for prefix in ["buy:", "lock:"]:
		for distance in _shop.offers.size():
			for index in [card + distance, card - distance]:
				var control: Control = _controls.get("%s%d" % [prefix, index])
				if _is_focusable(control):
					return control
	for key in ["weapon:0", "reroll"]:
		if _is_focusable(_controls.get(key)):
			return _controls[key]
	return _next


func _is_focusable(control: Control) -> bool:
	return control != null and not (control is Button and (control as Button).disabled)


func _rebuild_cards() -> void:
	for child in _cards.get_children():
		child.queue_free()
	for i in _shop.offers.size():
		_cards.add_child(_make_card(i, _shop.offers[i]))


func _make_card(index: int, offer: ShopOffer) -> Control:
	var accent := Tiers.color(offer.tier)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = CARD_SIZE
	panel.add_theme_stylebox_override("panel", _style(accent, 0.25 if offer.sold else 0.8, 3))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	if offer.sold:
		var sold := _label(28, Color(accent, 0.6))
		sold.text = "UI_SHOP_SOLD"
		box.add_child(sold)
		return panel
	var texts := describe(offer)
	var icon := IconTile.create(offer.weapon.icon if offer.is_weapon() else offer.item.icon,
		offer.tier, CARD_ICON)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(icon)
	var tag := _label(18, Color(accent, 0.9))
	tag.text = texts[0].to_upper()
	box.add_child(tag)
	var name_label := _label(28, offer.weapon.color if offer.is_weapon() else accent)
	name_label.text = texts[1]
	box.add_child(name_label)
	var effects := _label(20, TEXT_COLOR)
	effects.text = texts[2]
	effects.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effects.custom_minimum_size.x = CARD_SIZE.x - 24.0
	effects.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(effects)
	var buy := _button(tr("UI_SHOP_BUY") % offer.price, 24)
	buy.disabled = not _shop.can_buy(index)
	if not _wallet.can_afford(offer.price):
		buy.add_theme_color_override("font_disabled_color", TOO_EXPENSIVE)
	buy.pressed.connect(_on_buy.bind(index))
	box.add_child(buy)
	_controls["buy:%d" % index] = buy
	var lock := _button("UI_SHOP_UNLOCK" if offer.locked else "UI_SHOP_LOCK", 20)
	lock.pressed.connect(_on_lock.bind(index))
	box.add_child(lock)
	_controls["lock:%d" % index] = lock
	return panel


func _rebuild_weapons() -> void:
	for child in _weapon_row.get_children():
		child.queue_free()
	for child in _weapon_actions.get_children():
		child.queue_free()
	var slots := _weapons.get_slots()
	if _selected_weapon >= slots.size():
		_selected_weapon = -1
	for i in slots.size():
		var slot := slots[i]
		var button := _button("%s %s" % [tr(slot.data.name_key), Tiers.roman(slot.level)], 22)
		button.add_theme_stylebox_override("normal", _style(Tiers.color(slot.level), 1.0 if i == _selected_weapon else 0.5, 2))
		button.add_theme_color_override("font_color", slot.data.color)
		button.icon = slot.data.icon
		button.add_theme_constant_override("icon_max_width", WEAPON_ICON)
		button.pressed.connect(_on_weapon_selected.bind(i))
		_weapon_row.add_child(button)
		_controls["weapon:%d" % i] = button
	var free := _label(22, Color(TEXT_COLOR, 0.5))
	free.text = "%d / %d" % [slots.size(), _weapons.max_slots]
	_weapon_row.add_child(free)
	if _selected_weapon < 0:
		return
	var sell := _button(tr("UI_SHOP_SELL") % _shop.sell_price(_selected_weapon), 22)
	sell.disabled = not _shop.can_sell(_selected_weapon)
	sell.pressed.connect(_on_sell)
	_weapon_actions.add_child(sell)
	_controls["sell"] = sell
	var merge := _button("UI_SHOP_MERGE", 22)
	merge.disabled = not _shop.can_merge(_selected_weapon)
	merge.pressed.connect(_on_merge)
	_weapon_actions.add_child(merge)
	_controls["merge"] = merge


func _rebuild_items() -> void:
	for child in _items_row.get_children():
		_items_row.remove_child(child)
		child.queue_free()
	for item in _inventory.get_items():
		var count := _inventory.count(item)
		var tile := IconTile.create(item.icon, item.tier, ITEM_ICON, "×%d" % count if count > 1 else "")
		tile.tooltip_text = tr(item.name_key)
		_items_row.add_child(tile)
	if _inventory.get_items().is_empty():
		var none := _label(22, Color(TEXT_COLOR, 0.5))
		none.text = "—"
		_items_row.add_child(none)


func _accepting() -> bool:
	return Time.get_ticks_msec() >= _accept_after


func _on_buy(index: int) -> void:
	if _accepting():
		_play(Sounds.UI_BUY if _shop.buy(index) else Sounds.UI_ERROR)


func _on_lock(index: int) -> void:
	if _accepting():
		_shop.toggle_lock(index)
		_play(Sounds.UI_LOCK)


func _on_reroll() -> void:
	if _accepting():
		_play(Sounds.UI_REROLL if _shop.reroll() else Sounds.UI_ERROR)


func _on_weapon_selected(index: int) -> void:
	_selected_weapon = -1 if index == _selected_weapon else index
	_play(Sounds.UI_SELECT)
	_focus_key = "weapon:%d" % index
	_focus_forced = true
	_rebuild()


func _on_sell() -> void:
	if not _accepting():
		return
	var index := _clear_weapon_selection()
	if _shop.sell_weapon(index) > 0:
		_play(Sounds.UI_SELL)
	else:
		_play(Sounds.UI_ERROR)
		_rebuild()


func _on_merge() -> void:
	if not _accepting():
		return
	var index := _clear_weapon_selection()
	if _shop.merge_weapon(index):
		_play(Sounds.UI_MERGE)
	else:
		_play(Sounds.UI_ERROR)
		_rebuild()


## Before a Shop call: the rebuild it triggers shows no selection and focuses
## the weapon row. Returns the slot that was selected.
func _clear_weapon_selection() -> int:
	var index := _selected_weapon
	_selected_weapon = -1
	_focus_key = "weapon:0"
	_focus_forced = true
	return index


func _on_next() -> void:
	if _accepting():
		_play(Sounds.UI_NEXT)
		next_wave_requested.emit()


func _play(stream: AudioStream) -> void:
	Audio.play(stream, -6.0, 0.0)


func _label(size: int, color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _button(text: String, size: int) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", size)
	return button


func _style(accent: Color, strength: float, border: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = CARD_BG.lerp(Color(accent, 1.0), 0.08 * strength)
	style.border_color = Color(accent, strength)
	style.set_border_width_all(border)
	style.set_corner_radius_all(10)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style
