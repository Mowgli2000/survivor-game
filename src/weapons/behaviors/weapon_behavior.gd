@abstract
class_name WeaponBehavior
extends Resource
## How a weapon fires. Subclasses are stateless: per-weapon state lives in
## WeaponHolder, tuning values in WeaponData.


## Fires once. Returns false if nothing was fired (e.g. no target in range),
## in which case the weapon stays ready and tries again next frame.
@abstract func fire(weapon: WeaponData, ctx: WeaponContext) -> bool
