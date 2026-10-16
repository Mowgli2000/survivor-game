extends GutTest
## The boss test arena (debug): a real run opened on the boss wave, nothing recorded.

const ARENA := preload("res://src/debug/boss_arena.tscn")


func test_every_listed_fight_names_a_boss_with_phases() -> void:
	for fight in load("res://src/debug/boss_arena.gd").FIGHTS:
		var def: EnemyData = ContentDB.get_def(&"enemies", fight[0])
		assert_not_null(def, "%s exists" % fight[0])
		assert_false(def.phases.is_empty(), "%s is a boss" % fight[0])


func test_starting_a_final_boss_fight_spawns_it_on_wave_20_without_recording() -> void:
	var arena: Control = ARENA.instantiate()
	add_child_autofree(arena)
	arena._boss.select(0)
	arena._phase.select(1)
	arena._start_fight()
	assert_false(arena._run.record_profile, "the profile is never touched")
	assert_eq(arena._run.waves.wave, 20, "the run opens on the boss wave")
	await wait_seconds(2.0)
	assert_true(arena._run.enemies.has_living_boss(), "the Demon Knight is there")
	var boss: Enemy = null
	for enemy in arena._run.enemies._active:
		if enemy.data.boss:
			boss = enemy
	assert_not_null(boss)
	assert_lt(boss.hp / boss.max_hp, 0.6, "phase 2 start: the boss has lost life")
