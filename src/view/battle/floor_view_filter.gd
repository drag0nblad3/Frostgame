class_name FloorViewFilter
extends RefCounted
## A view category is not a surface identity. Hundreds of derived climbing
## nodes share one filter while ordinary named floors remain selectable.
const CLIMBING := "climb:*"

static func matches(selected: String,id: String) -> bool:
	return selected.is_empty() or selected==id or (selected==CLIMBING and id.begins_with("climb:"))

static func has_climbing(layout: FloorLayout) -> bool:
	for s in layout.surfaces:
		if s.id.begins_with("climb:"):
			return true
	return false

static func valid(layout: FloorLayout,selected: String) -> bool:
	return selected.is_empty() or (selected==CLIMBING and has_climbing(layout)) or layout.index_of(selected)>=0
