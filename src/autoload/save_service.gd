extends Node
## Profile persistence (autoload "SaveService", ADR 0015): user://profile.json,
## JSON only (never a Resource from user://). Records finished runs, checks
## challenges and applies their unlocks. No run logic here.
## Example: `SaveService.is_unlocked(&"items", item)` filters the shop pool.

signal profile_changed

const DEFAULT_PATH := "user://profile.json"
## Used by the GUT pre-run hook: tests never touch the player's profile.
const TEST_PATH := "user://test_profile.json"

var path: String = DEFAULT_PATH
var profile := Profile.new()


func _ready() -> void:
	load_profile()


func load_profile() -> void:
	profile = Profile.new()
	if FileAccess.file_exists(path):
		var json := JSON.new()
		if json.parse(FileAccess.get_file_as_string(path)) == OK and json.data is Dictionary:
			profile = Profile.from_dict(json.data)
		else:
			push_warning("SaveService: unreadable %s, starting a new profile" % path)
	profile_changed.emit()


func save_profile() -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("SaveService: cannot write %s" % path)
		return
	file.store_string(JSON.stringify(profile.to_dict(), "\t"))


## Content is available unless it is `locked` and not unlocked yet.
func is_unlocked(category: StringName, def: Resource) -> bool:
	if def == null or not def.get(&"locked"):
		return true
	return profile.is_unlocked(category, def.get(&"id"))


## Updates the statistics, completes the challenges this run meets, applies
## their unlocks and saves. Returns the challenges completed now.
func record_run(result: RunResult, challenges: Array[ChallengeData] = []) -> Array[ChallengeData]:
	if challenges.is_empty():
		challenges = all_challenges()
	profile.runs_played += 1
	profile.total_kills += result.kills
	profile.best_wave = maxi(profile.best_wave, result.wave)
	if result.won:
		profile.runs_won += 1
		profile.wins_by_character[result.character_id] = profile.wins_by_character.get(result.character_id, 0) + 1
	var done: Array[ChallengeData] = []
	for challenge in challenges:
		if profile.completed.has(challenge.id) or not challenge.is_met(profile, result):
			continue
		profile.completed.append(challenge.id)
		profile.unlock(challenge.unlock_category, challenge.unlock_id)
		done.append(challenge)
	save_profile()
	profile_changed.emit()
	return done


func all_challenges() -> Array[ChallengeData]:
	var list: Array[ChallengeData] = []
	list.assign(ContentDB.get_all(&"challenges"))
	return list
