class_name WeaponLayout
## Where weapons sit around their owner (Brotato-style fixed mounts on a circle,
## first one on the right). Shared by WeaponHolder (attack origins) and
## WeaponVisuals (drawing).

## Distance from the owner's center to a weapon mount.
const MOUNT_RADIUS := 34.0
## Distance from a mount to the weapon's muzzle (where shots start).
const BARREL := 22.0


static func mount_offset(index: int, count: int) -> Vector2:
	return Vector2.from_angle(TAU * index / maxi(count, 1)) * MOUNT_RADIUS
