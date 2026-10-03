extends GutTest
## Weapon tiers, effective stats, weapon holder (duplicates, merging) and texts.


func _weapon() -> WeaponData:
	var data := WeaponData.new()
	data.base_damage = 10.0
	data.cooldown = 1.0
	data.area = 100.0
	data.explosion_radius = 50.0
	data.projectile_count = 1
	var l2 := WeaponLevel.new()
	l2.damage_percent = 0.5
	l2.projectile_count = 1
	var l3 := WeaponLevel.new()
	l3.fire_rate_percent = 1.0
	l3.area_percent = 0.2
	l3.bounces = 2
	data.levels = [l2, l3]
	return data


func test_level_one_uses_base_values() -> void:
	var s := WeaponStats.compute(_weapon(), 1)
	assert_eq(s.damage, 10.0)
	assert_eq(s.cooldown, 1.0)
	assert_eq(s.projectile_count, 1)


func test_levels_accumulate() -> void:
	var s := WeaponStats.compute(_weapon(), 3)
	assert_almost_eq(s.damage, 15.0, 0.001)
	assert_almost_eq(s.cooldown, 0.5, 0.001, "+100 % fire rate halves the cooldown")
	assert_eq(s.projectile_count, 2)
	assert_eq(s.bounces, 2)
	assert_almost_eq(s.area, 120.0, 0.001)
	assert_almost_eq(s.explosion_radius, 60.0, 0.001)


func test_level_is_clamped_to_max() -> void:
	var data := _weapon()
	assert_eq(data.max_level(), 3)
	var slot := WeaponSlot.new(data, 99)
	assert_eq(slot.level, 3)
	assert_true(slot.is_max_level())



func _holder() -> WeaponHolder:
	var holder := WeaponHolder.new()
	holder.max_slots = 3
	autofree(holder)
	return holder


func test_holder_allows_duplicates_up_to_full() -> void:
	var holder := _holder()
	var data := _weapon()
	watch_signals(holder)
	holder.add_weapon(data)
	holder.add_weapon(data)
	assert_eq(holder.slot_count(), 2, "duplicates take their own slot")
	assert_false(holder.is_full())
	holder.add_weapon(data)
	assert_true(holder.is_full())
	assert_signal_emit_count(holder, "weapons_changed", 3)


func test_merge_two_identical_weapons() -> void:
	var holder := _holder()
	var data := _weapon()
	holder.add_weapon(data)
	holder.add_weapon(_weapon())  # same stats, different definition: never merges
	holder.add_weapon(data)
	assert_eq(holder.find_merge_partner(0), 2)
	assert_eq(holder.find_merge_partner(1), -1)
	assert_true(holder.merge(0))
	assert_eq(holder.slot_count(), 2)
	assert_eq(holder.get_slots()[0].level, 2)
	assert_false(holder.merge(0), "no partner left")


func test_merge_needs_same_level_and_stops_at_max() -> void:
	var holder := _holder()
	var data := _weapon()  # max level 3
	holder.add_weapon(data, 1)
	holder.add_weapon(data, 2)
	assert_false(holder.merge(0), "different levels")
	holder.add_weapon(data, 2)
	assert_true(holder.merge(1))
	assert_eq(holder.get_slots()[1].level, 3)
	holder.add_weapon(data, 3)
	assert_eq(holder.find_merge_partner(1), -1, "max level never merges")


func test_find_slot_upgrade_and_remove() -> void:
	var holder := _holder()
	var data := _weapon()
	holder.add_weapon(data, 1)
	holder.add_weapon(data, 2)
	assert_eq(holder.find_slot(data, 2), 1)
	assert_eq(holder.find_slot(data, 3), -1)
	assert_true(holder.upgrade_slot(1))
	assert_eq(holder.get_slots()[1].level, 3)
	assert_false(holder.upgrade_slot(1), "already max")
	assert_eq(holder.find_slot(data, 3), -1, "a max level slot cannot be upgraded")
	holder.remove_weapon(0)
	assert_eq(holder.slot_count(), 1)
	holder.remove_weapon(5)  # out of range: ignored
	assert_eq(holder.slot_count(), 1)


func test_tier_names_and_colors() -> void:
	assert_eq(Tiers.roman(1), "I")
	assert_eq(Tiers.roman(4), "IV")
	assert_eq(Tiers.roman(9), "IV", "clamped")
	assert_ne(Tiers.color(1), Tiers.color(4))


func test_weapon_level_card_text() -> void:
	TranslationServer.set_locale("en")
	var bonus := WeaponLevel.new()
	bonus.damage_percent = 0.25
	bonus.projectile_count = 1
	assert_eq(LevelUpScreen.describe_weapon_level(bonus), "+25% Damage\n+1 Projectiles")


func test_layout_spreads_mounts_on_a_circle() -> void:
	assert_almost_eq(WeaponLayout.mount_offset(0, 1), Vector2(WeaponLayout.MOUNT_RADIUS, 0), Vector2.ONE * 0.01)
	var seen: Array[Vector2] = []
	for i in 6:
		var p := WeaponLayout.mount_offset(i, 6)
		assert_almost_eq(p.length(), WeaponLayout.MOUNT_RADIUS, 0.01)
		for q in seen:
			assert_gt(p.distance_to(q), 1.0)
		seen.append(p)


func test_holder_updates_mounts_when_weapons_change() -> void:
	var holder := _holder()
	var a := holder.add_weapon(_weapon())
	assert_eq(a.mount_offset, WeaponLayout.mount_offset(0, 1))
	var b := holder.add_weapon(_weapon())
	assert_eq(a.mount_offset, WeaponLayout.mount_offset(0, 2))
	assert_eq(b.mount_offset, WeaponLayout.mount_offset(1, 2))
	holder.remove_weapon(0)
	assert_eq(b.mount_offset, WeaponLayout.mount_offset(0, 1))
