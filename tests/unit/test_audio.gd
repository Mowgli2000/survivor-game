extends GutTest
## Audio service: anti-saturation rules (hordes trigger dozens of sounds per frame).

const STREAM := preload("res://assets/audio/sfx/enemy_hit.ogg")


func before_each() -> void:
	Audio.stop_all()


func after_all() -> void:
	Audio.stop_all()


func test_same_sound_twice_in_a_row_is_skipped() -> void:
	assert_true(Audio.play(STREAM))
	assert_false(Audio.play(STREAM), "within MIN_INTERVAL_MS")


func test_voices_of_one_sound_are_capped() -> void:
	var played := 0
	for i in Audio.MAX_VOICES + 3:
		Audio.forget_last_play(STREAM)  # simulate time passing
		if Audio.play(STREAM):
			played += 1
	assert_eq(played, Audio.MAX_VOICES)
	assert_eq(Audio.voices(STREAM), Audio.MAX_VOICES)


func test_null_stream_is_ignored() -> void:
	assert_false(Audio.play(null))


func test_buses_exist() -> void:
	assert_ne(AudioServer.get_bus_index(Audio.MUSIC_BUS), -1)
	assert_ne(AudioServer.get_bus_index(Audio.SFX_BUS), -1)


func test_every_weapon_has_a_fire_sound() -> void:
	for def in ContentDB.get_all(&"weapons"):
		assert_not_null((def as WeaponData).fire_sound, "%s has no fire sound" % def.get("id"))
