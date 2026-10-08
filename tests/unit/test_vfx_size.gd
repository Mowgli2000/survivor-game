extends GutTest
## Late game: drawn effects grow slower than the real hit area (readability).


func test_small_effects_keep_their_real_size() -> void:
	var vfx := Vfx.new()
	autofree(vfx)
	assert_eq(vfx.shown_size(100.0, Vfx.SLASH_FULL), 100.0)


func test_oversized_effects_grow_at_a_fraction() -> void:
	var vfx := Vfx.new()
	autofree(vfx)
	var shown := vfx.shown_size(600.0, Vfx.SLASH_FULL)
	assert_lt(shown, 600.0)
	assert_almost_eq(shown, Vfx.SLASH_FULL + (600.0 - Vfx.SLASH_FULL) * Vfx.OVERSIZE_SHARE, 0.01)


func test_coop_draws_effects_smaller() -> void:
	var vfx := Vfx.new()
	autofree(vfx)
	vfx.coop_scale = 0.8
	assert_almost_eq(vfx.shown_size(100.0, Vfx.SLASH_FULL), 80.0, 0.01)
