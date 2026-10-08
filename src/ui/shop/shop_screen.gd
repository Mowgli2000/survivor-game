class_name ShopScreen
extends CanvasLayer
## Between waves, after the level-ups: shop slots (buy, lock), reroll, owned
## weapons (sell, merge), owned items, player stats and the "Next wave" button.
## Reads Shop / Wallet / Inventory / WeaponHolder and only calls Shop's API.
## Keyboard/gamepad navigable; focus is restored after each rebuild.

signal next_wave_requested

## Ignores presses right after opening (a held confirm key must not buy).
const INPUT_DELAY_MS := 350
const CARD_SIZE := Vector2(300, 370)
## Coop: each player's shop fills half of the screen (compact layout).
const COMPACT_CARD_SIZE := Vector2(214, 372)
const COMPACT_ITEMS_WIDTH := 800.0
## Height kept free at the bottom for the pinned "Next wave" button (solo / coop).
const NEXT_AREA := 140.0
const COMPACT_NEXT_AREA := 110.0
const SCROLL_SPEED := 700.0
## Width of the gold ring around two weapons that can be merged.
const MERGE_RING := 4
const SCROLL_DEADZONE := 0.25
const CARD_ICON := 96.0
## Coop: smaller icon, room for the card's text.
const COMPACT_CARD_ICON := 64.0
const ITEM_ICON := 60.0
## With many different items, the tiles shrink so the list stays on 3 rows.
const ITEM_ICON_SMALL := 46.0
const ITEMS_BEFORE_SMALL := 32
const ITEMS_WIDTH := 1100.0
const ITEM_GAP := 8
## Rows of item icons shown before the list scrolls.
const ITEM_ROWS := 2
const WEAPON_ICON := 56
const TEXT_COLOR := UiTheme.TEXT
const TOO_EXPENSIVE := UiTheme.BAD
## Delay between two cards appearing when the shop opens.
const CARD_STAGGER := 0.04

var _stats: StatBlock
var _shop: Shop
var _wallet: Wallet
var _inventory: Inventory
var _weapons: WeaponHolder
var stats_panel: StatsPanel
var _title: Label
var _materials: Label
var _cards: HBoxContainer
var _reroll: Button
var _weapon_row: GridContainer
## Half-screen layout (coop): narrower cards, no stats panel (Tab shows the stats).
var _compact: bool = false
var _card_size := CARD_SIZE
var _items_width := ITEMS_WIDTH
var _weapon_actions: HBoxContainer
var _items_label: Label
var _items_row: HFlowContainer
var _items_scroll: ScrollContainer
var _next: Button
var _selected_weapon: int = -1
## Identifies the focused control across rebuilds ("buy:2", "weapon:1", "next"...).
var _focus_key: String = ""
## True when _focus_key was chosen by code: the next rebuild must not overwrite it
## with the control that happens to be focused.
var _focus_forced: bool = false
var _accept_after: int = 0
var _controls: Dictionary[String, Control] = {}
## Cards appear one after the other only when the shop opens, not on every rebuild.
var _animate_cards: bool = false
## Gamepad whose right stick scrolls the items: its id, -1 none, -2 any (solo).
var scroll_device: int = -2
var _item_popup: PanelContainer
var _item_popup_label: Label
## Card bought just now (bounces once rebuilt), -1 if none.
var _bought_index: int = -1
var _shown_materials: int = -1


## Coop: whose shop it is ("Player 2"), hidden in solo.
var _player_tag: Label

func setup(shop: Shop, wallet: Wallet, inventory: Inventory, weapons: WeaponHolder,
		stats: StatBlock) -> void:
	stats_panel.setup(stats)
	_stats = stats
	_shop = shop
	_wallet = wallet
	_inventory = inventory
	_weapons = weapons
	_shop.changed.connect(_rebuild)


