class_name PeriodicHealEffect
extends ItemEffect
## Heals `amount` HP every `interval` seconds (only while the run is playing).

@export var interval: float = 5.0
@export var amount: float = 3.0

var _timer: float = 0.0


func on_tick(effects: ItemEffects, delta: float) -> void:
	_timer += delta
	if _timer >= interval:
		_timer -= interval
		effects.player.heal(amount)


func validate() -> PackedStringArray:
	return PackedStringArray(["interval must be > 0"]) if interval <= 0.0 else PackedStringArray()
