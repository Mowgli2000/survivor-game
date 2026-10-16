class_name ChestData
extends Resource
## A treasure chest dropped by a boss (small: mini-boss, big: final boss). Its opening plays from a
## SpriteSheet animation named "open" (pose 0 is the closed chest).

@export var sheet: SpriteSheet
## Size on screen of a whole cell (the chest is a part of it, light and sparks fill the rest).
@export var height: float = 200.0
## Frames per second of the opening.
@export var open_fps: float = 10.0
## A player this close to the chest opens it.
@export var open_radius: float = 90.0
## Item tier the chest gives (Run._grant_reward): 0 = nothing.
@export var reward_tier: int = 2
## Frame (0-based) of the opening where the light bursts out: the reward comes with it.
@export var burst_frame: int = 8
## Items it gives each player.
@export_range(1, 5) var reward_count: int = 1
## True: a screen shows the rewards until the player validates (final boss). False: their icons just float up
## from the chest and fade (mini-boss), nothing stops.
@export var show_screen: bool = true
## Painted light projection above the open chest (the rewards float in it); empty: a plain glow.
@export var projection: EffectSheet
