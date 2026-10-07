class_name WeaponLayout
## Where weapons sit around their owner (Brotato-style fixed mounts on a circle,
## first one on the right). Shared by WeaponHolder (attack origins) and
## WeaponVisuals (drawing).

## Center of the mount circle relative to the owner's origin (its feet area):
## around the chest of the character sprite.
## Raised from the chest (-36) so weapons above the hero clear his head (playtest).
const BODY_CENTER := Vector2(0.0, -54.0)
## Distance from the circle center to a weapon mount.
const MOUNT_RADIUS := 84.0
## Distance from a mount to the weapon's muzzle (where shots start).
const BARREL := 28.0


static func mount_offset(index: int, count: int) -> Vector2:
	return BODY_CENTER + Vector2.from_angle(TAU * index / maxi(count, 1)) * MOUNT_RADIUS
