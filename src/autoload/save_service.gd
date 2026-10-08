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
		# Falls back to the backup of the last good save (SafeFile).
		var saved := SafeFile.read_json(path)
		if saved.is_empty():
			push_warning("SaveService: unreadable %s, starting a new profile" % path)
		else:
			profile = Profile.from_dict(saved)
	_grant_past_seal_rewards()
	_grant_past_collection()
	profile_changed.emit()


## Seal rewards came after some seals were already won: a profile that holds a
## win at seal N (best_difficulty_by_character) gets the rewards up to N.
func _grant_past_seal_rewards() -> void:
	var best := -1
	for level in profile.best_difficulty_by_character.values():
		best = maxi(best, int(level))
	if best < 0:
		return
	var granted := false
	for challenge in all_challenges():
		if challenge.kind != ChallengeData.Kind.WIN_SEAL or challenge.threshold > best:
			continue
		if profile.completed.has(challenge.id):
			continue
		profile.completed.append(challenge.id)
		profile.unlock(challenge.unlock_category, challenge.unlock_id)
		granted = true
	if granted:
		save_profile()


## Collection challenges came after some runs were played: the statistics already
## kept pay the ones they meet (shards only, nothing is unlocked).
func _grant_past_collection() -> void:
	var granted := false
	for challenge in collection_challenges():
		if profile.completed.has(challenge.id) or not challenge.is_met_by_profile(profile):
			continue
		profile.completed.append(challenge.id)
		profile.add_shards(challenge.shards)
		granted = true
	if granted:
		save_profile()


func save_profile() -> void:
	# Crash-safe: temp file, backup, then replace (SafeFile).
	if not SafeFile.write_text(path, JSON.stringify(profile.to_dict(), "\t")):
		push_warning("SaveService: cannot write %s" % path)


## Content is available unless it is `locked` and not unlocked yet.
func has_seen_hint(key: StringName) -> bool:
	return profile.seen_hints.has(key)


func mark_hint_seen(key: StringName) -> void:
	if not profile.seen_hints.has(key):
		profile.seen_hints.append(key)
		save_profile()


func is_unlocked(category: StringName, def: Resource) -> bool:
	if def == null or not def.get(&"locked"):
		return true
	return profile.is_unlocked(category, def.get(&"id"))


## Updates the statistics, completes the challenges this run meets, applies
## their unlocks and saves. Returns the challenges completed now.
func record_run(result: RunResult, challenges: Array[ChallengeData] = []) -> Array[ChallengeData]:
	if challenges.is_empty():
		challenges = all_challenges()
		challenges.append_array(collection_challenges())
	profile.runs_played += 1
	profile.total_kills += result.kills
	profile.best_wave = maxi(profile.best_wave, result.wave)
	if result.won:
		profile.runs_won += 1
		profile.wins_by_character[result.character_id] = profile.wins_by_character.get(result.character_id, 0) + 1
		profile.best_difficulty_by_character[result.character_id] = maxi(
			profile.best_difficulty_by_character.get(result.character_id, -1), result.difficulty)
	var done: Array[ChallengeData] = []
	for challenge in challenges:
		if profile.completed.has(challenge.id) or not challenge.is_met(profile, result):
			continue
		profile.completed.append(challenge.id)
		if challenge.unlock_id != &"":
			profile.unlock(challenge.unlock_category, challenge.unlock_id)
		profile.add_shards(challenge.shards)
		done.append(challenge)
	save_profile()
	profile_changed.emit()
	return done


## Endless mode ended (the run itself was recorded at the victory).
func record_endless(character_id: StringName, wave: int) -> void:
	profile.best_endless_wave_by_character[character_id] = maxi(
		profile.best_endless_wave_by_character.get(character_id, 0), wave)
	save_profile()
	profile_changed.emit()


## Collection challenges (data/collection/): they pay portal shards for the skin shop.
func collection_challenges() -> Array[ChallengeData]:
	var list: Array[ChallengeData] = []
	list.assign(ContentDB.get_all(&"collection"))
	return list


## False while the seal a (prestige) skin asks for has not been won by any hunter.
func is_skin_available(skin: SkinData) -> bool:
	return skin.required_seal < 0 or profile.best_difficulty() >= skin.required_seal


## Buys a skin with portal shards: false when unknown, already owned or too expensive.
func buy_skin(skin: SkinData) -> bool:
	if skin == null or profile.is_unlocked(&"skins", skin.id) or not is_skin_available(skin):
		return false
	if not profile.spend_shards(skin.price):
		return false
	profile.unlock(&"skins", skin.id)
	save_profile()
	profile_changed.emit()
	return true


## Progression challenges (data/challenges/): they unlock content.
func all_challenges() -> Array[ChallengeData]:
	var list: Array[ChallengeData] = []
	list.assign(ContentDB.get_all(&"challenges"))
	return list
