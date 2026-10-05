extends GutTest
## Character puppet (ADR 0020): built from RigData, posed by code.

var _rig_data: RigData


func before_each() -> void:
	_rig_data = load("res://assets/rigs/ronin.tres")


func _rig() -> CharacterRig:
	var rig := CharacterRig.new()
	rig.setup(_rig_data)
	add_child_autofree(rig)
	return rig


func test_epeiste_puppet_has_every_piece() -> void:
	for piece in ["head", "ponytail", "torso", "skirt", "arm_front", "arm_back", "hand_front", "hand_back",
			"leg_front", "leg_back", "shin_front", "shin_back"]:
		assert_gt(_rig_data.index_of(StringName(piece)), -1, piece)
	assert_eq(_rig().get_child_count(), _rig_data.names.size(), "one sprite per piece")


func test_every_parent_exists() -> void:
	for parent in _rig_data.parents:
		assert_true(parent == "" or _rig_data.names.has(parent), parent)


func test_walking_swings_the_limbs_and_standing_still_does_not() -> void:
	var rig := _rig()
	for i in 20:
		rig.animate(1.0 / 60.0, 0.0, 0.0)
	assert_almost_eq(rig.angle_of(&"leg_front"), 0.0, 0.001, "idle")
	for i in 20:
		rig.animate(1.0 / 60.0, 1.0, 0.0)
	assert_ne(rig.angle_of(&"arm_front"), 0.0, "walking")


func test_hand_follows_its_arm() -> void:
	var rig := _rig()
	var hand := rig.get_child(_rig_data.index_of(&"hand_front")) as Sprite2D
	var rest := hand.position
	for i in 20:
		rig.animate(1.0 / 60.0, 1.0, 0.0)
	assert_ne(hand.position, rest, "carried by the swinging arm")


func test_death_lays_the_body_down_and_revive_stands_it_up() -> void:
	var rig := _rig()
	rig.die()
	for i in 60:
		rig.animate(1.0 / 60.0, 0.0, 0.0)
	var torso := rig.get_child(_rig_data.index_of(&"torso")) as Sprite2D
	assert_almost_eq(absf(torso.rotation), PI * 0.5, 0.05, "lying flat")
	rig.revive()
	rig.animate(1.0 / 60.0, 0.0, 0.0)
	assert_almost_eq(torso.rotation, 0.0, 0.1)


func test_player_uses_the_puppet_instead_of_the_sprite() -> void:
	var with_rig := (ContentDB.get_def(&"characters", &"ronin") as CharacterData).duplicate() as CharacterData
	with_rig.rig = _rig_data
	var player := Player.new()
	player.setup(with_rig, Rect2(-500, -500, 1000, 1000))
	add_child_autofree(player)
	assert_not_null(player.rig)
	var drifter := Player.new()
	drifter.setup(ContentDB.get_def(&"characters", &"drifter"), Rect2(-500, -500, 1000, 1000))
	add_child_autofree(drifter)
	assert_null(drifter.rig, "characters without a puppet keep their baked sprite")
