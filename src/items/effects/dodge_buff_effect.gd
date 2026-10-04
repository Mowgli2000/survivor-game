class_name DodgeBuffEffect
extends ItemEffect
## After each dodge, `modifier` applies for `duration` seconds (a new dodge
## restarts the timer, it does not stack). Assassin rule "Shadow step".

@export var modifier: StatModifier
@export var duration: float = 2.0

var _time_left: float = 0.0
var _applied: bool = false
var _effects: ItemEffects


func on_acquired(effects: ItemEffects) -> void:
	_effects = effects
	effects.player.dodged.connect(_on_dodged)


func on_tick(effects: ItemEffects, delta: float) -> void:
	if not _applied:
		return
	_time_left -= delta
	if _time_left <= 0.0:
		effects.stats.remove_modifier(modifier)
		_applied = false


func is_active() -> bool:
	return _applied


func _on_dodged() -> void:
	_time_left = duration
	if not _applied:
		_effects.stats.add_modifier(modifier)
		_applied = true


func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if modifier == null:
		problems.append("modifier is missing")
	if duration <= 0.0:
		problems.append("duration must be > 0")
	return problems
