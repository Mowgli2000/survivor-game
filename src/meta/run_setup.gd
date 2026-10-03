class_name RunSetup
extends RefCounted
## Choices made before a run (character select): passed to Run through
## SceneRouter.next_run and kept for "Restart" (ADR 0015).

var character: CharacterData
## Starting weapon; null = the character's default.
var weapon: WeaponData
## Null = Danger 0.
var difficulty: DifficultyData
