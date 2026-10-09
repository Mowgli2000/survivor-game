class_name CoopScreens
extends CanvasLayer
## Coop between waves (ADR 0021): both players level up and shop at the same time;
## also the split character pick of the main menu (CoopCharacterSelect).
## The screen is split in two halves, each a SubViewport holding one player's
## LevelUpScreen and ShopScreen (compact layout). A viewport has its own GUI focus,
## so two players can navigate with their own device at once: key and gamepad events
## are routed to the viewport of the player who owns the device (PlayerInput.owns_event);
## the mouse acts on the half it is over. Runs while the tree is paused.

## Size of a half on a 16:9 screen; on a wider window each half takes half of its width.
const HALF_SIZE := Vector2i(960, 1080)
## Stick push that counts as one step of navigation.
const STICK_THRESHOLD := 0.5

var _inputs: Array[PlayerInput] = []
var _viewports: Array[SubViewport] = []
var _containers: Array[SubViewportContainer] = []
var _screens: Array[CanvasLayer] = []
## Last focused control of each half (player index -> Control), see _remember_focus.
var _focus_memory: Dictionary = {}
## Selection frame drawn in each half (index = player).
var _frames: Array[FocusFrame] = []
## Left stick direction last turned into a ui_* press, per player and axis (-1, 0, 1).
var _stick_state: Dictionary = {}


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
		_containers.append(container)
		# The container would also forward every key / gamepad event to its viewport
		# (both halves reacting to both players). Only _input below routes them; the
		# mouse still reaches the half it is over through gui_input.
		container.set_process_input(false)
		container.set_process_unhandled_input(false)
		var viewport := SubViewport.new()
		viewport.size = HALF_SIZE
		viewport.transparent_bg = true
		viewport.handle_input_locally = true
		viewport.process_mode = Node.PROCESS_MODE_ALWAYS
		container.add_child(viewport)
		_viewports.append(viewport)
		# Above the hosted screens: this half's selection frame.
		var top := CanvasLayer.new()
		top.layer = 100
		viewport.add_child(top)
		var frame := FocusFrame.new()
		frame.color = RunPlayer.COLORS[i]
		frame.style = UiTheme.focus_style(RunPlayer.COLORS[i])
		top.add_child(frame)
		_frames.append(frame)


## Draws the selection of a half. Godot shows the focus of ONE half only (one focus
## per window), so each half draws its remembered control itself, in its player's color.
## The frame is the control's own focus box (same shape, corners and width) with the
## player's color and no fill: drawn over Godot's focus box in the half that has it,
## the two are one outline (playtest: two outlines of different shapes and colors).
class FocusFrame extends Control:
	## Fallback box for controls whose focus box is not a StyleBoxFlat.
	var style: StyleBox
	var color: Color
	var target: Control
	var _styled_for: Control
	var _target_style: StyleBox

	func _init() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if target == null:
			return
		if target != _styled_for:
			_styled_for = target
			_target_style = outline_of(target, color, style)
		draw_style_box(_target_style, target.get_global_rect())

	## `control`'s focus box recolored, without fill (or `fallback`).
	static func outline_of(control: Control, outline: Color, fallback: StyleBox) -> StyleBox:
		var own := control.get_theme_stylebox(&"focus")
		if own is StyleBoxTexture:
			var tex_copy := own.duplicate() as StyleBoxTexture
			tex_copy.draw_center = false
			tex_copy.modulate_color = outline
			return tex_copy
		if not own is StyleBoxFlat:
			return fallback
		var copy := own.duplicate() as StyleBoxFlat
		copy.draw_center = false
		copy.shadow_size = 0
		copy.border_color = outline
		if copy.border_width_left < 3:
			copy.set_border_width_all(3)
		return copy


## Keeps each half's frame on its remembered control (programmatic grabs included).
func _process(_delta: float) -> void:
	var active := is_active()
	if active:
		_remember_focus()
	for i in _frames.size():
		var remembered: Variant = _focus_memory.get(i)
		var target: Control = remembered if active and _is_shown(remembered) else null
		_frames[i].target = target
		_frames[i].queue_redraw()


func _is_shown(candidate: Variant) -> bool:
	return is_instance_valid(candidate) and candidate is Control \
			and not (candidate as Control).is_queued_for_deletion() and (candidate as Control).is_visible_in_tree()


