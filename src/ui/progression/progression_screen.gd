class_name ProgressionScreen
extends Control
## Profile screen (ADR 0015): lifetime statistics and every challenge, done
## or not, with what it unlocks. Read-only.

signal closed

## Pixels per second the list scrolls while up / down (D-pad, stick, arrows) is held.
const SCROLL_SPEED := 900.0

var _stats: Label
var _rows: VBoxContainer
var _back: Button
## The rows are not focusable (read-only): up / down scroll the list instead (playtest:
## the list could not be scrolled with a gamepad).
var _scroll: ScrollContainer


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.get_theme()
	visible = false
	var dim := ColorRect.new()
	dim.color = UiTheme.DIM
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	var title := Label.new()
	title.text = "UI_PROGRESSION"
	title.theme_type_variation = &"SubtitleLabel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_stats = Label.new()
	_stats.theme_type_variation = &"SmallLabel"
	_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_stats)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(900, 480)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_scroll = scroll
	_rows = VBoxContainer.new()
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation", 10)
	scroll.add_child(_rows)
	_back = Button.new()
	_back.text = "UI_BACK"
	_back.custom_minimum_size = Vector2(260, 64)
	_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_back.pressed.connect(close)
	box.add_child(_back)


func open() -> void:
	var profile := SaveService.profile
	_stats.text = tr("UI_PROFILE_STATS") % [profile.runs_played, profile.runs_won, profile.best_wave,
		profile.total_kills]
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	# Other challenges first, then the seal rewards from Copper to Astral.
	var challenges := SaveService.all_challenges()
	challenges.sort_custom(func(a: ChallengeData, b: ChallengeData) -> bool:
		var sa := a.kind == ChallengeData.Kind.WIN_SEAL
		var sb := b.kind == ChallengeData.Kind.WIN_SEAL
		if sa != sb:
			return sb
		if sa and a.threshold != b.threshold:
			return a.threshold < b.threshold
		return String(a.id) < String(b.id))
	for challenge in challenges:
		_rows.add_child(_row(challenge, profile.completed.has(challenge.id)))
	visible = true
	_scroll.scroll_vertical = 0
	_back.grab_focus()


func _process(delta: float) -> void:
	if not visible:
		return
	var axis := Input.get_axis(&"ui_up", &"ui_down")
	if axis != 0.0:
		_scroll.scroll_vertical += roundi(axis * SCROLL_SPEED * delta)


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		close()


func _row(challenge: ChallengeData, done: bool) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var mark := Label.new()
	mark.text = "✔" if done else "·"
	mark.custom_minimum_size = Vector2(32, 0)
	mark.add_theme_color_override("font_color", UiTheme.GOOD if done else UiTheme.MUTED)
	row.add_child(mark)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	var name_label := Label.new()
	name_label.text = challenge.name_key
	name_label.add_theme_color_override("font_color", UiTheme.TEXT if done else UiTheme.MUTED)
	text.add_child(name_label)
	var details := Label.new()
	var target := ContentDB.get_def(challenge.unlock_category, challenge.unlock_id)
	var target_name: String = tr(target.get(&"name_key")) if target != null else String(challenge.unlock_id)
	details.text = "%s  →  %s" % [tr(challenge.description_key), target_name]
	details.theme_type_variation = &"SmallLabel"
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(details)
	return row
