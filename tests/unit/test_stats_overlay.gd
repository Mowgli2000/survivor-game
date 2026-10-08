extends GutTest
## Share / Tab shows the holder's stats over every screen of a run.


func _players(count: int) -> Array[RunPlayer]:
	var players: Array[RunPlayer] = []
	var inputs := PlayerInput.assign(count, [3, 7] as Array[int])
	for i in count:
		var rp := RunPlayer.new()
		rp.index = i
		rp.input = inputs[i]
		rp.player = Player.new()
		rp.player.setup(ContentDB.get_def(&"characters", &"hero") as CharacterData, Rect2(-100, -100, 200, 200))
		rp.families = WeaponFamilies.new()
		autofree(rp.player)
		players.append(rp)
	return players


func test_solo_shows_one_panel_while_the_action_is_held() -> void:
	var overlay := StatsOverlay.new()
	add_child_autofree(overlay)
	overlay.setup(_players(1))
	await wait_process_frames(2)
	assert_false(overlay.panel_of(0).visible)
	Input.action_press(&"show_stats")
	await wait_process_frames(2)
	assert_true(overlay.panel_of(0).visible, "held: shown")
	Input.action_release(&"show_stats")
	await wait_process_frames(2)
	assert_false(overlay.panel_of(0).visible, "released: hidden")


func test_coop_panels_belong_to_their_player() -> void:
	var overlay := StatsOverlay.new()
	add_child_autofree(overlay)
	overlay.setup(_players(2))
	assert_eq(overlay.is_held(0), false)
	assert_eq(overlay.is_held(1), false)
	assert_eq(overlay.panel_of(0).get_parent().anchor_right, 0.5, "player 1: left half")
	assert_eq(overlay.panel_of(1).get_parent().anchor_left, 0.5, "player 2: right half")


func test_a_panel_already_on_screen_is_not_doubled() -> void:
	var overlay := StatsOverlay.new()
	add_child_autofree(overlay)
	overlay.setup(_players(1), func(_index: int) -> bool: return true)
	Input.action_press(&"show_stats")
	await wait_process_frames(2)
	assert_false(overlay.panel_of(0).visible)
	Input.action_release(&"show_stats")
