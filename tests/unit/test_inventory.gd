extends GutTest
## Inventory: owned items and their stat modifiers.


func _item(max_count: int = 0) -> ItemData:
	var mod := StatModifier.new()
	mod.stat = StatIds.ARMOR
	mod.flat = 2.0
	var item := ItemData.new()
	item.id = &"test_item"
	item.modifiers = [mod]
	item.max_count = max_count
	return item


func test_add_applies_modifiers_and_counts() -> void:
	var stats := StatBlock.from_defaults()
	var inventory := Inventory.new(stats)
	var item := _item()
	watch_signals(inventory)
	assert_true(inventory.add(item))
	assert_true(inventory.add(item))
	assert_eq(inventory.count(item), 2)
	assert_eq(stats.get_value(StatIds.ARMOR), 4.0)
	assert_eq(inventory.get_items().size(), 1, "each item listed once")
	assert_signal_emit_count(inventory, "changed", 2)


func test_max_count_is_respected() -> void:
	var stats := StatBlock.from_defaults()
	var inventory := Inventory.new(stats)
	var item := _item(1)
	assert_true(inventory.add(item))
	assert_false(inventory.can_add(item))
	assert_false(inventory.add(item))
	assert_eq(stats.get_value(StatIds.ARMOR), 2.0, "refused item changes nothing")
