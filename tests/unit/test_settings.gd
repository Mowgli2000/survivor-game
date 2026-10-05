extends GutTest
## Settings autoload: file round trip, corrupt file, engine application.


func before_each() -> void:
	SafeFile.remove(Settings.TEST_PATH)
	Settings.path = Settings.TEST_PATH
	Settings.load_settings()


func after_all() -> void:
	SafeFile.remove(Settings.TEST_PATH)
	Settings.load_settings()
	TranslationServer.set_locale("en")


func test_values_survive_a_reload() -> void:
	Settings.set_value(&"sfx_volume", 0.3)
	Settings.set_value(&"reduce_motion", true)
	Settings.load_settings()
	assert_almost_eq(Settings.data.sfx_volume, 0.3, 0.0001)
	assert_true(UiFx.reduce_motion)
	Settings.set_value(&"reduce_motion", false)
	assert_false(UiFx.reduce_motion)


func test_corrupt_file_gives_defaults() -> void:
	var file := FileAccess.open(Settings.TEST_PATH, FileAccess.WRITE)
	file.store_string("{not json")
	file.close()
	Settings.load_settings()
	assert_almost_eq(Settings.data.master_volume, 0.8, 0.0001)


func test_volume_goes_to_the_bus_and_zero_mutes() -> void:
	var bus := AudioServer.get_bus_index(&"Music")
	Settings.set_value(&"music_volume", 0.5)
	assert_almost_eq(AudioServer.get_bus_volume_db(bus), linear_to_db(0.5), 0.01)
	assert_false(AudioServer.is_bus_mute(bus))
	Settings.set_value(&"music_volume", 0.0)
	assert_true(AudioServer.is_bus_mute(bus))


func test_locale_is_applied() -> void:
	Settings.set_value(&"locale", "fr")
	assert_eq(TranslationServer.get_locale(), "fr")


func test_changed_is_emitted() -> void:
	watch_signals(Settings)
	Settings.set_value(&"vsync", false)
	assert_signal_emitted(Settings, "changed")
