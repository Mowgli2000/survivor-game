class_name PortalArrival
extends CanvasLayer
## First frames of a run entered through the seal screen's portal zoom: the screen is
## still the gate's violet, then clears on the empty arena. A gate appears and grows
## on the map (ArrivalGate), the heroes walk out of it (Player.enter_from), the gate
## closes, the wave starts. Purely visual; frees itself.

const COLOR := Color(0.36, 0.2, 0.85)
const CLEAR_SECONDS := 0.5
## The gate grows for this long before the heroes step out.
const WALK_START := 0.75
const WALK_SECONDS := 1.3
const GATE_RADIUS := 150.0
## Where the gate stands against the heroes' start spot (up and to the left).
const GATE_OFFSET := Vector2(-125.0, -128.0)


## Seconds after the run starts until the gate has closed and the wave begins.
static func start_delay() -> float:
	var open_for := WALK_START + WALK_SECONDS - ArrivalGate.OPEN_SECONDS
	return ArrivalGate.total_seconds(open_for)


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
