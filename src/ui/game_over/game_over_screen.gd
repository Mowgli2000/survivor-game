class_name GameOverScreen
extends CanvasLayer
## Shown when the run ends (death or victory): run summary, retry and main menu buttons.

signal retry_requested
signal main_menu_requested
signal endless_requested

## Defeat veil: the night violet of the UI, pushed toward red.
## Tint over the painted backdrop (the picture stays visible around the cards).
const DEFEAT_DIM := Color(0.1, 0.01, 0.04, 0.5)
const VICTORY_DIM := Color(0.0, 0.02, 0.08, 0.38)
const DEFEAT_BACKGROUND := preload("res://assets/ui/backgrounds/defeat.png")
const VICTORY_BACKGROUND := preload("res://assets/ui/backgrounds/victory.png")
## Rows shown in the damage summary (the biggest dealers).
const RECAP_ROWS := 6
const RECAP_ICON := 56.0
const RECAP_BAR_WIDTH := 260.0
## The unlock cards share this width (the end screen must fit the 1920 px viewport).
const UNLOCKS_MAX_WIDTH := 1500.0
const UNLOCK_CARD_MAX := 170.0
const UNLOCK_CARD_MIN := 116.0
var _unlock_card_width: float = UNLOCK_CARD_MAX
const RECAP_ROW_SEPARATION := 8
## Right-stick / page keys scroll the list when there are more rows than RECAP_ROWS.
const RECAP_SCROLL_SPEED := 700.0
const RECAP_STICK_DEADZONE := 0.25

## True when the last open() was a victory.
var is_victory: bool = false

var _title: Label
var _dim: ColorRect
var _backdrop: UiBackdrop
var _summary: Label
## Damage by weapon, next to the summary: one column per player (show_recap).
var _recap: HBoxContainer
## Scrolling lists of the recap columns (only the ones with more than RECAP_ROWS rows).
var _recap_scrolls: Array[ScrollContainer] = []
var _unlocks: HBoxContainer
## Rewards of the boss chests: icons to hover (mouse) or focus (gamepad); the description appears below.
var _rewards_box: VBoxContainer
var _rewards_row: HBoxContainer
var _reward_text: Label
## Victory with new unlocks: the cards come alone first, "Continue" then shows the statistics.
var _middle: HBoxContainer
var _buttons: HBoxContainer
var _continue: Button
var _revealing := false
var _retry: Button
var _main_menu: Button
var _endless: Button


func _init() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiTheme.get_theme()
	add_child(root)

	_backdrop = UiBackdrop.create(DEFEAT_BACKGROUND, 0.0)
	root.add_child(_backdrop)
	_dim = ColorRect.new()
	_dim.color = DEFEAT_DIM
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(_dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.window_style())
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 20)
	panel.add_child(box)

	_title = Label.new()
	_title.text = "UI_GAME_OVER"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.theme_type_variation = &"TitleLabel"
	_title.add_theme_font_size_override("font_size", 72)
	box.add_child(_title)

	var middle := HBoxContainer.new()
	middle.alignment = BoxContainer.ALIGNMENT_CENTER
	middle.add_theme_constant_override("separation", 64)
	box.add_child(middle)
	_middle = middle
	_summary = Label.new()
	_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_summary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_summary.theme_type_variation = &"ValueLabel"
	_summary.add_theme_font_size_override("font_size", 32)
	middle.add_child(_summary)
	_recap = HBoxContainer.new()
	_recap.add_theme_constant_override("separation", 48)
	_recap.visible = false
	middle.add_child(_recap)

	_rewards_box = VBoxContainer.new()
	_rewards_box.add_theme_constant_override("separation", 8)
	_rewards_box.visible = false
	box.add_child(_rewards_box)
	var rewards_title := Label.new()
	rewards_title.text = "UI_RECAP_REWARDS"
	rewards_title.theme_type_variation = &"SubtitleLabel"
	rewards_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rewards_box.add_child(rewards_title)
	_rewards_row = HBoxContainer.new()
	_rewards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_rewards_row.add_theme_constant_override("separation", 14)
	_rewards_box.add_child(_rewards_row)
	_reward_text = Label.new()
	_reward_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reward_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reward_text.custom_minimum_size = Vector2(900, 90)
	_rewards_box.add_child(_reward_text)

	_unlocks = HBoxContainer.new()
	_unlocks.alignment = BoxContainer.ALIGNMENT_CENTER
	_unlocks.add_theme_constant_override("separation", 18)
	_unlocks.visible = false
	box.add_child(_unlocks)

	# One row: three stacked buttons pushed the cards off the bottom of the screen.
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 24)
	box.add_child(buttons)
	_buttons = buttons
	_continue = Button.new()
	_continue.text = "UI_CONTINUE"
	_continue.custom_minimum_size = Vector2(340, 84)
	_continue.theme_type_variation = &"BigButton"
	_continue.visible = false
	_continue.pressed.connect(_end_reveal)
	box.add_child(_continue)
	_retry = Button.new()
	_retry.text = "UI_RETRY"
	_retry.custom_minimum_size = Vector2(340, 84)
	_retry.theme_type_variation = &"BigButton"
	_retry.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_retry.pressed.connect(func() -> void: retry_requested.emit())
	buttons.add_child(_retry)

	_endless = Button.new()
	_endless.text = "UI_CONTINUE_ENDLESS"
	_endless.custom_minimum_size = Vector2(300, 84)
	_endless.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_endless.pressed.connect(func() -> void: endless_requested.emit())
	buttons.add_child(_endless)

	_main_menu = Button.new()
	_main_menu.text = "UI_MAIN_MENU"
	_main_menu.custom_minimum_size = Vector2(300, 84)
	_main_menu.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_main_menu.pressed.connect(func() -> void: main_menu_requested.emit())
	buttons.add_child(_main_menu)


