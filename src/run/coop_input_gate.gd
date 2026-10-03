class_name CoopInputGate
extends Node
## Coop between waves (ADR 0017): only the devices of the player whose level-up
## or shop is open reach the screens. Runs while the tree is paused.

## Returns the PlayerInput allowed right now, or null when every device is.
var _owner_of: Callable


func setup(owner_of: Callable) -> void:
	_owner_of = owner_of


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	if not _owner_of.is_valid():
		return
	var allowed: PlayerInput = _owner_of.call()
	if allowed != null and not allowed.owns_event(event):
		get_viewport().set_input_as_handled()
