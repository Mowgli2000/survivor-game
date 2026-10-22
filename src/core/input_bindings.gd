class_name InputBindings
extends RefCounted
## Player-chosen controls (Settings `bindings`). Each remappable action has two keyboard slots (physical keys, so
## AZERTY and QWERTY both work) and one gamepad button slot. The stick, the menu actions (`ui_*`, `cancel`, `confirm`)
## and everything else keep the project's defaults. The defaults are read once from the InputMap, before the first
## override is applied.
## Example: `Settings.set_value(&"bindings", InputBindings.assign(Settings.data.bindings, &"pause", 0, KEY_P))`.

## Remappable actions, in the order the controls tab lists them.
const ACTIONS: Array[StringName] = [&"move_up", &"move_down", &"move_left", &"move_right", &"pause"]
const KEY_SLOTS := 2
## Slot number of the gamepad button (after the keyboard slots).
const PAD_SLOT := 2
## Cannot be bound: it cancels the capture, and it is the menus' own way back.
const RESERVED_KEY := KEY_ESCAPE

## Short names of the pad buttons (Xbox layout, as in the game's button hints).
const PAD_NAMES := {JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "Back", JOY_BUTTON_START: "Start", JOY_BUTTON_LEFT_SHOULDER: "L1",
	JOY_BUTTON_RIGHT_SHOULDER: "R1", JOY_BUTTON_LEFT_STICK: "L3", JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_DPAD_UP: "D-pad up", JOY_BUTTON_DPAD_DOWN: "D-pad down", JOY_BUTTON_DPAD_LEFT: "D-pad left",
	JOY_BUTTON_DPAD_RIGHT: "D-pad right"}

## action -> [key slot 0, key slot 1, pad button]: a physical keycode (0 = none) and a JoyButton (-1 = none).
static var _defaults: Dictionary = {}


## The slots of every action: the defaults, then the player's choices on top.
static func resolved(bindings: Dictionary) -> Dictionary:
	_read_defaults()
	var result: Dictionary = {}
	for action in ACTIONS:
		var slots: Array = (_defaults[action] as Array).duplicate()
		var chosen: Variant = bindings.get(String(action))
		if chosen is Array and (chosen as Array).size() == slots.size():
			slots = (chosen as Array).duplicate()
		result[action] = slots
	return result


## Gives the InputMap the bindings: the keys and pad buttons of each remappable action are replaced, the stick kept.
static func apply(bindings: Dictionary) -> void:
	var slots := resolved(bindings)
	for action in ACTIONS:
		if not InputMap.has_action(action):
			continue
		for event in InputMap.action_get_events(action):
			if event is InputEventKey or event is InputEventJoypadButton:
				InputMap.action_erase_event(action, event)
		var chosen: Array = slots[action]
		for slot in KEY_SLOTS:
			if int(chosen[slot]) > 0:
				var key := InputEventKey.new()
				key.physical_keycode = int(chosen[slot]) as Key
				InputMap.action_add_event(action, key)
		if int(chosen[PAD_SLOT]) >= 0:
			var button := InputEventJoypadButton.new()
			button.button_index = int(chosen[PAD_SLOT]) as JoyButton
			InputMap.action_add_event(action, button)


## `bindings` with `code` put in `slot` of `action`. A key already used by another action moves there the key this
## slot held (a swap), so no key ever drives two actions. Returns the new dictionary; the input is left alone.
static func assign(bindings: Dictionary, action: StringName, slot: int, code: int) -> Dictionary:
	var slots := resolved(bindings)
	var previous: int = int(slots[action][slot])
	if slot < KEY_SLOTS:
		for other in ACTIONS:
			for other_slot in KEY_SLOTS:
				if (other != action or other_slot != slot) and int(slots[other][other_slot]) == code:
					slots[other][other_slot] = previous
	else:
		for other in ACTIONS:
			if other != action and int(slots[other][PAD_SLOT]) == code:
				slots[other][PAD_SLOT] = previous
	slots[action][slot] = code
	return _only_changes(slots)


## The bindings with `action` back to its defaults.
static func reset_action(bindings: Dictionary, action: StringName) -> Dictionary:
	var kept := bindings.duplicate()
	kept.erase(String(action))
	return kept


## A bindings dictionary read from the JSON file: unknown actions, wrong sizes and wrong types are dropped.
static func sanitize(raw: Variant) -> Dictionary:
	var clean: Dictionary = {}
	if not raw is Dictionary:
		return clean
	for action in ACTIONS:
		var slots: Variant = (raw as Dictionary).get(String(action))
		if not slots is Array or (slots as Array).size() != KEY_SLOTS + 1:
			continue
		var ok := true
		for value in slots:
			ok = ok and (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT)
		if ok:
			var numbers: Array = []
			for value in slots:
				numbers.append(int(value))
			for slot in KEY_SLOTS:
				numbers[slot] = maxi(numbers[slot], 0)
			numbers[PAD_SLOT] = clampi(numbers[PAD_SLOT], -1, JOY_BUTTON_SDL_MAX - 1)
			clean[String(action)] = numbers
	return clean


## What a key slot shows: the key's name on the player's keyboard layout ("-" when empty).
static func key_text(code: int) -> String:
	if code <= 0:
		return "-"
	var label := DisplayServer.keyboard_get_label_from_physical(code as Key) if DisplayServer.get_name() != "headless" \
		else code as Key
	return OS.get_keycode_string(label)


## What the pad slot shows.
static func pad_text(button: int) -> String:
	if button < 0:
		return "-"
	return PAD_NAMES.get(button, "B%d" % button)


## Only the actions that differ from the defaults are stored, so the file stays short and new defaults reach players.
static func _only_changes(slots: Dictionary) -> Dictionary:
	var changes: Dictionary = {}
	for action in ACTIONS:
		if slots[action] != _defaults[action]:
			changes[String(action)] = slots[action]
	return changes


static func _read_defaults() -> void:
	if not _defaults.is_empty():
		return
	for action in ACTIONS:
		var keys: Array = []
		var pad := -1
		if InputMap.has_action(action):
			for event in InputMap.action_get_events(action):
				if event is InputEventKey and keys.size() < KEY_SLOTS:
					keys.append(int((event as InputEventKey).physical_keycode))
				elif event is InputEventJoypadButton and pad < 0:
					pad = (event as InputEventJoypadButton).button_index
		while keys.size() < KEY_SLOTS:
			keys.append(0)
		_defaults[action] = keys + [pad]
