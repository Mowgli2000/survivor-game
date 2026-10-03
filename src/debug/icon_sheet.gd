extends Node2D
## Shows every weapon and item icon on a tier-colored tile, to review the art.
## Run with F6, or headless capture:
## Godot.exe --path . res://src/debug/icon_sheet.tscn -- --out=<file.png>

const TILE := 112.0
const GAP := 18.0
const COLUMNS := 8
const BACKGROUND := Color(0.42, 0.42, 0.62)
const TILE_COLOR := Color(0.06, 0.06, 0.1, 0.92)

var _out: String = ""


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
	queue_redraw()
	if _out != "":
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(_out)
		print("capture saved: ", _out)
		get_tree().quit()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), BACKGROUND)
	var entries: Array = []
	for def in ContentDB.get_all(&"weapons"):
		var weapon := def as WeaponData
		entries.append([weapon.icon, 1])
	for def in ContentDB.get_all(&"items"):
		var item := def as ItemData
		entries.append([item.icon, item.tier])
	for i in entries.size():
		var pos := Vector2(GAP + (i % COLUMNS) * (TILE + GAP), GAP + (i / COLUMNS) * (TILE + GAP))
		var rect := Rect2(pos, Vector2(TILE, TILE))
		draw_rect(rect, TILE_COLOR)
		draw_rect(rect, Tiers.color(entries[i][1]), false, 3.0)
		var icon: Texture2D = entries[i][0]
		if icon != null:
			draw_texture_rect(icon, rect.grow(-8.0), false)
