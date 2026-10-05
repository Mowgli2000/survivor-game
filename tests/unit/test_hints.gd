extends GutTest
## First-time tips (HintBanner): shown once per profile, never when turned off.


func before_each() -> void:
	SafeFile.remove(SaveService.TEST_PATH)
	SaveService.load_profile()
	Settings.data.show_hints = true


func after_each() -> void:
	SafeFile.remove(SaveService.TEST_PATH)
	SaveService.load_profile()
	Settings.load_settings()


func _parent() -> Control:
	var parent := Control.new()
	add_child_autofree(parent)
	return parent


func test_a_tip_is_shown_only_the_first_time() -> void:
	var parent := _parent()
	assert_not_null(HintBanner.show_once(parent, &"shop"))
	assert_null(HintBanner.show_once(parent, &"shop"), "already seen")
	assert_not_null(HintBanner.show_once(parent, &"level_up"), "other tips stay")


func test_seen_tips_survive_a_reload() -> void:
	HintBanner.show_once(_parent(), &"move")
	SaveService.load_profile()
	assert_true(SaveService.has_seen_hint(&"move"))
	assert_false(SaveService.has_seen_hint(&"shop"))


func test_no_tip_when_turned_off() -> void:
	Settings.data.show_hints = false
	assert_null(HintBanner.show_once(_parent(), &"shop"))
	assert_false(SaveService.has_seen_hint(&"shop"), "still shown once turned back on")


func test_every_tip_has_a_text() -> void:
	for key: StringName in [&"move", &"stats", &"level_up", &"shop", &"seals"]:
		var text_key := HintBanner.text_key(key)
		assert_ne(TranslationServer.translate(text_key), StringName(text_key), text_key)


func test_profile_drops_bad_hint_entries() -> void:
	var profile := Profile.from_dict({"seen_hints": ["shop", 3, "shop", null]})
	assert_eq(profile.seen_hints, [&"shop"] as Array[StringName])
