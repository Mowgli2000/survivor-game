extends GutTest
## Pickups: XP crystals and material coins are two separate kinds.


func _manager(max_gems: int) -> PickupManager:
	var player := Player.new()
	player.setup(CharacterData.new(), Rect2(-1000, -1000, 2000, 2000))
	player.invincible = true
	player.bot_input = func() -> Vector2: return Vector2.ZERO
	add_child_autofree(player)
	var pickups := PickupManager.new()
	pickups.setup(Party.solo(player), max_gems)
	add_child_autofree(pickups)
	return pickups


func test_coins_and_crystals_are_collected_separately() -> void:
	var pickups := _manager(10)
	watch_signals(pickups)
	pickups.spawn_xp(Vector2(900, 900), 5)
	pickups.spawn_material(Vector2(-900, 900), 2.5)
	assert_eq(pickups.active_count(), 2)
	pickups.collect_all()
	assert_signal_emitted_with_parameters(pickups, "xp_collected", [5, PickupManager.SHARED])
	assert_signal_emitted_with_parameters(pickups, "material_collected", [2.5, PickupManager.SHARED])


func test_a_full_pool_merges_into_the_same_kind() -> void:
	var pickups := _manager(2)
	watch_signals(pickups)
	pickups.spawn_xp(Vector2(900, 900), 3)
	pickups.spawn_material(Vector2(-900, 900), 1.0)
	pickups.spawn_material(Vector2(900, -900), 1.5)  # merged into the coin, not the crystal
	pickups.spawn_xp(Vector2(-900, -900), 4)  # merged into the crystal
	assert_eq(pickups.active_count(), 2)
	pickups.collect_all()
	assert_signal_emitted_with_parameters(pickups, "xp_collected", [7, PickupManager.SHARED])
	assert_signal_emitted_with_parameters(pickups, "material_collected", [2.5, PickupManager.SHARED])