func _init(p_compact: bool = false) -> void:
	layer = 18
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_compact = p_compact
	if _compact:
		_card_size = COMPACT_CARD_SIZE
		_items_width = COMPACT_ITEMS_WIDTH

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
	# "Next wave" is pinned at the bottom (below): the rest is centered above it.
	center.offset_bottom = -(COMPACT_NEXT_AREA if _compact else NEXT_AREA)
	root.add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 40)
	center.add_child(row)
	row.add_child(box)
	stats_panel = StatsPanel.new()
	stats_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stats_panel.set_dense()
	# Solo: the stats sit beside the shop. Coop: no room, Share shows them (StatsOverlay).
	stats_panel.visible = not _compact
	row.add_child(stats_panel)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 48)
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(header)
	_player_tag = _label(32 if _compact else 40, UiTheme.ACCENT, &"SubtitleLabel")
	_player_tag.visible = false
	header.add_child(_player_tag)
	_title = _label(46 if _compact else 64, UiTheme.ACCENT, &"TitleLabel")
	header.add_child(_title)
	_materials = _label(30 if _compact else 40, UiTheme.GOLD, &"ValueLabel")
	header.add_child(_materials)
	# The amount first, then the gold coin ("41 (coin)").
	header.add_child(UiIcons.tile(UiIcons.coin(), 34.0 if _compact else 44.0))

	_cards = HBoxContainer.new()
	_cards.add_theme_constant_override("separation", 10 if _compact else 24)
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(_cards)

	_reroll = _button("", 28)
	UiIcons.put_after_text(_reroll, UiIcons.coin())
	_reroll.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_reroll.pressed.connect(_on_reroll)
	box.add_child(_reroll)

	var weapons_title := _label(28, TEXT_COLOR, &"SubtitleLabel")
	weapons_title.text = "UI_SHOP_WEAPONS"
	box.add_child(weapons_title)
	# A grid (3 per row): a flow container reported its unwrapped width and
	# pushed the whole screen past the edge with six long weapon names.
	_weapon_row = GridContainer.new()
	_weapon_row.columns = 3
	_weapon_row.add_theme_constant_override("h_separation", 12)
	_weapon_row.add_theme_constant_override("v_separation", 8)
	_weapon_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(_weapon_row)
	# Sell / merge buttons of the selected weapon (details are in the hover tooltip).
	_weapon_actions = HBoxContainer.new()
	_weapon_actions.add_theme_constant_override("separation", 12)
	_weapon_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(_weapon_actions)

	var items_box := HBoxContainer.new()
	items_box.add_theme_constant_override("separation", 16)
	items_box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(items_box)
	_items_label = _label(28, TEXT_COLOR, &"SubtitleLabel")
	_items_label.text = "UI_SHOP_ITEMS"
	items_box.add_child(_items_label)
	# At most ITEM_ROWS rows of icons, then a scroll bar: the list never pushes
	# "Next wave" below the screen (playtest bug, wave 19, 33 items).
	_items_scroll = ScrollContainer.new()
	_items_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_items_scroll.follow_focus = true
	_items_scroll.custom_minimum_size = Vector2(_items_width + 16.0, items_height(0, _items_width))
	items_box.add_child(_items_scroll)
	_items_row = HFlowContainer.new()
	_items_row.custom_minimum_size.x = _items_width
	_items_row.add_theme_constant_override("h_separation", ITEM_GAP)
	_items_row.add_theme_constant_override("v_separation", ITEM_GAP)
	_items_scroll.add_child(_items_row)

	# Pinned at the bottom (coop: center of the half; solo: right, far from Reroll).
	# In the column it went down as weapons and items were added, until it left the
	# screen (playtest, solo and coop).
	_next = _button("UI_NEXT_WAVE", 0)
	_next.theme_type_variation = &"CtaButton"
	_next.custom_minimum_size = Vector2(300, 72) if _compact else Vector2(380, 84)
	_next.pressed.connect(_on_next)
	_next.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM if _compact else Control.PRESET_BOTTOM_RIGHT)
	_next.grow_horizontal = Control.GROW_DIRECTION_BOTH if _compact else Control.GROW_DIRECTION_BEGIN
	_next.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_next.offset_bottom = -24.0 if _compact else -36.0
	if not _compact:
		_next.offset_right = -60.0
	root.add_child(_next)
	# Popup of the focused owned item (gamepad has no mouse tooltip).
	_item_popup = PanelContainer.new()
	_item_popup.add_theme_stylebox_override("panel", UiTheme.panel_style(UiTheme.ACCENT, 0.5, 14))
	_item_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_item_popup.visible = false
	_item_popup.z_index = 50
	_item_popup_label = _label(20, TEXT_COLOR)
	_item_popup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_item_popup_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_item_popup_label.custom_minimum_size.x = 380.0
	_item_popup.add_child(_item_popup_label)
	root.add_child(_item_popup)
	if not _compact:
		root.add_child(ButtonHints.create([[&"A", "UI_HINT_BUY"], [&"X", "UI_SHOP_MERGE"], [&"Y", "UI_HINT_REROLL"]]))


