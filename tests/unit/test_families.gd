extends GutTest
## Weapon families: set bonuses at 2 / 4 / 6 weapons of a family.

var _holder: WeaponHolder
var _stats: StatBlock
var _families: WeaponFamilies


func before_each() -> void:
	_holder = WeaponHolder.new()
	_holder.max_slots = 6
	autofree(_holder)
	_stats = StatBlock.from_defaults()
	var all: Array[FamilyData] = []
	all.assign(ContentDB.get_all(&"families"))
	_families = WeaponFamilies.new()
	_families.setup(_holder, _stats, all)


func _weapon(id: StringName) -> WeaponData:
	return ContentDB.get_def(&"weapons", id)


func test_two_blades_give_the_first_bonus() -> void:
	_holder.add_weapon(_weapon(&"katana"))
	assert_eq(_families.count(&"blade"), 1)
	assert_almost_eq(_stats.get_value(StatIds.CRIT_CHANCE), 0.0, 0.0001, "1 blade: nothing")
	_holder.add_weapon(_weapon(&"shuriken"))
	assert_almost_eq(_stats.get_value(StatIds.CRIT_CHANCE), 0.05, 0.0001)


func test_duplicates_count_and_tiers_do_not_stack() -> void:
	for i in 4:
		_holder.add_weapon(_weapon(&"katana"))
	assert_eq(_families.count(&"blade"), 4)
	assert_almost_eq(_stats.get_value(StatIds.CRIT_CHANCE), 0.10, 0.0001, "4-weapon tier only")


func test_selling_drops_back_a_tier() -> void:
	for i in 4:
		_holder.add_weapon(_weapon(&"katana"))
	_holder.remove_weapon(0)
	assert_almost_eq(_stats.get_value(StatIds.CRIT_CHANCE), 0.05, 0.0001)
	_holder.remove_weapon(0)
	_holder.remove_weapon(0)
	assert_almost_eq(_stats.get_value(StatIds.CRIT_CHANCE), 0.0, 0.0001)


func test_every_weapon_belongs_to_an_existing_family() -> void:
	for def in ContentDB.get_all(&"weapons"):
		var weapon := def as WeaponData
		assert_gt(weapon.families.size(), 0, "%s has no family" % weapon.id)
		for family in weapon.families:
			assert_true(ContentDB.has_def(&"families", family), "%s: unknown family %s" % [weapon.id, family])


func test_families_have_names_and_rising_tiers() -> void:
	for def in ContentDB.get_all(&"families"):
		var family := def as FamilyData
		assert_ne(tr(family.name_key), family.name_key, "%s name" % family.id)
		var last := 0
		for bonus in family.bonuses:
			assert_gt(bonus.count, last, "%s tiers in rising order" % family.id)
			last = bonus.count
