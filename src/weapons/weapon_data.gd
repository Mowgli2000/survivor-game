class_name WeaponData
extends Resource
## Definition of a weapon. Instances live in data/weapons/.
## The behavior decides how the weapon attacks; the values below are its tier I
## tuning, and `levels` describes what each following level adds.

@export var id: StringName
@export var name_key: String
## Hidden from the shop, rewards and selection until a challenge unlocks it (ADR 0015).
@export var locked: bool = false
@export var description_key: String
@export var behavior: WeaponBehavior
## Weapon families (ids in data/families/) for set bonuses.
@export var families: Array[StringName] = []
## Tiers II..IV: levels[0] = what tier II adds, levels[1] = tier III, levels[2] = tier IV.
@export var levels: Array[WeaponLevel] = []
## Shop price of the tier I weapon (higher tiers: ShopConfig.weapon_tier_price).
@export var base_price: int = 15

@export_group("Stats")
@export var base_damage: float = 5.0
## Seconds between two attacks at 100 % attack speed.
@export var cooldown: float = 1.0
## Distance at which the weapon looks for a target.
@export var attack_range: float = 500.0
@export var crit_chance: float = 0.05
@export var knockback: float = 100.0

## Look of the projectile body (assets/sprites/projectiles.png cell = style - 1).
## GLOW = neon halo only. Values are saved in .tres files: only append new ones.
enum ProjectileStyle { GLOW, ORB, BOLT, BULLET, MISSILE, SHURIKEN, ENEMY_ORB, FIREBALL, ICE_SHARD,
	LIGHTNING, ARROW, STONE, JAVELIN, BOMB, FIRE_FLASK, FROST_FLASK, GRENADE, CANNONBALL,
	ENEMY_ICE, ENEMY_FIRE, ENEMY_ACID, ENEMY_STONE, STAR_ARROW, BOMB_FLASK, SHADOW_BLADE }

@export_group("Projectiles")
@export var projectile_style: ProjectileStyle = ProjectileStyle.GLOW
@export var projectile_speed: float = 600.0
@export var projectile_count: int = 1
## Angle in degrees between two projectiles of the same volley.
@export var spread_deg: float = 10.0
## Random deviation in degrees applied to each projectile.
@export var inaccuracy_deg: float = 0.0
@export var pierce: int = 0
## > 0: turn rate (radians/s) toward the nearest enemy (bazooka missiles).
@export var homing: float = 0.0
@export var projectile_radius: float = 6.0
@export var projectile_lifetime: float = 1.0
## Number of times a projectile jumps to another enemy after a hit.
@export var bounces: int = 0
@export var bounce_range: float = 300.0
## > 0: the projectile explodes on impact (or at the end of its life).
@export var explosion_radius: float = 0.0
## Shards thrown outward in an even ring where the explosion happens (frag grenade): each one a small piercing shot.
@export var fragments: int = 0
@export var fragment_style: ProjectileStyle = ProjectileStyle.BULLET
## Lobbed bomb: seconds it sits on the ground, fuse burning, before it explodes (0 = explodes as it lands).
@export var fuse_time: float = 0.0
## Explosive flask: how many more times it bounces to another enemy (outside the blast) and explodes again.
@export var rebounds: int = 0
## Flask that leaves a burning ground: seconds it lasts (0 = none), and its painted loop (EffectSheet).
@export var zone_time: float = 0.0
@export var zone_sheet: EffectSheet
## Painted effect played over the ground effect when it ends (the gravity well collapsing).
@export var zone_end_sheet: EffectSheet
## > 0: radius of the ground effect (0 = 70 % of the explosion radius). A shot with a ground effect and no explosion
## plants it where it ends (heavy crossbow: the bolt sticks in the ground, slowing what is around it).
@export var zone_radius: float = 0.0
## > 0: a projectile that stays on its enemies hurts them again every `rehit_time` seconds (vortex orb, orbiting blades).
@export var rehit_time: float = 0.0
## Vortex: enemies within `pull_radius` px of the projectile are dragged toward it at `pull_speed` px/s.
@export var pull_radius: float = 0.0
@export var pull_speed: float = 0.0
## false: landing hurts nothing and shows no blast, only the ground effect it leaves (gravity well).
@export var landing_blast: bool = true
## false: the player's Projectiles stat adds no shots to this weapon (the gravity well: three wells side by side read badly).
@export var projectile_stat_applies: bool = true
## An exploding shot that pierces (`pierce` enemies) makes a small blast on each enemy it passes through (60 % of the
## radius, half the damage) and only then the full one at the end of its flight (alchemical cannon).
@export var blast_on_pierce: bool = false
## Extra damage a shot gains over its flight, as a share of its damage at the end of its range (long bow: 1.0 = +100 %).
@export var distance_damage: float = 0.0
## Rapid fire: the weapon fires up to `ramp_speedup` times faster (+100 % per 1.0) the longer it keeps firing;
## it takes `ramp_shots` shots to get there and the speed-up fades when it stops (repeating crossbow).
@export var ramp_speedup: float = 0.0
@export var ramp_shots: int = 30
## The shot comes back to its owner at the end of its flight, hurting again on the way (shuriken).
@export var returns: bool = false
## Times a shot bounces off the walls of the arena.
@export var wall_bounces: int = 0
## > 0: the hit shape is a capsule (the projectile radius around a segment this long on each side of its center, along its
## travel): a long blade hurts along its whole painted length.
@export var hit_half_length: float = 0.0

