extends GutTest
## Melee swings and beams follow their owner while they last (the hero keeps walking).


func _vfx() -> Vfx:
	var vfx := Vfx.new()
	add_child_autofree(vfx)
	return vfx


func test_a_slash_moves_with_its_owner() -> void:
	var owner_node := Node2D.new()
	add_child_autofree(owner_node)
	var vfx := _vfx()
	vfx.slash(Vector2.ZERO, 0.0, 100.0, 0.5, Color.WHITE, 0, owner_node)
	owner_node.global_position = Vector2(80.0, -30.0)
	vfx._process(0.016)
	assert_eq(vfx._a[0], Vector2(80.0, -30.0), "the swing is where the hero is now")
	assert_eq(vfx._b[0], Vector2.RIGHT, "its direction is unchanged")


func test_a_beam_moves_as_a_whole() -> void:
	var owner_node := Node2D.new()
	add_child_autofree(owner_node)
	var vfx := _vfx()
	vfx.beam(Vector2.ZERO, Vector2(300.0, 0.0), 10.0, Color.WHITE, owner_node)
	owner_node.global_position = Vector2(0.0, 50.0)
	vfx._process(0.016)
	assert_eq(vfx._a[0], Vector2(0.0, 50.0))
	assert_eq(vfx._b[0], Vector2(300.0, 50.0), "both ends move: the length stays")


func test_an_effect_without_owner_stays_in_place() -> void:
	var vfx := _vfx()
	vfx.slash(Vector2(10.0, 10.0), 0.0, 100.0, 0.5, Color.WHITE)
	vfx._process(0.016)
	assert_eq(vfx._a[0], Vector2(10.0, 10.0))


func test_a_freed_owner_does_not_break_the_effect() -> void:
	var owner_node := Node2D.new()
	add_child(owner_node)
	var vfx := _vfx()
	vfx.slash(Vector2.ZERO, 0.0, 100.0, 0.5, Color.WHITE, 0, owner_node)
	owner_node.free()
	vfx._process(0.016)
	assert_eq(vfx.active_count(), 1)
