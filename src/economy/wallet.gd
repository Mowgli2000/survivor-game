class_name Wallet
extends RefCounted
## Materials of the current run (Brotato-style: every XP pickup is also money).

signal changed(amount: int)

var amount: int = 0

var _fraction: float = 0.0


func add(value: int) -> void:
	if value <= 0:
		return
	amount += value
	changed.emit(amount)


func can_afford(cost: int) -> bool:
	return cost >= 0 and cost <= amount


## Returns false (and spends nothing) when the cost is negative or above `amount`.
func spend(cost: int) -> bool:
	if not can_afford(cost):
		return false
	amount -= cost
	changed.emit(amount)
	return true


## Adds `value * rate`, keeping the fractional part for the next call
## (materials per pickup that drop below 1 over the run).
func add_scaled(value: int, rate: float) -> void:
	_fraction += value * rate
	# Epsilon: 0.6 added ten times must give 6, not 5.999...
	var whole := floori(_fraction + 0.0001)
	_fraction -= whole
	add(whole)
