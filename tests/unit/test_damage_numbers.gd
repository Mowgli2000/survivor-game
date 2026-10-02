extends GutTest


func test_crit_is_bigger_than_normal() -> void:
	assert_gt(DamageNumbers.font_size_for(10.0, true), DamageNumbers.font_size_for(10.0, false))


func test_size_grows_with_damage_but_is_capped() -> void:
	var small := DamageNumbers.font_size_for(5.0, false)
	var big := DamageNumbers.font_size_for(100.0, false)
	var huge := DamageNumbers.font_size_for(100000.0, false)
	assert_eq(small, DamageNumbers.NORMAL_SIZE)
	assert_gt(big, small)
	assert_eq(huge, big)


func test_pop_starts_large_and_settles_to_one() -> void:
	assert_gt(DamageNumbers.pop_scale(0.0, false), 1.4)
	assert_gt(DamageNumbers.pop_scale(0.0, true), DamageNumbers.pop_scale(0.0, false))
	assert_almost_eq(DamageNumbers.pop_scale(DamageNumbers.POP_TIME, false), 1.0, 0.001)
	assert_almost_eq(DamageNumbers.pop_scale(0.5, true), 1.0, 0.001)


func test_spawn_respects_disabled_flag() -> void:
	var numbers := DamageNumbers.new()
	numbers.enabled = false
	numbers.spawn(Vector2.ZERO, 10.0, false)
	assert_eq(numbers.alive_count(), 0)
	numbers.enabled = true
	numbers.spawn(Vector2.ZERO, 10.0, false)
	assert_eq(numbers.alive_count(), 1)
	numbers.free()
