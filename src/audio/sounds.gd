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
const LEVEL_UP := preload("res://assets/audio/sfx/level_up.ogg")

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
const VICTORY := preload("res://assets/audio/sfx/victory.ogg")
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
## A run starts through a seal's gate ("Magic Spell SFX", OpenGameArt, CC0).
const PORTAL_OPEN := preload("res://assets/audio/sfx/portal_open.ogg")
const UI_NEXT := preload("res://assets/audio/sfx/ui_next.ogg")
