class_name InterestEffect
extends ItemEffect
## End of wave: gain a share of the materials kept (saving vs spending).

@export var percent: float = 0.1
@export var cap: int = 25


func on_wave_ended(effects: ItemEffects, _wave: int) -> void:
	var gain := mini(floori(effects.wallet.amount * percent), cap)
	if gain > 0:
		effects.wallet.add(gain)
