class_name Party
extends RefCounted
## The players of a run (1 or 2, ADR 0017) and the group queries every system
## uses instead of "the player": nearest living player, group center.
## Players call clamp_spread() after moving: never more than MAX_SPREAD apart.

## Max distance between two players, in px (both stay on the shared screen).
const MAX_SPREAD := 900.0

var members: Array[Player] = []


## A party of one (solo runs, tests).
static func solo(player: Player) -> Party:
	var party := Party.new()
	party.add(player)
	return party


func add(player: Player) -> void:
	members.append(player)


func size() -> int:
	return members.size()


func alive_count() -> int:
	var count := 0
	for player in members:
		if not player.is_dead:
			count += 1
	return count


## Closest living player to `pos`, or null when everyone is dead.
func nearest_alive(pos: Vector2) -> Player:
	var best: Player = null
	var best_d2 := INF
	for player in members:
		if player.is_dead:
			continue
		var d2 := player.global_position.distance_squared_to(pos)
		if d2 < best_d2:
			best_d2 = d2
			best = player
	return best


## Average position of the living players (of everyone when all are dead).
func center() -> Vector2:
	var total := Vector2.ZERO
	var count := 0
	for player in members:
		if not player.is_dead:
			total += player.global_position
			count += 1
	if count == 0:
		for player in members:
			total += player.global_position
		count = members.size()
	return total / maxf(count, 1.0)


## Largest distance between two living players (0 in solo).
func spread() -> float:
	var result := 0.0
	for i in members.size():
		for j in range(i + 1, members.size()):
			if members[i].is_dead or members[j].is_dead:
				continue
			result = maxf(result, members[i].global_position.distance_to(members[j].global_position))
	return result


## Position `player` may take: within MAX_SPREAD of every other living player.
func clamp_spread(player: Player, pos: Vector2) -> Vector2:
	if player.is_dead:
		return pos
	for other in members:
		if other == player or other.is_dead:
			continue
		var offset := pos - other.global_position
		if offset.length_squared() > MAX_SPREAD * MAX_SPREAD:
			pos = other.global_position + offset.normalized() * MAX_SPREAD
	return pos
