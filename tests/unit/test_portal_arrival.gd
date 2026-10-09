extends GutTest
## Start of a run entered through the seal screen's portal: a gate opens on the map, the
## heroes walk out of it, the gate closes, then the first wave starts.


func _run_with_arrival() -> Run:
	var setup := RunSetup.new()
	setup.portal_intro = true
	setup.difficulty = ContentDB.get_def(&"difficulties", &"danger_0")
	var run: Run = preload("res://src/run/run.tscn").instantiate()
	run.setup = setup
	return run


func test_the_first_wave_waits_for_the_gate_to_close() -> void:
	var run := _run_with_arrival()
	add_child_autofree(run)
	await wait_physics_frames(3)
	assert_false(run.waves.in_wave, "the heroes are still walking out")
	assert_gt(run.player._arrival_left, 0.0)
	await wait_seconds(PortalArrival.start_delay() + 0.3)
	assert_true(run.waves.in_wave, "the gate closed: wave 1 runs")
	assert_eq(run.waves.wave, 1)
	assert_lte(run.player._arrival_left, 0.0, "the hero arrived")


func test_a_run_without_the_portal_starts_at_once() -> void:
	var run: Run = preload("res://src/run/run.tscn").instantiate()
	add_child_autofree(run)
	await wait_physics_frames(2)
	assert_true(run.waves.in_wave)


func test_the_gate_takes_the_seal_color() -> void:
	var last := SealSelect.all_levels()[5]
	var gate := ArrivalGate.new()
	gate.setup(100.0, 1.0, last.color)
	add_child_autofree(gate)
	var mid: Vector3 = (gate.get_child(1) as Sprite2D).material.get_shader_parameter(&"mid")
	assert_gt(mid.x, mid.z, "last seal: red, more red than blue")
	var blue := ArrivalGate.new()
	blue.setup(100.0, 1.0, SealSelect.all_levels()[0].color)
	add_child_autofree(blue)
	var blue_mid: Vector3 = (blue.get_child(1) as Sprite2D).material.get_shader_parameter(&"mid")
	assert_gt(blue_mid.z, blue_mid.x, "blue: more blue than red")
