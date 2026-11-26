class_name JsonFile
extends RefCounted
## Reads JSON content files from res://data.


static func read(path: String) -> Variant:
	var text := FileAccess.get_file_as_string(path)
	if text == "":
		push_error("JsonFile: cannot read " + path)
		return null
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null:
		push_error("JsonFile: bad JSON in " + path)
	return parsed
