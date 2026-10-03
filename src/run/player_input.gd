class_name PlayerInput
extends RefCounted
## Movement input of one player (ADR 0017). Solo: the plain move_* actions
## (every device). Coop: per-player copies of the move_* actions (move_left_p2...)
## holding only that player's gamepad, plus the keyboard for player 1.

const MOVE_ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down"]

## 0-based player number.
var index: int = 0
## Gamepad id, -1 = none.
var device: int = -1
var keyboard: bool = true
## True in solo: every device drives the player.
var shared: bool = true

var _actions: Array[StringName] = []


## Solo input: the plain move_* actions.
static func solo() -> PlayerInput:
	var input := PlayerInput.new()
	input._actions = MOVE_ACTIONS.duplicate()
	return input


## Coop input of player `p_index` with gamepad `p_device` (-1 = none).
static func coop(p_index: int, p_device: int, p_keyboard: bool) -> PlayerInput:
	var input := PlayerInput.new()
	input.index = p_index
	input.device = p_device
	input.keyboard = p_keyboard
	input.shared = false
	input._build_actions()
	return input


## Inputs for `count` players from the connected gamepads.
## 2 pads: P1 = keyboard + pad 0, P2 = pad 1. 1 pad: P1 = keyboard, P2 = pad 0.
static func assign(count: int, pads: Array[int]) -> Array[PlayerInput]:
	var inputs: Array[PlayerInput] = []
	if count <= 1:
		inputs.append(solo())
		return inputs
	if pads.size() >= 2:
		inputs.append(coop(0, pads[0], true))
		inputs.append(coop(1, pads[1], false))
	else:
		inputs.append(coop(0, -1, true))
		inputs.append(coop(1, pads[0] if pads.size() == 1 else -1, false))
	return inputs


static func connected_pads() -> Array[int]:
	var pads: Array[int] = []
	pads.assign(Input.get_connected_joypads())
	return pads


func move_vector() -> Vector2:
	return Input.get_vector(_actions[0], _actions[1], _actions[2], _actions[3])


## True when `event` comes from this player's devices (screens between waves).
func owns_event(event: InputEvent) -> bool:
	if shared:
		return true
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return event.device == device
	return keyboard


## The action names this player reads, in MOVE_ACTIONS order.
func actions() -> Array[StringName]:
	return _actions


func _build_actions() -> void:
	_actions.clear()
	for base in MOVE_ACTIONS:
		var action := StringName("%s_p%d" % [base, index + 1])
		if InputMap.has_action(action):
			InputMap.erase_action(action)
		InputMap.add_action(action, InputMap.action_get_deadzone(base))
		for event in InputMap.action_get_events(base):
			var copy: InputEvent = null
			if event is InputEventKey and keyboard:
				copy = event.duplicate()
			elif (event is InputEventJoypadButton or event is InputEventJoypadMotion) and device >= 0:
				copy = event.duplicate()
				copy.device = device
			if copy != null:
				InputMap.action_add_event(action, copy)
		_actions.append(action)
