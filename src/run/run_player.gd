class_name RunPlayer
extends RefCounted
## Everything one player owns in a run (ADR 0017): built and wired by Run.
## Solo runs have one; Run's legacy fields (player, progression, shop...) point to players[0].

## Player colors (tags on the screens between waves, HUD), by index.
## Hunter colors, the same on every screen: cyan (hunter 1) and amber (hunter 2), the colors of
## the seals of the coop character select.
const COLORS: Array[Color] = [Color("4fc3ff"), Color("ffb030")]

var index: int = 0
var character: CharacterData
## 0 = the character's own look, 1 = its second look.
var variant: int = 0
var player: Player
var input: PlayerInput
## Seconds to the next heartbeat while this player is on low health (Run).
var heartbeat_timer: float = 0.0
var progression: Progression
var wallet: Wallet
var inventory: Inventory
var shop: Shop
var item_effects: ItemEffects
var families: WeaponFamilies
var shop_screen: ShopScreen
var level_up_screen: LevelUpScreen
## Between waves: this player has pressed "Next wave" in his shop.
var between_done: bool = false
## Level-ups rerolled during the current between-waves screen (cost grows).
var level_up_rerolls: int = 0
var max_materials: int = 0
## Coop end-of-run summary: enemies this player killed and times they went down.
var kills: int = 0
var deaths: int = 0


func color() -> Color:
	return COLORS[index % COLORS.size()]
