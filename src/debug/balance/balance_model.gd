extends Node
## Fast balance model (ADR 0019): no combat, seconds to run. For every weapon and
## tier, from the real WeaponStats and shop prices: damage per second on the sheet,
## targets hit in a late-wave crowd, crowd DPS, and crowd DPS per material at wave 10.
## Spots outliers that the full simulator then confirms. Writes one JSON and quits:
##   Godot.exe --headless --path . res://src/debug/balance/balance_model.tscn -- --out=<file.json>

const PRICE_WAVE := 10


func _ready() -> void:
	var out := "user://balance_model.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	var shop: ShopConfig = ContentDB.get_def(&"shop", &"default")
	var rows := []
	for def in ContentDB.get_all(&"weapons"):
		var weapon := def as WeaponData
		for tier in range(1, weapon.max_level() + 1):
			var s := WeaponStats.compute(weapon, tier)
			var dps := sheet_dps(s)
			var targets := BalanceSimTools.targets_hit(weapon, s)
			var price := shop.weapon_price(weapon, tier, PRICE_WAVE)
			rows.append({
				"weapon": String(weapon.id), "tier": tier, "families": weapon.families.map(func(f: StringName) -> String: return String(f)),
				"melee": weapon.is_melee(), "sheet_dps": snappedf(dps, 0.01), "targets": snappedf(targets, 0.01),
				"crowd_dps": snappedf(dps * targets, 0.01), "price_w10": price,
				"crowd_dps_per_material": snappedf(dps * targets / maxf(price, 1.0), 0.001),
			})
	var file := FileAccess.open(out, FileAccess.WRITE)
	file.store_string(JSON.stringify({"weapons": rows}))
	file.close()
	print("balance model -> ", out)
	get_tree().quit()


## Damage per second of one weapon with default player stats (crit 1.5x).
static func sheet_dps(s: WeaponStats) -> float:
	var crit_factor := 1.0 + clampf(s.crit_chance, 0.0, 1.0) * (StatIds.DEFAULTS[StatIds.CRIT_DAMAGE] - 1.0)
	return s.damage * crit_factor * maxf(s.projectile_count, 1) / maxf(s.cooldown, 0.05)