func open(time_survived: float, level: int, kills: int, wave: int, victory: bool = false) -> void:
	is_victory = victory
	_title.text = "UI_VICTORY" if victory else "UI_GAME_OVER"
	_title.add_theme_color_override("font_color", UiTheme.GOLD if victory else UiTheme.BAD)
	_dim.color = VICTORY_DIM if victory else DEFEAT_DIM
	_backdrop.texture = VICTORY_BACKGROUND if victory else DEFEAT_BACKGROUND
	_backdrop.queue_redraw()
	_summary.text = "%s %d\n%s %s\n%s %d\n%s %d" % [
		tr("UI_WAVE_REACHED"), wave,
		tr("UI_TIME_SURVIVED"), Hud.format_time(time_survived),
		tr("UI_LEVEL_LABEL"), level,
		tr("UI_KILLS"), kills,
	]
	_unlocks.visible = false
	_recap.visible = false
	_rewards_box.visible = false
	_revealing = false
	_middle.visible = true
	_buttons.visible = true
	_continue.visible = false
	_endless.visible = victory
	visible = true
	UiFx.pop_in(_title)
	UiFx.pop_in(_summary, 0.08)
	UiFx.pop_in(_retry, 0.16)
	UiFx.pop_in(_main_menu, 0.24)
	_retry.grab_focus()


## Damage summary, one column per player: {"title": "" (solo) or "Player 2",
## "color": player color, "rows": recap_rows(), coop: "kills", "deaths"}.
func show_recap(columns: Array[Dictionary]) -> void:
	for child in _recap.get_children():
		_recap.remove_child(child)
		child.queue_free()
	_recap_scrolls.clear()
	for column in columns:
		var rows: Array[Dictionary] = column.rows
		if rows.is_empty() and column.title == "":
			continue
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 8)
		_recap.add_child(box)
		var title := Label.new()
		title.theme_type_variation = &"SubtitleLabel"
		if column.title == "":
			title.text = "UI_RECAP_DAMAGE"
		else:
			title.text = "%s · %s" % [column.title, tr("UI_RECAP_DAMAGE")]
			title.add_theme_color_override("font_color", column.color)
		box.add_child(title)
		# Coop: each player's own kills and deaths.
		if column.title != "":
			var tally := Label.new()
			tally.text = "%s %d   ·   %s %d" % [tr("UI_KILLS"), column.get("kills", 0),
				tr("UI_DEATHS"), column.get("deaths", 0)]
			tally.add_theme_color_override("font_color", column.color)
			box.add_child(tally)
		if rows.is_empty():
			continue
		var top: float = rows[0].damage
		var total := 0.0
		for row in rows:
			total += row.damage
		# The weapons held at the end come first; the others (sold, merged away, effects)
		# follow under a divider, reachable by scrolling when the list is longer than RECAP_ROWS.
		var list := VBoxContainer.new()
		list.add_theme_constant_override("separation", RECAP_ROW_SEPARATION)
		var divider_done := false
		for i in rows.size():
			if i > 0 and not rows[i].final and rows[i - 1].final and not divider_done:
				list.add_child(_recap_divider())
				divider_done = true
			list.add_child(_recap_row(rows[i], top, total))
		if list.get_child_count() > RECAP_ROWS:
			var scroll := ScrollContainer.new()
			scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
			scroll.custom_minimum_size.y = RECAP_ROWS * RECAP_ICON + (RECAP_ROWS - 1) * RECAP_ROW_SEPARATION
			scroll.add_child(list)
			box.add_child(scroll)
			_recap_scrolls.append(scroll)
		else:
			box.add_child(list)
	_recap.visible = _recap.get_child_count() > 0
	if _recap.visible:
		UiFx.pop_in(_recap, 0.12)


