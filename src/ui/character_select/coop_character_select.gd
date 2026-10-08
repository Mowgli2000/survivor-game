class_name CoopCharacterSelect
extends Control
## Local coop pick (ADR 0017, split screen like ADR 0021): one compact CharacterSelect
## per half of the screen (CoopScreens routes each player's devices to his half), so
## both players pick a character and a weapon at the same time. Once both are ready,
## the shared seal screen (SealSelect) opens full screen: a seal is open when both
## hunters have won the one below it; either player picks it and the run starts.

signal started(setup: RunSetup)
signal closed

var _halves: CoopScreens
var _selects: Array[CharacterSelect] = []
var _seals: SealSelect


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_seals = SealSelect.new()
	_seals.chosen.connect(_start)
	_seals.back.connect(_on_seals_back)
	add_child(_seals)


func open() -> void:
	_free_halves()
	visible = true
	_halves = CoopScreens.new()
	_halves.name = "CoopHalves"
	_halves.setup(PlayerInput.assign(2, PlayerInput.connected_pads()))
	add_child(_halves)
	for i in 2:
		var layer := CanvasLayer.new()
		var select := CharacterSelect.new(true)
		layer.add_child(select)
		_halves.add_screen(i, layer)
		select.picked.connect(_on_picked)
		select.closed.connect(close)
		_selects.append(select)
		select.open(i)
		# Godot keeps one focus per window: each half starts on its first head.
		_halves.remember_focus(i, select.first_card())


func close() -> void:
	if not visible:
		return
	visible = false
	_free_halves()
	closed.emit()


## The two halves (tests and the capture tool).
func select_of(index: int) -> CharacterSelect:
	return _selects[index]


func halves() -> CoopScreens:
	return _halves


func _free_halves() -> void:
	_selects.clear()
	if _seals.visible:
		_seals.close()
	if _halves != null:
		_halves.queue_free()
		_halves = null


## Both players ready: the halves hide (their input routing stops with them) and the
## shared seal screen opens.
func _on_picked() -> void:
	if not (_selects[0].is_ready and _selects[1].is_ready):
		return
	_show_halves(false)
	_seals.open([_selects[0].chosen_character(), _selects[1].chosen_character()] as Array[CharacterData])


## Back from the seals: both players are back on their weapons.
func _on_seals_back() -> void:
	_show_halves(true)
	for select in _selects:
		select.unready()


func _show_halves(on: bool) -> void:
	for i in _selects.size():
		(_selects[i].get_parent() as CanvasLayer).visible = on
	if on and _halves != null:
		for i in _selects.size():
			_halves.remember_focus(i, _selects[i].get_viewport().gui_get_focus_owner())


## The seal screen (tests and the capture tool).
func seals() -> SealSelect:
	return _seals


func _start(difficulty: DifficultyData) -> void:
	var first := _selects[0]
	var second := _selects[1]
	var setup := RunSetup.new()
	setup.character = first.chosen_character()
	setup.weapon = first.chosen_weapon()
	setup.variant = first.chosen_variant()
	setup.character_2 = second.chosen_character()
	setup.weapon_2 = second.chosen_weapon()
	setup.variant_2 = second.chosen_variant()
	setup.difficulty = difficulty
	Audio.play(Sounds.PORTAL_OPEN, -4.0)
	started.emit(setup)
