extends Node2D
## Shows every weapon and item icon on a tier-colored tile, to review the art.
## Run with F6, or headless capture:
## Godot.exe --path . res://src/debug/icon_sheet.tscn -- --out=<file.png>
## [--art=<folder>]: weapons only, big, with alternative art <folder>/<weapon id>.png
## (restyle preview before import) and the current icon small in the corner.

const TILE := 112.0
const GAP := 18.0
const COLUMNS := 8
const BACKGROUND := Color(0.42, 0.42, 0.62)
const TILE_COLOR := Color(0.06, 0.06, 0.1, 0.92)

var _out: String = ""
## Weapon id -> alternative art (--art), empty in the normal mode.
var _art: Dictionary = {}


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--art="):
			_load_art(arg.trim_prefix("--art="))
	if not _art.is_empty():
		get_window().size = Vector2i(1920, 1080)
	queue_redraw()
	if _out != "":
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(_out)
		print("capture saved: ", _out)
		get_tree().quit()


func _load_art(folder: String) -> void:
	for def in ContentDB.get_all(&"weapons"):
		var path := folder.path_join(String(def.get("id")) + ".png")
		var image := Image.load_from_file(path) if FileAccess.file_exists(path) else null
		if image != null:
			# Generated art has wide transparent margins: crop to the drawing.
			_art[def.get("id")] = ImageTexture.create_from_image(image.get_region(image.get_used_rect()))


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), BACKGROUND)
	if not _art.is_empty():
		_draw_weapon_preview()
		return
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


## Restyle preview: weapons by family, new art big, current icon small, name below.
func _draw_weapon_preview() -> void:
	const COLS := 6
	const CELL := Vector2(310.0, 196.0)
	var font := UiTheme.font(700)
	var weapons: Array = ContentDB.get_all(&"weapons")
	weapons.sort_custom(func(a: WeaponData, b: WeaponData) -> bool:
		var fa := String(a.families[0]) if not a.families.is_empty() else ""
		var fb := String(b.families[0]) if not b.families.is_empty() else ""
		return fa < fb or fa == fb and String(a.id) < String(b.id))
	draw_string(font, Vector2(24, 40), tr("UI_WEAPON_PREVIEW_TITLE"), HORIZONTAL_ALIGNMENT_LEFT, -1, 26)
	for i in weapons.size():
		var w: WeaponData = weapons[i]
		var rect := Rect2(Vector2(15 + (i % COLS) * CELL.x, 62 + (i / COLS) * CELL.y), CELL - Vector2(12, 12))
		draw_rect(rect, TILE_COLOR)
		draw_rect(rect, w.color, false, 3.0)
		var art: Texture2D = _art.get(w.id, w.icon)
		if art != null:
			draw_texture_rect(art, _fit(art, Rect2(rect.position + Vector2(8, 4), rect.size - Vector2(16, 44))), false)
		if w.icon != null:
			draw_texture_rect(w.icon, Rect2(rect.end - Vector2(48, 48), Vector2(42, 42)), false, Color(1, 1, 1, 0.9))
		draw_string(font, rect.position + Vector2(12, rect.size.y - 12), tr(w.name_key), HORIZONTAL_ALIGNMENT_LEFT,
			rect.size.x - 64, 22)


## Largest rect of `texture`'s aspect centered in `box`.
static func _fit(texture: Texture2D, box: Rect2) -> Rect2:
	var size := Vector2(texture.get_size())
	var s := minf(box.size.x / size.x, box.size.y / size.y)
	return Rect2(box.get_center() - size * s * 0.5, size * s)
