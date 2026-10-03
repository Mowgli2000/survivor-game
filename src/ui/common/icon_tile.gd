class_name IconTile
extends PanelContainer
## Square tile showing a weapon/item icon on a dark background, framed with the
## rarity tier color, with an optional count badge (bottom right). Display only.

const BACKGROUND := Color(0.06, 0.06, 0.1, 0.9)
const BORDER := 3
const RADIUS := 8

var icon_rect: TextureRect
var badge: Label


static func create(texture: Texture2D, tier: int, size: float, badge_text: String = "") -> IconTile:
	var tile := IconTile.new()
	tile.custom_minimum_size = Vector2(size, size)
	tile.mouse_filter = Control.MOUSE_FILTER_PASS
	var style := StyleBoxFlat.new()
	style.bg_color = BACKGROUND
	style.border_color = Tiers.color(tier)
	style.set_border_width_all(BORDER)
	style.set_corner_radius_all(RADIUS)
	style.set_content_margin_all(size * 0.08)
	tile.add_theme_stylebox_override("panel", style)

	tile.icon_rect = TextureRect.new()
	tile.icon_rect.texture = texture
	tile.icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tile.icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tile.icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	tile.icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(tile.icon_rect)

	tile.badge = Label.new()
	tile.badge.text = badge_text
	tile.badge.visible = badge_text != ""
	tile.badge.size_flags_horizontal = Control.SIZE_SHRINK_END
	tile.badge.size_flags_vertical = Control.SIZE_SHRINK_END
	tile.badge.add_theme_font_size_override("font_size", maxi(14, roundi(size * 0.3)))
	tile.badge.add_theme_constant_override("outline_size", 6)
	tile.badge.add_theme_color_override("font_outline_color", Color.BLACK)
	tile.badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(tile.badge)
	return tile


func border_color() -> Color:
	return (get_theme_stylebox("panel") as StyleBoxFlat).border_color
