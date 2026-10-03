extends SceneTree
## Contact sheet of the drawn SVG sprites, to review the art without baking.
## Default: idle_0, walk_1 and walk_5 of every sprite. With --id: every frame of one sprite.
## Usage: Godot.exe --headless --path . -s res://tools/art/preview_sheet.gd -- --out=<png> [--id=drifter]

const ROOT := "res://assets_src/drawn"
const CELL := 192


func _initialize() -> void:
	var out := "user://sprites_preview.png"
	var only := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
		elif arg.begins_with("--id="):
			only = arg.trim_prefix("--id=")
	var frames: Array[Image] = []
	for id in DirAccess.get_directories_at(ROOT):
		if only != "" and id != only:
			continue
		var names: Array[String] = []
		for f in DirAccess.get_files_at(ROOT.path_join(id)):
			if f.ends_with(".svg"):
				names.append(f)
		names.sort()
		var picks: Array[String] = []
		if only != "":
			picks = names
		else:
			for prefix in ["idle_0", "walk_1", "walk_5"]:
				if names.has(prefix + ".svg"):
					picks.append(prefix + ".svg")
		for f in picks:
			var image := Image.new()
			image.load_svg_from_string(FileAccess.get_file_as_string(ROOT.path_join(id).path_join(f)), 0.75)
			image.convert(Image.FORMAT_RGBA8)
			frames.append(image)
	var columns := 9 if only == "" else 7
	var rows := ceili(frames.size() / float(columns))
	var sheet := Image.create(columns * CELL, rows * CELL, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.42, 0.42, 0.62))
	for i in frames.size():
		var f := frames[i]
		sheet.blend_rect(f, Rect2i(Vector2i.ZERO, f.get_size()), Vector2i((i % columns) * CELL, (i / columns) * CELL))
	sheet.save_png(out)
	print("preview: ", out)
	quit()
