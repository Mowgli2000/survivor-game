class_name ProgressionScreen
extends Control
## Profile screen (ADR 0015): lifetime statistics and every challenge, done
## or not, with what it unlocks. Read-only.

signal closed

## Pixels per second the list scrolls while up / down (D-pad, stick, arrows) is held.
const SCROLL_SPEED := 900.0
## Reward icon of a challenge row.
const REWARD_ICON := 52.0

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
	# One row per condition: the three rewards of a seal are one challenge to the player.
	for group in grouped(challenges):
		_rows.add_child(_row(group, profile))
	_add_collection(profile)
	visible = true
	_scroll.scroll_vertical = 0
	_back.grab_focus()


## Collection challenges: they pay portal shards for the skin shop (ADR 0023).
func _add_collection(profile: Profile) -> void:
	var collection := SaveService.collection_challenges()
	if collection.is_empty():
		return
	collection.sort_custom(func(a: ChallengeData, b: ChallengeData) -> bool:
		return a.shards < b.shards or (a.shards == b.shards and String(a.id) < String(b.id)))
	var done_count := 0
	var earned := 0
	for challenge in collection:
		if profile.completed.has(challenge.id):
			done_count += 1
			earned += challenge.shards
	var header := Label.new()
	header.text = tr("UI_COLLECTION_HEADER") % [done_count, collection.size(), earned]
	header.theme_type_variation = &"SubtitleLabel"
	header.add_theme_color_override("font_color", UiTheme.VIOLET)
	_rows.add_child(header)
	for challenge in collection:
		_rows.add_child(_collection_row(challenge, profile))


func _collection_row(challenge: ChallengeData, profile: Profile) -> Control:
	var done := profile.completed.has(challenge.id)
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
	details.text = challenge.description_key
	details.theme_type_variation = &"SmallLabel"
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(details)
	var reward := Label.new()
	reward.text = "◆ %d" % challenge.shards
	reward.add_theme_color_override("font_color", UiTheme.VIOLET if not done else UiTheme.MUTED)
	row.add_child(reward)
	return row


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


## Challenges sharing the same condition (kind, character, enemy, threshold), in order.
static func grouped(challenges: Array[ChallengeData]) -> Array[Array]:
	var groups: Array[Array] = []
	var index: Dictionary = {}
	for challenge in challenges:
		var key := "%d|%s|%s|%d" % [challenge.kind, challenge.character_id, challenge.enemy_id, challenge.threshold]
		if challenge.kind != ChallengeData.Kind.WIN_SEAL and challenge.kind != ChallengeData.Kind.WIN_WITH:
			key += "|" + String(challenge.id)  # a single reward: never merged
		if index.has(key):
			groups[index[key]].append(challenge)
		else:
			index[key] = groups.size()
			groups.append([challenge])
	return groups


## A row: mark, name and condition, then every reward of the group as an icon.
func _row(group: Array, profile: Profile) -> Control:
	var challenge: ChallengeData = group[0]
	var done := profile.completed.has(challenge.id)
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
	var names: Array[String] = []
	for member: ChallengeData in group:
		var target := ContentDB.get_def(member.unlock_category, member.unlock_id)
		names.append(tr(target.get(&"name_key")) if target != null else String(member.unlock_id))
	details.text = "%s  →  %s" % [tr(challenge.description_key), ", ".join(names)]
	details.theme_type_variation = &"SmallLabel"
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(details)
	# The rewards, side by side in the same slot (a silhouette until won).
	var rewards := HBoxContainer.new()
	rewards.add_theme_constant_override("separation", 8)
	rewards.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for member: ChallengeData in group:
		var target := ContentDB.get_def(member.unlock_category, member.unlock_id)
		var icon: Texture2D = target.get(&"icon") if target != null else null
		if icon == null:
			continue
		var rect := TextureRect.new()
		rect.texture = icon
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.custom_minimum_size = Vector2(REWARD_ICON, REWARD_ICON)
		rect.tooltip_text = names[group.find(member)]
		if not profile.completed.has(member.id):
			rect.material = SealSelect.silhouette_material()
		rewards.add_child(rect)
	row.add_child(rewards)
	return row
