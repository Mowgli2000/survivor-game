extends GutTest
## Stats panel texts: bonuses shown the way players read them.


func before_each() -> void:
	TranslationServer.set_locale("en")


func test_multiplier_stats_show_the_bonus_percent() -> void:
	assert_eq(StatsPanel.format_value(StatIds.DAMAGE, 1.23), "+23%")
	assert_eq(StatsPanel.format_value(StatIds.ATTACK_SPEED, 0.9), "-10%")
	assert_eq(StatsPanel.format_value(StatIds.AREA, 1.0), "+0%")


func test_other_stats_show_their_value() -> void:
	assert_eq(StatsPanel.format_value(StatIds.CRIT_CHANCE, 0.12), "12%")
	assert_eq(StatsPanel.format_value(StatIds.CRIT_DAMAGE, 1.5), "x1.5")
	assert_eq(StatsPanel.format_value(StatIds.PROJECTILE_COUNT, 2.0), "+2")
	assert_eq(StatsPanel.format_value(StatIds.MAX_HP, 115.0), "115")
	assert_eq(StatsPanel.format_value(StatIds.HP_REGEN, 1.5), "1.5")


func test_panel_lists_every_stat_and_follows_changes() -> void:
	var stats := StatBlock.from_defaults()
	var panel := StatsPanel.new()
	add_child_autofree(panel)
	panel.setup(stats)
	assert_eq(panel.line_count(), StatIds.DEFAULTS.size())
	var bonus := StatModifier.new()
	bonus.stat = StatIds.DAMAGE
	bonus.percent = 0.2
	stats.add_modifier(bonus)
	assert_eq(panel.value_text(StatIds.DAMAGE), "+20%")


func test_stats_action_exists() -> void:
	assert_true(InputMap.has_action("show_stats"))
