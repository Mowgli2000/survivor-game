class_name SpriteSheet
extends Resource
## Horizontal strip of animation frames inside the shared sprite atlas, generated
## by tools/sprites/bake_sprites.gd. Each animation is a run of consecutive cells.
## Pure data + one draw helper. Every sheet shares one atlas texture, so enemies
## of different types never switch textures while rendering.

## Used when an animation is missing (every sheet has at least "walk").
const FALLBACK := &"walk"

@export var texture: Texture2D
## Top-left corner of this strip in the atlas texture.
@export var origin := Vector2i.ZERO
@export var cell_size := Vector2i(1, 1)
## Animation name -> Vector3i(first cell, frame count, frames per second).
@export var animations: Dictionary[StringName, Vector3i] = {}


func has_animation(anim: StringName) -> bool:
	return animations.has(anim)


## Absolute cell index of `anim` after `time` seconds (looping).
func frame_at(anim: StringName, time: float) -> int:
	var info: Vector3i = animations.get(anim, animations.get(FALLBACK, Vector3i(0, 1, 1)))
	var count := maxi(info.y, 1)
	return info.x + posmod(int(floor(time * info.z)), count)


func region(frame: int) -> Rect2:
	return Rect2(origin.x + frame * cell_size.x, origin.y, cell_size.x, cell_size.y)


## Draws `frame` scaled to `height` px, feet at `foot_y`, mirrored when facing < 0.
func draw(canvas: CanvasItem, frame: int, height: float, foot_y: float, facing: float, tint: Color) -> void:
	canvas.draw_texture_rect_region(texture, draw_rect(height, foot_y, facing), region(frame), tint)


## Local rect of a frame, centered on x. Mirroring uses a negative width (Godot
## flips the texture but keeps position.x), not draw_set_transform: extra
## transform commands per enemy would cost more.
func draw_rect(height: float, foot_y: float, facing: float) -> Rect2:
	var width := height * cell_size.x / float(cell_size.y)
	return Rect2(-width * 0.5, foot_y - height, width * signf(facing), height)
