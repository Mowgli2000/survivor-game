class_name ItemData
extends Resource
## A passive item sold in the shop: stat bonuses and maluses. Instances live in data/items/.

@export var id: StringName
@export var name_key: String
## Hidden from the shop, rewards and selection until a challenge unlocks it (ADR 0015).
@export var locked: bool = false
## 1..Tiers.COUNT, fixed for an item.
@export var tier: int = 1
## Price on wave 1 (grows with the waves, see ShopConfig).
@export var base_price: int = 15
@export var modifiers: Array[StatModifier] = []
## 0 = unlimited.
@export var max_count: int = 0
## Shop icon (null: text only).
@export var icon: Texture2D
## What the item does beyond its modifiers (one instance per owned copy).
@export var effects: Array[ItemEffect] = []
## Effect text shown on the card, below the modifiers (localization key, optional).
@export var effect_key: String = ""
