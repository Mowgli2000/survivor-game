class_name BossPhase
extends Resource
## One phase of a boss fight (ADR 0014): active while HP / max HP <= hp_ratio
## (the first phase uses 1.0). Patterns play in order, looping.

@export_range(0.0, 1.0) var hp_ratio: float = 1.0
@export var patterns: Array[BossPattern] = []
## Multiplies the boss speed during this phase.
@export var speed_multiplier: float = 1.0
