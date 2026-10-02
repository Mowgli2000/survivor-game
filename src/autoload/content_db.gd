extends Node
## Registry of all content definitions (.tres) stored under res://data/.
##
## Each subfolder of res://data/ is a category (weapons, enemies, items...).
## A definition is indexed by its `id` property, or by its file name if it has none.
## Systems ask ContentDB for definitions instead of loading paths directly,
## so that save files, shop pools and unlocks only ever reference stable IDs.

const DATA_ROOT := "res://data"

## category (StringName) -> { id (StringName) -> Resource }
var _defs: Dictionary[StringName, Dictionary] = {}


func _ready() -> void:
	reload()


## Rescans res://data/. Called automatically at startup.
func reload(root: String = DATA_ROOT) -> void:
	_defs.clear()
	var dir := DirAccess.open(root)
	if dir == null:
		return
	for category in dir.get_directories():
		var entries: Dictionary = {}
		_scan_folder(root.path_join(category), entries)
		_defs[StringName(category)] = entries


func get_def(category: StringName, id: StringName) -> Resource:
	var entries: Dictionary = _defs.get(category, {})
	return entries.get(id)


func has_def(category: StringName, id: StringName) -> bool:
	return get_def(category, id) != null


## All definitions of a category, in a stable (sorted by id) order.
func get_all(category: StringName) -> Array[Resource]:
	var result: Array[Resource] = []
	var entries: Dictionary = _defs.get(category, {})
	var ids := entries.keys()
	ids.sort()
	for id in ids:
		result.append(entries[id])
	return result


func get_categories() -> Array[StringName]:
	var result: Array[StringName] = []
	result.assign(_defs.keys())
	return result


func _scan_folder(path: String, entries: Dictionary) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for sub in dir.get_directories():
		_scan_folder(path.path_join(sub), entries)
	for file in dir.get_files():
		# Exported builds list resources as "*.tres.remap".
		file = file.trim_suffix(".remap")
		if not (file.ends_with(".tres") or file.ends_with(".res")):
			continue
		var res := load(path.path_join(file))
		if res == null:
			push_error("ContentDB: failed to load %s" % path.path_join(file))
			continue
		var id: StringName = StringName(file.get_basename())
		if "id" in res and res.get("id") != null and String(res.get("id")) != "":
			id = StringName(res.get("id"))
		if entries.has(id):
			push_error("ContentDB: duplicate id '%s' in %s" % [id, path])
			continue
		entries[id] = res
