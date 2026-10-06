class_name CoopScreens
extends CanvasLayer
## Coop between waves (ADR 0021): both players level up and shop at the same time.
## The screen is split in two halves, each a SubViewport holding one player's
## LevelUpScreen and ShopScreen (compact layout). A viewport has its own GUI focus,
## so two players can navigate with their own device at once: key and gamepad events
## are routed to the viewport of the player who owns the device (PlayerInput.owns_event);
## the mouse acts on the half it is over. Runs while the tree is paused.

const HALF_SIZE := Vector2i(960, 1080)

var _inputs: Array[PlayerInput] = []
var _viewports: Array[SubViewport] = []
var _screens: Array[CanvasLayer] = []


func _init() -> void:
	layer = 21
	process_mode = Node.PROCESS_MODE_ALWAYS


## One half per input (left: player 1, right: player 2).
func setup(inputs: Array[PlayerInput]) -> void:
	_inputs = inputs
	for i in inputs.size():
		var container := SubViewportContainer.new()
		container.stretch = true
		container.position = Vector2(HALF_SIZE.x * i, 0.0)
		container.size = Vector2(HALF_SIZE)
		container.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(container)
		var viewport := SubViewport.new()
		viewport.size = HALF_SIZE
		viewport.transparent_bg = true
		viewport.handle_input_locally = true
		viewport.process_mode = Node.PROCESS_MODE_ALWAYS
		container.add_child(viewport)
		_viewports.append(viewport)


## Puts a player's screen (level-up or shop) in his half.
func add_screen(player_index: int, screen: CanvasLayer) -> void:
	_viewports[player_index].add_child(screen)
	_screens.append(screen)


func viewport_of(player_index: int) -> SubViewport:
	return _viewports[player_index]


## True while one of the hosted screens is open.
func is_active() -> bool:
	for screen in _screens:
		if screen.visible:
			return true
	return false


func _input(event: InputEvent) -> void:
	if not is_active():
		return
	if not (event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion):
		return  # the mouse reaches the half it is over by itself
	var index := owner_of(event)
	if index < 0:
		return
	_viewports[index].push_input(event)
	get_viewport().set_input_as_handled()


## Player number whose devices produced `event`, -1 if none.
func owner_of(event: InputEvent) -> int:
	for i in _inputs.size():
		if _inputs[i].owns_event(event):
			return i
	return -1
