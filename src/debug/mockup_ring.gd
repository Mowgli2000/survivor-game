extends Node2D
## Debug: a ring (or disc) for the UI mockups (src/debug/ui_mockup.gd).

var center := Vector2.ZERO
var radius := 100.0
var color := Color.WHITE
var width := 6.0
var start := 0.0
var sweep := TAU
## Alpha > 0 draws a filled disc under the ring.
var fill := Color(0, 0, 0, 0)


func _draw() -> void:
	if fill.a > 0.0:
		draw_circle(center, radius, fill)
	if width > 0.0:
		draw_arc(center, radius, start, start + sweep, 96, color, width, true)
