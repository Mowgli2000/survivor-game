class_name Profile
extends RefCounted
## Player profile kept between runs (ADR 0015): unlocks, completed challenges
## and lifetime statistics. Pure data; SaveService writes it as versioned JSON.
## from_dict() never trusts its input (hand-edited or older files).

const VERSION := 1
const MAX_DIFFICULTY := 5

## category -> unlocked ids (content whose `locked` flag is lifted).
var unlocked: Dictionary[StringName, Array] = {}
var completed: Array[StringName] = []
var runs_played: int = 0
var runs_won: int = 0
var best_wave: int = 0
var total_kills: int = 0
var wins_by_character: Dictionary[StringName, int] = {}
## Highest difficulty level won with each character.
var best_difficulty_by_character: Dictionary[StringName, int] = {}
## Best wave reached in endless mode with each character.
var best_endless_wave_by_character: Dictionary[StringName, int] = {}


## Highest difficulty level `character` may pick: one above its best win.
func max_difficulty(character: StringName) -> int:
	return mini(best_difficulty_by_character.get(character, -1) + 1, MAX_DIFFICULTY)


func is_unlocked(category: StringName, id: StringName) -> bool:
	return unlocked.get(category, []).has(id)


func unlock(category: StringName, id: StringName) -> void:
	if not unlocked.has(category):
		unlocked[category] = []
	if not unlocked[category].has(id):
		unlocked[category].append(id)


func to_dict() -> Dictionary:
	var unlocks := {}
	for category in unlocked:
		var ids: Array[String] = []
		for id: StringName in unlocked[category]:
			ids.append(String(id))
		unlocks[String(category)] = ids
	var done: Array[String] = []
	for id in completed:
		done.append(String(id))
	var wins := {}
	for character in wins_by_character:
		wins[String(character)] = wins_by_character[character]
	return {
		"version": VERSION,
		"unlocked": unlocks,
		"completed": done,
		"runs_played": runs_played,
		"runs_won": runs_won,
		"best_wave": best_wave,
		"total_kills": total_kills,
		"wins_by_character": wins,
		"best_difficulty_by_character": _id_ints(best_difficulty_by_character),
		"best_endless_wave_by_character": _id_ints(best_endless_wave_by_character),
	}


static func from_dict(d: Dictionary) -> Profile:
	# Version 1 is the first format: a missing version reads the same keys.
	var profile := Profile.new()
	var unlocks: Variant = d.get("unlocked")
	if unlocks is Dictionary:
		for category: Variant in unlocks:
			if unlocks[category] is Array:
				for id: Variant in unlocks[category]:
					if id is String:
						profile.unlock(StringName(str(category)), StringName(id))
	var done: Variant = d.get("completed")
	if done is Array:
		for id: Variant in done:
			if id is String:
				profile.completed.append(StringName(id))
	profile.runs_played = _int(d, "runs_played")
	profile.runs_won = _int(d, "runs_won")
	profile.best_wave = _int(d, "best_wave")
	profile.total_kills = _int(d, "total_kills")
	var wins: Variant = d.get("wins_by_character")
	if wins is Dictionary:
		for character: Variant in wins:
			if typeof(wins[character]) in [TYPE_INT, TYPE_FLOAT]:
				profile.wins_by_character[StringName(str(character))] = int(wins[character])
	_read_id_ints(d.get("best_difficulty_by_character"), profile.best_difficulty_by_character)
	_read_id_ints(d.get("best_endless_wave_by_character"), profile.best_endless_wave_by_character)
	return profile


static func _id_ints(source: Dictionary[StringName, int]) -> Dictionary:
	var out := {}
	for key in source:
		out[String(key)] = source[key]
	return out


static func _read_id_ints(source: Variant, target: Dictionary[StringName, int]) -> void:
	if not source is Dictionary:
		return
	for key: Variant in source:
		if typeof(source[key]) in [TYPE_INT, TYPE_FLOAT]:
			target[StringName(str(key))] = int(source[key])


static func _int(d: Dictionary, key: String) -> int:
	var value: Variant = d.get(key)
	return maxi(int(value), 0) if typeof(value) in [TYPE_INT, TYPE_FLOAT] else 0
