class_name RigData
extends Resource
## A character puppet (ADR 0020): body pieces cut from one illustration, packed
## in one texture, each turning around its joint. Made by tools/art/make_rig.gd
## from tools/art/rigs/<id>.json; drawn and animated by CharacterRig.
## Arrays are parallel, one entry per piece, in drawing order (back first).

@export var texture: Texture2D
@export var names: PackedStringArray = []
## Piece the joint is attached to ("" = the body root, at the feet).
@export var parents: PackedStringArray = []
## Piece in `texture`, in pixels.
@export var regions: Array[Rect2] = []
## Joint inside the piece, in pixels from the region's top-left corner.
@export var pivots: PackedVector2Array = PackedVector2Array()
## Joint on the assembled body at rest, in pixels from the feet (y up is negative).
@export var joints: PackedVector2Array = PackedVector2Array()
## Body height at rest, in texture pixels (feet to top of the head).
@export var height: float = 1.0


func index_of(piece: StringName) -> int:
	return names.find(String(piece))
