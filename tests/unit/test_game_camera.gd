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


func test_camera_follows_at_the_physics_rate() -> void:
	# The players move in physics ticks; a camera updated every rendered frame
	# makes them stutter against the world on high refresh rate screens (seen as blur).
	assert_eq(_camera().process_callback, Camera2D.CAMERA2D_PROCESS_PHYSICS)


func _player_at(pos: Vector2) -> Player:
	var player := Player.new()
	player.setup(CharacterData.new(), Rect2(-5000, -5000, 10000, 10000))
	player.position = pos
	add_child_autofree(player)
	return player


func test_follows_the_center_of_the_party() -> void:
	var party := Party.new()
	party.add(_player_at(Vector2(-100, 0)))
	party.add(_player_at(Vector2(300, 200)))
	var camera := _camera()
	camera.follow(party, 1.0)
	assert_eq(camera.global_position, Vector2(100, 100))


func test_zooms_out_when_two_players_spread_apart() -> void:
	var party := Party.new()
	party.add(_player_at(Vector2.ZERO))
	var far := _player_at(Vector2(Party.MAX_SPREAD, 0))
	party.add(far)
	var camera := _camera()
	camera.follow(party, 1.0)
	for i in 120:
		camera._physics_process(1.0 / 60.0)
	assert_almost_eq(camera.zoom.x, GameCamera.MIN_ZOOM_FACTOR, 0.001)


func test_solo_keeps_the_configured_zoom() -> void:
	var party := Party.solo(_player_at(Vector2(50, 50)))
	var camera := _camera()
	camera.follow(party, 1.3)
	for i in 30:
		camera._physics_process(1.0 / 60.0)
	assert_eq(camera.zoom, Vector2(1.3, 1.3))
