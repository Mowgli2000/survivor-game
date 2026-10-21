class_name Sounds
## Sound effects and music of the game (CC0, see assets/CREDITS.md).
## Weapon fire sounds live in WeaponData.fire_sound.

# Fantasy music (CC0, OpenGameArt): menu "Dark Shrine Loop" (qubodup),
# combat "Battle Theme A" (cynicmusic.com / pixelsphere.org), boss "Battle RPG
# Theme" (CleytonRX).
const MUSIC_MENU := preload("res://assets/audio/music/menu_dark_shrine.ogg")
const MUSIC_RUN := preload("res://assets/audio/music/battle_theme_a.mp3")
const MUSIC_BOSS := preload("res://assets/audio/music/boss_battle_rpg.mp3")

const EXPLOSION := preload("res://assets/audio/sfx/explosion.ogg")
const ENEMY_HIT := preload("res://assets/audio/sfx/enemy_hit.ogg")
const ENEMY_DEATH := preload("res://assets/audio/sfx/enemy_death.ogg")
const ELITE_DEATH := preload("res://assets/audio/sfx/elite_death.ogg")
const PLAYER_HURT := preload("res://assets/audio/sfx/player_hurt.ogg")
const PICKUP := preload("res://assets/audio/sfx/pickup.ogg")
const LEVEL_UP := preload("res://assets/audio/sfx/level_up.wav")
## End of a wave: ElevenLabs (tools/audio/sound_list.json) replaces the synthesized two-note marimba (tools/audio/make_wave_clear.py), not satisfying enough (dev, 2026-10-18).
const WAVE_CLEAR := preload("res://assets/audio/sfx/wave_clear.mp3")
## The old level-up sound, now the death of a character.
const PLAYER_DEATH := preload("res://assets/audio/sfx/player_death.ogg")

## Combat cues (Kenney "Impact Sounds", CC0; heartbeat synthesized). Every interaction has
## its own sound so the player hears what happens: hit, crit, kill, hurt, low HP...
## Five punchy body thuds (Kenney "impactPunch_medium"): noisy and short, nothing tonal
## (the first set rang like a xylophone, the metal ring too: dev's feedback).
const KILL_THUD: Array[AudioStream] = [
	preload("res://assets/audio/sfx/combat/kill_thud_1.ogg"),
	preload("res://assets/audio/sfx/combat/kill_thud_2.ogg"),
	preload("res://assets/audio/sfx/combat/kill_thud_3.ogg"),
	preload("res://assets/audio/sfx/combat/kill_thud_4.ogg"),
	preload("res://assets/audio/sfx/combat/kill_thud_5.ogg")]
## Monster death: a soft "pop" with a puff of smoke, six pitches (synthesized by
## tools/audio/make_kill_pops.py). Replaces the body thuds for normal kills.
const KILL_POP: Array[AudioStream] = [
	preload("res://assets/audio/sfx/combat/kill_pop_1.wav"),
	preload("res://assets/audio/sfx/combat/kill_pop_2.wav"),
	preload("res://assets/audio/sfx/combat/kill_pop_3.wav"),
	preload("res://assets/audio/sfx/combat/kill_pop_4.wav"),
	preload("res://assets/audio/sfx/combat/kill_pop_5.wav"),
	preload("res://assets/audio/sfx/combat/kill_pop_6.wav")]
const HIT_CRIT := preload("res://assets/audio/sfx/combat/hit_crit.ogg")
## Low thump layered under the player's hurt sound (louder with the damage).
const PLAYER_HIT_HEAVY := preload("res://assets/audio/sfx/combat/player_hit_heavy.ogg")
const HEARTBEAT := preload("res://assets/audio/sfx/combat/heartbeat.wav")
## Telegraph of a boss attack or a kamikaze blast.
const WARNING := preload("res://assets/audio/sfx/combat/warning.ogg")
const BOSS_ALERT := preload("res://assets/audio/sfx/combat/boss_alert.ogg")
## Wave countdown (last seconds) and kamikaze fuse.
const TICK := preload("res://assets/audio/sfx/combat/tick.ogg")
const FUSE := preload("res://assets/audio/sfx/combat/fuse.ogg")
const ENEMY_SHOT := preload("res://assets/audio/sfx/combat/enemy_shot.ogg")

