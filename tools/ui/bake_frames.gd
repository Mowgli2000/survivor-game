extends SceneTree
## Rasterizes assets_src/ui_frames/*.svg to assets/ui/frames/*.png (1:1).
## Usage: Godot.exe --headless --path . -s res://tools/ui/bake_frames.gd [-- --scale=1]


func _initialize() -> void:
	var scale := 1.0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scale="):
			scale = float(arg.trim_prefix("--scale="))
	var src := ProjectSettings.globalize_path("res://assets_src/ui_frames")
	var dst := ProjectSettings.globalize_path("res://assets/ui/frames")
	DirAccess.make_dir_recursive_absolute(dst)
	for file in DirAccess.get_files_at(src):
		if not file.ends_with(".svg"):
			continue
		var image := Image.new()
		var err := image.load_svg_from_string(FileAccess.get_file_as_string(src + "/" + file), scale)
		if err != OK:
			push_error("SVG failed: " + file)
			continue
		image.save_png(dst + "/" + file.get_basename() + ".png")
		print("%s %dx%d" % [file, image.get_width(), image.get_height()])
	quit()
