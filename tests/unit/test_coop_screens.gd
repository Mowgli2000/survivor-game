extends GutTest
## Coop halves (ADR 0021): each player's device drives only his own half.

var _picked: Array[int] = []


func _joy(device: int, button: int, pressed: bool) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.device = device
	event.button_index = button as JoyButton
	event.pressed = pressed
	return event


func _setup_halves() -> CoopScreens:
	var halves := CoopScreens.new()
	var inputs: Array[PlayerInput] = [PlayerInput.coop(0, 0, true), PlayerInput.coop(1, 1, false)]
	halves.setup(inputs)
	add_child_autofree(halves)
	_picked.clear()
	for i in 2:
		var screen := LevelUpScreen.new(true)
		halves.add_screen(i, screen)
		screen.offer_chosen.connect(func(_offer: UpgradeOffer) -> void: _picked.append(i))
		var offers: Array[UpgradeOffer] = [
			UpgradeOffer.for_stat(ContentDB.get_def(&"upgrades", &"vitality"), 1),
			UpgradeOffer.for_stat(ContentDB.get_def(&"upgrades", &"vitality"), 2)]
		screen.open(offers)
	return halves


func _press_accept(halves: CoopScreens, device: int) -> void:
	halves._input(_joy(device, JOY_BUTTON_A, true))
	halves._input(_joy(device, JOY_BUTTON_A, false))


func test_each_pad_picks_in_its_own_half_one_after_the_other() -> void:
	var halves := _setup_halves()
	await wait_seconds(0.6)
	_press_accept(halves, 1)
	await wait_process_frames(2)
	assert_eq(_picked, [1] as Array[int], "pad 1 picks for player 2 only")
	_press_accept(halves, 0)
	await wait_process_frames(2)
	assert_eq(_picked, [1, 0] as Array[int], "pad 0 then picks for player 1")



func test_press_survives_the_other_players_input_before_release() -> void:
	var halves := _setup_halves()
	await wait_seconds(0.6)
	_press_accept(halves, 1)  # both halves hold a focus memory now
	_picked.clear()
	halves._input(_joy(0, JOY_BUTTON_A, true))
	halves._input(_joy(1, JOY_BUTTON_DPAD_RIGHT, true))  # player 2 moves meanwhile
	halves._input(_joy(1, JOY_BUTTON_DPAD_RIGHT, false))
	halves._input(_joy(0, JOY_BUTTON_A, false))
	await wait_process_frames(2)
	assert_eq(_picked, [0] as Array[int], "player 1's press is not cancelled by player 2")


func test_idle_stick_noise_does_not_steal_the_focus() -> void:
	var halves := _setup_halves()
	await wait_seconds(0.6)
	_press_accept(halves, 1)
	_picked.clear()
	halves._input(_joy(0, JOY_BUTTON_A, true))
	var noise := InputEventJoypadMotion.new()
	noise.device = 1
	noise.axis = JOY_AXIS_LEFT_X
	noise.axis_value = 0.05
	halves._input(noise)
	halves._input(_joy(0, JOY_BUTTON_A, false))
	await wait_process_frames(2)
	assert_eq(_picked, [0] as Array[int], "stick noise of pad 1 does not cancel player 1's press")


func test_remembered_card_freed_by_new_offers_is_skipped() -> void:
	var halves := _setup_halves()
	await wait_seconds(0.6)
	_press_accept(halves, 1)  # player 2's half remembers its first card
	var screen := halves.viewport_of(1).find_children("*", "LevelUpScreen", false, false)[0] as LevelUpScreen
	var offers: Array[UpgradeOffer] = [UpgradeOffer.for_stat(ContentDB.get_def(&"upgrades", &"vitality"), 1)]
	screen.open(offers)  # frees the remembered card; the new one waits INPUT_DELAY
	await wait_process_frames(2)
	_picked.clear()
	_press_accept(halves, 1)  # pressed before the new card is enabled
	assert_eq(_picked, [] as Array[int], "nothing to pick yet")
	await wait_seconds(0.6)
	_press_accept(halves, 1)
	assert_eq(_picked, [1] as Array[int], "then player 2 picks the new card")


func test_both_halves_show_their_selection_frame() -> void:
	var halves := _setup_halves()
	await wait_seconds(0.6)
	halves._input(_joy(0, JOY_BUTTON_DPAD_RIGHT, true))
	halves._input(_joy(1, JOY_BUTTON_DPAD_RIGHT, true))
	await wait_process_frames(2)
	for i in 2:
		assert_not_null(halves._frames[i].target, "half %d draws its selection" % i)
		assert_eq(halves._frames[i].target.get_viewport(), halves.viewport_of(i))
	assert_null(halves.viewport_of(0).gui_get_focus_owner(), "Godot keeps only the last focus")


func test_halves_share_the_whole_visible_width() -> void:
	var halves := _setup_halves()
	var visible_size := halves.get_viewport().get_visible_rect().size
	assert_almost_eq(halves._containers[0].size.x + halves._containers[1].size.x, visible_size.x, 0.5)
	assert_almost_eq(halves._containers[1].position.x, visible_size.x * 0.5, 0.5)


func test_left_stick_moves_the_selection_one_step_per_push() -> void:
	var halves := _setup_halves()
	await wait_seconds(0.6)
	halves._input(_joy(0, JOY_BUTTON_DPAD_LEFT, true))  # player 1's half holds the focus
	var cards := halves.viewport_of(0).find_children("*", "Button", true, false)
	var first := halves.viewport_of(0).gui_get_focus_owner()
	for value in [0.2, 0.6, 0.9, 1.0]:  # one push to the right, several motion events
		var motion := InputEventJoypadMotion.new()
		motion.device = 0
		motion.axis = JOY_AXIS_LEFT_X
		motion.axis_value = value
		halves._input(motion)
	var moved := halves.viewport_of(0).gui_get_focus_owner()
	assert_ne(moved, first, "the stick moves the selection")
	assert_eq(cards.find(moved), cards.find(first) + 1, "by one card only")