@export_group("Area")
## Radius of a melee arc, or width of a beam.
@export var area: float = 0.0
## Opening of a melee arc, in degrees.
@export var arc_degrees: float = 120.0
## Look of a melee hit (Vfx.slash): each weapon reads differently in a crowd.
enum SlashStyle { CRESCENT, THIN, THRUST, HEAVY, SMASH, FLAME, RUNIC }
@export var slash_style: SlashStyle = SlashStyle.CRESCENT
## Painted animation of the swing (EffectSheet, art on black, additive); null: the style's code drawing.
@export var slash_sheet: EffectSheet
## How the painted swing plays (melee arc weapons): ARC = the sheet sweeps around the wielder;
## TRAVEL = it flies toward the target; LINE = a long thin line from the wielder through the target;
## ORBIT = it circles the wielder at the weapon's reach; TARGET = it lands on the enemy (a circle that
## hurts what it covers); RING = a shockwave growing from the target; FLURRY = three fanned thin lines.
## What is drawn is exactly what hurts (MeleeArcBehavior).
enum SwingFx { ARC, TRAVEL, LINE, ORBIT, TARGET, RING, FLURRY }
@export var swing_fx: SwingFx = SwingFx.ARC
## TARGET and RING swings are drawn on the ground, under the hero and the monsters (a sigil he walks over stays whole).
@export var ground_swing: bool = false
## TARGET swings turn toward the hit enemy (a crescent that opens to the right otherwise always cuts rightward).
@export var face_target: bool = false
## Width of the lines (LINE, FLURRY): the real damage width, an enemy's own size comes on top.
@export var hit_width: float = 20.0
## Fine tuning of the size of the weapon's damage shape (circle, wave): 1 = the size its cooldown asks for.
@export var hit_scale: float = 1.0
## Share of the painted effect's duration before it hurts (the impact frame: a slam lands early, a sigil late).
@export var hit_time: float = 0.2
## Painted mark played on every enemy this weapon hurts (the X of a cut), at the moment it is hurt.
@export var target_sheet: EffectSheet
## Painted beam (BeamBehavior), stretched over the beam's length; null: the beam drawn by code.
@export var beam_sheet: EffectSheet

@export_group("Status")
@export var status: StatusData
@export_range(0.0, 1.0) var status_chance: float = 1.0

@export_group("Audio")
@export var fire_sound: AudioStream
@export var fire_volume_db: float = -6.0

@export_group("Visual")
@export var color: Color = Color(1.0, 0.9, 0.4)
## Shop/HUD icon, also drawn as the in-game weapon (profile, barrel pointing right,
## centered). Null: text only in the UI, not drawn in game.
@export var icon: Texture2D
## The icon art lies diagonally, tip up-right (long weapons: it fills the UI squares).
## WeaponVisuals turns it back to horizontal for the floating weapon.
@export var icon_diagonal: bool = false
## Size of the floating weapon relative to WeaponVisuals.SIZE: round things (bombs,
## flasks) fill their icon and looked too big next to blades; melee weapons a bit bigger.
@export var float_scale: float = 1.0
## Counts as a melee weapon for the class rules though it is not a MeleeArcBehavior.
@export var melee_class: bool = false


func max_level() -> int:
	return levels.size() + 1


## Close-range slashing weapon (MeleeArcBehavior); everything else is ranged.
func is_melee() -> bool:
	return behavior is MeleeArcBehavior


## Class rules (CharacterData.allows_weapon): true for a melee weapon, and for the
## short-range weapons of `melee_class`, which a melee class may carry (dev's call: shadow blades).
func in_melee_class() -> bool:
	return is_melee() or melee_class
