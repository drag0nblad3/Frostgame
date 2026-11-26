class_name ScrollActions
extends RefCounted


static func has_scroll(f: Figure, id: String) -> bool:
	for item in f.items:
		if item.get("scroll", "") == id:
			return true
	return false


static func consume(f: Figure, id: String) -> bool:
	return consume_roll(f,id)>0


static func consume_roll(f: Figure,id: String) -> int:
	var index := RedKingMaterials.item_index(f.items,"scroll",id)
	if index<0:
		return 0
	var roll := 15 if f.items[index].get("enchanted",false) else 14
	f.items.remove_at(index)
	return roll
