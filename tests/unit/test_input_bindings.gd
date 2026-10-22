extends GutTest
## InputBindings: remappable keys and pad buttons (Settings `bindings`).


func after_each() -> void:
	InputBindings.apply({})  # the InputMap is global: put the defaults back


func _keys(action: StringName) -> Array[int]:
	var found: Array[int] = []
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			found.append(int((event as InputEventKey).physical_keycode))
	return found


func test_defaults_are_read_from_the_project_and_cover_two_keys_and_a_pad_button() -> void:
	var slots := InputBindings.resolved({})
	for action in InputBindings.ACTIONS:
		assert_eq((slots[action] as Array).size(), InputBindings.KEY_SLOTS + 1, "%s has its three slots" % action)
	assert_eq(int(slots[&"pause"][InputBindings.PAD_SLOT]), JOY_BUTTON_START, "pause is on Start by default")
	assert_gt(int(slots[&"move_left"][0]), 0, "a default key")


func test_assigning_a_key_changes_the_action_and_nothing_else() -> void:
	var bindings := InputBindings.assign({}, &"move_left", 0, KEY_J)
	InputBindings.apply(bindings)
	assert_has(_keys(&"move_left"), int(KEY_J))
	assert_eq(_keys(&"move_left").size(), 2, "still two keys: the second slot is untouched")
	var stick := InputMap.action_get_events(&"move_left").filter(func(e: InputEvent) -> bool: return e is InputEventJoypadMotion)
	assert_eq(stick.size(), 1, "the stick stays")
	assert_eq(_keys(&"move_right"), InputBindings.resolved({})[&"move_right"].slice(0, 2).filter(func(c: int) -> bool: return c > 0), "other actions keep their keys")


func test_a_key_used_by_another_action_is_swapped_so_no_key_drives_two_actions() -> void:
	var defaults := InputBindings.resolved({})
	var pause_key := int(defaults[&"pause"][0])
	var left_key := int(defaults[&"move_left"][0])
	var bindings := InputBindings.assign({}, &"move_left", 0, pause_key)
	var slots := InputBindings.resolved(bindings)
	assert_eq(int(slots[&"move_left"][0]), pause_key)
	assert_eq(int(slots[&"pause"][0]), left_key, "pause took the key move_left gave up")


func test_only_the_changes_are_kept_and_a_reset_clears_them() -> void:
	var bindings := InputBindings.assign({}, &"pause", 0, KEY_O)
	assert_eq(bindings.keys(), ["pause"], "the other actions stay on their defaults, out of the file")
	assert_true(InputBindings.reset_action(bindings, &"pause").is_empty())


func test_the_pad_button_can_be_changed_too() -> void:
	var bindings := InputBindings.assign({}, &"pause", InputBindings.PAD_SLOT, JOY_BUTTON_BACK)
	InputBindings.apply(bindings)
	var buttons := InputMap.action_get_events(&"pause").filter(func(e: InputEvent) -> bool: return e is InputEventJoypadButton)
	assert_eq((buttons[0] as InputEventJoypadButton).button_index, JOY_BUTTON_BACK)
	assert_eq(buttons.size(), 1)


func test_bad_saved_bindings_are_dropped() -> void:
	var clean := InputBindings.sanitize({"pause": [80, -5, 3], "move_up": [1, 2], "unknown": [1, 2, 3], "move_down": "x"})
	assert_eq(clean.keys(), ["pause"], "wrong size, unknown action and wrong type are dropped")
	assert_eq(clean["pause"], [80, 0, 3], "a negative key becomes none")
	assert_true(InputBindings.sanitize("nonsense").is_empty())


func test_bindings_survive_the_settings_file() -> void:
	var settings := SettingsData.new()
	settings.set_value(&"bindings", InputBindings.assign({}, &"move_up", 1, KEY_I))
	var back := SettingsData.from_dict(JSON.parse_string(JSON.stringify(settings.to_dict())))
	assert_eq(int(InputBindings.resolved(back.bindings)[&"move_up"][1]), int(KEY_I), "floats from JSON are read back as keys")
