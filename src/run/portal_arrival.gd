class_name PortalArrival
extends CanvasLayer
## First frames of a run entered through the seal screen's portal zoom: the screen
## is still the gate's violet, then clears while the heroes drop out of the top gate
## (Player.enter_from). Purely visual; frees itself.

const COLOR := Color(0.36, 0.2, 0.85)
const CLEAR_SECONDS := 0.6
## Seconds the heroes fall, then the camera zooms in to the play view.
const FALL_SECONDS := 1.5
const ZOOM_SECONDS := 1.0
const GATE_RADIUS := 260.0


func _ready() -> void:
	layer = 100
	var cover := ColorRect.new()
	cover.color = COLOR
	cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cover)
	var tween := create_tween()
	tween.tween_property(cover, "modulate:a", 0.0, CLEAR_SECONDS).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(queue_free)
