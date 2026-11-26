class_name VisualPalette
extends RefCounted
## Visual settings are independent of scenario rules; shared by terrain and lighting.
static var _data: Dictionary = {}


static func for_scenario(id: String) -> Dictionary:
	if _data.is_empty():
		_data = JsonFile.read("res://data/visual_palettes.json")
	if id == "frozen_ruins":
		id = "treasure_skirmish"
	return _data.get(id, _data.get("default", {}))
