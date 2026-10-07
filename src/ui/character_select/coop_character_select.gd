class_name CoopCharacterSelect
extends Control
## Local coop pick (ADR 0017, split screen like ADR 0021): one compact CharacterSelect
## per half of the screen (CoopScreens routes each player's devices to his half), so
## both players pick a character and a weapon at the same time; player 1 also picks
## the seal and presses Play. The run starts as soon as both are ready, with the seal
## lowered to what player 2's character has unlocked if needed.

signal started(setup: RunSetup)
signal closed

var _halves: CoopScreens
var _selects: Array[CharacterSelect] = []


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


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
		select.unpicked.connect(_on_unpicked)
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
	if _halves != null:
		_halves.queue_free()
		_halves = null


## A player is done: player 1's seal row learns player 2's character; both done: start.
func _on_picked() -> void:
	var first := _selects[0]
	var second := _selects[1]
	first.set_partner(second.chosen_character() if second.is_ready else null)
	if first.is_ready and second.is_ready:
		_start()


func _on_unpicked() -> void:
	_selects[0].set_partner(_selects[1].chosen_character() if _selects[1].is_ready else null)


func _start() -> void:
	var first := _selects[0]
	var second := _selects[1]
	var setup := RunSetup.new()
	setup.character = first.chosen_character()
	setup.weapon = first.chosen_weapon()
	setup.variant = first.chosen_variant()
	setup.character_2 = second.chosen_character()
	setup.weapon_2 = second.chosen_weapon()
	setup.variant_2 = second.chosen_variant()
	setup.difficulty = shared_difficulty(first.chosen_difficulty(), second.chosen_character())
	Audio.play(Sounds.PORTAL_OPEN, -4.0)
	started.emit(setup)


## `wanted`, or the hardest seal `partner` has unlocked if that is lower.
static func shared_difficulty(wanted: DifficultyData, partner: CharacterData) -> DifficultyData:
	var allowed := SaveService.profile.max_difficulty(partner.id)
	if wanted.level <= allowed:
		return wanted
	for def in ContentDB.get_all(&"difficulties"):
		if (def as DifficultyData).level == allowed:
			return def
	return wanted
