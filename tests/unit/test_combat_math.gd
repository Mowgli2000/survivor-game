extends GutTest


func test_crit_roll() -> void:
	assert_true(CombatMath.is_crit(0.25, 0.1))
	assert_false(CombatMath.is_crit(0.25, 0.25))
	assert_false(CombatMath.is_crit(0.0, 0.0))


func test_outgoing_damage() -> void:
	assert_almost_eq(CombatMath.outgoing_damage(10.0, 1.5, false, 2.0), 15.0, 0.001)
	assert_almost_eq(CombatMath.outgoing_damage(10.0, 1.5, true, 2.0), 30.0, 0.001)


func test_armor_reduces_with_diminishing_returns() -> void:
	assert_almost_eq(CombatMath.apply_armor(100.0, 0.0), 100.0, 0.001)
	assert_almost_eq(CombatMath.apply_armor(100.0, 100.0), 50.0, 0.001)
	assert_lt(CombatMath.apply_armor(100.0, 300.0), CombatMath.apply_armor(100.0, 100.0))


func test_negative_armor_increases_damage() -> void:
	assert_almost_eq(CombatMath.apply_armor(100.0, -100.0), 150.0, 0.001)


func test_minimum_one_damage() -> void:
	assert_eq(CombatMath.apply_armor(2.0, 10000.0), 1.0)
	assert_eq(CombatMath.apply_armor(0.0, 0.0), 0.0)
