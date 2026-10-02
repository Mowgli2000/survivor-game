@abstract
class_name WeaponBehavior
extends Resource
## How a weapon attacks. Subclasses are stateless: per-weapon state lives in
## WeaponSlot, tuning values in WeaponData / WeaponStats.


## Attacks once. Returns false if nothing happened (e.g. no target in range),
## in which case the weapon stays ready and tries again next frame.
@abstract func fire(slot: WeaponSlot, ctx: WeaponContext) -> bool
