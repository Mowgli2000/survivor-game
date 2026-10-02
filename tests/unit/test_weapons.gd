extends GutTest
## Weapon levels, effective stats, weapon holder and level-up card texts.


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


func test_holder_add_and_level_up() -> void:
	var holder := WeaponHolder.new()
	autofree(holder)
	var data := _weapon()
	watch_signals(holder)
	holder.add_weapon(data)
	holder.add_weapon(data)
	assert_eq(holder.slot_count(), 1, "same weapon is never added twice")
	assert_true(holder.level_up(data))
	assert_true(holder.level_up(data))
	assert_false(holder.level_up(data), "already at max level")
	assert_eq(holder.owned_levels()[data], 3)
	assert_false(holder.level_up(WeaponData.new()), "not owned")
	assert_signal_emit_count(holder, "weapons_changed", 3)


func test_weapon_level_card_text() -> void:
	TranslationServer.set_locale("en")
	var bonus := WeaponLevel.new()
	bonus.damage_percent = 0.25
	bonus.projectile_count = 1
	assert_eq(LevelUpScreen.describe_weapon_level(bonus), "+25% Damage\n+1 Projectiles")


func test_offer_card_texts() -> void:
	TranslationServer.set_locale("en")
	var katana: WeaponData = ContentDB.get_def(&"weapons", &"katana")
	var texts := LevelUpScreen.describe_offer(UpgradeOffer.for_new_weapon(katana))
	assert_eq(texts[0], "New weapon")
	assert_eq(texts[1], "Plasma katana")
	var level_texts := LevelUpScreen.describe_offer(UpgradeOffer.for_weapon_level(katana, 2))
	assert_eq(level_texts[0], "Level 2")
	assert_eq(level_texts[2], "+25% Damage")
