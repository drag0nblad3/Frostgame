class_name ActiveGear
extends RefCounted


static func has(f: Figure, id: String) -> bool:
	for item in f.items:
		if item.get("gear", "") == id:
			return true
	return false


static func ready(f: Figure, id: String) -> bool:
	return f != null and not MagicEquipment.suppressed(f) and has(f, id) and not f.used_gear.has(id)


static func spend(f: Figure, id: String) -> bool:
	if not ready(f, id):
		return false
	f.used_gear[id] = true
	return true


static func casting_bonus(f: Figure, id: String) -> int:
	if MagicEquipment.suppressed(f):
		return 0
	for item in f.items:
		if item.get("gear", "") == "gear_staff_casting" and item.get("casting_spell", "") == id and not f.destroyed_weapons.has("staff"):
			return 1
	return 0
