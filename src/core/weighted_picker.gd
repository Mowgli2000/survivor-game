class_name WeightedPicker
## Weighted random selection helpers.


## Returns an index chosen proportionally to `weights`, or -1 if all weights are <= 0.
static func pick_index(weights: PackedFloat32Array, rng: RandomNumberGenerator) -> int:
	var total := 0.0
	for w in weights:
		total += maxf(w, 0.0)
	if total <= 0.0:
		return -1
	var roll := rng.randf() * total
	for i in weights.size():
		var w := maxf(weights[i], 0.0)
		if roll < w:
			return i
		roll -= w
	# Float rounding: fall back to the last positive weight.
	for i in range(weights.size() - 1, -1, -1):
		if weights[i] > 0.0:
			return i
	return -1


## Picks up to `count` distinct indices, without replacement.
static func pick_distinct(weights: PackedFloat32Array, count: int, rng: RandomNumberGenerator) -> PackedInt32Array:
	var remaining := weights.duplicate()
	var result := PackedInt32Array()
	for i in count:
		var index := pick_index(remaining, rng)
		if index < 0:
			break
		result.append(index)
		remaining[index] = 0.0
	return result
