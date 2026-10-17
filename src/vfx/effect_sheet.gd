class_name EffectSheet
extends Resource
## A painted effect animation: a grid of equal square frames in one texture, played once over
## `duration` seconds by Vfx (additive blending: the art sits on black). The effect is centered
## on the frame center, pointing right (+x) before it is rotated.

@export var texture: Texture2D
@export var columns: int = 3
@export var rows: int = 2
@export var frames: int = 6
@export var duration: float = 0.3
## Side of a frame relative to the size Vfx is asked for (a slash's radius, a blast's radius).
@export var scale: float = 2.0
## Shift of the frame center along the effect's direction, as a share of the size (a hammer smash
## lands in front of the wielder, not on him).
@export var forward: float = 0.0
## How far the art reaches from the frame center, as a share of half a frame (measured by
## tools/art/bake_vfx.py): Vfx.sheet_at uses it to draw the art exactly as big as a damage shape.
@export var reach: float = 0.7
## Height of a plain sheet relative to its width (> 1 stretches an oval painted in perspective back to a round shape).
@export var squash: float = 1.0
## Where the head of a falling object sits in its frame, as a share of the frame side from the center
## (Vfx.sheet_fall lands that spot on the impact point).
@export var head: Vector2 = Vector2.ZERO
## Direction the painted object travels in its frame, radians (a meteor drawn falling toward the lower right = 0.64):
## Vfx.sheet_fall turns the frame so it travels along the direction it is asked for.
@export var art_angle: float = 0.0
## Overall opacity of the painting (a thick ground effect, like the frost patch, is toned down).
@export var opacity: float = 1.0
## An enemy attack: drawn whole, never faded around the hero (the fade is for the hero's own swings), so a hit reads as a hit.
@export var hostile: bool = false


func cell_size() -> Vector2:
	if texture == null:
		return Vector2.ONE
	return Vector2(texture.get_width() / float(maxi(columns, 1)), texture.get_height() / float(maxi(rows, 1)))


## Source rectangle of frame `index` (row by row, left to right).
func frame_region(index: int) -> Rect2:
	var cell := cell_size()
	var i := clampi(index, 0, maxi(frames, 1) - 1)
	return Rect2(Vector2(i % maxi(columns, 1), i / maxi(columns, 1)) * cell, cell)


## Frame shown at `progress` (0 = start, 1 = end of the effect).
func frame_at(progress: float) -> int:
	return clampi(int(progress * frames), 0, maxi(frames, 1) - 1)


## Scale `size` that makes the art of this sheet span `half_extent` px from its center.
func size_for(half_extent: float) -> float:
	return 2.0 * half_extent / (maxf(reach, 0.05) * maxf(scale, 0.01))
