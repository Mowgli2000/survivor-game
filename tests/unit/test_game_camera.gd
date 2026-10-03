extends GutTest
## GameCamera screen shake: smooth motion (no per-frame jitter that reads as
## blur) and explosions alone never saturate it.


func _camera() -> GameCamera:
	var camera := GameCamera.new()
	add_child_autofree(camera)
	return camera


func test_shake_moves_smoothly_between_frames() -> void:
	var camera := _camera()
	camera.add_trauma(1.0)
	camera._process(1.0 / 240.0)  # the first frame jumps from rest: that is the impact
	var previous := camera.offset
	var biggest_step := 0.0
	for i in 20:
		camera._process(1.0 / 240.0)  # high refresh rate screen
		biggest_step = maxf(biggest_step, camera.offset.distance_to(previous))
		previous = camera.offset
	assert_gt(previous.length() + biggest_step, 0.0, "it does shake")
	# White noise jumped up to 2 x amplitude (tens of px) every frame.
	assert_lt(biggest_step, 4.0, "no big jump from one rendered frame to the next")


func test_explosions_alone_cannot_saturate_the_shake() -> void:
	var camera := _camera()
	for i in 20:
		camera.add_trauma(0.4, GameCamera.EXPLOSION_CAP)
	assert_almost_eq(camera.trauma(), GameCamera.EXPLOSION_CAP, 0.001)
	camera.add_trauma(0.35)  # a hit on the player still adds on top
	assert_gt(camera.trauma(), GameCamera.EXPLOSION_CAP)
