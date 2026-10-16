class_name RewardPopup
extends Node2D
## A small chest's reward: the item's icon and name float up from the chest and fade out. No screen, no
## pause: the fight goes on (a mini-boss chest must not stop the run).

const LIFE := 2.8
const RISE := 110.0
const ICON := 72.0

var _time := 0.0
var _label: Label


static func create(item: ItemData, pos: Vector2, index: int) -> RewardPopup:
	var popup := RewardPopup.new()
	popup.position = pos + Vector2((index - 0.0) * 90.0, -60.0)
	popup.z_index = 40
	popup._build(item)
	return popup


func _build(item: ItemData) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = item.icon
	sprite.scale = Vector2.ONE * ICON / maxf(item.icon.get_width(), 1.0)
	sprite.position = Vector2(0, -ICON * 0.5)
	add_child(sprite)
	_label = Label.new()
	_label.text = TranslationServer.translate(item.name_key)
	_label.theme_type_variation = &"SubtitleLabel"
	_label.add_theme_color_override("font_color", Tiers.color(item.tier))
	_label.add_theme_font_size_override("font_size", 26)
	_label.position = Vector2(-120, 8)
	_label.size = Vector2(240, 36)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label)


func _process(delta: float) -> void:
	_time += delta
	var t := clampf(_time / LIFE, 0.0, 1.0)
	position.y -= RISE * delta / LIFE
	modulate.a = 1.0 - clampf((t - 0.65) / 0.35, 0.0, 1.0)
	scale = Vector2.ONE * (0.6 + 0.4 * clampf(_time / 0.25, 0.0, 1.0))
	if t >= 1.0:
		queue_free()
