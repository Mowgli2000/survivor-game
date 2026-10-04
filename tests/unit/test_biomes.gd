extends GutTest
## Seals and biomes (ADR 0018): each seal's gate swaps the bestiary and arena.


func test_biome_swaps_every_role_and_boss() -> void:
	var stage: StageData = ContentDB.get_def(&"stages", &"default")
	var iron: DifficultyData = ContentDB.get_def(&"difficulties", &"danger_1")
	var copy := stage.with_difficulty(iron)
	for entry in copy.spawn_pool:
		assert_true(String(entry.enemy.id).begins_with("iron_"), "%s swapped" % entry.enemy.id)
	for event in copy.events:
		if event.enemy != null:
			assert_true(String(event.enemy.id).begins_with("iron_"), "event %s swapped" % event.enemy.id)
	for entry in stage.spawn_pool:
		assert_false(String(entry.enemy.id).begins_with("iron_"), "the shared stage is never modified")


func test_every_seal_has_a_biome_and_a_color() -> void:
	for difficulty: DifficultyData in ContentDB.get_all(&"difficulties"):
		assert_not_null(difficulty.biome, String(difficulty.id))


func test_biome_monsters_keep_their_role_size() -> void:
	var temple: BiomeData = ContentDB.get_def(&"biomes", &"temple")
	for base_id in temple.enemy_swaps:
		var base: EnemyData = ContentDB.get_def(&"enemies", base_id)
		var swapped: EnemyData = temple.enemy_swaps[base_id]
		assert_eq(swapped.boss, base.boss, String(base_id))
		assert_eq(swapped.radius, base.radius, String(base_id))
