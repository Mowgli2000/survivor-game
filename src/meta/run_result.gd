class_name RunResult
extends RefCounted
## What a finished run reports to SaveService (ADR 0015).

var character_id: StringName
var won: bool = false
var wave: int = 0
var kills: int = 0
## Most materials held at once during the run.
var max_materials: int = 0
## Ids of special enemies killed (bosses, mini-bosses).
var killed_special: Array[StringName] = []
