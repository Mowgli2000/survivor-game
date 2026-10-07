extends GutTest
## Wave timer warning: from 5 seconds left the timer grows a step each second.


func test_timer_keeps_its_size_before_the_last_five_seconds() -> void:
	assert_eq(Hud.timer_font_size(30), Hud.TIMER_FONT_SIZE)
	assert_eq(Hud.timer_font_size(6), Hud.TIMER_FONT_SIZE)


func test_timer_grows_each_of_the_last_seconds() -> void:
	var previous := Hud.TIMER_FONT_SIZE
	for seconds in [5, 4, 3, 2, 1]:
		var size := Hud.timer_font_size(seconds)
		assert_gt(size, previous, "%d s left is bigger than the second before" % seconds)
		previous = size


func test_timer_is_back_to_normal_at_zero() -> void:
	assert_eq(Hud.timer_font_size(0), Hud.TIMER_FONT_SIZE)
