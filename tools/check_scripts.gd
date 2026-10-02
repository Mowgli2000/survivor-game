extends SceneTree
## Loads every GDScript under res://src and res://tests to catch compile errors.
## Run through tools/check_scripts.ps1 (autoloads are available in this mode).

const ROOTS: Array[String] = ["res://src", "res://tests"]


func _initialize() -> void:
	var scripts: Array[String] = []
	for root in ROOTS:
		_collect(root, scripts)
	var failed: Array[String] = []
	for path in scripts:
		var script := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as GDScript
		if script == null or not script.can_instantiate() and not script.is_abstract():
			failed.append(path)
	if failed.is_empty():
		print("%d scripts OK." % scripts.size())
		quit(0)
	else:
		printerr("Script errors in:")
		for path in failed:
			printerr("  " + path)
		quit(1)


func _collect(path: String, out: Array[String]) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for sub in dir.get_directories():
		_collect(path.path_join(sub), out)
	for file in dir.get_files():
		if file.ends_with(".gd"):
			out.append(path.path_join(file))
