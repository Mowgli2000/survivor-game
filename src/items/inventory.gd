class_name Inventory
extends RefCounted
## Items owned during a run. Adding an item applies its stat modifiers for good.

signal changed
## One more copy of `item` (ItemEffects starts its effects).
signal item_added(item: ItemData)

var _stats: StatBlock
var _counts: Dictionary[ItemData, int] = {}
## First purchase order, each item once (UI listing).
var _order: Array[ItemData] = []


func _init(stats: StatBlock) -> void:
	_stats = stats


func count(item: ItemData) -> int:
	return _counts.get(item, 0)


func can_add(item: ItemData) -> bool:
	return item.max_count <= 0 or count(item) < item.max_count


func add(item: ItemData) -> bool:
	if not can_add(item):
		return false
	for mod in item.modifiers:
		_stats.add_modifier(mod)
	if not _counts.has(item):
		_order.append(item)
	_counts[item] = count(item) + 1
	item_added.emit(item)
	changed.emit()
	return true


func get_items() -> Array[ItemData]:
	return _order
