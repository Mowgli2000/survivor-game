extends Control
## Boss test arena (debug): fight any boss or mini-boss right away, without playing the waves
## before it. Open res://src/debug/boss_arena.tscn in the Godot editor and press F6.
## The fight is a real run on the boss wave of the chosen seal (its biome, its HP and damage
## curves, its boss pace), played with your keyboard / gamepad. Nothing is saved to the profile.
## F10 during the fight: back to this selector (it also comes back by itself a few seconds after the chest is opened).

const RUN_SCENE := preload("res://src/run/run.tscn")

## [boss id, seal index, wave]: final bosses (wave 20) then mini-bosses (wave 10).
const FIGHTS: Array = [
	[&"shogun", 0, 20], [&"iron_boss_final", 1, 20], [&"silver_boss_final", 2, 20],
	[&"gold_boss_final", 3, 20], [&"obsidian_boss_final", 4, 20], [&"astral_boss_final", 5, 20],
	[&"ronin", 0, 10], [&"iron_boss_mini", 1, 10], [&"silver_boss_mini", 2, 10],
	[&"gold_boss_mini", 3, 10], [&"obsidian_boss_mini", 4, 10], [&"astral_boss_mini", 5, 10]]
const PHASES: Array = [["Phase 1 (PV pleins)", 1.0], ["Phase 2 (60 % des PV)", 0.55], ["Phase 3 (25 % des PV)", 0.25]]
const BUILDS: Array = ["Départ (armes du personnage)", "Moyen (6 armes rang III)", "Fort (6 armes rang IV + 25 objets)"]
const BUILD_WEAPONS: Array[StringName] = [&"spear", &"scythe", &"longbow", &"shadow_blades", &"runic_blade", &"lightning_staff"]
const RETURN_DELAY := 3.0

var _boss: OptionButton
var _phase: OptionButton
var _build: OptionButton
var _character: OptionButton
var _invincible: CheckBox
var _panel: Control
var _column: VBoxContainer
var _run: Run
var _hp_ratio := 1.0
var _characters: Array = []


func _ready() -> void:
	theme = UiTheme.get_theme()
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.05, 0.06, 0.12)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	_panel = CenterContainer.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_panel)
	_panel.visibility_changed.connect(func() -> void: backdrop.visible = _panel.visible)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	_panel.add_child(column)
	var title := Label.new()
	title.text = "Arène de test des boss"
	title.theme_type_variation = &"TitleLabel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	_column = column
	_boss = _picker("Boss", FIGHTS.map(_fight_label))
	_phase = _picker("Départ du combat", PHASES.map(func(p: Array) -> String: return p[0]))
	_build = _picker("Build du joueur", BUILDS)
	_build.select(1)
	_characters = ContentDB.get_all(&"characters")
	_character = _picker("Personnage", _characters.map(func(c: CharacterData) -> String: return tr(c.name_key)))
	_invincible = CheckBox.new()
	_invincible.text = "Joueur invincible (pour voir les attaques)"
	column.add_child(_invincible)
	var start := Button.new()
	start.text = "Combattre"
	start.theme_type_variation = &"BigButton"
	start.pressed.connect(_start_fight)
	column.add_child(start)
	var hint := Label.new()
	hint.text = "F10 pendant le combat : retour ici. Rien n'est enregistré dans ta progression."
	hint.theme_type_variation = &"SmallLabel"
	column.add_child(hint)
	start.grab_focus()


func _input(event: InputEvent) -> void:
	if _run != null and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F10:
		_back_to_selector()


func _fight_label(fight: Array) -> String:
	var def: EnemyData = ContentDB.get_def(&"enemies", fight[0])
	return "Danger %d — %s (vague %d)" % [fight[1] + 1, tr(def.name_key), fight[2]]


func _picker(label_text: String, items: Array) -> OptionButton:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 260.0
	row.add_child(label)
	var picker := OptionButton.new()
	picker.custom_minimum_size.x = 520.0
	for item in items:
		picker.add_item(str(item))
	row.add_child(picker)
	_column.add_child(row)
	return picker


func _start_fight() -> void:
	var fight: Array = FIGHTS[_boss.selected]
	_hp_ratio = PHASES[_phase.selected][1]
	_run = RUN_SCENE.instantiate()
	_run.setup = RunSetup.new()
	_run.setup.difficulty = ContentDB.get_def(&"difficulties", StringName("danger_%d" % fight[1]))
	_run.setup.character = _characters[_character.selected]
	_run.record_profile = false
	_run.unlock_all = true
	_run.first_wave = fight[2]
	_run.player_invincible = _invincible.button_pressed
	_run.auto_choose_upgrades = true
	_panel.visible = false
	add_child(_run)
	_run.enemies.boss_spawned.connect(_on_boss_spawned)
	_run.waves.wave_ended.connect(_on_wave_ended)
	_give_build(_build.selected)


## Weapons and items of the chosen build on top of the character's starting ones.
func _give_build(kind: int) -> void:
	if kind == 0:
		return
	for id in BUILD_WEAPONS:
		var def: WeaponData = ContentDB.get_def(&"weapons", id)
		if def != null and not _run.player.weapons.is_full():
			_run.player.weapons.add_weapon(def, 3 if kind == 1 else def.max_level())
	if kind == 2:
		var added := 0
		for def in ContentDB.get_all(&"items"):
			if added >= 25:
				break
			if _run.inventory.can_add(def as ItemData):
				_run.inventory.add(def as ItemData)
				added += 1


func _on_boss_spawned(enemy: Enemy) -> void:
	if _hp_ratio < 1.0 and not enemy.data.phases.is_empty():
		enemy.hp = enemy.max_hp * _hp_ratio


## The wave ends once the boss is dead, its death animation played and its chest opened.
func _on_wave_ended(_wave: int) -> void:
	get_tree().create_timer(RETURN_DELAY, true).timeout.connect(_back_to_selector)


func _back_to_selector() -> void:
	if _run == null:
		return
	get_tree().paused = false
	_run.queue_free()
	_run = null
	_panel.visible = true
