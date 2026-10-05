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
}

@export var id: StringName
@export var name_key: String
@export var description_key: String
@export var kind: Kind = Kind.WIN_ANY
@export var character_id: StringName
@export var enemy_id: StringName
@export var threshold: int = 0
## What it unlocks: a ContentDB category and id (the target has `locked = true`).
@export var unlock_category: StringName = &"characters"
@export var unlock_id: StringName


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
	return false
