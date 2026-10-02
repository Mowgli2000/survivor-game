class_name SpriteAnimator
extends RefCounted
## Playback state of a SpriteSheet: current animation, time, frame and facing.
## advance() tells the owner when it must redraw (frame or facing changed).

## Ignore tiny horizontal movements so sprites do not flicker left/right.
const FACING_DEADZONE := 0.5

var sheet: SpriteSheet
var animation: StringName = SpriteSheet.FALLBACK
var time: float = 0.0
var frame: int = 0
## 1.0 = facing right (art default), -1.0 = mirrored.
var facing: float = 1.0


func reset(p_sheet: SpriteSheet, start_time: float) -> void:
	sheet = p_sheet
	animation = SpriteSheet.FALLBACK
	time = start_time
	facing = 1.0
	frame = sheet.frame_at(animation, time) if sheet != null else 0


func advance(delta: float, p_animation: StringName, facing_x: float) -> bool:
	if sheet == null:
		return false
	var changed := false
	if p_animation != animation and sheet.has_animation(p_animation):
		animation = p_animation
	time += delta
	var f := sheet.frame_at(animation, time)
	if f != frame:
		frame = f
		changed = true
	if absf(facing_x) > FACING_DEADZONE:
		var side := signf(facing_x)
		if side != facing:
			facing = side
			changed = true
	return changed
