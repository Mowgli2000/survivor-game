class_name WeaponLayout
## Where weapons sit around their owner (Brotato-style fixed mounts on a circle,
## first one on the right). Shared by WeaponHolder (attack origins) and
## WeaponVisuals (drawing).

## Center of the mount circle relative to the owner's origin, which is the hips (the middle of
## the character since the hitbox was moved there, 2026-10-09): the weapons circle round the body,
## the ones above still clear the head (the sprite's top is ~53 px above the origin).
const BODY_CENTER := Vector2(0.0, -12.0)
## Distance from the circle center to a weapon mount.
const MOUNT_RADIUS := 84.0
## Distance from a mount to the weapon's muzzle (where shots start).
const BARREL := 28.0


static func mount_offset(index: int, count: int) -> Vector2:
	return BODY_CENTER + Vector2.from_angle(TAU * index / maxi(count, 1)) * MOUNT_RADIUS