## Rows of the damage summary, biggest first: weapons with their icon and
## name, then item effects and burning. `dealt` = EnemyManager.damage_dealt().
## `final_ids`: weapons held at the end of the run; their rows ("final") come first.
static func recap_rows(dealt: Dictionary, final_ids: Array[StringName] = []) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for key: StringName in dealt:
		var damage: float = dealt[key]
		if damage <= 0.0:
			continue
		var row := {"damage": damage, "icon": null, "name": "", "tier": 1, "final": key in final_ids}
		if key == EnemyManager.ITEMS_TAG:
			row.name = "UI_RECAP_ITEMS"
		elif key == EnemyManager.BURN_TAG:
			row.name = "UI_RECAP_BURN"
		else:
			var weapon := ContentDB.get_def(&"weapons", key) as WeaponData
			if weapon == null:
				continue
			row.name = weapon.name_key
			row.icon = weapon.icon
		rows.append(row)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.final != b.final:
			return a.final
		return a.damage > b.damage)
	return rows


## 950, 12.3k, 4.5M: big late-game numbers stay short.
static func compact(value: float) -> String:
	if value >= 1e6:
		return "%.1fM" % (value / 1e6)
	if value >= 1e4:
		return "%.1fk" % (value / 1e3)
	return str(roundi(value))


func _recap_divider() -> Control:
	var label := Label.new()
	label.text = "UI_RECAP_OTHERS"
	label.theme_type_variation = &"SmallLabel"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _process(delta: float) -> void:
	if not visible or _recap_scrolls.is_empty():
		return
	var direction := 0.0
	for device in Input.get_connected_joypads():
		var axis := Input.get_joy_axis(device, JOY_AXIS_RIGHT_Y)
		if absf(axis) > RECAP_STICK_DEADZONE:
			direction += axis
	direction += Input.get_action_strength(&"ui_page_down") - Input.get_action_strength(&"ui_page_up")
	if is_zero_approx(direction):
		return
	for scroll in _recap_scrolls:
		scroll.scroll_vertical += roundi(clampf(direction, -1.0, 1.0) * RECAP_SCROLL_SPEED * delta)


func _recap_row(row: Dictionary, top: float, total: float) -> Control:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 12)
	var icon: Control
	if row.icon != null:
		icon = IconTile.create(row.icon, row.tier, RECAP_ICON)
	else:
		icon = Control.new()
		icon.custom_minimum_size = Vector2(RECAP_ICON, RECAP_ICON)
	line.add_child(icon)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 2)
	line.add_child(info)
	var name_label := Label.new()
	name_label.text = row.name
	name_label.add_theme_font_size_override("font_size", 20)
	info.add_child(name_label)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(RECAP_BAR_WIDTH, 26)  # as tall as the 9-slice frame needs, else its ends break
	bar.max_value = top
	bar.value = row.damage
	var styles := UiTheme.bar_styles(UiTheme.BAD)
	bar.add_theme_stylebox_override("background", styles[0])
	bar.add_theme_stylebox_override("fill", styles[1])
	info.add_child(bar)
	var value := Label.new()
	value.text = "%s  (%d%%)" % [compact(row.damage), roundi(100.0 * row.damage / maxf(total, 1.0))]
	value.theme_type_variation = &"ValueLabel"
	value.add_theme_font_size_override("font_size", 22)
	value.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(value)
	return line


