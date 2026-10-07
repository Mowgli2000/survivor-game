class_name SpatialGrid
extends RefCounted
## Uniform grid over a fixed area, rebuilt from scratch every frame.
##
## Items are integer indices into the caller's own array (e.g. EnemyManager's
## active enemies). Rebuild is a counting sort into flat packed arrays, so it
## does not allocate once the arrays have grown to their working size.
## Positions outside the area are clamped into the border cells.

var cell_size: float
var origin: Vector2
var cols: int
var rows: int

var _positions := PackedVector2Array()
var _count: int = 0
var _cell_start := PackedInt32Array()  # size cols*rows + 1, prefix sums
var _cell_items := PackedInt32Array()  # item indices sorted by cell
var _item_cell := PackedInt32Array()
var _cursor := PackedInt32Array()


func _init(area: Rect2, cell_size_px: float) -> void:
	cell_size = cell_size_px
	origin = area.position
	cols = maxi(1, ceili(area.size.x / cell_size))
	rows = maxi(1, ceili(area.size.y / cell_size))
	_cell_start.resize(cols * rows + 1)
	_cursor.resize(cols * rows)


func rebuild(positions: PackedVector2Array, count: int) -> void:
	_positions = positions
	_count = count
	_cell_start.fill(0)
	if _item_cell.size() < count:
		_item_cell.resize(count)
		_cell_items.resize(count)
	for i in count:
		var c := _cell_of(positions[i])
		_item_cell[i] = c
		_cell_start[c + 1] += 1
	for c in range(1, _cell_start.size()):
		_cell_start[c] += _cell_start[c - 1]
	for c in _cursor.size():
		_cursor[c] = _cell_start[c]
	for i in count:
		var c := _item_cell[i]
		_cell_items[_cursor[c]] = i
		_cursor[c] += 1


func size() -> int:
	return _count


## Fills `out` with every item whose position is within `radius` of `center`.
## Returns the number of results.
## Hot path (one call per projectile per tick): the cell bounds are computed inline,
## a GDScript call each (_col_of / _row_of) cost a third of the query (profiled).
func query_radius(center: Vector2, radius: float, out: Array[int]) -> int:
	out.clear()
	var r2 := radius * radius
	var last_col := cols - 1
	var last_row := rows - 1
	var min_x := clampi(floori((center.x - radius - origin.x) / cell_size), 0, last_col)
	var max_x := clampi(floori((center.x + radius - origin.x) / cell_size), 0, last_col)
	var min_y := clampi(floori((center.y - radius - origin.y) / cell_size), 0, last_row)
	var max_y := clampi(floori((center.y + radius - origin.y) / cell_size), 0, last_row)
	for cy in range(min_y, max_y + 1):
		var row_start := cy * cols
		for cx in range(min_x, max_x + 1):
			var c := row_start + cx
			var end := _cell_start[c + 1]
			for k in range(_cell_start[c], end):
				var item := _cell_items[k]
				if _positions[item].distance_squared_to(center) <= r2:
					out.append(item)
	return out.size()


## Fills `out` with every item whose position is within `radius` of the segment [a, b].
## Returns the number of results.
func query_segment(a: Vector2, b: Vector2, radius: float, out: Array[int]) -> int:
	out.clear()
	var r2 := radius * radius
	var min_x := _col_of(minf(a.x, b.x) - radius)
	var max_x := _col_of(maxf(a.x, b.x) + radius)
	var min_y := _row_of(minf(a.y, b.y) - radius)
	var max_y := _row_of(maxf(a.y, b.y) + radius)
	for cy in range(min_y, max_y + 1):
		for cx in range(min_x, max_x + 1):
			var c := cy * cols + cx
			for k in range(_cell_start[c], _cell_start[c + 1]):
				var item := _cell_items[k]
				var p := _positions[item]
				if p.distance_squared_to(Geometry2D.get_closest_point_to_segment(p, a, b)) <= r2:
					out.append(item)
	return out.size()


## Index of the closest item within `max_radius`, or -1. Searches rings of cells
## outward and stops as soon as no closer item can exist.
func nearest(center: Vector2, max_radius: float) -> int:
	if _count == 0:
		return -1
	var best := -1
	var best_d2 := max_radius * max_radius
	var cx0 := _col_of(center.x)
	var cy0 := _row_of(center.y)
	var max_ring := ceili(max_radius / cell_size) + 1
	for ring in range(0, max_ring + 1):
		if best >= 0:
			var ring_min_dist := (ring - 1) * cell_size
			if ring_min_dist > 0.0 and ring_min_dist * ring_min_dist > best_d2:
				break
		for cy in range(cy0 - ring, cy0 + ring + 1):
			if cy < 0 or cy >= rows:
				continue
			var on_edge_row := cy == cy0 - ring or cy == cy0 + ring
			var step := 1 if on_edge_row else ring * 2
			var cx := cx0 - ring
			while cx <= cx0 + ring:
				if cx >= 0 and cx < cols:
					var c := cy * cols + cx
					for k in range(_cell_start[c], _cell_start[c + 1]):
						var item := _cell_items[k]
						var d2 := _positions[item].distance_squared_to(center)
						if d2 <= best_d2:
							best_d2 = d2
							best = item
				if step == 0:
					break
				cx += step
	return best


func _cell_of(pos: Vector2) -> int:
	return _row_of(pos.y) * cols + _col_of(pos.x)


func _col_of(x: float) -> int:
	return clampi(floori((x - origin.x) / cell_size), 0, cols - 1)


func _row_of(y: float) -> int:
	return clampi(floori((y - origin.y) / cell_size), 0, rows - 1)
