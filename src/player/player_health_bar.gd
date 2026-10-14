class_name PlayerHealthBar
extends Node2D
## Small HP bar above the player's head (playtest: the HUD bar alone was too far from
## the action), with the player's level in a badge at its left and a short celebration
## when the level goes up. Redrawn only when the health or the level changes, and every
## frame during the 0.9 s celebration. Own node: the player's sprite shader must not
## apply to it.

const SIZE := Vector2(64.0, 9.0)
## Gap between the top of the sprite and the bar.
const GAP := 10.0
const BORDER := 2.0
const BACK := Color(0.05, 0.03, 0.12, 0.85)

const BADGE_RADIUS := 10.0
const BADGE_GAP := 6.0
const BADGE_FONT_SIZE := 15
const BADGE_OUTLINE := 5
const EMBOLDEN := 0.35
const CELEBRATION_SECONDS := 0.9
const RING_GROWTH := 34.0
const POP_SCALE := 0.7
const TEXT_RISE := 26.0
const TEXT_FONT_SIZE := 22

var _ratio: float = 1.0
var _color: Color = UiTheme.BAD
var _level: int = 0
## Celebration progress, 0 (idle) .. 1 (just leveled up).
var _glow: float = 0.0
var _font: FontVariation
var _tween: Tween


## `head_height`: distance from the player's center to the top of its sprite.
## `color`: coop tag color, or the default red.
func setup(player: Player, head_height: float, color: Color = UiTheme.BAD) -> void:
	position = Vector2(0.0, -head_height - GAP - SIZE.y)
	z_index = 5
	_color = color
	_font = FontVariation.new()
	_font.base_font = UiTheme.BANGERS
	_font.variation_embolden = EMBOLDEN
	player.health_changed.connect(_on_health_changed)
	_on_health_changed(player.hp, player.stats.get_value(StatIds.MAX_HP))


## Shows the level of `progression` and celebrates each level-up.
func bind_progression(progression: Progression) -> void:
	_level = progression.level
	progression.leveled_up.connect(_on_leveled_up)
	queue_redraw()


func ratio() -> float:
	return _ratio


func level() -> int:
	return _level


## 0 when idle, 1 at the moment of a level-up, back to 0 at the end of the celebration.
func glow() -> float:
	return _glow


func _on_health_changed(hp: float, max_hp: float) -> void:
	var value := clampf(hp / maxf(max_hp, 1.0), 0.0, 1.0)
	if is_equal_approx(value, _ratio) and is_inside_tree():
		return
	_ratio = value
	queue_redraw()


func _on_leveled_up(level: int) -> void:
	_level = level
	if UiFx.reduce_motion or not is_inside_tree():
		queue_redraw()
		return
	if _tween != null:
		_tween.kill()
	_glow = 1.0
	_tween = create_tween()
	_tween.tween_method(_set_glow, 1.0, 0.0, CELEBRATION_SECONDS)


func _set_glow(value: float) -> void:
	_glow = value
	queue_redraw()


func _draw() -> void:
	var frame := Rect2(-SIZE.x * 0.5 - BORDER, -BORDER, SIZE.x + BORDER * 2.0, SIZE.y + BORDER * 2.0)
	draw_rect(frame, UiTheme.OUTLINE.lerp(UiTheme.GOLD_VIVID, _glow))
	draw_rect(Rect2(-SIZE.x * 0.5, 0.0, SIZE.x, SIZE.y), BACK)
	if _ratio > 0.0:
		draw_rect(Rect2(-SIZE.x * 0.5, 0.0, SIZE.x * _ratio, SIZE.y), _color)
	if _level > 0:
		_draw_badge()


func _draw_badge() -> void:
	var center := Vector2(-SIZE.x * 0.5 - BORDER - BADGE_GAP - BADGE_RADIUS, SIZE.y * 0.5)
	var scale_now := 1.0 + POP_SCALE * _glow
	var radius := BADGE_RADIUS * scale_now
	if _glow > 0.0:
		# Expanding gold ring that fades out.
		var ring := Color(UiTheme.GOLD_VIVID, _glow)
		draw_arc(center, BADGE_RADIUS + RING_GROWTH * (1.0 - _glow), 0.0, TAU, 32, ring, 3.0)
		_draw_level_up_text(center)
	draw_circle(center, radius + 2.0, UiTheme.OUTLINE)
	draw_circle(center, radius, UiTheme.GOLD.lerp(Color.WHITE, _glow * 0.6))
	var text := str(_level)
	var size := roundi(BADGE_FONT_SIZE * scale_now)
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var at := center + Vector2(-width * 0.5, size * 0.33)
	draw_string_outline(_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, BADGE_OUTLINE, UiTheme.OUTLINE)
	draw_string(_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color.WHITE)


## "Level up!" floating above the bar, rising while it fades.
func _draw_level_up_text(badge_center: Vector2) -> void:
	var text := tr("UI_LEVEL_UP")
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, TEXT_FONT_SIZE).x
	var at := Vector2(-width * 0.5, badge_center.y - 16.0 - TEXT_RISE * (1.0 - _glow))
	var outline := Color(UiTheme.OUTLINE, _glow)
	draw_string_outline(_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, TEXT_FONT_SIZE, BADGE_OUTLINE, outline)
	draw_string(_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, TEXT_FONT_SIZE, Color(UiTheme.GOLD_VIVID, _glow))
