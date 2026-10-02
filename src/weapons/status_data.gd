class_name StatusData
extends Resource
## A status effect applied by a weapon hit.
##  BURN:  damage over time = power x hit damage per second, for `duration`.
##  SLOW:  movement reduced by `power` (0.4 = -40 %), for `duration`.
##  SHOCK: lightning jumps to `chain_count` nearby enemies (within `chain_range`),
##         each taking power x hit damage.

enum Type { BURN, SLOW, SHOCK }

@export var type: Type = Type.BURN
@export var power: float = 0.3
@export var duration: float = 2.0
@export var chain_count: int = 3
@export var chain_range: float = 200.0
