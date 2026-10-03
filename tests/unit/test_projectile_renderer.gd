extends GutTest
## Projectile renderer: glow for every projectile, a body only for styled ones.


func _projectile(style: int) -> Projectile:
	var p := Projectile.new()
	p.reset_basic(Vector2.ZERO, Vector2.RIGHT * 100.0, 1.0, 6.0, 1.0, Color.WHITE, style)
	return p


func test_bodies_only_for_styled_projectiles() -> void:
	var renderer := ProjectileRenderer.new()
	add_child_autofree(renderer)
	var list: Array[Projectile] = [_projectile(0), _projectile(WeaponData.ProjectileStyle.MISSILE),
		_projectile(WeaponData.ProjectileStyle.SHURIKEN)]
	renderer.render(list)
	assert_eq(renderer.multimesh.visible_instance_count, 1, "glow for the plain one")
	assert_eq(renderer.body_count(), 2, "bodies for the styled ones")


func test_every_style_has_render_settings_and_a_cell() -> void:
	var styles := WeaponData.ProjectileStyle.size()
	assert_eq(ProjectileRenderer.BODY_STRETCH.size(), styles)
	assert_eq(ProjectileRenderer.BODY_SCALE.size(), styles)
	assert_lt(styles, int(ProjectileRenderer.CELL_CODE), "cell code fits every style")
	assert_eq(ProjectileRenderer.BODY_TINT.size(), styles)
	assert_eq(ProjectileRenderer.BODY_CELLS, styles - 1)
	assert_eq(ProjectileRenderer.BODY_TEXTURE.get_width(), 64 * ProjectileRenderer.BODY_CELLS)
