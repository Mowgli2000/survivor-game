extends SceneTree
## Contact sheet of a character puppet (ADR 0020): idle, walk cycle, hit and
## death poses side by side, at 2x the in-game size, next to the baked sprite.
## Needs a window (not --headless):
##   Godot.exe --path . -s res://tools/art/rig_preview.gd -- --character=ronin --out=<png>

const CELL := Vector2(170, 330)
const SCALE := 2.0


func _initialize() -> void:
	var character_id := "ronin"
	var out := "user://rig_preview.png"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--character="):
			character_id = arg.trim_prefix("--character=")
		elif arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	var data: CharacterData = load("res://data/characters/%s.tres" % character_id)
	var height := 16.0 * Player.SPRITE_HEIGHT_PER_RADIUS * data.sprite_scale * SCALE
	# Poses: [label, walk steps, hurt, death steps]
	var poses := [["idle", 0, 0.0, 0, 0.0], ["idle", 0, 0.0, 0, 1.4]]
	for k in 8:
		poses.append(["walk", k, 0.0, 0, 0.0])
	poses.append(["hit", 0, 1.0, 0, 0.0])
	for k in [1, 2, 4, 8]:
		poses.append(["death", 0, 0.0, k, 0.0])
	# Own viewport: exact pixels, whatever the window stretch.
	var viewport := SubViewport.new()
	viewport.size = Vector2i(roundi(CELL.x * (poses.size() + 1)), roundi(CELL.y))
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(viewport)
	var root := Node2D.new()
	viewport.add_child(root)
	var bg := ColorRect.new()
	bg.color = Color(0.42, 0.4, 0.62)
	bg.size = Vector2(viewport.size)
	root.add_child(bg)
	# The baked sprite, first cell (reference).
	var sheet: SpriteSheet = load("res://assets/sprites/%s.tres" % data.sprite_id)
	var ref := Sprite2D.new()
	ref.texture = sheet.texture
	ref.region_enabled = true
	ref.region_rect = Rect2(sheet.origin, sheet.cell_size)
	ref.scale = Vector2.ONE * height / sheet.cell_size.y
	ref.position = Vector2(CELL.x * 0.5, CELL.y - 20.0 - height * 0.5)
	root.add_child(ref)
	for i in poses.size():
		var pose: Array = poses[i]
		var rig := CharacterRig.new()
		rig.setup(data.rig)
		root.add_child(rig)
		rig.position = Vector2(CELL.x * (i + 1.5), CELL.y - 20.0)
		rig.scale = Vector2.ONE * height / data.rig.height
		rig.animate(pose[4], 0.0, 0.0)
		# Walk: blend in, then step to 1/8 of a cycle per frame.
		if pose[0] == "walk":
			for s in 30:
				rig.animate(1.0 / 60.0, 1.0, 0.0)
			var step := 1.0 / (CharacterRig.WALK_RATE * 8.0)
			for s in pose[1]:
				rig.animate(step, 1.0, 0.0)
		if pose[2] > 0.0:
			rig.flash = 1.0
			rig.animate(0.0, 0.0, pose[2])
		if pose[3] > 0:
			rig.die()
			for s in pose[3]:
				rig.animate(CharacterRig.DEATH_TIME / 8.0, 0.0, 0.0)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png(out)
	print("saved ", ProjectSettings.globalize_path(out))
	quit()
