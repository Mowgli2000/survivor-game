class_name SpritePreview
extends Control
## Animated character/enemy sprite inside the UI (character select, unlock
## cards): plays the sheet's idle animation, scaled to fit the control.
## `silhouette` draws it as a dark shape (locked character). Display only.

## Sprite height as a fraction of the control height (room for the feet).
const FILL := 0.92
const SILHOUETTE := Color(0.05, 0.03, 0.1, 0.85)

var silhouette: bool = false:
	set(value):
		silhouette = value
		queue_redraw()

var _animator := SpriteAnimator.new()


static func create(sheet: SpriteSheet, height: float, p_silhouette: bool = false) -> SpritePreview:
	var preview := SpritePreview.new()
	preview.custom_minimum_size = Vector2(height * 0.9, height)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview._animator.reset(sheet, 0.0)
	preview.silhouette = p_silhouette
	return preview


func has_sheet() -> bool:
	return _animator.sheet != null


func _process(delta: float) -> void:
	if _animator.sheet != null and _animator.advance(delta, &"idle", 1.0):
		queue_redraw()


func _draw() -> void:
	var sheet := _animator.sheet
	if sheet == null:
		return
	var height := size.y * FILL
	draw_set_transform(Vector2(size.x * 0.5, size.y))
	sheet.draw(self, _animator.frame, height, 0.0, 1.0, SILHOUETTE if silhouette else Color.WHITE)
	draw_set_transform(Vector2.ZERO)
