class_name BossCorpse
extends Node2D
## A dying boss: its "death" animation plays where it fell (the enemy itself is gone: rewards and the
## end of the fight do not wait for it), then the last pose fades out and the node frees itself.

const FADE_TIME := 0.8

var _sheet: SpriteSheet
var _first: int = 0
var _frames: int = 1
var _fps: float = 12.0
var _height: float = 100.0
var _foot: float = 0.0
var _facing: float = 1.0
var _tint := Color.WHITE
var _time: float = 0.0
var _shown: int = -1


## `enemy` is the boss that just died (its data, size, position and facing are copied).
static func create(enemy: Enemy) -> BossCorpse:
	var corpse := BossCorpse.new()
	var sheet := enemy.data.attack_sheet
	var info: Vector3i = sheet.animations[&"death"]
	corpse._sheet = sheet
	corpse._first = info.x
	corpse._frames = maxi(info.y, 1)
	corpse._fps = maxf(info.z, 1.0)
	corpse._height = enemy.sprite_height() * enemy.data.attack_scale
	corpse._foot = enemy.foot_offset()
	corpse._facing = enemy.animator.facing
	corpse._tint = enemy.data.sprite_tint
	corpse.position = enemy.position
	corpse.z_index = 1
	return corpse


## Seconds the animation itself lasts (without the fade).
static func duration_of(data: EnemyData) -> float:
	if data.attack_sheet == null or not data.attack_sheet.has_animation(&"death"):
		return 0.0
	var info: Vector3i = data.attack_sheet.animations[&"death"]
	return info.y / float(maxi(info.z, 1))


func _process(delta: float) -> void:
	_time += delta / maxf(Engine.time_scale, 0.05)  # real time, even in the death slow-motion
	var length := _frames / _fps
	if _time >= length + FADE_TIME:
		queue_free()
		return
	var frame := mini(int(_time * _fps), _frames - 1)
	if frame != _shown or _time > length:
		_shown = frame
		queue_redraw()


func _draw() -> void:
	if _sheet == null:
		return
	var length := _frames / _fps
	var fade := 1.0 if _time <= length else clampf(1.0 - (_time - length) / FADE_TIME, 0.0, 1.0)
	var tint := Color(_tint, _tint.a * fade)
	_sheet.draw(self, _first + mini(int(_time * _fps), _frames - 1), _height, _foot, _facing, tint)