const WAVE_START := preload("res://assets/audio/sfx/wave_start.ogg")
const WAVE_END := preload("res://assets/audio/sfx/wave_end.ogg")
## Fanfare generated with ElevenLabs (tools/audio/sound_list.json); the old CC0 jingle sounded like a defeat.
const VICTORY := preload("res://assets/audio/sfx/victory.mp3")
const DEFEAT := preload("res://assets/audio/sfx/defeat.ogg")

const UI_BUY := preload("res://assets/audio/sfx/ui_buy.ogg")
const UI_ERROR := preload("res://assets/audio/sfx/ui_error.ogg")
const UI_REROLL := preload("res://assets/audio/sfx/ui_reroll.ogg")
const UI_LOCK := preload("res://assets/audio/sfx/ui_lock.ogg")
const UI_SELL := preload("res://assets/audio/sfx/ui_sell.ogg")
const UI_MERGE := preload("res://assets/audio/sfx/ui_merge.ogg")
const UI_SELECT := preload("res://assets/audio/sfx/ui_select.ogg")
## Quick wind whoosh (the select-screen turntable changes look).
const UI_SWOOSH := preload("res://assets/audio/sfx/ui_swoosh.wav")
## Every button (Audio hooks them): hover / focus tick and press click (Kenney UI Audio, CC0).
const UI_HOVER := preload("res://assets/audio/sfx/ui_hover.ogg")
const UI_CLICK := preload("res://assets/audio/sfx/ui_click.ogg")
## Fire burning when the mouse lights a brazier of a menu picture (synthesized,
## tools/audio/make_fire.py).
const FIRE_CRACKLE := preload("res://assets/audio/sfx/fire_crackle.wav")
## Lightning striking out of the last seal's portal (synthesized, tools/audio/make_zap.py).
const LIGHTNING_ZAP: Array[AudioStream] = [preload("res://assets/audio/sfx/lightning_zap_1.wav"),
		preload("res://assets/audio/sfx/lightning_zap_2.wav"), preload("res://assets/audio/sfx/lightning_zap_3.wav")]
## Constant deep rumble of the last seal's portal, looped while it is pointed (synthesized,
## tools/audio/make_rumble.py).
const PORTAL_RUMBLE := preload("res://assets/audio/sfx/portal_rumble.wav")
## A run starts through a seal's gate ("Magic Spell SFX", OpenGameArt, CC0).
const PORTAL_OPEN := preload("res://assets/audio/sfx/portal_open.ogg")
const UI_NEXT := preload("res://assets/audio/sfx/ui_next.ogg")

## ElevenLabs sounds (2026-10, tools/audio/sound_list.json). One sound per family of boss attacks:
## BossDirector asks boss_attack() when a pattern fires.
const BOSS_ENTRANCE := preload("res://assets/audio/sfx/boss/boss_entrance.mp3")
const BOSS_PHASE_CHANGE := preload("res://assets/audio/sfx/boss/boss_phase_change.mp3")
const BOSS_RAGE := preload("res://assets/audio/sfx/boss/boss_rage.mp3")
const BOSS_DEATH := preload("res://assets/audio/sfx/boss/boss_death.mp3")
const MINI_BOSS_DEATH := preload("res://assets/audio/sfx/boss/mini_boss_death.mp3")
const BOSS_SLAM := preload("res://assets/audio/sfx/boss/boss_slam.mp3")
const BOSS_SLASH := preload("res://assets/audio/sfx/boss/boss_slash.mp3")
const BOSS_FIRE := preload("res://assets/audio/sfx/boss/boss_fire.mp3")
const BOSS_ICE := preload("res://assets/audio/sfx/boss/boss_ice.mp3")
const BOSS_VENOM := preload("res://assets/audio/sfx/boss/boss_venom.mp3")
const BOSS_PROJECTILES := preload("res://assets/audio/sfx/boss/boss_projectiles.mp3")
const BOSS_WIND := preload("res://assets/audio/sfx/boss/boss_wind.mp3")
const BOSS_SUMMON := preload("res://assets/audio/sfx/boss/boss_summon.mp3")
const ENEMY_SHOT_ARROW := preload("res://assets/audio/sfx/combat/enemy_shot_arrow.mp3")
const ENEMY_SHOT_MAGIC := preload("res://assets/audio/sfx/combat/enemy_shot_magic.mp3")
const ENEMY_SHOT_VENOM := preload("res://assets/audio/sfx/combat/enemy_shot_venom.mp3")
const IMPACT_FIRE := preload("res://assets/audio/sfx/impacts/impact_fire.mp3")
const IMPACT_ICE := preload("res://assets/audio/sfx/impacts/impact_ice.mp3")
const IMPACT_LIGHTNING := preload("res://assets/audio/sfx/impacts/impact_lightning.mp3")
const EXPLOSION_SMALL := preload("res://assets/audio/sfx/impacts/explosion_small.mp3")
const EXPLOSION_BIG := preload("res://assets/audio/sfx/impacts/explosion_big.mp3")
const UI_UNLOCK := preload("res://assets/audio/sfx/ui_unlock.mp3")
const UI_VICTORY_CARD := preload("res://assets/audio/sfx/ui_victory_card.mp3")

