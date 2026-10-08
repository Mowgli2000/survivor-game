class_name ChallengeData
extends Resource
## A challenge (ADR 0015): a condition checked at the end of each run and the
## content it unlocks. Instances live in data/challenges/.

enum Kind {
	WIN_WITH,  ## Win a run with `character_id`.
	WIN_ANY,  ## Win any run.
	TOTAL_KILLS,  ## Lifetime kills >= threshold.
	REACH_WAVE,  ## Reach wave >= threshold in one run.
	MATERIALS_HELD,  ## Hold >= threshold materials at once in one run.
	KILL_ENEMY,  ## Kill an enemy of type `enemy_id` (bosses).
	WIN_SEAL,  ## Win a run at seal (difficulty level) `threshold` or higher, any character.
	WIN_SEAL_WITH,  ## Win at seal `threshold` or higher with `character_id`.
}

@export var id: StringName
@export var name_key: String
@export var description_key: String
@export var kind: Kind = Kind.WIN_ANY
@export var character_id: StringName
@export var enemy_id: StringName
@export var threshold: int = 0
## What it unlocks: a ContentDB category and id (the target has `locked = true`).
## Empty `unlock_id` = nothing to unlock (collection challenge).
@export var unlock_category: StringName = &"characters"
@export var unlock_id: StringName
## Portal shards paid when completed (ADR 0023). Collection challenges
## (data/collection/) give shards and unlock nothing; progression challenges
## (data/challenges/) unlock content and give no shards.
@export var shards: int = 0


func is_collection() -> bool:
	return unlock_id == &"" and shards > 0


## True when the lifetime statistics alone already meet the condition (used to pay
## collection challenges a profile earned before they existed). Conditions that
## depend on a single run (materials held, bosses killed) are never met this way.
func is_met_by_profile(profile: Profile) -> bool:
	match kind:
		Kind.WIN_WITH:
			return profile.wins_by_character.get(character_id, 0) > 0
		Kind.WIN_ANY:
			return profile.runs_won > 0
		Kind.TOTAL_KILLS:
			return profile.total_kills >= threshold
		Kind.REACH_WAVE:
			return profile.best_wave >= threshold
		Kind.WIN_SEAL:
			return profile.best_difficulty() >= threshold
		Kind.WIN_SEAL_WITH:
			return profile.best_difficulty_by_character.get(character_id, -1) >= threshold
	return false


## `profile` already includes this run's statistics.
func is_met(profile: Profile, result: RunResult) -> bool:
	match kind:
		Kind.WIN_WITH:
			return result.won and result.character_id == character_id
		Kind.WIN_ANY:
			return result.won
		Kind.TOTAL_KILLS:
			return profile.total_kills >= threshold
		Kind.REACH_WAVE:
			return result.wave >= threshold
		Kind.MATERIALS_HELD:
			return result.max_materials >= threshold
		Kind.KILL_ENEMY:
			return result.killed_special.has(enemy_id)
		Kind.WIN_SEAL:
			return result.won and result.difficulty >= threshold
		Kind.WIN_SEAL_WITH:
			return result.won and result.difficulty >= threshold and result.character_id == character_id
	return false
