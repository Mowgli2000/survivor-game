extends GutTest
## ContentDB indexing behaviour, using a throwaway folder in user://.

const TMP_ROOT := "user://test_content_db"


func before_each() -> void:
	_remove_dir(TMP_ROOT)
	DirAccess.make_dir_recursive_absolute(TMP_ROOT.path_join("weapons"))


func after_each() -> void:
	_remove_dir(TMP_ROOT)
	ContentDB.reload()


func test_missing_root_gives_no_categories() -> void:
	ContentDB.reload("user://does_not_exist")
	assert_eq(ContentDB.get_categories().size(), 0)


func test_indexes_resources_by_file_name() -> void:
	ResourceSaver.save(Resource.new(), TMP_ROOT.path_join("weapons/pistol.tres"))
	ResourceSaver.save(Resource.new(), TMP_ROOT.path_join("weapons/axe.tres"))
	ContentDB.reload(TMP_ROOT)
	assert_true(ContentDB.has_def(&"weapons", &"pistol"))
	assert_eq(ContentDB.get_all(&"weapons").size(), 2)
	assert_null(ContentDB.get_def(&"weapons", &"missing"))
	assert_null(ContentDB.get_def(&"unknown_category", &"pistol"))


func _remove_dir(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for sub in dir.get_directories():
		_remove_dir(path.path_join(sub))
	for file in dir.get_files():
		dir.remove(file)
	DirAccess.remove_absolute(path)
