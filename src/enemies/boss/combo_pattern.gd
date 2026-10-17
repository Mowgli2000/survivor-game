class_name ComboPattern
extends BossPattern
## A finale attack made of several attacks played together: every part announces itself at the windup and fires on
## the same volleys (a part with fewer repeats simply stops earlier). Parts share the windup and the interval of the
## combo, so each warning is exactly the attack that follows it.

@export var parts: Array[BossPattern] = []


func telegraph(ctx: BossContext, boss: Enemy, aim: Vector2) -> void:
	for part in parts:
		part.telegraph(ctx, boss, aim)


func fire(ctx: BossContext, boss: Enemy, aim: Vector2, repeat: int) -> void:
	for part in parts:
		if repeat < part.repeats:
			part.fire(ctx, boss, aim, repeat)


func validate() -> String:
	if parts.size() < 2:
		return "a combo needs two attacks"
	var most := 1
	for part in parts:
		var problem := part.validate()
		if problem != "":
			return problem
		if not is_equal_approx(part.windup, windup):
			return "a combo's parts share its windup"
		if part.repeats > 1 and not is_equal_approx(part.repeat_interval, repeat_interval):
			return "a combo's parts share its repeat interval"
		most = maxi(most, part.repeats)
	if repeats != most:
		return "a combo has as many volleys as its longest part"
	return super.validate()
