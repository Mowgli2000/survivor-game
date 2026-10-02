extends GutTest


func test_pool_reuses_released_objects() -> void:
	var pool := ObjectPool.new(func() -> Object: return RefCounted.new())
	pool.prewarm(2)
	assert_eq(pool.free_count(), 2)
	var a := pool.acquire()
	var b := pool.acquire()
	var c := pool.acquire()
	assert_eq(pool.created_count(), 3)
	pool.release(a)
	assert_same(pool.acquire(), a)
	assert_eq(pool.created_count(), 3)
	assert_ne(b, c)


func test_pick_index_respects_zero_weights() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var weights := PackedFloat32Array([0.0, 1.0, 0.0])
	for i in 50:
		assert_eq(WeightedPicker.pick_index(weights, rng), 1)
	assert_eq(WeightedPicker.pick_index(PackedFloat32Array([0.0, 0.0]), rng), -1)


func test_pick_index_distribution() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var counts := [0, 0]
	for i in 4000:
		counts[WeightedPicker.pick_index(PackedFloat32Array([3.0, 1.0]), rng)] += 1
	assert_almost_eq(counts[0] / 4000.0, 0.75, 0.04)


func test_pick_distinct() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var picked := WeightedPicker.pick_distinct(PackedFloat32Array([1.0, 1.0, 1.0, 1.0]), 3, rng)
	assert_eq(picked.size(), 3)
	assert_ne(picked[0], picked[1])
	assert_ne(picked[1], picked[2])
	assert_ne(picked[0], picked[2])
	assert_eq(WeightedPicker.pick_distinct(PackedFloat32Array([1.0, 0.0]), 3, rng).size(), 1)
