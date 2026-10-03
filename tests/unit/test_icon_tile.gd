extends GutTest
## IconTile: icon on a tier-colored frame, optional count badge.


func test_border_uses_the_tier_color() -> void:
	var icon: Texture2D = (ContentDB.get_def(&"items", &"oni_mask") as ItemData).icon
	var tile := IconTile.create(icon, 3, 64.0)
	add_child_autofree(tile)
	assert_eq(tile.border_color(), Tiers.color(3))
	assert_eq(tile.custom_minimum_size, Vector2(64, 64))
	assert_false(tile.badge.visible, "no badge text, no badge")


func test_badge_shows_its_text() -> void:
	var tile := IconTile.create(null, 1, 48.0, "×3")
	add_child_autofree(tile)
	assert_true(tile.badge.visible)
	assert_eq(tile.badge.text, "×3")
