class_name EffectSheets
extends RefCounted
## Painted effects (EffectSheet) used by the combat code, and which projectile style plays which.
## The art is baked by tools/art/bake_vfx.py from the candidates of tools/art/gen_vfx.py.

const STAR_IMPACT := preload("res://data/vfx/star_impact.tres")
const IMPACT_GENERIC := preload("res://data/vfx/impact_generic.tres")
const IMPACT_FROST := preload("res://data/vfx/impact_frost.tres")
const IMPACT_SLING := preload("res://data/vfx/impact_sling.tres")
const IMPACT_LIGHTNING := preload("res://data/vfx/impact_lightning.tres")
const EXPLOSION_FIRE := preload("res://data/vfx/explosion_fire.tres")
const EXPLOSION_FROST := preload("res://data/vfx/explosion_frost.tres")
const EXPLOSION_BLAST := preload("res://data/vfx/explosion_blast.tres")
const EXPLOSION_STAR := preload("res://data/vfx/explosion_star.tres")
## One unique explosion per explosive weapon (bomb, explosive flask, cannon, fire staff).
const EXPLOSION_BOMB := preload("res://data/vfx/explosion_bomb.tres")
const EXPLOSION_FLASK := preload("res://data/vfx/explosion_flask.tres")
const EXPLOSION_CANNON := preload("res://data/vfx/explosion_cannon.tres")
const EXPLOSION_STAFF := preload("res://data/vfx/explosion_staff.tres")
## One hop of chain electricity (any weapon that electrocutes).
const STORM_ARC := preload("res://data/vfx/storm_arc.tres")

## Size (radius covered) of a hit burst, px.
const IMPACT_SIZE := 46.0
const STAR_IMPACT_SIZE := 70.0


## Burst where a non-explosive projectile of `style` lands (null: none).
static func impact_for(style: int) -> EffectSheet:
	match style:
		WeaponData.ProjectileStyle.STAR_ARROW:
			return STAR_IMPACT
		WeaponData.ProjectileStyle.ICE_SHARD:
			return IMPACT_FROST
		WeaponData.ProjectileStyle.LIGHTNING:
			return IMPACT_LIGHTNING
		WeaponData.ProjectileStyle.STONE:
			return IMPACT_SLING
		WeaponData.ProjectileStyle.ORB, WeaponData.ProjectileStyle.BOLT, WeaponData.ProjectileStyle.BULLET, WeaponData.ProjectileStyle.MISSILE, \
		WeaponData.ProjectileStyle.SHURIKEN, WeaponData.ProjectileStyle.ARROW, WeaponData.ProjectileStyle.JAVELIN:
			return IMPACT_GENERIC
	return null


## Explosion of a projectile of `style`: each explosive weapon has its own, recognisable at a glance.
static func explosion_for(style: int) -> EffectSheet:
	match style:
		WeaponData.ProjectileStyle.STAR_ARROW:
			return EXPLOSION_STAR
		WeaponData.ProjectileStyle.FROST_FLASK:
			return EXPLOSION_FROST
		WeaponData.ProjectileStyle.FIRE_FLASK:
			return EXPLOSION_FIRE
		WeaponData.ProjectileStyle.FIREBALL:
			return EXPLOSION_STAFF
		WeaponData.ProjectileStyle.BOMB:
			return EXPLOSION_BOMB
		WeaponData.ProjectileStyle.BOMB_FLASK:
			return EXPLOSION_FLASK
		WeaponData.ProjectileStyle.CANNONBALL:
			return EXPLOSION_CANNON
	return EXPLOSION_BLAST
