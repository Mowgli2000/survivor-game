extends GutTest
## UiHotspots: spots of a painted background that light up under the mouse.


func _hotspots() -> UiHotspots:
	var spots := UiHotspots.new()
	spots.picture_rect = func() -> Rect2: return Rect2(0.0, 0.0, 1000.0, 600.0)
	spots.add_spot(UiHotspots.Kind.CRYSTAL, Vector2(0.25, 0.5), 0.03, Color.CYAN)
	spots.add_spot(UiHotspots.Kind.SEAL, Vector2(0.5, 0.8), 0.25, Color.CYAN, 0.2)
	add_child_autofree(spots)
	return spots


func test_a_spot_far_from_the_mouse_stays_dark() -> void:
	var spots := _hotspots()
	assert_eq(spots.spot_count(), 2)
	assert_false(spots._hovered(spots._spots[0], Rect2(0.0, 0.0, 1000.0, 600.0), Vector2(900.0, 100.0)))
	assert_eq(spots.level_of(0), 0.0)


func test_the_mouse_over_a_crystal_or_the_seal_lights_it() -> void:
	var spots := _hotspots()
	var rect := Rect2(0.0, 0.0, 1000.0, 600.0)
	assert_true(spots._hovered(spots._spots[0], rect, Vector2(250.0, 300.0)), "crystal center")
	assert_true(spots._hovered(spots._spots[1], rect, Vector2(500.0, 480.0)), "seal center")
	assert_true(spots._hovered(spots._spots[1], rect, Vector2(650.0, 480.0)), "seal side (wide ellipse)")
	assert_false(spots._hovered(spots._spots[1], rect, Vector2(500.0, 300.0)), "far above the flat seal")


func test_reduce_motion_lights_instantly() -> void:
	UiFx.reduce_motion = true
	var spots := _hotspots()
	spots._process(0.016)
	UiFx.reduce_motion = false
	assert_between(spots.level_of(0), 0.0, 1.0)


func test_the_fire_loop_runs_while_a_flame_is_hovered_and_stops_after() -> void:
	Audio.loop_start(&"test_fire", Sounds.FIRE_CRACKLE, -20.0)
	assert_true(Audio.is_loop_playing(&"test_fire"))
	Audio.loop_start(&"test_fire", Sounds.FIRE_CRACKLE, -20.0)
	assert_true(Audio.is_loop_playing(&"test_fire"), "starting twice keeps one loop")
	Audio.loop_stop(&"test_fire", 0.05)
	await wait_seconds(0.2)
	assert_false(Audio.is_loop_playing(&"test_fire"))
