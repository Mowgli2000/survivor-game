extends GutTest
## HitStop: a short real-time freeze through Engine.time_scale, restored afterwards.


func before_each() -> void:
	Engine.time_scale = 1.0


func after_each() -> void:
	Engine.time_scale = 1.0


func _hit_stop() -> HitStop:
	var hit_stop := HitStop.new()
	add_child_autofree(hit_stop)
	return hit_stop


func test_freezes_then_restores_the_time_scale() -> void:
	var hit_stop := _hit_stop()
	assert_true(hit_stop.request(0.05))
	assert_true(hit_stop.is_frozen())
	assert_almost_eq(Engine.time_scale, HitStop.FROZEN_SCALE, 0.0001)
	await wait_seconds(0.2)  # real time: the timer ignores the time scale
	assert_false(hit_stop.is_frozen())
	assert_almost_eq(Engine.time_scale, 1.0, 0.0001)


func test_disabled_never_freezes() -> void:
	var hit_stop := _hit_stop()
	hit_stop.enabled = false
	assert_false(hit_stop.request(0.05))
	assert_almost_eq(Engine.time_scale, 1.0, 0.0001)


func test_a_second_freeze_too_soon_is_refused_unless_forced() -> void:
	var hit_stop := _hit_stop()
	assert_true(hit_stop.request(0.02))
	await wait_seconds(0.1)
	assert_false(hit_stop.request(0.02), "inside the minimum gap")
	assert_true(hit_stop.request(0.02, true), "forced (final boss death)")


func test_base_scale_set_during_a_freeze_applies_at_the_end() -> void:
	var hit_stop := _hit_stop()
	hit_stop.request(0.05)
	hit_stop.set_base_scale(0.5)  # the boss death slow-motion starts under the freeze
	assert_almost_eq(Engine.time_scale, HitStop.FROZEN_SCALE, 0.0001, "still frozen")
	await wait_seconds(0.2)
	assert_almost_eq(Engine.time_scale, 0.5, 0.0001)


func test_base_scale_outside_a_freeze_applies_at_once() -> void:
	var hit_stop := _hit_stop()
	hit_stop.set_base_scale(0.5)
	assert_almost_eq(Engine.time_scale, 0.5, 0.0001)


func test_leaving_the_tree_during_a_freeze_restores_the_time_scale() -> void:
	var hit_stop := HitStop.new()
	add_child(hit_stop)
	hit_stop.request(1.0)
	hit_stop.free()
	assert_almost_eq(Engine.time_scale, 1.0, 0.0001)
