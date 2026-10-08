class_name ArrivalGate
extends Node2D
## The big gate the heroes drop out of when a run starts (after the seal screen's
## portal zoom): a dark core, violet spiral arms turning, a glowing rim. It opens,
## stays while the heroes fall and closes behind them, then frees itself.

const COLOR := Color(0.64, 0.35, 1.0)
const INK := Color(0.05, 0.04, 0.1)
const OPEN_SECONDS := 0.45
const CLOSE_SECONDS := 0.6
const ARMS := 5
const ARM_POINTS := 22

var _radius: float = 200.0
var _stay: float = 1.0
var _time: float = 0.0


## `stay`: seconds it stays fully open after opening.
func setup(radius: float, stay: float) -> void:
	_radius = radius
	_stay = stay
	z_index = 1


func _process(delta: float) -> void:
	_time += delta
	if _time > OPEN_SECONDS + _stay + CLOSE_SECONDS:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var open := clampf(_time / OPEN_SECONDS, 0.0, 1.0)
	var closing := clampf((_time - OPEN_SECONDS - _stay) / CLOSE_SECONDS, 0.0, 1.0)
	var grow := open * (1.0 - closing)
	var r := _radius * (1.0 - pow(1.0 - grow, 3.0))
	if r <= 1.0:
		return
	for k in 4:
		draw_circle(Vector2.ZERO, r * (1.5 - k * 0.12), Color(COLOR, 0.07))
	draw_circle(Vector2.ZERO, r, INK)
	draw_circle(Vector2.ZERO, r * 0.9, COLOR.darkened(0.6))
	for arm in ARMS:
		var points := PackedVector2Array()
		var colors := PackedColorArray()
		var start := _time * 1.8 + arm * TAU / ARMS
		for i in ARM_POINTS:
			var f := float(i) / (ARM_POINTS - 1)
			# Log spiral: turns tighter toward the center.
			var angle := start + f * 2.6
			var dist := r * 0.88 * (1.0 - f * 0.92)
			points.append(Vector2.from_angle(angle) * dist)
			colors.append(Color(COLOR.lightened(0.25 * (1.0 - f)), 0.95 * (1.0 - f * 0.7)))
		draw_polyline_colors(points, colors, maxf(r * 0.05, 3.0), true)
	draw_circle(Vector2.ZERO, r * 0.3, Color(0.0, 0.0, 0.03, 0.95))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, INK, maxf(r * 0.08, 4.0), true)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, COLOR, maxf(r * 0.035, 3.0), true)
