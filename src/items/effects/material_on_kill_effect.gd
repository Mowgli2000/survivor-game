class_name MaterialOnKillEffect
extends ItemEffect
## Killed enemies may give extra materials straight to the wallet.

@export_range(0.0, 1.0) var chance: float = 0.08
@export var amount: int = 1


func on_enemy_killed(effects: ItemEffects, _data: EnemyData, _pos: Vector2, _elite: bool) -> void:
	if effects.roll(chance):
		effects.wallet.add(amount)
