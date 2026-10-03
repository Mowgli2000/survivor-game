extends GutTest
## Arena decor: floor decals stay inside and away from the spawn, props outside.


func test_decor_placement() -> void:
	var rect := Rect2(-1200, -1200, 2400, 2400)
	var arena := Arena.new()
	add_child_autofree(arena)
	arena.setup(rect)
	assert_gt(arena.decal_count(), 0)
	assert_gt(arena.prop_count(), 0)
	for decal in arena._decals:
		var pos: Vector2 = decal[1]
		assert_true(rect.has_point(pos), "decal inside the arena")
		assert_gt(pos.distance_to(rect.get_center()), Arena.DECAL_CLEAR_CENTER - 0.1, "spawn kept clear")
	for prop in arena._props:
		assert_false(rect.grow(-1.0).has_point(prop[1]), "props stand outside the arena")


func test_layout_is_the_same_every_run() -> void:
	var a := Arena.new()
	var b := Arena.new()
	add_child_autofree(a)
	add_child_autofree(b)
	a.setup(Rect2(-1000, -1000, 2000, 2000))
	b.setup(Rect2(-1000, -1000, 2000, 2000))
	assert_eq(a._decals, b._decals)
