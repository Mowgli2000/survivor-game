class_name LocalizationKeys
## Test helper: reads localization/strings.csv.

const CSV_PATH := "res://localization/strings.csv"


## Returns key -> { locale -> text }.
static func load_table() -> Dictionary:
	var table := {}
	var file := FileAccess.open(CSV_PATH, FileAccess.READ)
	if file == null:
		return table
	var header := file.get_csv_line()
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.is_empty() or row[0] == "":
			continue
		var entry := {}
		for col in range(1, header.size()):
			entry[header[col]] = row[col] if col < row.size() else ""
		table[row[0]] = entry
	return table