## merge_weapon (gamepad Square / X, key F) on an owned weapon merges it at once;
## reroll (gamepad Triangle / Y, key R) rerolls the offers, as the button hints say.
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("reroll"):
		get_viewport().set_input_as_handled()
		_on_reroll()
		return
	if not event.is_action_pressed("merge_weapon"):
		return
	var focused := get_viewport().gui_get_focus_owner()
	for key in _controls:
		if _controls[key] == focused and key.begins_with("weapon:"):
			get_viewport().set_input_as_handled()
			merge_from_focus(int(key.get_slice(":", 1)))
			return


## Merges owned weapon `index` with its copy (shortcut), error sound if it cannot.
func merge_from_focus(index: int) -> void:
	if not _shop.can_merge(index):
		_play(Sounds.UI_ERROR)
		return
	_selected_weapon = index
	_on_merge()


func open() -> void:
	_selected_weapon = -1
	_focus_key = "buy:0"
	_focus_forced = true
	_accept_after = Time.get_ticks_msec() + INPUT_DELAY_MS
	_animate_cards = true
	_shown_materials = -1
	visible = true
	_rebuild()
	UiFx.pop_in(_title)
	# Bottom left, under the owned items: the offers stay readable.
	HintBanner.show_once(self, &"shop", Vector2(0.0, 1.0), Vector2(130.0, -24.0))


func close() -> void:
	visible = false


## Coop: shows whose turn it is; an empty text hides the tag (solo).
func set_player_tag(text: String, color: Color) -> void:
	_player_tag.text = text
	_player_tag.visible = text != ""
	_player_tag.add_theme_color_override("font_color", color)


## Weapon and item names use their rarity color (one color code: the tier),
## not the weapon's neon color.
static func name_color(offer: ShopOffer) -> Color:
	return Tiers.color(offer.tier)


## Card texts: [type · tier, name, effects]. `owned`: copies of the item already
## owned (shown as "owned n/max" for limited items); `stats`: marks capped bonuses.
static func describe(offer: ShopOffer, owned: int = 0, stats: StatBlock = null,
		weapons: WeaponHolder = null) -> PackedStringArray:
	var parts := describe_parts(offer, owned, stats, weapons)
	var effects := parts[2]
	for extra in [parts[3], parts[4]]:
		if extra != "":
			effects = (effects + "\n" + extra).strip_edges()
	return PackedStringArray([parts[0], parts[1], effects])


