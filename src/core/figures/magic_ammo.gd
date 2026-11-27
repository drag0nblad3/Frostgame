class_name MagicAmmo
extends RefCounted
## Single-use Enchant Weapon ammunition; ordinary quivers hold one, Hunter quivers four.
const ITEM := "gear_rk_quiver_of_the_hunter"
const KEY := "enchanted_ammunition"

static func capacity(f: Figure) -> int:
	return 4 if ActiveGear.has(f,ITEM) else 1

static func count(f: Figure) -> int:
	return int(f.used_gear.get(KEY,0))

static func equipped(f: Figure) -> bool:
	return f!=null and f.ranged!=null and f.ranged.id in ["bow","crossbow"]

static func can_enchant(f: Figure) -> bool:
	return equipped(f) and count(f)<capacity(f)

static func add(f: Figure) -> bool:
	if not can_enchant(f):
		return false
	f.used_gear[KEY]=count(f)+1
	return true

static func ready(f: Figure) -> bool:
	return equipped(f) and not MagicEquipment.suppressed(f) and count(f)>0

static func spend(f: Figure) -> bool:
	if not ready(f):
		return false
	f.used_gear[KEY]=count(f)-1
	return true
