class_name ConditionalStatEffect
extends ItemEffect
## "+X % of a stat per step of another": e.g. +1 % damage per armor point.
## Uses the source's bonus over its base value (so move speed counts only what
## items and upgrades added). Kept up to date when the source changes.

@export var source_stat: StringName = StatIds.ARMOR
## Size of one step of the source stat.
@export var step: float = 1.0
@export var target_stat: StringName = StatIds.DAMAGE
@export var percent_per_step: float = 0.01
@export var flat_per_step: float = 0.0

var _stats: StatBlock
var _applied: StatModifier


func on_acquired(effects: ItemEffects) -> void:
	_stats = effects.stats
	_stats.changed.connect(_on_stat_changed)
	_update()


func preview_modifiers(stats: StatBlock, _weapons: WeaponHolder) -> Array[StatModifier]:
	var steps := floorf(maxf(stats.get_value(source_stat) - stats.get_base(source_stat), 0.0) / step)
	var mod := StatModifier.new()
	mod.stat = target_stat
	mod.percent = percent_per_step * steps
	mod.flat = flat_per_step * steps
	return [mod]


func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if source_stat == target_stat:
		problems.append("source and target are the same stat (feedback loop)")
	if step <= 0.0:
		problems.append("step must be > 0")
	if not StatIds.is_valid(source_stat) or not StatIds.is_valid(target_stat):
		problems.append("unknown stat")
	return problems


func _on_stat_changed(stat: StringName) -> void:
	if stat == source_stat:
		_update()


func _update() -> void:
	if _applied != null:
		_stats.remove_modifier(_applied)
	var steps := floorf(maxf(_stats.get_value(source_stat) - _stats.get_base(source_stat), 0.0) / step)
	_applied = StatModifier.new()
	_applied.stat = target_stat
	_applied.percent = percent_per_step * steps
	_applied.flat = flat_per_step * steps
	_stats.add_modifier(_applied)
