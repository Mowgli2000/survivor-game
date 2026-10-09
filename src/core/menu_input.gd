class_name MenuInput
extends RefCounted
## Gamepad shoulder buttons in the menus (dev's request, 2026-10-09): L1 (left bumper) moves left and
## R1 (right bumper) moves right, in addition to the D-pad and the stick, on every screen that reads
## `ui_left` / `ui_right` (focus moves, sliders, the looks of a hunter, the cards of a level-up or a
## shop). They are not the movement of a hunter in a run (that is `move_*`). Y no longer turns the
## looks (it keeps its other uses, such as rerolling).

const LEFT_BUTTON := JOY_BUTTON_LEFT_SHOULDER
const RIGHT_BUTTON := JOY_BUTTON_RIGHT_SHOULDER


## Adds the bumpers to the InputMap actions (safe to call twice).
static func install() -> void:
	_add_bumper(&"ui_left", LEFT_BUTTON)
	_add_bumper(&"ui_right", RIGHT_BUTTON)
	# Y turned the looks and rerolled at once: it only rerolls now.
	if InputMap.has_action(&"switch_variant"):
		for event in InputMap.action_get_events(&"switch_variant"):
			if event is InputEventJoypadButton:
				InputMap.action_erase_event(&"switch_variant", event)


static func _add_bumper(action: StringName, button: JoyButton) -> void:
	if not InputMap.has_action(action):
		return
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and (event as InputEventJoypadButton).button_index == button:
			return
	var bumper := InputEventJoypadButton.new()
	bumper.button_index = button
	InputMap.action_add_event(action, bumper)
