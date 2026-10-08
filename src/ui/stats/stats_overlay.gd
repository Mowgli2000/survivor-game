class_name StatsOverlay
extends CanvasLayer
## Holding Share (gamepad Select / Back) or Tab shows the stats of the player who holds
## it, on top of EVERY screen of a run: wave, level-up, shop, pause aside (it shows them
## already), game over and victory (playtest: it only worked in the shop, and one
## player's press opened both players' stats).
## Polled per device (not through input events): the coop halves, the pause and the
## end screens all eat or reroute events, a poll sees the real button state.

## Above every other screen of the run (CoopScreens is 21, the end screens are lower).
const OVERLAY_LAYER := 100

var _panels: Array[StatsPanel] = []
var _inputs: Array[PlayerInput] = []
var _coop: bool = false
## Called with the player index: true when that player's stats are already on screen.
var _already_shown: Callable


func _init() -> void:
	layer = OVERLAY_LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS


## One panel per player. `already_shown`: Callable(index) -> bool (pause, solo shop).
func setup(players: Array[RunPlayer], already_shown: Callable = Callable()) -> void:
	_coop = players.size() > 1
	_already_shown = already_shown
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiTheme.get_theme()
	add_child(root)
	for rp in players:
		_inputs.append(rp.input)
		var panel := StatsPanel.new()
		panel.setup(rp.player.stats)
		panel.setup_families(rp.families)
		if _coop:
			panel.set_tag(tr("UI_PLAYER_N") % (rp.index + 1), rp.color())
		panel.visible = false
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var slot := Control.new()
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.set_anchors_preset(Control.PRESET_FULL_RECT)
		if _coop:
			# Each player's panel in the middle of his half of the screen.
			slot.anchor_left = 0.5 * rp.index
			slot.anchor_right = 0.5 * rp.index + 0.5
		else:
			slot.anchor_left = 0.62
		root.add_child(slot)
		panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
		panel.grow_vertical = Control.GROW_DIRECTION_BOTH
		slot.add_child(panel)
		_panels.append(panel)


func _process(_delta: float) -> void:
	for i in _panels.size():
		_panels[i].visible = is_held(i) and not (_already_shown.is_valid() and _already_shown.call(i))


## True while player `index`'s Share / Tab is down. Solo: any device.
func is_held(index: int) -> bool:
	if not _coop:
		return Input.is_action_pressed(&"show_stats")
	var input := _inputs[index]
	if input.keyboard and Input.is_physical_key_pressed(KEY_TAB):
		return true
	return input.device >= 0 and Input.is_joy_button_pressed(input.device, JOY_BUTTON_BACK)


## The panel of player `index` (tests).
func panel_of(index: int) -> StatsPanel:
	return _panels[index]
