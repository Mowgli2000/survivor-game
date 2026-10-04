class_name MissingHpStatEffect
extends ItemEffect
## +`percent_per_point` of `target_stat` per percent of max HP missing, updated
## when health changes. Berserker rule "Rage" (+1 % damage per % HP missing).

@export var target_stat: StringName = StatIds.DAMAGE
@export var percent_per_point: float = 0.01

var _player: Player
var _applied: StatModifier


func on_acquired(effects: ItemEffects) -> void:
	_player = effects.player
	_player.health_changed.connect(func(_hp: float, _max_hp: float) -> void: _update())
	_update()


func current_bonus() -> float:
	return _applied.percent if _applied != null else 0.0


func _update() -> void:
	var max_hp := _player.stats.get_value(StatIds.MAX_HP)
	var missing := clampf(1.0 - _player.hp / maxf(max_hp, 1.0), 0.0, 1.0) * 100.0
	var percent := roundf(missing) * percent_per_point
	if _applied != null:
		if is_equal_approx(_applied.percent, percent):
			return
		_player.stats.remove_modifier(_applied)
	_applied = StatModifier.new()
	_applied.stat = target_stat
	_applied.percent = percent
	_player.stats.add_modifier(_applied)


func validate() -> PackedStringArray:
	return PackedStringArray(["unknown stat"]) if not StatIds.is_valid(target_stat) else PackedStringArray()
