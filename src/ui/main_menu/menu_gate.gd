class_name MenuGate
extends Node2D
## Main menu backdrop: a gate ring (the portals monsters come out of) drawn in
## flat ink + color, turning slowly. Drawn once per frame, a handful of arcs.

const RUNES := 18
const SPEED := 0.12
const ARMS := 6

var radius: float = 360.0
var color: Color = Color(0.64, 0.35, 1.0)
## Base of the swirling core (lighter discs are drawn towards the middle).
var core: Color = Color(0.2, 0.08, 0.4)
var _time: float = 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var ink := Color(0.05, 0.04, 0.1, 0.9)
	var pulse := 0.75 + 0.25 * sin(_time * 1.3)
	# Halo: soft rings breathing around the gate.
	for k in 4:
		draw_arc(Vector2.ZERO, radius * (1.1 + 0.11 * k), 0.0, TAU, 96, Color(color, (0.14 - 0.03 * k) * pulse), 18.0, true)
	# Core: discs getting lighter towards the middle, with turning spiral arms.
	draw_circle(Vector2.ZERO, radius * 0.95, Color(core, 0.92))
	draw_circle(Vector2.ZERO, radius * 0.76, Color(core.lightened(0.16), 0.9))
	draw_circle(Vector2.ZERO, radius * 0.52, Color(core.lightened(0.34), 0.9))
	draw_circle(Vector2.ZERO, radius * 0.27, Color(0.85, 0.7, 1.0, 0.55 + 0.25 * pulse))
	for k in ARMS:
		var r := radius * (0.2 + 0.13 * k)
		var start := _time * (0.5 + 0.12 * k) * (1.0 if k % 2 == 0 else -1.0) + k * 1.05
		draw_arc(Vector2.ZERO, r, start, start + 3.6, 40, Color(color.lightened(0.3), 0.75 - 0.09 * k), 8.0 - 0.6 * k, true)
	for ring in [[1.0, 10.0, 1.0], [0.82, 6.0, -1.4]]:
		var r: float = radius * ring[0]
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 96, ink, ring[1] + 6.0, true)
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 96, Color(color, 0.8 + 0.2 * pulse), ring[1], true)
	# Rune dashes between the two rings, turning.
	for k in RUNES:
		var a := _time * SPEED + TAU * k / RUNES
		var dir := Vector2.from_angle(a)
		var from := dir * radius * 0.86
		var to := dir * radius * 0.96
		draw_line(from, to, ink, 9.0, true)
		draw_line(from, to, Color(color.lightened(0.4), pulse), 4.0, true)
	for k in RUNES / 2:
		var a := -_time * SPEED * 1.6 + TAU * k / (RUNES / 2)
		draw_arc(Vector2.ZERO, radius * 0.7, a, a + 0.18, 8, Color(color, 0.6 * pulse), 5.0, true)
