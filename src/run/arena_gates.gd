class_name ArenaGates
extends Node2D
## The gates monsters come out of (ADR 0018): one swirling portal in the middle of
## each arena side, just outside the wall. Decorative: spawning keeps its rules.
## Four portals redrawn each frame by one node, a few cheap draw calls.

const DEFAULT_COLOR := Color(0.64, 0.35, 1.0)
const RADIUS := 95.0
## Pushed out of the wall so they never cover the play area.
const OFFSET := 120.0
const SPIN := 1.6
const INK := Color(0.05, 0.04, 0.1)

var _centers: PackedVector2Array = []
var _color := DEFAULT_COLOR
var _time: float = 0.0


func setup(arena: Rect2, color: Color) -> void:
	_color = color
	var c := arena.get_center()
	_centers = PackedVector2Array([
		Vector2(c.x, arena.position.y - OFFSET),
		Vector2(c.x, arena.end.y + OFFSET),
		Vector2(arena.position.x - OFFSET, c.y),
		Vector2(arena.end.x + OFFSET, c.y),
	])
	z_index = 0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var pulse := 1.0 + 0.05 * sin(_time * 3.0)
	for center in _centers:
		var r := RADIUS * pulse
		draw_circle(center, r, INK)
		draw_circle(center, r * 0.78, Color(_color.darkened(0.55), 1.0))
		# Three spiral arms turning slowly.
		for k in 3:
			var start := _time * SPIN + k * TAU / 3.0
			draw_arc(center, r * 0.5, start, start + 2.2, 12, Color(_color, 0.9), 6.0)
		draw_arc(center, r, 0.0, TAU, 32, INK, 10.0)
		draw_arc(center, r, 0.0, TAU, 32, _color, 5.0)
