extends GutTest
## Gamepad hint bars: a screen covered by another one hides its bar and it stays hidden.


func after_each() -> void:
	ButtonHints.show_always = false


func test_a_bar_hidden_by_its_screen_stays_hidden() -> void:
	ButtonHints.show_always = true
	var bar := ButtonHints.create([[&"A", "UI_HINT_CONFIRM"]])
	add_child_autofree(bar)
	assert_true(bar.visible, "shown while hints are forced on")
	bar.visible = false  # the screen opens a sub-screen
	bar._process(0.0)
	assert_false(bar.visible, "the bar does not come back on top of the sub-screen's own bar")