## Extra level (dB) of the sounds that were too discreet in a fight (dev, 2026-10-18).
const BOSS_ATTACK_TRIM_DB := {BOSS_ICE: 4.0}

## Boss attack script name -> sound. A pattern absent from the table is silent.
const _BOSS_ATTACK_SOUND := {
	&"ClubShockwavePattern": BOSS_SLAM, &"PillarDropPattern": BOSS_SLAM, &"ImpactZonesPattern": BOSS_SLAM,
	&"ShockRingsPattern": BOSS_SLAM, &"TailSweepPattern": BOSS_SLAM,
	&"CrossSlashPattern": BOSS_SLASH, &"BladeRainPattern": BOSS_SLASH, &"BladeWhirlPattern": BOSS_SLASH,
	&"IaidoPattern": BOSS_SLASH, &"ThrustBarragePattern": BOSS_SLASH, &"ShadowStepPattern": BOSS_SLASH,
	&"DashPattern": BOSS_SLASH, &"ChainLashPattern": BOSS_SLASH,
	&"FireBeamPattern": BOSS_FIRE, &"FireBreathPattern": BOSS_FIRE, &"FlameRingPattern": BOSS_FIRE,
	&"FlameCheckerPattern": BOSS_FIRE, &"MeteorShowerPattern": BOSS_FIRE, &"ConeBreathPattern": BOSS_FIRE,
	&"FrostWallPattern": BOSS_ICE, &"FreezingPatchPattern": BOSS_ICE, &"HailPattern": BOSS_ICE,
	&"IceSpikeLinePattern": BOSS_ICE,
	&"VenomSpitPattern": BOSS_VENOM, &"VenomPoolsPattern": BOSS_VENOM, &"EggClutchPattern": BOSS_VENOM,
	&"WebNetPattern": BOSS_VENOM,
	&"RadialBurstPattern": BOSS_PROJECTILES, &"AimedFanPattern": BOSS_PROJECTILES, &"CrackRaysPattern": BOSS_PROJECTILES,
	&"WingBlastPattern": BOSS_WIND, &"DragonFlybyPattern": BOSS_WIND, &"StormFrontPattern": BOSS_WIND,
	&"SummonPattern": BOSS_SUMMON, &"RuneSealPattern": BOSS_SUMMON, &"LegCagePattern": BOSS_SUMMON,
	&"WallPattern": BOSS_SUMMON}


## Sounds of one boss attack (a combo gives one per distinct part). `shot_style` (the boss's
## projectile look) tells a frost breath from a fire breath.
static func boss_attack(pattern: BossPattern, shot_style: int = -1) -> Array[AudioStream]:
	var found: Array[AudioStream] = []
	if pattern is ComboPattern:
		for part in (pattern as ComboPattern).parts:
			for stream in boss_attack(part, shot_style):
				if not found.has(stream):
					found.append(stream)
		return found
	var script_name: StringName = pattern.get_script().get_global_name()
	var stream: AudioStream = _BOSS_ATTACK_SOUND.get(script_name)
	if script_name == &"ConeBreathPattern" and shot_style == WeaponData.ProjectileStyle.ENEMY_ICE:
		stream = BOSS_ICE
	if stream != null:
		found.append(stream)
	return found


## Shot sound of an enemy projectile by its look.
static func enemy_shot(style: int) -> AudioStream:
	match style:
		WeaponData.ProjectileStyle.ENEMY_ACID:
			return ENEMY_SHOT_VENOM
		WeaponData.ProjectileStyle.ENEMY_STONE:
			return ENEMY_SHOT_ARROW
		_:
			return ENEMY_SHOT_MAGIC
