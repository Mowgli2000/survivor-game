extends GutTest
## Upgrade card descriptions (number formatting, independent of the language).


func before_each() -> void:
	TranslationServer.set_locale("en")


func _upgrade(stat: StringName, flat: float, percent: float) -> UpgradeData:
	var mod := StatModifier.new()
	mod.stat = stat
	mod.flat = flat
	mod.percent = percent
	var upgrade := UpgradeData.new()
	upgrade.modifiers = [mod]
	return upgrade


func test_percent_modifier() -> void:
	assert_eq(LevelUpScreen.describe(_upgrade(StatIds.DAMAGE, 0.0, 0.15)), "+15% Damage")


func test_flat_integer_modifier() -> void:
	assert_eq(LevelUpScreen.describe(_upgrade(StatIds.MAX_HP, 20.0, 0.0)), "+20 Max HP")


func test_fraction_stat_shown_as_percent() -> void:
	assert_eq(LevelUpScreen.describe(_upgrade(StatIds.CRIT_CHANCE, 0.05, 0.0)), "+5% Crit chance")
