extends Node
## Global audio service (autoload "Audio"): one music player and a pool of
## sound effect players on the Music / SFX buses (default_bus_layout.tres).
## Anti-saturation: a sound is skipped when the same stream played less than
## MIN_INTERVAL_MS ago or already has MAX_VOICES players running (a horde can
## die in one frame). No game logic here: systems call play() with a stream.

const POOL_SIZE := 32
const MIN_INTERVAL_MS := 35
const MAX_VOICES := 4
const UI_HOVER_DB := -16.0
const UI_CLICK_DB := -9.0
const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"

var _players: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
## stream -> Time.get_ticks_msec() of its last play
var _last_played: Dictionary[AudioStream, int] = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # UI sounds and music during pauses
	_music = AudioStreamPlayer.new()
	_music.bus = MUSIC_BUS
	add_child(_music)
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = SFX_BUS
		add_child(player)
		_players.append(player)
	# Every button of every screen gets its hover / click sounds here, once.
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	var button := node as BaseButton
	if button == null or button.has_meta(&"ui_sounds"):
		return
	button.set_meta(&"ui_sounds", true)
	button.mouse_entered.connect(_on_button_hovered.bind(button))
	button.focus_entered.connect(_on_button_hovered.bind(button))
	button.pressed.connect(func() -> void: play(Sounds.UI_CLICK, UI_CLICK_DB, 0.03))


func _on_button_hovered(button: BaseButton) -> void:
	if not button.disabled and button.is_visible_in_tree():
		play(Sounds.UI_HOVER, UI_HOVER_DB, 0.05)


## Plays `stream` unless throttled. Returns true when a player was used.
func play(stream: AudioStream, volume_db: float = 0.0, pitch_variation: float = 0.06, pitch: float = 1.0) -> bool:
	if stream == null:
		return false
	var now := Time.get_ticks_msec()
	if now - _last_played.get(stream, -MIN_INTERVAL_MS) < MIN_INTERVAL_MS:
		return false
	if voices(stream) >= MAX_VOICES:
		return false
	var player := _free_player()
	if player == null:
		return false
	_last_played[stream] = now
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch + randf_range(-pitch_variation, pitch_variation)
	player.play()
	return true


## Number of players currently playing `stream`.
func voices(stream: AudioStream) -> int:
	var count := 0
	for player in _players:
		if player.playing and player.stream == stream:
			count += 1
	return count


## Loops `stream` on the music bus (does nothing if it is already playing).
func play_music(stream: AudioStream, volume_db: float = 0.0) -> void:
	if _music.stream == stream and _music.playing:
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	_music.stream = stream
	_music.volume_db = volume_db
	_music.play()


func stop_music() -> void:
	_music.stop()


func stop_all() -> void:
	stop_music()
	for player in _players:
		player.stop()
	_last_played.clear()


## Tests: lets `stream` play again without waiting MIN_INTERVAL_MS.
func forget_last_play(stream: AudioStream) -> void:
	_last_played.erase(stream)


func _exit_tree() -> void:
	stop_all()
	for player in _players:
		player.stream = null
	_music.stream = null


func _free_player() -> AudioStreamPlayer:
	for player in _players:
		if not player.playing:
			return player
	return null
