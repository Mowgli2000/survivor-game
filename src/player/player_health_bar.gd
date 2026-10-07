class_name PlayerHealthBar
extends Node2D
## Small HP bar above the player's head (playtest: the HUD bar alone was too far from
## the action). Redrawn only when the health changes. Own node: the player's sprite
## shader must not apply to it.

const SIZE := Vector2(64.0, 9.0)
## Gap between the top of the sprite and the bar.
const GAP := 10.0
const BORDER := 2.0
const BACK := Color(0.05, 0.03, 0.12, 0.85)

var _ratio: float = 1.0
var _color: Color = UiTheme.BAD


## `head_height`: distance from the player's center to the top of its sprite.
## `color`: coop tag color, or the default red.
func setup(player: Player, head_height: float, color: Color = UiTheme.BAD) -> void:
	position = Vector2(0.0, -head_height - GAP - SIZE.y)
	z_index = 5
	_color = color
	player.health_changed.connect(_on_health_changed)
	_on_health_changed(player.hp, player.stats.get_value(StatIds.MAX_HP))


func ratio() -> float:
	return _ratio


func _on_health_changed(hp: float, max_hp: float) -> void:
	var value := clampf(hp / maxf(max_hp, 1.0), 0.0, 1.0)
	if is_equal_approx(value, _ratio) and is_inside_tree():
		return
	_ratio = value
	queue_redraw()


func _draw() -> void:
	var frame := Rect2(-SIZE.x * 0.5 - BORDER, -BORDER, SIZE.x + BORDER * 2.0, SIZE.y + BORDER * 2.0)
	draw_rect(frame, UiTheme.OUTLINE)
	draw_rect(Rect2(-SIZE.x * 0.5, 0.0, SIZE.x, SIZE.y), BACK)
	if _ratio > 0.0:
		draw_rect(Rect2(-SIZE.x * 0.5, 0.0, SIZE.x * _ratio, SIZE.y), _color)
