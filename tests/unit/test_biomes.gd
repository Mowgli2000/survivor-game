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


func test_every_place_swaps_all_nine_roles_with_baked_sprites() -> void:
	for biome: BiomeData in ContentDB.get_all(&"biomes"):
		if biome.enemy_swaps.is_empty():
			continue  # the default dungeon keeps the base monsters
		assert_eq(biome.enemy_swaps.size(), 9, String(biome.id))
		assert_not_null(biome.decor, String(biome.id) + " decor")
		for base_id in biome.enemy_swaps:
			var enemy: EnemyData = biome.enemy_swaps[base_id]
			var path := "res://assets/sprites/%s.tres" % enemy.sprite_id
			assert_true(ResourceLoader.exists(path), "%s: sprite %s" % [biome.id, enemy.sprite_id])


func test_seal_runs_only_meet_their_place_monsters() -> void:
	var stage: StageData = ContentDB.get_def(&"stages", &"default")
	for difficulty: DifficultyData in ContentDB.get_all(&"difficulties"):
		if difficulty.biome == null or difficulty.biome.enemy_swaps.is_empty():
			continue
		var place := difficulty.biome.enemy_swaps.values()
		var copy := stage.with_difficulty(difficulty)
		for entry in copy.spawn_pool:
			assert_true(place.has(entry.enemy), "%s: %s" % [difficulty.id, entry.enemy.id])
		for event in copy.events:
			if event.enemy != null:
				assert_true(place.has(event.enemy), "%s: event %s" % [difficulty.id, event.enemy.id])


func test_boss_summons_come_from_their_own_place() -> void:
	for biome: BiomeData in ContentDB.get_all(&"biomes"):
		var place := biome.enemy_swaps.values()
		for enemy: EnemyData in place:
			for phase in enemy.phases:
				for pattern in phase.patterns:
					assert_eq(pattern.validate(), "", "%s pattern" % enemy.id)
					if pattern is SummonPattern:
						assert_true(place.has((pattern as SummonPattern).enemy), "%s summons from its place" % enemy.id)


func test_every_seal_leads_to_its_own_place() -> void:
	var seen: Dictionary = {}
	for difficulty: DifficultyData in ContentDB.get_all(&"difficulties"):
		assert_false(seen.has(difficulty.biome), "%s shares a place" % difficulty.id)
		seen[difficulty.biome] = true
