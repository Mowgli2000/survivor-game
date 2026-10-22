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


func test_camera_zoom_defaults_to_one_is_clamped_and_round_trips() -> void:
	var s := SettingsData.new()
	assert_eq(s.camera_zoom, 1.0, "default zoom unchanged")
	s.set_value(&"camera_zoom", 0.9)
	assert_almost_eq(SettingsData.from_dict(s.to_dict()).camera_zoom, 0.9, 0.0001)
	s.set_value(&"camera_zoom", 5.0)
	assert_eq(s.camera_zoom, SettingsData.ZOOM_MAX)
	s.set_value(&"camera_zoom", 0.1)
	assert_eq(s.camera_zoom, SettingsData.ZOOM_MIN)
	assert_false(s.set_value(&"camera_zoom", "far"), "wrong type rejected")



func test_fps_cap_and_resolution_default_to_untouched_and_round_trip() -> void:
	var s := SettingsData.new()
	assert_eq(s.fps_cap, 0, "no cap by default")
	assert_eq(s.resolution, 0, "window left alone by default")
	assert_false(s.light_mode)
	s.set_value(&"fps_cap", 60)
	s.set_value(&"resolution", 3)
	s.set_value(&"light_mode", true)
	var back := SettingsData.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	assert_eq(back.fps_cap, 60, "JSON turns ints into floats: still read as 60")
	assert_eq(back.resolution, 3)
	assert_true(back.light_mode)


func test_unknown_fps_cap_and_out_of_range_resolution_are_corrected() -> void:
	var s := SettingsData.from_dict({"fps_cap": 77, "resolution": 99})
	assert_eq(s.fps_cap, 0, "a cap that is not offered means no cap")
	assert_eq(s.resolution, SettingsData.RESOLUTIONS.size(), "clamped to the biggest size")
	assert_false(s.set_value(&"fps_cap", "fast"), "wrong type rejected")


func test_accessibility_options_default_to_off_clamp_and_round_trip() -> void:
	var s := SettingsData.new()
	assert_eq(s.text_size, 0)
	assert_eq(s.colorblind, 0)
	assert_false(s.reduce_flashes)
	s.set_value(&"text_size", 2)
	s.set_value(&"colorblind", 3)
	s.set_value(&"reduce_flashes", true)
	var back := SettingsData.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	assert_eq(back.text_size, 2)
	assert_eq(back.colorblind, 3)
	assert_true(back.reduce_flashes)
	assert_eq(SettingsData.from_dict({"text_size": 9, "colorblind": -4}).text_size, SettingsData.TEXT_SCALES.size() - 1)
	assert_eq(SettingsData.from_dict({"colorblind": -4}).colorblind, 0)
