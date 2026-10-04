extends GutTest


func _mod(stat: StringName, flat: float, percent: float) -> StatModifier:
	var mod := StatModifier.new()
	mod.stat = stat
	mod.flat = flat
	mod.percent = percent
	return mod


func test_defaults_and_overrides() -> void:
	var block := StatBlock.from_defaults({"max_hp": 80.0})
	assert_eq(block.get_value(StatIds.MAX_HP), 80.0)
	assert_eq(block.get_value(StatIds.MOVE_SPEED), StatIds.DEFAULTS[StatIds.MOVE_SPEED])


func test_flat_then_percent() -> void:
	var block := StatBlock.from_defaults({"max_hp": 100.0})
	block.add_modifier(_mod(StatIds.MAX_HP, 20.0, 0.0))
	block.add_modifier(_mod(StatIds.MAX_HP, 0.0, 0.5))
	assert_almost_eq(block.get_value(StatIds.MAX_HP), 180.0, 0.001)


func test_remove_modifier_restores_value() -> void:
	var block := StatBlock.from_defaults()
	var mod := _mod(StatIds.DAMAGE, 0.0, 0.25)
	block.add_modifier(mod)
	assert_almost_eq(block.get_value(StatIds.DAMAGE), 1.25, 0.001)
	block.remove_modifier(mod)
	assert_almost_eq(block.get_value(StatIds.DAMAGE), 1.0, 0.001)


func test_bounds_are_applied() -> void:
	var block := StatBlock.from_defaults()
	block.add_modifier(_mod(StatIds.CRIT_CHANCE, 3.0, 0.0))
	assert_eq(block.get_value(StatIds.CRIT_CHANCE), 1.0)
	block.add_modifier(_mod(StatIds.ATTACK_SPEED, 0.0, -5.0))
	assert_almost_eq(block.get_value(StatIds.ATTACK_SPEED), 0.1, 0.0001)


func test_changed_signal_and_cache_invalidation() -> void:
	var block := StatBlock.from_defaults()
	watch_signals(block)
	assert_eq(block.get_value(StatIds.ARMOR), 0.0)
	block.add_modifier(_mod(StatIds.ARMOR, 5.0, 0.0))
	assert_signal_emitted_with_parameters(block, "changed", [StatIds.ARMOR])
	assert_eq(block.get_value(StatIds.ARMOR), 5.0)


func test_value_with_previews_without_changing_the_block() -> void:
	var block := StatBlock.from_defaults({"max_hp": 100.0})
	var mod := StatModifier.new()
	mod.stat = StatIds.MAX_HP
	mod.flat = 16.0
	var extra: Array[StatModifier] = [mod]
	assert_eq(block.value_with(StatIds.MAX_HP, extra), 116.0)
	assert_eq(block.get_value(StatIds.MAX_HP), 100.0, "block unchanged")