func _ready() -> void:
	get_viewport().size_changed.connect(_layout)
	_layout()


## Each half takes half of the visible area: with stretch aspect "expand" a window wider
## than 16:9 shows more than 1920 units (playtest: the right half stopped short).
func _layout() -> void:
	var visible_size := get_viewport().get_visible_rect().size
	var half := Vector2(visible_size.x / maxf(_containers.size(), 1.0), visible_size.y)
	for i in _containers.size():
		_containers[i].position = Vector2(half.x * i, 0.0)
		_containers[i].size = half


## Puts a player's screen (level-up or shop) in his half.
func add_screen(player_index: int, screen: CanvasLayer) -> void:
	_viewports[player_index].add_child(screen)
	_screens.append(screen)


## Starting focus of a half (before its player pressed anything).
func remember_focus(player_index: int, control: Control) -> void:
	if control != null:
		_focus_memory[player_index] = control


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
	get_viewport().set_input_as_handled()
	if event is InputEventJoypadMotion:
		_on_stick(index, event)
		return
	_remember_focus()
	_restore_focus(index)
	if event.is_action("ui_accept", true):
		# A Button cancels its press when it loses focus, and the other half taking the
		# focus back between press and release does exactly that. So "accept" presses the
		# focused button directly and its release is swallowed.
		var focused := _viewports[index].gui_get_focus_owner()
		if focused is BaseButton and not (focused as BaseButton).toggle_mode:
			if event.is_pressed() and not event.is_echo() and not (focused as BaseButton).disabled:
				(focused as BaseButton).pressed.emit()
			return
	_viewports[index].push_input(event)
	_remember_focus()


## A pushed stick motion does not move the GUI focus in a SubViewport (playtest: only
## the D-pad worked in the halves). The left stick is turned into one ui_* press each
## time it is pushed past STICK_THRESHOLD in a direction; idle noise does nothing.
func _on_stick(index: int, event: InputEventJoypadMotion) -> void:
	if event.axis != JOY_AXIS_LEFT_X and event.axis != JOY_AXIS_LEFT_Y:
		return
	var key := index * 10 + event.axis
	var direction := 0
	if absf(event.axis_value) >= STICK_THRESHOLD:
		direction = 1 if event.axis_value > 0.0 else -1
	if direction == _stick_state.get(key, 0):
		return
	_stick_state[key] = direction
	if direction == 0:
		return
	var action: StringName
	if event.axis == JOY_AXIS_LEFT_X:
		action = &"ui_right" if direction > 0 else &"ui_left"
	else:
		action = &"ui_down" if direction > 0 else &"ui_up"
	_remember_focus()
	_restore_focus(index)
	for pressed in [true, false]:
		var press := InputEventAction.new()
		press.action = action
		press.pressed = pressed
		_viewports[index].push_input(press)
	_remember_focus()


## Godot keeps ONE GUI focus per window: a grab in one half silently clears the other
## half's focus. Each half's focused control is remembered here and given back to the
## half whose player presses a button, so both players can navigate in turn at any time.
func _remember_focus() -> void:
	for i in _viewports.size():
		var focused := _viewports[i].gui_get_focus_owner()
		if focused != null:
			_focus_memory[i] = focused


func _restore_focus(index: int) -> void:
	var viewport := _viewports[index]
	if viewport.gui_get_focus_owner() != null:
		return
	# Untyped on purpose: the remembered card may be freed (new offers), and assigning a
	# freed instance to a typed variable is a script error.
	var remembered: Variant = _focus_memory.get(index)
	var target: Control = remembered if _can_focus(remembered) else null
	if target == null:
		for node in viewport.find_children("*", "Control", true, false):
			if _can_focus(node):
				target = node
				break
	if target != null:
		target.grab_focus()


func _can_focus(candidate: Variant) -> bool:
	if not is_instance_valid(candidate) or not candidate is Control:
		return false
	var control := candidate as Control
	if control.is_queued_for_deletion() or not control.is_visible_in_tree():
		return false
	if control.focus_mode != Control.FOCUS_ALL:
		return false
	return not (control is BaseButton and (control as BaseButton).disabled)


## Player number whose devices produced `event`, -1 if none.
func owner_of(event: InputEvent) -> int:
	for i in _inputs.size():
		if _inputs[i].owns_event(event):
			return i
	return -1
