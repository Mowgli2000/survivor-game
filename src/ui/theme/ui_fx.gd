class_name UiFx
## Small, stateless UI animations (ADR 0011): appear, hover lift, bounce, number
## roll. All last <= 0.35 s, never block input, and are skipped entirely when
## `reduce_motion` is on (future accessibility setting).

static var reduce_motion: bool = false

const APPEAR_TIME := 0.18
const APPEAR_SCALE := 0.94
const LIFT_SCALE := 1.04
const LIFT_TIME := 0.1
const COUNT_TIME := 0.35


## Fades and scales `control` in, after `delay` seconds.
static func pop_in(control: Control, delay: float = 0.0) -> void:
	_center_pivot(control)
	_kill(control, &"_ui_fx_appear")
	if reduce_motion:
		control.modulate.a = 1.0
		control.scale = Vector2.ONE
		return
	control.modulate.a = 0.0
	control.scale = Vector2.ONE * APPEAR_SCALE
	var tween := control.create_tween().set_parallel()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "modulate:a", 1.0, APPEAR_TIME).set_delay(delay)
	tween.tween_property(control, "scale", Vector2.ONE, APPEAR_TIME + 0.04).set_delay(delay)
	control.set_meta(&"_ui_fx_appear", tween)


## Slightly enlarges `control` while hovered or focused.
static func hover_lift(control: Control) -> void:
	_center_pivot(control)
	var lift := func(on: bool) -> void:
		if reduce_motion:
			return
		_kill(control, &"_ui_fx_lift")
		var tween := control.create_tween()
		tween.tween_property(control, "scale", Vector2.ONE * (LIFT_SCALE if on else 1.0), LIFT_TIME)
		control.set_meta(&"_ui_fx_lift", tween)
	control.mouse_entered.connect(lift.bind(true))
	control.focus_entered.connect(lift.bind(true))
	control.mouse_exited.connect(lift.bind(false))
	control.focus_exited.connect(lift.bind(false))


## Quick "pop" (purchase, confirmation).
static func bounce(control: Control) -> void:
	_center_pivot(control)
	if reduce_motion:
		return
	_kill(control, &"_ui_fx_lift")
	control.scale = Vector2.ONE * 1.1
	var tween := control.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2.ONE, 0.25)
	control.set_meta(&"_ui_fx_lift", tween)


## Rolls `label.text` (format with one %d) from `from` to `to`.
static func count_to(label: Label, from: int, to: int, format: String) -> void:
	_kill(label, &"_ui_fx_count")
	if reduce_motion or from == to:
		label.text = format % to
		return
	var tween := label.create_tween()
	tween.tween_method(func(value: float) -> void: label.text = format % roundi(value),
		float(from), float(to), COUNT_TIME)
	label.set_meta(&"_ui_fx_count", tween)


## Scale animations grow from the center, also once the layout gives a size.
static func _center_pivot(control: Control) -> void:
	control.pivot_offset = control.size * 0.5
	if not control.has_meta(&"_ui_fx_pivot"):
		control.set_meta(&"_ui_fx_pivot", true)
		control.resized.connect(func() -> void: control.pivot_offset = control.size * 0.5)


static func _kill(control: Control, key: StringName) -> void:
	if control.has_meta(key):
		var tween: Tween = control.get_meta(key)
		if tween != null and tween.is_valid():
			tween.kill()
