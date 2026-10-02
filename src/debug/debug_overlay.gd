class_name DebugOverlay
extends CanvasLayer
## FPS, frame times and entity counts. Toggle with the `debug_toggle` action (F3).
## Visible by default in debug builds only.

const REFRESH_INTERVAL := 0.25

var _label: Label
var _enemies: EnemyManager
var _projectiles: ProjectileManager
var _pickups: PickupManager
var _enemy_projectiles: EnemyProjectileManager
var _vfx: Vfx
var _state: RunState
var _stage: StageData
var _waves: WaveDirector
var _timer: float = 0.0


func setup(enemies: EnemyManager, projectiles: ProjectileManager, pickups: PickupManager,
		enemy_projectiles: EnemyProjectileManager, vfx: Vfx) -> void:
	_enemies = enemies
	_projectiles = projectiles
	_pickups = pickups
	_enemy_projectiles = enemy_projectiles
	_vfx = vfx


## Optional: adds the current wave line (kills / spawns, spawn rate, HP multiplier).
func setup_waves(state: RunState, stage: StageData, waves: WaveDirector) -> void:
	_state = state
	_stage = stage
	_waves = waves


func _init() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = OS.is_debug_build()
	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_label.offset_top = 28
	_label.offset_right = -24
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label.add_theme_font_size_override("font_size", 20)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 5)
	add_child(_label)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle"):
		visible = not visible


func _process(delta: float) -> void:
	_timer -= delta
	if not visible or _timer > 0.0 or _enemies == null:
		return
	_timer = REFRESH_INTERVAL
	_label.text = "FPS %d\nprocess %.2f ms | physics %.2f ms\nenemies %d | projectiles %d | gems %d\nenemy shots %d | vfx %d" % [
		Engine.get_frames_per_second(),
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		_enemies.active_count(), _projectiles.active_count(), _pickups.active_count(),
		_enemy_projectiles.active_count(), _vfx.active_count(),
	]
	if _state != null and _waves.wave > 0:
		var spawned := maxi(_state.wave_spawned, 1)
		_label.text += "\nwave %d: killed %d / %d (%d%%)\nspawn %.1f/s | hp x%.2f" % [
			_waves.wave, _state.wave_kills, _state.wave_spawned,
			roundi(100.0 * _state.wave_kills / spawned),
			_stage.spawn_rate_at(_waves.wave), _stage.hp_multiplier_at(_waves.wave),
		]
