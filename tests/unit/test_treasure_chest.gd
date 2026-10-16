extends GutTest
## Boss treasure chests: drop, wait, open when a player walks on them, give the reward with the burst.

var _player: Player
var _party: Party
var _data: ChestData


func before_each() -> void:
	_player = Player.new()
	_player.setup(CharacterData.new(), Rect2(-2000, -2000, 4000, 4000))
	_player.bot_input = func() -> Vector2: return Vector2.ZERO
	add_child_autofree(_player)
	_party = Party.solo(_player)
	_data = ContentDB.get_def(&"chests", &"big")


func _chest(at: Vector2) -> TreasureChest:
	var chest := TreasureChest.create(_data, _party, at)
	add_child_autofree(chest)
	return chest


func test_the_boss_chests_exist_and_have_an_opening_animation() -> void:
	for id in [&"small", &"big"]:
		var data: ChestData = ContentDB.get_def(&"chests", id)
		assert_not_null(data, "%s chest" % id)
		assert_true(data.sheet.has_animation(&"open"))
		assert_lt(data.burst_frame, data.sheet.animations[&"open"].y)
	for boss in [&"shogun", &"astral_boss_final"]:
		assert_eq(ContentDB.get_def(&"enemies", boss).chest, _data, "%s drops the big chest" % boss)
	assert_eq(ContentDB.get_def(&"enemies", &"ronin").chest, ContentDB.get_def(&"chests", &"small"))


func test_a_chest_drops_then_waits_and_only_a_player_close_by_opens_it() -> void:
	_player.global_position = Vector2(2000, 2000)
	var chest := _chest(Vector2.ZERO)
	assert_eq(chest.state, TreasureChest.State.DROPPING)
	await wait_seconds(TreasureChest.DROP_TIME + 0.2)
	assert_eq(chest.state, TreasureChest.State.WAITING, "it waits, glowing")
	await wait_physics_frames(10)
	assert_eq(chest.state, TreasureChest.State.WAITING, "nobody is near: it stays closed")
	_player.global_position = Vector2(_data.open_radius - 10.0, 0.0)
	await wait_physics_frames(3)
	assert_eq(chest.state, TreasureChest.State.OPENING, "a player walked onto it")


func test_the_reward_comes_with_the_burst_and_the_chest_finishes_after_the_animation() -> void:
	var chest := _chest(Vector2.ZERO)
	_player.global_position = Vector2.ZERO
	watch_signals(chest)
	await wait_seconds(TreasureChest.DROP_TIME + 0.2)
	await wait_physics_frames(2)
	assert_eq(chest.state, TreasureChest.State.OPENING)
	assert_signal_not_emitted(chest, "opened")
	await wait_seconds((_data.burst_frame + 1.5) / _data.open_fps)
	assert_signal_emit_count(chest, "opened", 1)
	assert_signal_not_emitted(chest, "finished")
	await wait_seconds(16.0 / _data.open_fps)
	assert_signal_emit_count(chest, "finished", 1)


func test_a_chest_opened_in_a_hurry_gives_its_reward_at_once() -> void:
	var chest := _chest(Vector2(500, 0))
	watch_signals(chest)
	chest.open_now()
	assert_signal_emit_count(chest, "opened", 1)
	assert_signal_emit_count(chest, "finished", 1)
	chest.open_now()
	assert_signal_emit_count(chest, "opened", 1, "the reward is given once")
