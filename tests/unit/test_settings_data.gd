extends GutTest
## SettingsData: validation and JSON round trip.


func test_round_trip_keeps_every_value() -> void:
	var s := SettingsData.new()
	s.set_value(&"music_volume", 0.25)
	s.set_value(&"fullscreen", true)
	s.set_value(&"locale", "fr")
	var back := SettingsData.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	assert_almost_eq(back.music_volume, 0.25, 0.0001)
	assert_true(back.fullscreen)
	assert_eq(back.locale, "fr")
	assert_eq(int(s.to_dict()["version"]), SettingsData.VERSION)


func test_bad_values_are_rejected_or_clamped() -> void:
	var s := SettingsData.from_dict({"master_volume": 3.0, "sfx_volume": -1, "vsync": "yes",
		"locale": "de", "unknown": 1})
	assert_eq(s.master_volume, 1.0)
	assert_eq(s.sfx_volume, 0.0)
	assert_true(s.vsync, "wrong type keeps the default")
	assert_eq(s.locale, "", "unknown locale = system")
	assert_false(s.set_value(&"nope", 1))


func test_empty_dict_gives_defaults() -> void:
	var s := SettingsData.from_dict({})
	assert_almost_eq(s.master_volume, 0.8, 0.0001)
	assert_true(s.screen_shake)
	assert_false(s.reduce_motion)
