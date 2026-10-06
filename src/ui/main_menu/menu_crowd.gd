class_name MenuCrowd
extends Node2D
## Main menu decoration: the monsters standing around the gate, a fixed layout
## (dev's choice "C2": a still picture, only the gate moves). One node draws
## them all, far to near; no EnemyManager (nothing to fight).
## `y_from` / `y_to` select the monsters to draw (world y of their feet): two
## instances let the demon knight stand between the far and the near ones.

## [enemy id, feet position (world), cell height, facing]. World = screen - (960, 540).
const SPOTS: Array = [
	[&"runner", Vector2(170, 100), 120.0, 1.0],
	[&"grunt", Vector2(70, 160), 150.0, 1.0],
	[&"kamikaze", Vector2(770, 110), 130.0, -1.0],
	[&"charger", Vector2(870, 180), 180.0, -1.0],
	[&"shooter", Vector2(50, 310), 200.0, 1.0],
	[&"tank", Vector2(880, 360), 260.0, -1.0],
	[&"runner", Vector2(170, 450), 190.0, 1.0],
	[&"grunt", Vector2(720, 500), 230.0, -1.0],
]
## Ground shadow margin under the feet inside a baked frame (share of its height).
const FOOT_MARGIN := 0.04

var y_from: float = -INF
var y_to: float = INF
var _drawn: Array[Dictionary] = []


func setup(enemies: Array[EnemyData]) -> void:
	var by_id: Dictionary = {}
	for data in enemies:
		by_id[data.id] = data
	for spot in SPOTS:
		var data: EnemyData = by_id.get(spot[0])
		var feet: Vector2 = spot[1]
		if data == null or data.get_sheet(false) == null or feet.y < y_from or feet.y >= y_to:
			continue
		_drawn.append({"sheet": data.get_sheet(false), "tint": data.sprite_tint, "feet": feet,
			"height": spot[2], "facing": spot[3]})
	_drawn.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.feet.y < b.feet.y)
	queue_redraw()


func count() -> int:
	return _drawn.size()


func _draw() -> void:
	for item in _drawn:
		var sheet: SpriteSheet = item.sheet
		draw_set_transform(item.feet)
		sheet.draw(self, sheet.frame_at(&"idle", 0.0), item.height, item.height * FOOT_MARGIN,
			item.facing, item.tint)
	draw_set_transform(Vector2.ZERO)
