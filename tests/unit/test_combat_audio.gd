extends GutTest
## Combat sound cues: hits, crits, kill streaks, player hurt, warnings.

var _player: Player
var _enemies: EnemyManager


func before_each() -> void:
	Audio.stop_all()
	var arena := Rect2(-1000, -1000, 2000, 2000)
	_player = Player.new()
	_player.setup(CharacterData.new(), arena)
	_player.invincible = true
	add_child_autofree(_player)
	_enemies = EnemyManager.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	_enemies.setup(Party.solo(_player), arena, 4, rng)
	add_child_autofree(_enemies)


func after_each() -> void:
	Audio.stop_all()


func _tough_enemy(boss: bool = false) -> int:
	var data := EnemyData.new()
	data.boss = boss
	data.max_hp = 1000.0
	data.speed = 0.0
	data.radius = 16.0
	return _spawn_index(data)


func _spawn_index(data: EnemyData) -> int:
	_enemies.spawn(data, Vector2(300, 0))
	return _enemies.active_count() - 1


func _flesh_voices() -> int:
	var count := 0
	for stream in Sounds.KILL_THUD:
		count += Audio.voices(stream)
	return count


func test_a_normal_hit_is_silent() -> void:
	var index := _tough_enemy()
	_enemies.damage_enemy(index, 10.0, false, Vector2.RIGHT, 0.0)
	assert_eq(_flesh_voices(), 0)
	assert_eq(Audio.voices(Sounds.HIT_CRIT), 0)


func test_a_kill_makes_a_thud() -> void:
	var index := _tough_enemy()
	_enemies.damage_enemy(index, 2000.0, false, Vector2.RIGHT, 0.0)
	assert_eq(_flesh_voices(), 1)


func test_a_boss_hit_makes_a_thud() -> void:
	var index := _tough_enemy(true)
	_enemies.damage_enemy(index, 10.0, false, Vector2.RIGHT, 0.0)
	assert_eq(_flesh_voices(), 1)


func test_a_critical_hit_has_its_own_heavier_sound() -> void:
	var index := _tough_enemy()
	_enemies.damage_enemy(index, 10.0, true, Vector2.RIGHT, 0.0)
	assert_eq(Audio.voices(Sounds.HIT_CRIT), 1)
	assert_eq(_flesh_voices(), 0)


func test_a_horde_hit_in_one_frame_is_one_sound() -> void:
	var index := _tough_enemy(true)
	for i in 20:
		_enemies.damage_enemy(index, 5.0, false, Vector2.RIGHT, 0.0)
	assert_eq(_flesh_voices(), 1, "hit sounds are spaced out")


func test_every_combat_cue_exists() -> void:
	for stream: AudioStream in [Sounds.HIT_CRIT, Sounds.PLAYER_HIT_HEAVY, Sounds.HEARTBEAT,
			Sounds.WARNING, Sounds.BOSS_ALERT, Sounds.TICK, Sounds.FUSE, Sounds.ENEMY_SHOT]:
		assert_not_null(stream)
	assert_eq(Sounds.KILL_THUD.size(), 5, "five body thud variants")


func test_warnings_make_a_sound() -> void:
	var vfx := Vfx.new()
	add_child_autofree(vfx)
	vfx.warning_line(Vector2.ZERO, Vector2(100, 0), 20.0, Color.RED, 1.0)
	assert_eq(Audio.voices(Sounds.WARNING), 1)


func test_enemy_shots_make_a_sound() -> void:
	var shots := EnemyProjectileManager.new()
	shots.setup(Party.solo(_player), Rect2(-500, -500, 1000, 1000))
	add_child_autofree(shots)
	shots.spawn(Vector2.ZERO, Vector2.RIGHT * 100.0, 5.0, 8.0)
	assert_eq(Audio.voices(Sounds.ENEMY_SHOT), 1)


func test_hit_sounds_never_change_pitch_with_the_number_of_hits() -> void:
	var index := _tough_enemy(true)
	var pitches: Array[float] = []
	for i in 12:
		await wait_seconds((EnemyManager.HIT_SOUND_GAP_MS + 10) / 1000.0)
		_enemies.damage_enemy(index, 5.0, false, Vector2.RIGHT, 0.0)
		for player in Audio._players:
			if player.playing and Sounds.KILL_THUD.has(player.stream):
				pitches.append(player.pitch_scale)
		Audio.stop_all()
	assert_gt(pitches.size(), 6)
	for pitch in pitches:
		assert_almost_eq(pitch, 1.0, EnemyManager.HIT_PITCH_VARIATION + 0.001)


func test_the_same_variant_never_plays_twice_in_a_row() -> void:
	var index := _tough_enemy(true)
	var last: AudioStream = null
	for i in 20:
		await wait_seconds((EnemyManager.HIT_SOUND_GAP_MS + 10) / 1000.0)
		Audio.stop_all()
		_enemies.damage_enemy(index, 5.0, false, Vector2.RIGHT, 0.0)
		for stream in Sounds.KILL_THUD:
			if Audio.voices(stream) > 0:
				assert_ne(stream, last, "variant repeated")
				last = stream
