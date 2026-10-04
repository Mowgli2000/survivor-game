class_name StatBlock
extends RefCounted
## Base values + modifiers for a set of stats, with cached final values.
## Formula: (base + sum(flat)) * (1 + sum(percent)), then clamped by StatIds.BOUNDS.

signal changed(stat: StringName)

var _base: Dictionary[StringName, float] = {}
var _flat: Dictionary[StringName, float] = {}
var _percent: Dictionary[StringName, float] = {}
var _cache: Dictionary[StringName, float] = {}


## Creates a block filled with StatIds.DEFAULTS, overridden by `overrides`.
static func from_defaults(overrides: Dictionary = {}) -> StatBlock:
	var block := StatBlock.new()
	for stat: StringName in StatIds.DEFAULTS:
		block._base[stat] = StatIds.DEFAULTS[stat]
	for key in overrides:
		block._base[StringName(key)] = float(overrides[key])
	return block


func set_base(stat: StringName, value: float) -> void:
	_base[stat] = value
	_invalidate(stat)


func get_base(stat: StringName) -> float:
	return _base.get(stat, 0.0)


func add_modifier(mod: StatModifier) -> void:
	_flat[mod.stat] = _flat.get(mod.stat, 0.0) + mod.flat
	_percent[mod.stat] = _percent.get(mod.stat, 0.0) + mod.percent
	_invalidate(mod.stat)


func remove_modifier(mod: StatModifier) -> void:
	_flat[mod.stat] = _flat.get(mod.stat, 0.0) - mod.flat
	_percent[mod.stat] = _percent.get(mod.stat, 0.0) - mod.percent
	_invalidate(mod.stat)


func get_value(stat: StringName) -> float:
	if _cache.has(stat):
		return _cache[stat]
	var value: float = (_base.get(stat, 0.0) + _flat.get(stat, 0.0)) * (1.0 + _percent.get(stat, 0.0))
	if StatIds.BOUNDS.has(stat):
		var bounds: Vector2 = StatIds.BOUNDS[stat]
		value = clampf(value, bounds.x, bounds.y)
	_cache[stat] = value
	return value


## Value `stat` would have with `extra` modifiers added (preview, no change).
func value_with(stat: StringName, extra: Array[StatModifier]) -> float:
	var flat: float = _flat.get(stat, 0.0)
	var percent: float = _percent.get(stat, 0.0)
	for mod in extra:
		if mod.stat == stat:
			flat += mod.flat
			percent += mod.percent
	var value: float = (_base.get(stat, 0.0) + flat) * (1.0 + percent)
	if StatIds.BOUNDS.has(stat):
		var bounds: Vector2 = StatIds.BOUNDS[stat]
		value = clampf(value, bounds.x, bounds.y)
	return value


func _invalidate(stat: StringName) -> void:
	_cache.erase(stat)
	changed.emit(stat)