## Card texts in pieces: [tag, name, stat lines, effect description, limit line]. The stat
## lines are what the player buys the item for; the half-screen card keeps them whole
## and trims the effect description (the full text is in the popup).
static func describe_parts(offer: ShopOffer, owned: int = 0, stats: StatBlock = null,
		weapons: WeaponHolder = null) -> PackedStringArray:
	var kind := "UI_SHOP_WEAPON" if offer.is_weapon() else "UI_SHOP_ITEM"
	var tag := "%s · %s" % [TranslationServer.translate(kind), Tiers.roman(offer.tier)]
	if offer.is_weapon():
		for family_id in offer.weapon.families:
			var family := ContentDB.get_def(&"families", family_id) as FamilyData
			if family != null:
				tag += " · " + TranslationServer.translate(family.name_key)
		return PackedStringArray([tag, TranslationServer.translate(offer.weapon.name_key),
			"", TranslationServer.translate(offer.weapon.description_key), ""])
	var lines := LevelUpScreen.describe_modifiers(offer.item.modifiers, stats)
	var effect: String = TranslationServer.translate(offer.item.effect_key) if offer.item.effect_key != "" else ""
	if stats != null:
		var now := _current_bonus_line(offer.item, stats, weapons)
		if now != "":
			effect = (effect + "
" + now).strip_edges()
	var limit := ""
	if offer.item.max_count == 1:
		limit = TranslationServer.translate("UI_SHOP_UNIQUE")
	elif offer.item.max_count > 1:
		limit = TranslationServer.translate("UI_SHOP_OWNED_MAX") % [owned, offer.item.max_count]
	return PackedStringArray([tag, TranslationServer.translate(offer.item.name_key), lines, effect, limit])


## "Now: +8% Damage": what the item would give with the current build, for the
## effects that scale with it (weapons of a family, armor, ...).
static func _current_bonus_line(item: ItemData, stats: StatBlock, weapons: WeaponHolder) -> String:
	var mods: Array[StatModifier] = []
	for effect in item.effects:
		mods.append_array(effect.preview_modifiers(stats, weapons))
	var text := LevelUpScreen.describe_modifiers(mods)
	if text == "":
		return ""
	return TranslationServer.translate("UI_SHOP_ITEM_NOW") % text.replace("
", ", ")


## Hover text of an item owned `count` times: name, effect of one copy and,
## from two copies, the total bonus of all of them.
static func item_tooltip(item: ItemData, count: int) -> String:
	var lines: PackedStringArray = [TranslationServer.translate(item.name_key)]
	var one := LevelUpScreen.describe_modifiers(item.modifiers)
	if one != "":
		lines.append(one)
	if item.effect_key != "":
		lines.append(TranslationServer.translate(item.effect_key))
	if count > 1 and not item.modifiers.is_empty():
		var total: Array[StatModifier] = []
		for mod in item.modifiers:
			var scaled := StatModifier.new()
			scaled.stat = mod.stat
			scaled.flat = mod.flat * count
			scaled.percent = mod.percent * count
			total.append(scaled)
		lines.append("")
		lines.append(TranslationServer.translate("UI_SHOP_ITEM_TOTAL") % count)
		lines.append(LevelUpScreen.describe_modifiers(total))
	return "\n".join(lines)


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
	var materials_format := "%d"
	if _shown_materials < 0:
		_materials.text = materials_format % _wallet.amount
	elif _shown_materials != _wallet.amount:
		UiFx.count_to(_materials, _shown_materials, _wallet.amount, materials_format)
	_shown_materials = _wallet.amount
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
		_cards.remove_child(child)
		child.queue_free()
	for i in _shop.offers.size():
		var card := _make_card(i, _shop.offers[i])
		_cards.add_child(card)
		if _animate_cards:
			UiFx.pop_in(card, CARD_STAGGER * i)
		elif i == _bought_index:
			UiFx.bounce(card)
	_animate_cards = false
	_bought_index = -1
	_link_card_rows()


## Links the buy and lock buttons left/right across the cards still for sale:
## sold cards have no button, and Godot's automatic search does not jump the gap.
func _link_card_rows() -> void:
	for prefix in ["buy:", "lock:"]:
		var row: Array[Control] = []
		for i in _shop.offers.size():
			var control: Control = _controls.get("%s%d" % [prefix, i])
			if control != null:
				row.append(control)
		for i in row.size():
			if i > 0:
				row[i].focus_neighbor_left = row[i].get_path_to(row[i - 1])
			if i < row.size() - 1:
				row[i].focus_neighbor_right = row[i].get_path_to(row[i + 1])


func _make_card(index: int, offer: ShopOffer) -> Control:
	var accent := Tiers.color(offer.tier)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = _card_size
	panel.add_theme_stylebox_override("panel", UiTheme.card_style(accent, 0.25 if offer.sold else 0.8))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	if offer.sold:
		var sold := _label(30, Color(accent, 0.6), &"SubtitleLabel")
		sold.text = "UI_SHOP_SOLD"
		box.add_child(sold)
		return panel
	var texts := describe(offer, 0 if offer.is_weapon() else _inventory.count(offer.item), _stats, _weapons)
	var icon := IconTile.create(offer.weapon.icon if offer.is_weapon() else offer.item.icon,
		offer.tier, COMPACT_CARD_ICON if _compact else CARD_ICON)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if not offer.is_weapon():
		# Hover: total bonus with this copy added to the ones already owned.
		panel.tooltip_text = item_tooltip(offer.item, _inventory.count(offer.item) + 1)
	# Type and tier above the icon, the name stays under it (dev's request).
	var tag := _label(13 if _compact else 17, accent, &"SmallLabel")
	tag.text = texts[0].to_upper()
	tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tag.custom_minimum_size.x = _card_size.x - 24.0
	box.add_child(tag)
	box.add_child(icon)
	var name_label := _label(23 if _compact else 30, name_color(offer), &"SubtitleLabel")
	name_label.text = texts[1]
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size.x = _card_size.x - 24.0
	box.add_child(name_label)
	if _compact:
		# Half screen: the stat lines whole, the effect description trimmed (3 lines
		# at most, "..." then), the limit on one line; the popup has the full text.
		var parts := describe_parts(offer, 0 if offer.is_weapon() else _inventory.count(offer.item), _stats, _weapons)
		if parts[2] != "":
			box.add_child(_card_text(parts[2], 16, TEXT_COLOR, 0))
		var effect := _card_text(parts[3], 14, TEXT_COLOR, 3)
		effect.size_flags_vertical = Control.SIZE_EXPAND_FILL
		box.add_child(effect)
		if parts[4] != "":
			box.add_child(_card_text(parts[4], 14, TEXT_COLOR, 1))
		name_label.max_lines_visible = 2
	else:
		var effects := _label(19, TEXT_COLOR)
		effects.text = texts[2]
		effects.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		effects.custom_minimum_size.x = _card_size.x - 24.0
		effects.size_flags_vertical = Control.SIZE_EXPAND_FILL
		box.add_child(effects)
	var buy := _button(tr("UI_SHOP_BUY") % offer.price, 20 if _compact else 24)
	UiIcons.put_after_text(buy, UiIcons.coin(), 22 if _compact else 28)
	UiFx.hover_lift(buy)
	buy.disabled = not _shop.can_buy(index)
	if not _wallet.can_afford(offer.price):
		buy.add_theme_color_override("font_disabled_color", TOO_EXPENSIVE)
	buy.pressed.connect(_on_buy.bind(index))
	if _compact:
		# Gamepad / keyboard: the full card text while the buy button is focused.
		var full := texts[1] + "\n" + texts[2]
		buy.focus_entered.connect(func() -> void: _show_item_popup(panel, full))
		buy.focus_exited.connect(func() -> void: _item_popup.visible = false)
	box.add_child(buy)
	_controls["buy:%d" % index] = buy
	# A padlock icon instead of the word: closed when the offer is locked, open otherwise.
	var lock := _button("🔒" if offer.locked else "🔓", 26)
	lock.tooltip_text = "UI_SHOP_UNLOCK" if offer.locked else "UI_SHOP_LOCK"
	lock.pressed.connect(_on_lock.bind(index))
	if _compact:
		lock.add_theme_font_size_override("font_size", 20)
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
		var tier_color := Tiers.color(slot.level)
		var mergeable := _shop.can_merge(i)
		# A mergeable pair gets a gold ring around its outline (clearly visible, not only a glow).
		var normal := UiTheme.card_style(UiTheme.GOLD if mergeable else tier_color,
			1.0 if mergeable or i == _selected_weapon else 0.45)
		normal.set_content_margin_all(10)
		if mergeable:
			normal.border_color = UiTheme.GOLD
			normal.set_border_width_all(MERGE_RING)
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("focus", UiTheme.card_focus_style())
		# Hover / press keep the card shape (the theme's pill read as another button).
		var lit := UiTheme.card_style(UiTheme.GOLD if mergeable else tier_color, 1.0)
		lit.set_content_margin_all(10)
		if mergeable:
			lit.border_color = UiTheme.GOLD
			lit.set_border_width_all(MERGE_RING)
		button.add_theme_stylebox_override("hover", lit)
		button.add_theme_stylebox_override("pressed", lit)
		button.add_theme_color_override("font_color", tier_color)
		button.icon = slot.data.icon
		button.add_theme_constant_override("icon_max_width", WEAPON_ICON)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_on_weapon_selected.bind(i))
		button.tooltip_text = weapon_details(slot)
		_weapon_row.add_child(button)
		_controls["weapon:%d" % i] = button
	var free := _label(22, UiTheme.MUTED, &"ValueLabel")
	free.text = "%d / %d" % [slots.size(), _weapons.max_slots]
	_weapon_row.add_child(free)
	if _selected_weapon < 0:
		return
	var sell := _button(tr("UI_SHOP_SELL") % _shop.sell_price(_selected_weapon), 22)
	UiIcons.put_after_text(sell, UiIcons.coin(), 24)
	sell.disabled = not _shop.can_sell(_selected_weapon)
	sell.pressed.connect(_on_sell)
	_weapon_actions.add_child(sell)
	_controls["sell"] = sell
	var merge := _button("UI_SHOP_MERGE", 22)
	merge.disabled = not _shop.can_merge(_selected_weapon)
	merge.pressed.connect(_on_merge)
	_weapon_actions.add_child(merge)
	_controls["merge"] = merge


## Hover text of an owned weapon: name and tier, description, stats at its tier.
static func weapon_details(slot: WeaponSlot) -> String:
	var lines: PackedStringArray = ["%s %s" % [TranslationServer.translate(slot.data.name_key), Tiers.roman(slot.level)],
		TranslationServer.translate(slot.data.description_key)]
	lines.append_array(weapon_stat_lines(slot.stats))
	return "\n".join(lines)


## The weapon's own numbers at its tier (before the player's stats).
static func weapon_stat_lines(s: WeaponStats) -> PackedStringArray:
	var t := func(key: String) -> String: return TranslationServer.translate(key)
	var lines: PackedStringArray = []
	lines.append("%s %d" % [t.call("STAT_DAMAGE"), roundi(s.damage)])
	lines.append("%s %.1f/s" % [t.call("WSTAT_FIRE_RATE"), 1.0 / maxf(s.cooldown, 0.01)])
	if s.crit_chance > 0.0:
		lines.append("%s %d%%" % [t.call("STAT_CRIT_CHANCE"), roundi(s.crit_chance * 100.0)])
	if s.projectile_count > 1:
		lines.append("%s %d" % [t.call("STAT_PROJECTILE_COUNT"), s.projectile_count])
	if s.pierce > 0:
		lines.append("%s %d" % [t.call("STAT_PIERCE"), s.pierce])
	if s.bounces > 0:
		lines.append("%s %d" % [t.call("WSTAT_BOUNCES"), s.bounces])
	if s.explosion_radius > 0.0:
		lines.append("%s %d" % [t.call("WSTAT_BLAST"), roundi(s.explosion_radius)])
	elif s.area > 0.0:
		lines.append("%s %d" % [t.call("STAT_AREA"), roundi(s.area)])
	if s.attack_range > 0.0:
		lines.append("%s %d" % [t.call("STAT_RANGE"), roundi(s.attack_range)])
	return lines


func _rebuild_items() -> void:
	for child in _items_row.get_children():
		_items_row.remove_child(child)
		child.queue_free()
	var count_items := _inventory.get_items().size()
	var icon_size := item_icon_size(count_items)
	_items_scroll.custom_minimum_size.y = items_height(count_items, _items_width)
	var number := 0
	for item in _inventory.get_items():
		var count := _inventory.count(item)
		var tile := IconTile.create(item.icon, item.tier, icon_size, "×%d" % count if count > 1 else "")
		var details := item_tooltip(item, count)
		tile.tooltip_text = details
		_make_item_focusable(tile, details)
		_controls["item:%d" % number] = tile
		number += 1
		_items_row.add_child(tile)
	if _inventory.get_items().is_empty():
		var none := _label(22, UiTheme.MUTED)
		none.text = "—"
		_items_row.add_child(none)


## An owned item can take the focus (gamepad / keyboard): a frame shows it and its
## details appear in a popup, as the mouse tooltip does.
func _make_item_focusable(tile: IconTile, details: String) -> void:
	tile.focus_mode = Control.FOCUS_ALL
	var frame := Panel.new()
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", UiTheme.focus_style(UiTheme.ACCENT, 10))
	frame.visible = false
	tile.add_child(frame)
	tile.focus_entered.connect(func() -> void:
		frame.visible = true
		_show_item_popup(tile, details))
	tile.focus_exited.connect(func() -> void:
		frame.visible = false
		_item_popup.visible = false)


## Details of the focused item, above its tile (kept inside the screen).
func _show_item_popup(tile: Control, details: String) -> void:
	_item_popup_label.text = details
	_item_popup.visible = true
	_item_popup.reset_size()
	var screen := get_viewport().get_visible_rect().size
	var at := tile.get_global_rect().position + Vector2(0.0, -_item_popup.size.y - 10.0)
	at.x = clampf(at.x, 8.0, screen.x - _item_popup.size.x - 8.0)
	at.y = maxf(at.y, 8.0)
	_item_popup.position = at


## Right stick of the shop's player scrolls the item list (a scroll bar cannot be
## reached with a gamepad). `scroll_device`: gamepad id, -1 none, -2 any gamepad.
func _process(delta: float) -> void:
	if not visible or _items_scroll == null:
		return
	var axis := right_stick_y(scroll_device)
	if absf(axis) > SCROLL_DEADZONE:
		_items_scroll.scroll_vertical += roundi(axis * SCROLL_SPEED * delta)


static func right_stick_y(device: int) -> float:
	if device == -1:
		return 0.0
	var best := 0.0
	var devices: Array[int] = []
	if device >= 0:
		devices.append(device)
	else:
		devices.assign(Input.get_connected_joypads())
	for id in devices:
		var value := Input.get_joy_axis(id, JOY_AXIS_RIGHT_Y)
		if absf(value) > absf(best):
			best = value
	return best


static func item_icon_size(count: int) -> float:
	return ITEM_ICON if count <= ITEMS_BEFORE_SMALL else ITEM_ICON_SMALL


## Height of the item list for `count` different items: as many rows as
## needed, at most ITEM_ROWS (then it scrolls).
static func items_height(count: int, width: float = ITEMS_WIDTH) -> float:
	var size := item_icon_size(count)
	var per_row := maxi(1, floori((width + ITEM_GAP) / (size + ITEM_GAP)))
	var rows := clampi(ceili(float(count) / per_row), 1, ITEM_ROWS)
	return rows * size + (rows - 1) * ITEM_GAP


func _accepting() -> bool:
	return Time.get_ticks_msec() >= _accept_after


func _on_buy(index: int) -> void:
	if _accepting():
		_bought_index = index
		_play(Sounds.UI_BUY if _shop.buy(index) else Sounds.UI_ERROR)
		_bought_index = -1


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


## Wrapped card text; `max_lines` > 0 trims with "..." past that many lines.
func _card_text(text: String, size: int, color: Color, max_lines: int) -> Label:
	var label := _label(size, color)
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = _card_size.x - 24.0
	if max_lines > 0:
		label.max_lines_visible = max_lines
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return label


func _label(size: int, color: Color, variation: StringName = &"") -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


## `size` 0 keeps the theme's font size.
func _button(text: String, size: int) -> Button:
	var button := Button.new()
	button.text = text
	if size > 0:
		button.add_theme_font_size_override("font_size", size)
	return button
