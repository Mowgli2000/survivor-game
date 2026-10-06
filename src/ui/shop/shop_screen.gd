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
## Coop: each player's shop fills half of the screen (compact layout).
const COMPACT_CARD_SIZE := Vector2(214, 392)
const COMPACT_ITEMS_WIDTH := 800.0
const CARD_ICON := 96.0
const ITEM_ICON := 60.0
## With many different items, the tiles shrink so the list stays on 3 rows.
const ITEM_ICON_SMALL := 46.0
const ITEMS_BEFORE_SMALL := 32
const ITEMS_WIDTH := 1100.0
const ITEM_GAP := 8
## Rows of item icons shown before the list scrolls.
const ITEM_ROWS := 2
const WEAPON_ICON := 40
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
	root.add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 24)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 40)
	center.add_child(row)
	row.add_child(box)
	stats_panel = StatsPanel.new()
	stats_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stats_panel.set_dense()
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
	_materials = _label(30 if _compact else 40, UiTheme.GOOD, &"ValueLabel")
	header.add_child(_materials)

	_cards = HBoxContainer.new()
	_cards.add_theme_constant_override("separation", 10 if _compact else 24)
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(_cards)

	_reroll = _button("", 28)
	_reroll.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_reroll.pressed.connect(_on_reroll)
	box.add_child(_reroll)

	var weapons_title := _label(28, TEXT_COLOR, &"SubtitleLabel")
	weapons_title.text = "UI_SHOP_WEAPONS"
	box.add_child(weapons_title)
	# A grid (3 per row, 2 in coop): a flow container reported its unwrapped width and
	# pushed the whole screen past the edge with six long weapon names.
	_weapon_row = GridContainer.new()
	_weapon_row.columns = 2 if _compact else 3
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
	_items_scroll.custom_minimum_size = Vector2(_items_width + 16.0, items_height(0, _items_width))
	items_box.add_child(_items_scroll)
	_items_row = HFlowContainer.new()
	_items_row.custom_minimum_size.x = _items_width
	_items_row.add_theme_constant_override("h_separation", ITEM_GAP)
	_items_row.add_theme_constant_override("v_separation", ITEM_GAP)
	_items_scroll.add_child(_items_row)

	# Bottom right, under the items, far from Reroll (no misclick).
	_next = _button("UI_NEXT_WAVE", 0)
	_next.theme_type_variation = &"CtaButton"
	_next.custom_minimum_size = Vector2(300, 72) if _compact else Vector2(380, 84)
	_next.size_flags_horizontal = Control.SIZE_SHRINK_CENTER if _compact else Control.SIZE_SHRINK_END
	_next.pressed.connect(_on_next)
	box.add_child(_next)
	if not _compact:
		root.add_child(ButtonHints.create([[&"A", "UI_HINT_BUY"], [&"X", "UI_HINT_LOCK"], [&"Y", "UI_HINT_REROLL"]]))


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
static func describe(offer: ShopOffer, owned: int = 0, stats: StatBlock = null) -> PackedStringArray:
	var kind := "UI_SHOP_WEAPON" if offer.is_weapon() else "UI_SHOP_ITEM"
	var tag := "%s · %s" % [TranslationServer.translate(kind), Tiers.roman(offer.tier)]
	if offer.is_weapon():
		for family_id in offer.weapon.families:
			var family := ContentDB.get_def(&"families", family_id) as FamilyData
			if family != null:
				tag += " · " + TranslationServer.translate(family.name_key)
		return PackedStringArray([tag, TranslationServer.translate(offer.weapon.name_key),
			TranslationServer.translate(offer.weapon.description_key)])
	var effects := LevelUpScreen.describe_modifiers(offer.item.modifiers, stats)
	if offer.item.effect_key != "":
		effects = "
".join(PackedStringArray([effects, TranslationServer.translate(offer.item.effect_key)])).strip_edges()
	if offer.item.max_count == 1:
		effects += "
" + TranslationServer.translate("UI_SHOP_UNIQUE")
	elif offer.item.max_count > 1:
		effects += "
" + TranslationServer.translate("UI_SHOP_OWNED_MAX") % [owned, offer.item.max_count]
	return PackedStringArray([tag, TranslationServer.translate(offer.item.name_key), effects])


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
	var materials_format := tr("UI_MATERIALS") + " %d"
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
	var texts := describe(offer, 0 if offer.is_weapon() else _inventory.count(offer.item), _stats)
	var icon := IconTile.create(offer.weapon.icon if offer.is_weapon() else offer.item.icon,
		offer.tier, CARD_ICON)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if not offer.is_weapon():
		# Hover: total bonus with this copy added to the ones already owned.
		panel.tooltip_text = item_tooltip(offer.item, _inventory.count(offer.item) + 1)
	box.add_child(icon)
	var tag := _label(13 if _compact else 17, accent, &"SmallLabel")
	tag.text = texts[0].to_upper()
	tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tag.custom_minimum_size.x = _card_size.x - 24.0
	box.add_child(tag)
	var name_label := _label(23 if _compact else 30, name_color(offer), &"SubtitleLabel")
	name_label.text = texts[1]
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size.x = _card_size.x - 24.0
	box.add_child(name_label)
	var effects := _label(16 if _compact else 19, TEXT_COLOR)
	effects.text = texts[2]
	effects.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effects.custom_minimum_size.x = _card_size.x - 24.0
	effects.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(effects)
	var buy := _button(tr("UI_SHOP_BUY") % offer.price, 20 if _compact else 24)
	UiFx.hover_lift(buy)
	buy.disabled = not _shop.can_buy(index)
	if not _wallet.can_afford(offer.price):
		buy.add_theme_color_override("font_disabled_color", TOO_EXPENSIVE)
	buy.pressed.connect(_on_buy.bind(index))
	box.add_child(buy)
	_controls["buy:%d" % index] = buy
	# A padlock icon instead of the word: closed when the offer is locked, open otherwise.
	var lock := _button("🔒" if offer.locked else "🔓", 26)
	lock.tooltip_text = "UI_SHOP_UNLOCK" if offer.locked else "UI_SHOP_LOCK"
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
		var tier_color := Tiers.color(slot.level)
		var mergeable := _shop.can_merge(i)
		# A mergeable pair gets a gold frame.
		var normal := UiTheme.card_style(UiTheme.GOLD if mergeable else tier_color,
			1.0 if mergeable or i == _selected_weapon else 0.45)
		normal.set_content_margin_all(10)
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_color_override("font_color", tier_color)
		button.icon = slot.data.icon
		button.add_theme_constant_override("icon_max_width", WEAPON_ICON)
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
	return "
".join(lines)


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
	for item in _inventory.get_items():
		var count := _inventory.count(item)
		var tile := IconTile.create(item.icon, item.tier, icon_size, "×%d" % count if count > 1 else "")
		tile.tooltip_text = item_tooltip(item, count)
		_items_row.add_child(tile)
	if _inventory.get_items().is_empty():
		var none := _label(22, UiTheme.MUTED)
		none.text = "—"
		_items_row.add_child(none)


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
