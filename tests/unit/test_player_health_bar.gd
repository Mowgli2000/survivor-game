extends GutTest
## HP bar above the player's head follows its health.


func test_bar_follows_damage_and_sits_above_the_head() -> void:
	var player := Player.new()
	player.setup(ContentDB.get_def(&"characters", &"drifter") as CharacterData, Rect2(-500, -500, 1000, 1000))
	add_child_autofree(player)
	assert_not_null(player.health_bar)
	assert_almost_eq(player.health_bar.ratio(), 1.0, 0.001)
	assert_lt(player.health_bar.position.y, -player.head_height(), "above the sprite")
	player.take_damage(player.hp * 0.5)
	assert_lt(player.health_bar.ratio(), 1.0)


func test_setting_turns_the_bar_off() -> void:
	var data := SettingsData.new()
	assert_true(data.player_hp_bar, "on by default")
	assert_true(data.set_value(&"player_hp_bar", false))
	assert_false(SettingsData.from_dict(data.to_dict()).player_hp_bar, "saved")
