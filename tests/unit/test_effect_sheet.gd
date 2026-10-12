extends GutTest
## EffectSheet: frames of a painted effect, and the content that uses one.


func _sheet(frames: int = 6) -> EffectSheet:
	var sheet := EffectSheet.new()
	sheet.texture = ImageTexture.create_from_image(Image.create(300, 200, false, Image.FORMAT_RGBA8))
	sheet.columns = 3
	sheet.rows = 2
	sheet.frames = frames
	return sheet


func test_frames_are_read_row_by_row() -> void:
	var sheet := _sheet()
	assert_eq(sheet.frame_region(0), Rect2(0, 0, 100, 100))
	assert_eq(sheet.frame_region(2), Rect2(200, 0, 100, 100))
	assert_eq(sheet.frame_region(3), Rect2(0, 100, 100, 100))
	assert_eq(sheet.frame_region(5), Rect2(200, 100, 100, 100))


func test_frame_follows_progress_and_stays_in_range() -> void:
	var sheet := _sheet()
	assert_eq(sheet.frame_at(0.0), 0)
	assert_eq(sheet.frame_at(0.5), 3)
	assert_eq(sheet.frame_at(1.0), 5, "the end of the effect shows the last frame")
	assert_eq(sheet.frame_at(2.0), 5)
	assert_eq(sheet.frame_at(-1.0), 0)


func test_vfx_plays_and_removes_a_sheet_effect() -> void:
	var vfx := Vfx.new()
	add_child_autofree(vfx)
	var sheet := _sheet()
	sheet.duration = 0.2
	vfx.sheet(sheet, Vector2.ZERO, 0.0, 50.0)
	assert_eq(vfx.active_count(), 1)
	vfx._process(0.3)
	assert_eq(vfx.active_count(), 0, "gone after its duration")


func test_weapons_with_a_painted_slash_have_a_sheet_with_a_texture() -> void:
	for weapon: WeaponData in ContentDB.get_all(&"weapons"):
		if weapon.slash_sheet != null:
			assert_not_null(weapon.slash_sheet.texture, "%s slash sheet has a texture" % weapon.id)
