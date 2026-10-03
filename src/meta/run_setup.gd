class_name RunSetup
extends RefCounted
## Choices made before a run (character select): passed to Run through
## SceneRouter.next_run and kept for "Restart" (ADR 0015).

var character: CharacterData
## Starting weapon; null = the character's default.
var weapon: WeaponData
## Null = Danger 0.
var difficulty: DifficultyData
## Local coop (ADR 0017): player 2's character; null = solo.
var character_2: CharacterData
## Player 2's starting weapon; null = the character's default.
var weapon_2: WeaponData
