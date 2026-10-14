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


func test_badge_shows_the_level_and_celebrates_a_level_up() -> void:
	var player := Player.new()
	player.setup(ContentDB.get_def(&"characters", &"drifter") as CharacterData, Rect2(-500, -500, 1000, 1000))
	add_child_autofree(player)
	var progression := Progression.new(10.0, 1.0)
	player.health_bar.bind_progression(progression)
	assert_eq(player.health_bar.level(), 1)
	assert_almost_eq(player.health_bar.glow(), 0.0, 0.001, "no celebration at the start")
	UiFx.reduce_motion = false
	progression.add_xp(progression.xp_needed())
	assert_eq(player.health_bar.level(), 2, "badge follows the level")
	assert_gt(player.health_bar.glow(), 0.5, "celebration just started")
	await wait_seconds(PlayerHealthBar.CELEBRATION_SECONDS + 0.2)
	assert_almost_eq(player.health_bar.glow(), 0.0, 0.001, "celebration ends by itself")


func test_reduced_motion_updates_the_level_without_celebration() -> void:
	var player := Player.new()
	player.setup(ContentDB.get_def(&"characters", &"drifter") as CharacterData, Rect2(-500, -500, 1000, 1000))
	add_child_autofree(player)
	var progression := Progression.new(10.0, 1.0)
	player.health_bar.bind_progression(progression)
	UiFx.reduce_motion = true
	progression.add_xp(progression.xp_needed())
	UiFx.reduce_motion = false
	assert_eq(player.health_bar.level(), 2)
	assert_almost_eq(player.health_bar.glow(), 0.0, 0.001)

