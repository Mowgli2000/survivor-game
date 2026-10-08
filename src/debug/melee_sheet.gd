extends Node2D
## Debug tool: contact sheet of the melee animations. One row per weapon, one column per
## moment of the swing: the weapon's pose (wind-up, strike, follow-through) and the slash
## streak at that moment, around a stand-in hero. Review the feel without playing.
## Godot.exe --path . res://src/debug/melee_sheet.tscn -- --out=<png> [--weapons=a,b,c]

const CELL := Vector2(250, 230)
const MOMENTS: Array[float] = [0.0, 0.14, 0.26, 0.36, 0.5, 0.68, 0.9]
const DEFAULT_WEAPONS: Array[String] = ["katana", "steel_katana", "rapier", "scythe", "warhammer", "runic_blade"]

var _out := "user://melee_sheet.png"
var _ids: Array[String] = DEFAULT_WEAPONS.duplicate()


func _ready() -> void:
	# 1 unit = 1 pixel: the project stretches to 1920x1080, this sheet must not.
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--weapons="):
			_ids.assign(arg.trim_prefix("--weapons=").split(","))
	var bg := ColorRect.new()
	bg.color = Color("2a2150")
	bg.size = Vector2(CELL.x * MOMENTS.size(), CELL.y * _ids.size())
	add_child(bg)
	for row in _ids.size():
		var weapon := ContentDB.get_def(&"weapons", StringName(_ids[row])) as WeaponData
		for col in MOMENTS.size():
			_cell(weapon, MOMENTS[col], Vector2(col, row))
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out)
	print("melee sheet saved: ", ProjectSettings.globalize_path(_out))
	get_tree().quit()


func _cell(weapon: WeaponData, progress: float, at: Vector2) -> void:
	var origin := Vector2(CELL.x * (at.x + 0.3), CELL.y * (at.y + 0.5))
	var holder := Node2D.new()
	holder.position = origin
	add_child(holder)
	var hero := Polygon2D.new()
	hero.polygon = PackedVector2Array([Vector2(-14, 14), Vector2(14, 14), Vector2(10, -30), Vector2(-10, -30)])
	hero.color = Color(0.9, 0.5, 0.5)
	holder.add_child(hero)
	var style := weapon.slash_style
	var swing := WeaponVisuals.melee_time(style)
	var elapsed := progress * swing
	# The streak, `delay` after the start (the wind-up).
	var vfx := Vfx.new()
	holder.add_child(vfx)
	vfx.set_process(false)  # after the node is ready (it re-enables _process on ready)
	var radius := weapon.area * 0.8
	vfx.slash(Vector2.ZERO, 0.0, radius, deg_to_rad(weapon.arc_degrees) * 0.5, weapon.color, style)
	vfx._life[0] = clampf(vfx._max_life[0] + WeaponVisuals.strike_delay(style) - elapsed, 0.0, vfx._max_life[0] + 1.0)
	vfx.queue_redraw()
	# The weapon at its pose (mount to the right of the hero, aimed along +x).
	var pose := WeaponVisuals.melee_pose(progress, style)
	var node := Node2D.new()
	node.position = Vector2(WeaponLayout.MOUNT_RADIUS, 0.0) + Vector2(pose.y, 0.0)
	node.rotation = pose.x
	node.z_index = 6
	holder.add_child(node)
	var icon := Sprite2D.new()
	icon.texture = weapon.icon
	var size_scale := WeaponVisuals.SIZE * weapon.float_scale / weapon.icon.get_width()
	if weapon.icon_diagonal:
		size_scale /= sqrt(2.0)
		icon.rotation = PI / 4.0
	icon.scale = Vector2(size_scale * pose.z, size_scale * (2.0 - pose.z))
	node.add_child(icon)
	var label := Label.new()
	label.text = "%s  %.0f %%" % [weapon.id, progress * 100.0] if at.x == 0.0 else "%.0f %%" % (progress * 100.0)
	label.position = origin + Vector2(-30, 70)
	label.add_theme_font_size_override("font_size", 16)
	add_child(label)
