extends GutTest
## SafeFile: crash-safe JSON saves with a backup of the last good file.

const PATH := "user://test_safe_file.json"


func before_each() -> void:
	SafeFile.remove(PATH)


func after_all() -> void:
	SafeFile.remove(PATH)


func test_write_then_read_round_trip() -> void:
	assert_true(SafeFile.write_text(PATH, JSON.stringify({"a": 1})))
	assert_eq(SafeFile.read_json(PATH).get("a"), 1.0)
	assert_false(FileAccess.file_exists(PATH + ".tmp"), "temp file renamed away")


func test_second_write_keeps_the_previous_file_as_backup() -> void:
	SafeFile.write_text(PATH, JSON.stringify({"a": 1}))
	SafeFile.write_text(PATH, JSON.stringify({"a": 2}))
	assert_eq(SafeFile.read_json(PATH).get("a"), 2.0)
	assert_eq(JSON.parse_string(FileAccess.get_file_as_string(PATH + ".bak")).get("a"), 1.0)


func test_corrupt_file_falls_back_to_the_backup() -> void:
	SafeFile.write_text(PATH, JSON.stringify({"a": 1}))
	SafeFile.write_text(PATH, JSON.stringify({"a": 2}))
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("{half writ")
	file.close()
	assert_eq(SafeFile.read_json(PATH).get("a"), 1.0, "last good save")


func test_missing_file_is_no_save_even_with_a_backup() -> void:
	SafeFile.write_text(PATH, JSON.stringify({"a": 1}))
	SafeFile.write_text(PATH, JSON.stringify({"a": 2}))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	assert_eq(SafeFile.read_json(PATH), {}, "deleting the save resets")


func test_profile_survives_a_corrupted_save() -> void:
	SaveService.profile.runs_played = 3
	SaveService.save_profile()
	SaveService.profile.runs_played = 4
	SaveService.save_profile()
	var file := FileAccess.open(SaveService.TEST_PATH, FileAccess.WRITE)
	file.store_string("{crash")
	file.close()
	SaveService.load_profile()
	assert_eq(SaveService.profile.runs_played, 3, "backup of the previous save")
	SafeFile.remove(SaveService.TEST_PATH)
	SaveService.load_profile()
