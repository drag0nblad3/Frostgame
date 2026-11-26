class_name ScrollActions
extends RefCounted


static func has_scroll(f: Figure, id: String) -> bool:
	for item in f.items:
		if item.get("scroll", "") == id:
			return true
	return false


static func consume(f: Figure, id: String) -> bool:
	for i in f.items.size():
		if f.items[i].get("scroll", "") == id:
			f.items.remove_at(i)
			return true
	return false
