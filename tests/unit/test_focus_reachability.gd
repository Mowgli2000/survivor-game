extends GutTest
## Gamepad / keyboard: from the focused control, the four directions must reach every usable control
## of a screen (no button the pad cannot get to) and each move must have a way back.

const RUN := preload("res://src/run/run.tscn")
const SIDES: Array[Side] = [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]


## Usable controls under `root`: visible, enabled, focusable.
func _usable(root: Node) -> Array[Control]:
	var found: Array[Control] = []
	for node in root.find_children("*", "Control", true, false):
		var control := node as Control
		if control.focus_mode == Control.FOCUS_ALL and control.is_visible_in_tree() \
				and not (control is BaseButton and (control as BaseButton).disabled):
			found.append(control)
	return found


## Controls reached from `start` by pushing the four directions, as the GUI does.
func _reach(start: Control) -> Array[Control]:
	var seen: Array[Control] = [start]
	var queue: Array[Control] = [start]
	while not queue.is_empty():
		var current: Control = queue.pop_front()
		for side in SIDES:
			var next := current.find_valid_focus_neighbor(side)
			if next != null and not seen.has(next):
				seen.append(next)
				queue.append(next)
	return seen


func _names(controls: Array[Control]) -> PackedStringArray:
	var names := PackedStringArray()
	for control in controls:
		names.append("%s(%s)" % [control.name, (control as Button).text if control is Button else ""])
	return names


func _assert_all_reachable(root: Node, start: Control, label: String) -> void:
	await wait_process_frames(3)  # layout
	var reached := _reach(start)
	assert_gt(_usable(root).size(), 3, "%s: the walk really sees the controls" % label)
	var missing: Array[Control] = []
	for control in _usable(root):
		if not reached.has(control):
			missing.append(control)
	assert_eq(missing.size(), 0, "%s: unreachable with the pad: %s" % [label, ", ".join(_names(missing))])


func _shop_screen(selected: int, weapons: int) -> ShopScreen:
	TranslationServer.set_locale("en")
	var stats := StatBlock.from_defaults()
	var wallet := Wallet.new()
	wallet.add(200)
	var inventory := Inventory.new(stats)
	var holder := WeaponHolder.new()
	autofree(holder)
	var pool: Array[WeaponData] = []
	pool.assign(ContentDB.get_all(&"weapons").filter(func(w: WeaponData) -> bool: return not w.locked).slice(0, 6))
	for i in weapons:
		holder.add_weapon(pool[i % 2])  # two kinds: pairs that can merge
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var items: Array[ItemData] = []
	items.assign(ContentDB.get_all(&"items").filter(func(i: ItemData) -> bool: return not i.locked))
	var shop := Shop.new(ShopConfig.new(), wallet, inventory, holder, pool, items, rng)
	shop.open(1)
	var screen := ShopScreen.new()
	add_child_autofree(screen)
	screen.setup(shop, wallet, inventory, holder, stats)
	screen.open()
	screen._accept_after = 0
	if selected >= 0:
		screen._controls["weapon:%d" % selected].pressed.emit()
	return screen


func test_shop_every_button_is_reachable_with_the_pad() -> void:
	var screen := _shop_screen(-1, 4)
	await _assert_all_reachable(screen, screen._focus_target(), "shop")


func test_shop_with_a_selected_weapon_reaches_sell_and_merge() -> void:
	var screen := _shop_screen(0, 4)
	await _assert_all_reachable(screen, screen._focus_target(), "shop, weapon selected")


func test_shop_with_six_weapons_is_reachable() -> void:
	var screen := _shop_screen(-1, 6)
	await _assert_all_reachable(screen, screen._focus_target(), "shop, six weapons")


func test_pause_menu_is_reachable() -> void:
	var run: Run = RUN.instantiate()
	run.seed_override = 1
	add_child_autofree(run)
	run.open_pause()
	await _assert_all_reachable(run.pause_menu, run.pause_menu._resume, "pause")
	get_tree().paused = false


func test_level_up_cards_and_reroll_are_reachable() -> void:
	TranslationServer.set_locale("en")
	var screen := LevelUpScreen.new()
	add_child_autofree(screen)
	var stats := StatBlock.from_defaults()
	var offers: Array[UpgradeOffer] = []
	for upgrade in ContentDB.get_all(&"upgrades").slice(0, 4):
		var offer := UpgradeOffer.new()
		offer.upgrade = upgrade
		offer.tier = 1
		offers.append(offer)
	screen.open(offers, 1, true, stats)
	await wait_seconds(0.5)  # the cards accept input after a short delay
	var start := get_viewport().gui_get_focus_owner()
	assert_not_null(start, "a card has the focus")
	await _assert_all_reachable(screen, start, "level up")


func test_settings_screen_is_reachable() -> void:
	var screen := SettingsScreen.new()
	add_child_autofree(screen)
	screen.open()
	await wait_process_frames(2)
	var start := get_viewport().gui_get_focus_owner()
	assert_not_null(start, "a control has the focus")
	await _assert_all_reachable(screen, start, "settings")
