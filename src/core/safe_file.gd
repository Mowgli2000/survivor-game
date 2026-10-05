class_name SafeFile
## Crash-safe text files for the JSON saves (profile, settings). A write goes to
## "<path>.tmp" first, the previous file is kept as "<path>.bak", then the temp
## file replaces the real one: a crash mid-write never leaves a half-written
## save. Reading falls back to the backup when the file is invalid (a missing
## file means "no save yet", so deleting it really resets).
## Example: `SafeFile.write_text("user://profile.json", json)`.


## Writes `text` to `path` safely. Returns false (and keeps the old file) on failure.
static func write_text(path: String, text: String) -> bool:
	var tmp := path + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.close()
	var absolute := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		DirAccess.copy_absolute(absolute, absolute + ".bak")
	# The rename replaces the old file in one step; if the platform refuses,
	# remove it first (the backup holds it meanwhile).
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), absolute) == OK:
		return true
	DirAccess.remove_absolute(absolute)
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), absolute) == OK


## Parsed JSON dictionary of `path`, or of its backup when the file is
## unreadable. Empty dictionary when there is no file or nothing valid.
static func read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	for candidate in [path, path + ".bak"]:
		if not FileAccess.file_exists(candidate):
			continue
		# JSON.parse() (not parse_string) reports errors without an engine error log.
		var json := JSON.new()
		if json.parse(FileAccess.get_file_as_string(candidate)) == OK and json.data is Dictionary:
			if candidate != path:
				push_warning("SafeFile: %s unreadable, using %s" % [path, candidate])
			return json.data
	return {}


## Deletes `path` and its backup / temp files (tests).
static func remove(path: String) -> void:
	for candidate in [path, path + ".bak", path + ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate))
