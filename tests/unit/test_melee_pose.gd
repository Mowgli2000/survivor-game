extends GutTest
## Melee swing animation: wind-up, strike, follow-through, and the slash streak delay.


func test_the_weapon_pulls_back_before_it_strikes() -> void:
	var rest := WeaponVisuals.melee_pose(0.0, WeaponData.SlashStyle.CRESCENT)
	assert_almost_eq(rest.x, 0.0, 0.001, "starts at rest")
	var wound := WeaponVisuals.melee_pose(0.2, WeaponData.SlashStyle.CRESCENT)
	assert_lt(wound.x, -0.3, "turned back")
	assert_lt(wound.z, 1.0, "squashed while winding up")
	var struck := WeaponVisuals.melee_pose(0.5, WeaponData.SlashStyle.CRESCENT)
	assert_gt(struck.x, 0.8, "swung through")
	assert_gt(struck.z, 1.1, "stretched while striking")


func test_the_weapon_settles_back_at_the_end() -> void:
	for style in [WeaponData.SlashStyle.CRESCENT, WeaponData.SlashStyle.THRUST, WeaponData.SlashStyle.SMASH]:
		var end := WeaponVisuals.melee_pose(1.0, style)
		assert_almost_eq(end.x, 0.0, 0.1, "style %d: angle at rest" % style)
		assert_almost_eq(end.y, 0.0, 0.5, "style %d: no push" % style)
		assert_almost_eq(end.z, 1.0, 0.05, "style %d: back to normal size" % style)


func test_a_thrust_lunges_instead_of_turning() -> void:
	var lunge := WeaponVisuals.melee_pose(0.5, WeaponData.SlashStyle.THRUST)
	assert_almost_eq(lunge.x, 0.0, 0.001, "no turn")
	assert_gt(lunge.y, 20.0, "pushed forward")


func test_heavy_weapons_swing_slower_than_light_ones_and_a_thrust_is_quick() -> void:
	assert_gt(WeaponVisuals.melee_time(WeaponData.SlashStyle.SMASH), WeaponVisuals.melee_time(WeaponData.SlashStyle.CRESCENT))
	assert_lt(WeaponVisuals.melee_time(WeaponData.SlashStyle.THRUST), WeaponVisuals.melee_time(WeaponData.SlashStyle.CRESCENT))


func test_the_streak_waits_for_the_wind_up() -> void:
	var vfx := Vfx.new()
	add_child_autofree(vfx)
	vfx.slash(Vector2.ZERO, 0.0, 100.0, 1.0, Color.WHITE, WeaponData.SlashStyle.CRESCENT)
	assert_gt(vfx._life[0], vfx._max_life[0], "not drawn yet")
	assert_almost_eq(vfx._life[0] - vfx._max_life[0], WeaponVisuals.strike_delay(WeaponData.SlashStyle.CRESCENT), 0.001)


func test_afterimages_only_during_the_strike() -> void:
	assert_eq(WeaponVisuals.strike_amount(0.0, WeaponData.SlashStyle.CRESCENT), 0.0)
	assert_gt(WeaponVisuals.strike_amount(0.4, WeaponData.SlashStyle.CRESCENT), 0.5)
	assert_eq(WeaponVisuals.strike_amount(0.9, WeaponData.SlashStyle.CRESCENT), 0.0)