## New unlocks from this run (challenges completed), one card each: the
## character's animated sprite or the item/weapon icon, its name, "Unlocked!".
func show_unlocks(challenges: Array[ChallengeData], backdrops: Array[int] = []) -> void:
	for child in _unlocks.get_children():
		_unlocks.remove_child(child)
		child.queue_free()
	var count_cards := 0
	var has_shards := false
	for challenge in challenges:
		if ContentDB.get_def(challenge.unlock_category, challenge.unlock_id) != null:
			count_cards += 1
		has_shards = has_shards or challenge.shards > 0
	if has_shards:
		count_cards += 1
	count_cards += backdrops.size()
	_unlock_card_width = clampf((UNLOCKS_MAX_WIDTH - 18.0 * maxi(count_cards - 1, 0)) / maxi(count_cards, 1),
		UNLOCK_CARD_MIN, UNLOCK_CARD_MAX)
	var delay := 0.3
	var shards := 0
	var collected := 0
	for challenge in challenges:
		if challenge.shards > 0:
			shards += challenge.shards
			collected += 1
		var def := ContentDB.get_def(challenge.unlock_category, challenge.unlock_id)
		if def == null:
			continue
		var card := _unlock_card(def)
		_unlocks.add_child(card)
		UiFx.pop_in(card, delay)
		delay += 0.12
	for level in backdrops:
		var card := _backdrop_card(level)
		Audio.play(Sounds.UI_VICTORY_CARD, -8.0, 0.0)
		_unlocks.add_child(card)
		UiFx.pop_in(card, delay)
		delay += 0.12
	if shards > 0:
		var card := _shards_card(shards, collected)
		_unlocks.add_child(card)
		UiFx.pop_in(card, delay)
	_unlocks.visible = _unlocks.get_child_count() > 0
	if _unlocks.visible:
		Audio.play(Sounds.UI_UNLOCK, -5.0, 0.0)
	if _unlocks.visible and is_victory:
		_begin_reveal()


## What the boss chests gave (victory): [{"item": ItemData, ...}, ...]. Hover an icon, or move the
## focus to it with the gamepad, to read what it does.
func show_rewards(rewards: Array[Dictionary]) -> void:
	for child in _rewards_row.get_children():
		_rewards_row.remove_child(child)
		child.queue_free()
	_reward_text.text = ""
	_rewards_box.visible = not rewards.is_empty()
	for reward in rewards:
		var item: ItemData = reward.item
		var button := Button.new()
		button.icon = item.icon
		button.expand_icon = true
		button.custom_minimum_size = Vector2(84, 84)
		button.focus_mode = Control.FOCUS_ALL
		button.tooltip_text = ShopScreen.item_tooltip(item, 1)
		var text := ShopScreen.item_tooltip(item, 1)
		button.mouse_entered.connect(func() -> void: _reward_text.text = text)
		button.focus_entered.connect(func() -> void: _reward_text.text = text)
		_rewards_row.add_child(button)


func reward_icon_count() -> int:
	return _rewards_row.get_child_count()


## The chest is open: the unlocks alone on the screen, before the statistics.
func _begin_reveal() -> void:
	_revealing = true
	_rewards_box.visible = false
	_title.text = "UI_UNLOCKED_TITLE"
	_middle.visible = false
	_buttons.visible = false
	_continue.visible = true
	UiFx.pop_in(_title)
	_continue.grab_focus()


func _end_reveal() -> void:
	_revealing = false
	_rewards_box.visible = _rewards_row.get_child_count() > 0
	_title.text = "UI_VICTORY"
	_unlocks.visible = false
	_middle.visible = true
	_buttons.visible = true
	_continue.visible = false
	UiFx.pop_in(_title)
	UiFx.pop_in(_summary, 0.08)
	_retry.grab_focus()


## True while the unlocks are shown alone, before the statistics.
func is_revealing() -> bool:
	return _revealing


## Names (translation keys) of the unlock cards shown, in order (tests).
func unlock_names() -> PackedStringArray:
	var names: PackedStringArray = []
	for card in _unlocks.get_children():
		names.append(card.get_meta(&"name_key"))
	return names


