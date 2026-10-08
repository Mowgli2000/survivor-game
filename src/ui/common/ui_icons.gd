class_name UiIcons
extends RefCounted
## Currency icons shared by the screens: the gold coin (a run's money, shop prices) and
## the portal shard (skin shop money, ADR 0023). Display only.

const COIN := preload("res://assets/icons/ui/coin.svg")
const SHARD := preload("res://assets/icons/ui/shard.png")
## Icon height inside a button, in px.
const BUTTON_ICON := 28
static var _cache: Dictionary = {}


static func coin() -> Texture2D:
	return COIN


static func shard() -> Texture2D:
	return SHARD


## Small icon next to a number: `parent` gets the icon (`size` px) then returns it.
static func tile(icon: Texture2D, size: float) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = icon
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = Vector2(size, size)
	rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


## `icon` on the right of the button's text, `size` px high. The texture is resized
## once and cached: `expand_icon` adds nothing to a button's minimum width, so a
## shrink-centered button (reroll, sell) would hide it.
static func put_after_text(button: Button, icon: Texture2D, size: int = BUTTON_ICON) -> void:
	button.icon = _sized(icon, size)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT


static func _sized(icon: Texture2D, size: int) -> Texture2D:
	var key := "%d:%d" % [icon.get_rid().get_id(), size]
	if _cache.has(key):
		return _cache[key]
	var image := icon.get_image()
	if image == null:
		return icon
	image.resize(size, size, Image.INTERPOLATE_LANCZOS)
	var texture := ImageTexture.create_from_image(image)
	_cache[key] = texture
	return texture
