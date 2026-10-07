extends GutTest
## Progression screen: up / down scroll the read-only list (gamepad).


func test_holding_down_scrolls_the_list() -> void:
	var screen := ProgressionScreen.new()
	add_child_autofree(screen)
	screen.open()
	await wait_process_frames(2)
	Input.action_press(&"ui_down")
	await wait_process_frames(10)
	Input.action_release(&"ui_down")
	assert_gt(screen._scroll.scroll_vertical, 0, "the list moved down")