## One card for the select screen background a danger win just opened: the picture, the place, "Unlocked!".
func _backdrop_card(level: int) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(_unlock_card_width, 0)
	card.add_theme_stylebox_override("panel", UiTheme.card_style(UiTheme.GOLD, 0.9))
	card.set_meta(&"name_key", "UI_UNLOCK_BACKDROP")
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)
	var picture := TextureRect.new()
	picture.texture = SelectBackdrops.picture(level, false)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.custom_minimum_size = Vector2(_unlock_card_width - 24.0, (_unlock_card_width - 24.0) * 9.0 / 16.0)
	box.add_child(picture)
	var name_label := Label.new()
	name_label.text = SelectBackdrops.place_name(level)
	name_label.theme_type_variation = &"SubtitleLabel"
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(name_label)
	var kind := Label.new()
	kind.text = "UI_UNLOCK_BACKDROP"
	kind.theme_type_variation = &"SmallLabel"
	kind.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(kind)
	var tag := Label.new()
	tag.text = "UI_UNLOCKED_TAG"
	tag.theme_type_variation = &"SmallLabel"
	tag.add_theme_color_override("font_color", UiTheme.GOLD)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(tag)
	return card


## One card for the portal shards the collection challenges of this run paid.
func _shards_card(shards: int, challenges: int) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(_unlock_card_width, 0)
	card.add_theme_stylebox_override("panel", UiTheme.card_style(UiTheme.VIOLET, 0.9))
	card.set_meta(&"name_key", "UI_SHARDS_EARNED")
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)
	var line := HBoxContainer.new()
	line.alignment = BoxContainer.ALIGNMENT_CENTER
	line.add_theme_constant_override("separation", 8)
	box.add_child(line)
	line.add_child(UiIcons.tile(UiIcons.shard(), 48.0))
	var amount := Label.new()
	amount.text = "+%d" % shards
	amount.theme_type_variation = &"TitleLabel"
	amount.add_theme_font_size_override("font_size", 40)
	amount.add_theme_color_override("font_color", UiTheme.VIOLET)
	line.add_child(amount)
	var name_label := Label.new()
	name_label.text = "UI_SHARDS_EARNED"
	name_label.theme_type_variation = &"SubtitleLabel"
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name_label)
	var count := Label.new()
	count.text = tr("UI_SHARDS_FROM") % challenges
	count.theme_type_variation = &"SmallLabel"
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(count)
	return card


func _unlock_card(def: Resource) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(_unlock_card_width, 0)
	card.add_theme_stylebox_override("panel", UiTheme.card_style(UiTheme.GOLD, 0.9))
	card.set_meta(&"name_key", def.get(&"name_key"))
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)
	var visual: Control
	if def is CharacterData:
		visual = SpritePreview.create(CharacterSelect.character_sheet(def), 84.0)
	else:
		visual = IconTile.create(def.get(&"icon"), int(def.get(&"tier")) if def is ItemData else 1, 72.0)
	visual.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(visual)
	var name_label := Label.new()
	name_label.text = def.get(&"name_key")
	name_label.theme_type_variation = &"SubtitleLabel"
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Long names wrap inside the card instead of widening it.
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# The name takes the spare height so the kind and the tag line up across cards.
	name_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if not def is CharacterData:
		name_label.add_theme_color_override("font_color", Tiers.color(int(def.get(&"tier")) if def is ItemData else 1))
	box.add_child(name_label)
	# What was unlocked (character, weapon or item) and what it does, on hover too.
	var kind := Label.new()
	kind.text = unlock_kind_key(def)
	kind.theme_type_variation = &"SmallLabel"
	kind.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(kind)
	card.tooltip_text = unlock_tooltip(def)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	var tag := Label.new()
	tag.text = "UI_UNLOCKED_TAG"
	tag.theme_type_variation = &"SmallLabel"
	tag.add_theme_color_override("font_color", UiTheme.GOLD)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(tag)
	return card


## "New character" / "New weapon" / "New item" (translation key).
static func unlock_kind_key(def: Resource) -> String:
	if def is CharacterData:
		return "UI_UNLOCK_CHARACTER"
	if def is WeaponData:
		return "UI_UNLOCK_WEAPON"
	return "UI_UNLOCK_ITEM"


## Hover text of an unlock card: the character's rule, the weapon or item effect.
static func unlock_tooltip(def: Resource) -> String:
	if def is CharacterData:
		return TranslationServer.translate(def.name_key) + "\n" + TranslationServer.translate(def.description_key)
	if def is WeaponData:
		return TranslationServer.translate(def.name_key) + "\n" + TranslationServer.translate(def.description_key)
	if def is ItemData:
		return ShopScreen.item_tooltip(def, 1)
	return ""


func close() -> void:
	visible = false
