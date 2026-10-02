extends GutTest

var _grid: SpatialGrid
var _out: Array[int] = []


func before_each() -> void:
	_grid = SpatialGrid.new(Rect2(-500, -500, 1000, 1000), 64.0)


func test_query_radius_returns_only_items_in_range() -> void:
	var positions := PackedVector2Array([Vector2(0, 0), Vector2(50, 0), Vector2(200, 0), Vector2(-60, 30)])
	_grid.rebuild(positions, positions.size())
	var found := _grid.query_radius(Vector2.ZERO, 100.0, _out)
	assert_eq(found, 3)
	assert_has(_out, 0)
	assert_has(_out, 1)
	assert_has(_out, 3)
	assert_does_not_have(_out, 2)


func test_nearest() -> void:
	var positions := PackedVector2Array([Vector2(300, 300), Vector2(-120, 10), Vector2(90, -90)])
	_grid.rebuild(positions, positions.size())
	assert_eq(_grid.nearest(Vector2.ZERO, 1000.0), 1)  # (-120, 10) is ~120 away, (90, -90) ~127
	assert_eq(_grid.nearest(Vector2(280, 280), 1000.0), 0)
	assert_eq(_grid.nearest(Vector2.ZERO, 50.0), -1)


func test_nearest_matches_brute_force() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var positions := PackedVector2Array()
	for i in 300:
		positions.append(Vector2(rng.randf_range(-500, 500), rng.randf_range(-500, 500)))
	_grid.rebuild(positions, positions.size())
	for t in 50:
		var center := Vector2(rng.randf_range(-500, 500), rng.randf_range(-500, 500))
		var best := -1
		var best_d2 := INF
		for i in positions.size():
			var d2 := positions[i].distance_squared_to(center)
			if d2 < best_d2:
				best_d2 = d2
				best = i
		var found := _grid.nearest(center, 2000.0)
		assert_almost_eq(positions[found].distance_squared_to(center), best_d2, 0.01, "query %d" % t)


func test_rebuild_with_fewer_items_and_outside_positions() -> void:
	var positions := PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(5000, 5000)])
	_grid.rebuild(positions, 3)
	assert_eq(_grid.query_radius(Vector2(5000, 5000), 10.0, _out), 1)
	_grid.rebuild(positions, 1)
	assert_eq(_grid.size(), 1)
	assert_eq(_grid.query_radius(Vector2.ZERO, 100.0, _out), 1)


func test_empty_grid() -> void:
	_grid.rebuild(PackedVector2Array(), 0)
	assert_eq(_grid.nearest(Vector2.ZERO, 100.0), -1)
	assert_eq(_grid.query_radius(Vector2.ZERO, 100.0, _out), 0)
