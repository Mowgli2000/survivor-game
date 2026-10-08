class_name PickupManager
extends Node2D
## Owns the pickups: XP crystals and material coins. Magnet attraction toward the nearest
## living player and collection. Above `max_gems`, new pickups are merged into existing
## ones of the same kind to cap the entity count. Collecting makes a chime / a coin ting
## whose pitch climbs while pickups chain (an arpeggio, the "addictive" feedback).

## `collector`: player number, or SHARED for the end-of-wave sweep (split by Run).
signal xp_collected(amount: int, collector: int)
## Materials of the coins picked up (fractions kept).
signal material_collected(amount: float, collector: int)

const SHARED := -1
## How much of the owner's color a pickup takes in coop.
const OWNER_TINT_SHARE := 0.4

const ATTRACT_START_SPEED := 150.0
const ATTRACT_ACCELERATION := 1500.0
const CRYSTAL_SOUND := preload("res://assets/audio/sfx/pickup_crystal.wav")
const COIN_SOUND := preload("res://assets/audio/sfx/pickup_coin.wav")
## A pickup within this delay of the previous one continues the chain.
const CHAIN_WINDOW_MS := 320
const CHAIN_MAX := 14
## Pitch gained per link, in semitones (a major scale feel: 2 then 2 then 1...).
const SEMITONES: Array[int] = [0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17, 19, 21, 23, 24]

var _party: Party
var _max_gems: int = 300
var _active: Array[XpGem] = []
var _pool: ObjectPool
var _merge_cursor: int = 0
## Physics frame of the last pickup sound request.
var _sound_frame: int = -1
var _chain: int = 0
var _last_pickup_ms: int = -10000
var _drawn: bool = false


func setup(party: Party, max_gems: int) -> void:
	_party = party
	_max_gems = max_gems
	_pool = ObjectPool.new(_create_gem)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


func _ready() -> void:
	process_physics_priority = 20
	z_index = -1


## `owner_index`: the player who made the kill (coop), -1 for nobody's.
func spawn_xp(pos: Vector2, value: int, owner_index: int = -1) -> void:
	if _active.size() >= _max_gems:
		var target := _merge_target(false, owner_index)
		if target != null:
			target.add_value(value)
			return
	var gem: XpGem = _pool.acquire()
	gem.reset(pos, value, owner_index, _owner_tint(owner_index))
	_active.append(gem)


## A coin worth `amount` materials (Run converts the XP of a kill into materials).
func spawn_material(pos: Vector2, amount: float, owner_index: int = -1) -> void:
	if amount <= 0.0:
		return
	if _active.size() >= _max_gems:
		var target := _merge_target(true, owner_index)
		if target != null:
			target.add_coins(amount)
			return
	var gem: XpGem = _pool.acquire()
	gem.reset_material(pos, amount, owner_index, _owner_tint(owner_index))
	_active.append(gem)


## Coop only: a light mix of the owner's color (solo and unowned pickups stay as drawn).
func _owner_tint(owner_index: int) -> Color:
	if _party == null or _party.size() < 2 or owner_index < 0 or owner_index >= _party.size():
		return Color.WHITE
	return Color.WHITE.lerp(_party.members[owner_index].tag_color, OWNER_TINT_SHARE)


## Next pickup of the wanted kind and owner to merge into (round robin). Merging into
## someone else's pickup would move rewards between players: only when none is left
## (the cap matters more), and never in a coop run that still has an owned one.
func _merge_target(material: bool, owner_index: int = -1) -> XpGem:
	var fallback: XpGem = null
	for step in _active.size():
		_merge_cursor = (_merge_cursor + 1) % _active.size()
		var gem := _active[_merge_cursor]
		if gem.is_material != material:
			continue
		if gem.owner_index == owner_index:
			return gem
		if fallback == null:
			fallback = gem
	return fallback


## Collects every gem at once (end of wave): a single xp_collected with the total.
func collect_all() -> void:
	var total := 0
	var coins := 0.0
	for gem in _active:
		total += gem.value
		coins += gem.coins
		_pool.release(gem)
	_active.clear()
	queue_redraw()
	if total > 0:
		xp_collected.emit(total, SHARED)
	if coins > 0.0:
		material_collected.emit(coins, SHARED)


func active_count() -> int:
	return _active.size()


func _physics_process(delta: float) -> void:
	if _party == null:
		return
	for player in _party.members:
		if not player.is_dead:
			_update_for(player, delta)
	if not _active.is_empty() or _drawn:
		_drawn = not _active.is_empty()
		queue_redraw()


## One draw for every pickup: the textures batch into a few draw calls.
func _draw() -> void:
	for gem in _active:
		gem.draw(self)


## Gems in range of `player` fly to it; the ones it touches are its own.
## Coop: a gem already flying to the other player may be taken over (rare, harmless).
func _update_for(player: Player, delta: float) -> void:
	var player_pos := player.global_position
	var pickup_range := player.stats.get_value(StatIds.PICKUP_RANGE)
	var pickup_r2 := pickup_range * pickup_range
	var collect_dist := player.radius + XpGem.SIZE
	var collect_r2 := collect_dist * collect_dist
	var coop := _party.size() > 1
	for i in range(_active.size() - 1, -1, -1):
		var gem := _active[i]
		var d2 := gem.position.distance_squared_to(player_pos)
		if gem.attracted and coop and gem.target != player.index:
			if _party.members[gem.target].is_dead:
				gem.attracted = false  # its player died: free for the others
			elif d2 > collect_r2:
				continue  # flying to the other player: only taken when passing right by
		if not gem.attracted and d2 <= pickup_r2 and _pulls(gem, player, coop):
			gem.attracted = true
			gem.target = player.index
			gem.speed = ATTRACT_START_SPEED
		if gem.attracted and gem.target == player.index:
			gem.speed += ATTRACT_ACCELERATION * delta
			gem.position = gem.position.move_toward(player_pos, gem.speed * delta)
			d2 = gem.position.distance_squared_to(player_pos)
		if d2 <= collect_r2:
			var value := gem.value
			var coins := gem.coins
			var material := gem.is_material
			_active[i] = _active[_active.size() - 1]
			_active.pop_back()
			_pool.release(gem)
			if material:
				material_collected.emit(coins, player.index)
			else:
				xp_collected.emit(value, player.index)
			_play_pickup(material)


## Whether `player`'s magnet pulls `gem`. Solo: always. Coop: only its owner's (the one who
## made the kill), so a big pickup range cannot vacuum the other player's drops; an
## unowned pickup, or one whose owner died, goes to the nearest living player.
func _pulls(gem: XpGem, player: Player, coop: bool) -> bool:
	if not coop:
		return true
	if gem.owner_index >= 0 and gem.owner_index < _party.size() and not _party.members[gem.owner_index].is_dead:
		return gem.owner_index == player.index
	return _party.nearest_alive(gem.position) == player


## One sound per kind and physics frame; the pitch climbs one step per chained pickup.
func _play_pickup(material: bool) -> void:
	if Engine.get_physics_frames() == _sound_frame:
		return
	_sound_frame = Engine.get_physics_frames()
	var now := Time.get_ticks_msec()
	_chain = mini(_chain + 1, CHAIN_MAX) if now - _last_pickup_ms <= CHAIN_WINDOW_MS else 0
	_last_pickup_ms = now
	var pitch := pow(2.0, SEMITONES[_chain] / 12.0)
	Audio.play(COIN_SOUND if material else CRYSTAL_SOUND, -11.0 if material else -13.0, 0.0, pitch)


func _create_gem() -> XpGem:
	return XpGem.new()
