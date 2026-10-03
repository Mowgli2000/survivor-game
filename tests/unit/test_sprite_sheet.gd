extends GutTest
## SpriteSheet (frame lookup, regions) and SpriteAnimator (looping, facing).


func _sheet() -> SpriteSheet:
	var sheet := SpriteSheet.new()
	sheet.cell_size = Vector2i(10, 20)
	sheet.animations = {&"idle": Vector3i(0, 4, 8), &"walk": Vector3i(4, 2, 10)}
	return sheet


func test_frame_at_loops() -> void:
	var sheet := _sheet()
	assert_eq(sheet.frame_at(&"idle", 0.0), 0)
	assert_eq(sheet.frame_at(&"idle", 0.13), 1)
	assert_eq(sheet.frame_at(&"idle", 0.5), 0, "4 frames at 8 fps loop every 0.5 s")
	assert_eq(sheet.frame_at(&"walk", 0.15), 5)


func test_frame_stays_in_bounds_for_huge_times() -> void:
	var f := _sheet().frame_at(&"walk", 123456.789)
	assert_between(f, 4, 5)


func test_missing_animation_falls_back_to_walk() -> void:
	var sheet := _sheet()
	assert_false(sheet.has_animation(&"fly"))
	assert_eq(sheet.frame_at(&"fly", 0.0), 4)


func test_region() -> void:
	assert_eq(_sheet().region(5), Rect2(50, 0, 10, 20))


func test_region_is_offset_by_atlas_origin() -> void:
	var sheet := _sheet()
	sheet.origin = Vector2i(3, 40)
	assert_eq(sheet.region(5), Rect2(53, 40, 10, 20))


func test_animator_reports_frame_and_facing_changes() -> void:
	var animator := SpriteAnimator.new()
	animator.reset(_sheet(), 0.0)
	assert_false(animator.advance(0.01, &"walk", 0.0), "same frame, no facing input")
	assert_true(animator.advance(0.1, &"walk", 0.0), "walk frame 4 -> 5")
	assert_true(animator.advance(0.0, &"walk", -5.0), "turned left")
	assert_eq(animator.facing, -1.0)
	assert_false(animator.advance(0.0, &"walk", -5.0))


func test_animator_keeps_current_animation_when_missing() -> void:
	var animator := SpriteAnimator.new()
	animator.reset(_sheet(), 0.0)
	animator.advance(0.0, &"fly", 0.0)
	assert_eq(animator.animation, &"walk")


func test_animator_without_sheet_does_nothing() -> void:
	var animator := SpriteAnimator.new()
	animator.reset(null, 0.0)
	assert_false(animator.advance(1.0, &"walk", 3.0))


func test_draw_rect_stays_centered_when_mirrored() -> void:
	var sheet := _sheet()  # cells 10 x 20
	var right := sheet.draw_rect(40.0, 5.0, 1.0)
	var left := sheet.draw_rect(40.0, 5.0, -1.0)
	assert_eq(right, Rect2(-10, -35, 20, 40))
	# Negative width = mirrored; Godot keeps position.x, so x must stay -10.
	assert_eq(left, Rect2(-10, -35, -20, 40))
