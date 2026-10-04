extends GutTest

const DT := 1.0 / 60.0
const SPEED := 300.0


func _run(motion: PlayerMotion, seconds: float, velocity: Vector2) -> void:
	var position := Vector2.ZERO
	for i in int(seconds / DT):
		position += velocity * DT
		motion.update(DT, position, velocity, SPEED)


func test_leans_toward_movement_then_back() -> void:
	var motion := PlayerMotion.new()
	_run(motion, 1.0, Vector2(SPEED, 0.0))
	assert_almost_eq(motion.lean, PlayerMotion.MAX_LEAN, 0.01, "settles at the max lean")
	_run(motion, 1.5, Vector2.ZERO)
	assert_almost_eq(motion.lean, 0.0, 0.01, "straightens up when stopped")


func test_turns_instantly() -> void:
	var motion := PlayerMotion.new()
	motion.update(DT, Vector2.ZERO, Vector2(-SPEED, 0.0), SPEED)
	assert_eq(motion.facing, -1.0)
	assert_lt(motion.body_scale().x, 0.0, "mirrored body")


func test_hurt_flashes_and_squashes_then_recovers() -> void:
	var motion := PlayerMotion.new()
	motion.hurt()
	motion.update(DT, Vector2.ZERO, Vector2.ZERO, SPEED)
	assert_gt(motion.flash, 0.5)
	assert_lt(motion.body_scale().y, 1.0)
	_run(motion, PlayerMotion.HURT_TIME + 0.05, Vector2.ZERO)
	assert_eq(motion.flash, 0.0)
	assert_eq(motion.body_scale(), Vector2.ONE)


func test_dust_puffs_expire() -> void:
	var motion := PlayerMotion.new()
	_run(motion, 1.0, Vector2(SPEED, 0.0))
	assert_between(motion.dust_positions.size(), 1, PlayerMotion.MAX_DUST)
	_run(motion, PlayerMotion.DUST_LIFE + 0.05, Vector2.ZERO)
	assert_eq(motion.dust_positions.size(), 0)
