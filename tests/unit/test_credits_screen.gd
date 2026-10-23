extends GutTest
## Credits screen: opens, closes with its signal, every heading and text line is translated.


func test_open_shows_screen_and_close_emits_closed() -> void:
	var screen := CreditsScreen.new()
	add_child_autofree(screen)
	watch_signals(screen)
	screen.open()
	assert_true(screen.visible)
	screen.close()
	assert_false(screen.visible)
	assert_signal_emitted(screen, "closed")


func test_every_heading_and_key_line_is_translated() -> void:
	TranslationServer.set_locale("en")
	for section: Array in CreditsScreen.SECTIONS:
		assert_ne(tr(section[0]), section[0], "heading %s" % section[0])
		for line: String in section[1]:
			if line.begins_with("CREDITS_"):
				assert_ne(tr(line), line, "line %s" % line)


func test_music_credits_name_the_three_tracks() -> void:
	var lines: Array = []
	for section: Array in CreditsScreen.SECTIONS:
		if section[0] == "CREDITS_MUSIC":
			lines = section[1]
	var text := " ".join(lines)
	assert_string_contains(text, "qubodup")
	assert_string_contains(text, "cynicmusic")
	assert_string_contains(text, "CleytonRX")
