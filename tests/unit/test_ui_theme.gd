extends GutTest
## UiTheme (shared "chibi neon" look) and UiFx (UI animations).


func after_each() -> void:
	UiFx.reduce_motion = false


func test_theme_is_built_once() -> void:
	assert_same(UiTheme.get_theme(), UiTheme.get_theme())


func test_default_font_is_nunito() -> void:
	var font := UiTheme.get_theme().default_font as FontVariation
	assert_not_null(font)
	assert_eq(font.base_font, UiTheme.NUNITO)


func test_buttons_have_every_state() -> void:
	var theme := UiTheme.get_theme()
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		assert_true(theme.has_stylebox(state, "Button"), "Button %s style" % state)


func test_type_variations_exist() -> void:
	var theme := UiTheme.get_theme()
	for variation in [&"TitleLabel", &"SubtitleLabel", &"SmallLabel"]:
		assert_eq(theme.get_type_variation_base(variation), &"Label", "%s is a Label variation" % variation)
	assert_eq(theme.get_type_variation_base(&"BigButton"), &"Button")


func test_panel_style_has_black_outline_and_accent_glow() -> void:
	var style := UiTheme.panel_style(Color.RED)
	assert_eq(style.border_color, Color.BLACK)
	assert_gt(style.border_width_left, 0)
	assert_eq(Color(style.shadow_color, 1.0), Color.RED)
	assert_gt(style.shadow_size, 0)


func test_pop_in_ends_fully_visible() -> void:
	var control := Control.new()
	add_child_autofree(control)
	UiFx.pop_in(control)
	assert_lt(control.modulate.a, 1.0, "starts transparent")
	await wait_seconds(0.4)
	assert_eq(control.modulate.a, 1.0)
	assert_eq(control.scale, Vector2.ONE)


func test_pop_in_twice_still_ends_visible() -> void:
	var control := Control.new()
	add_child_autofree(control)
	UiFx.pop_in(control)
	await wait_seconds(0.05)
	UiFx.pop_in(control)
	await wait_seconds(0.4)
	assert_eq(control.modulate.a, 1.0)
	assert_eq(control.scale, Vector2.ONE)


func test_pivot_follows_late_layout() -> void:
	var control := Control.new()
	add_child_autofree(control)
	UiFx.pop_in(control)  # size is still 0 here
	control.size = Vector2(100, 40)
	assert_eq(control.pivot_offset, Vector2(50, 20))


func test_reduce_motion_shows_immediately() -> void:
	UiFx.reduce_motion = true
	var control := Control.new()
	add_child_autofree(control)
	UiFx.pop_in(control)
	assert_eq(control.modulate.a, 1.0)
	assert_eq(control.scale, Vector2.ONE)


func test_count_to_ends_on_the_last_value() -> void:
	var label := Label.new()
	add_child_autofree(label)
	UiFx.count_to(label, 0, 50, "M %d")
	await wait_seconds(0.1)
	UiFx.count_to(label, 50, 80, "M %d")
	await wait_seconds(0.6)
	assert_eq(label.text, "M 80")
