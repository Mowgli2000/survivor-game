extends GutTest
## Every localization key must have a non-empty translation in each required locale.

const CSV_PATH := "res://localization/strings.csv"
const REQUIRED_LOCALES: Array[String] = ["en", "fr"]


func test_all_keys_translated() -> void:
	var file := FileAccess.open(CSV_PATH, FileAccess.READ)
	assert_not_null(file, "strings.csv must exist")
	if file == null:
		return
	var header := file.get_csv_line()
	for locale in REQUIRED_LOCALES:
		assert_has(header, locale, "missing locale column '%s'" % locale)
	var seen: Dictionary = {}
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() <= 1 and (row.is_empty() or row[0] == ""):
			continue
		var key := row[0]
		assert_false(seen.has(key), "duplicate key '%s'" % key)
		seen[key] = true
		for locale in REQUIRED_LOCALES:
			var col := header.find(locale)
			var value := row[col] if col < row.size() else ""
			assert_ne(value.strip_edges(), "", "key '%s' has no '%s' text" % [key, locale])


func test_translations_loaded_at_runtime() -> void:
	TranslationServer.set_locale("fr")
	assert_eq(tr("UI_PLAY"), "Jouer")
	TranslationServer.set_locale("en")
	assert_eq(tr("UI_PLAY"), "Play")
