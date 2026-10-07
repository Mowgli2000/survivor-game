extends GutTest
## Melee weapons: the Range stat lengthens the reach at half effect (Brotato rule).


func test_no_range_bonus_keeps_the_base_reach() -> void:
	var stats := StatBlock.from_defaults({})
	assert_almost_eq(MeleeArcBehavior.reach_multiplier(stats), 1.0, 0.001)


func test_range_bonus_counts_half_for_melee() -> void:
	var stats := StatBlock.from_defaults({"range": 1.4})
	assert_almost_eq(MeleeArcBehavior.reach_multiplier(stats), 1.2, 0.001)
