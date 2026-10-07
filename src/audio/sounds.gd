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
