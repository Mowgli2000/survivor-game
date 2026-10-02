class_name ItemData
extends Resource
## A passive item sold in the shop: stat bonuses and maluses. Instances live in data/items/.

@export var id: StringName
@export var name_key: String
## 1..Tiers.COUNT, fixed for an item.
@export var tier: int = 1
## Price on wave 1 (grows with the waves, see ShopConfig).
@export var base_price: int = 15
@export var modifiers: Array[StatModifier] = []
## 0 = unlimited.
@export var max_count: int = 0
