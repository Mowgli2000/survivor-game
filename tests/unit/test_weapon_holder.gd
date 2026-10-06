extends GutTest
## WeaponHolder: slots, copies, merging.


func test_copies_of_one_weapon_start_out_of_step() -> void:
	var holder := WeaponHolder.new()
	autofree(holder)
	var weapon: WeaponData = ContentDB.get_def(&"weapons", &"katana")
	var first := holder.add_weapon(weapon)
	var second := holder.add_weapon(weapon)
	var third := holder.add_weapon(weapon)
	assert_eq(first.cooldown, 0.0)
	assert_gt(second.cooldown, 0.0, "the second copy waits")
	assert_ne(second.cooldown, third.cooldown, "each copy has its own phase")
