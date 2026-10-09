extends GutTest
## PortalFx: random lightning of very different sizes out of the last seal's portal.


func test_bolts_appear_at_random_in_different_sizes_and_end() -> void:
	var fx := PortalFx.new()
	add_child_autofree(fx)
	fx.place(Vector2(500.0, 400.0), Vector2(100.0, 200.0))
	fx.intensity = 1.0
	var sizes := {}
	for i in 40:
		fx.spawn_bolt()
		sizes[snappedf(float(fx._bolts[fx._bolts.size() - 1]["size"]), 0.1)] = true
	assert_gt(sizes.size(), 3, "several size classes")
	await wait_seconds(0.9)
	fx.intensity = 0.0
	assert_eq(fx.bolt_count(), 0, "turning the effect off clears the bolts")


func test_a_bolt_is_a_jagged_path_between_two_points() -> void:
	var fx := PortalFx.new()
	add_child_autofree(fx)
	var points := fx.jagged(Vector2.ZERO, Vector2(0.0, -100.0), 4, 10.0)
	assert_eq(points.size(), 17)
	assert_eq(points[0], Vector2.ZERO)
	assert_eq(points[16], Vector2(0.0, -100.0))
