class_name PowerPool
extends RefCounted
## Rechargeable power is used first, then permanent orb charges, then Health.

const GEM := "gear_rk_pulsing_gem"
const BRILLIANT := "gear_rk_wand_of_brilliant_power_3"
const CAPACITY := {"gear_rk_pulsing_gem":4,"gear_rk_wand_of_brilliant_power_3":3,"gear_staff_power1": 1, "gear_staff_power2": 2, "gear_staff_power3": 3, "gear_ring_power1": 1, "gear_wand_power1": 1, "gear_orb_power6": 6}
const ORB := "gear_orb_power6"


static func remaining(item: Dictionary) -> int:
	var id := str(item.get("gear", ""))
	return int(item.get("power_left", CAPACITY.get(id, 0)))


static func words_only(f: Figure,spell: String) -> bool:
	return spell in ["draining_word","power_word"] and ActiveGear.has(f,BRILLIANT) and not MagicEquipment.suppressed(f)


static func cast_resources(f: Figure,spell: String) -> int:
	return (0 if words_only(f,spell) else maxi(0,f.health))+available(f,spell)


static func available(f: Figure,spell: String="") -> int:
	if f.def.role not in ["wizard", "apprentice"] or MagicEquipment.suppressed(f):
		return 0
	var total := 0
	for item in f.items:
		if item.get("gear","")==GEM and spell!="blink":
			continue
		if words_only(f,spell) and item.get("gear","")!=BRILLIANT:
			continue
		total += remaining(item)
	return total


static func spend(f: Figure, amount: int,spell: String="") -> int:
	var left := mini(amount,available(f,spell))
	var spent := left
	for orb in [false, true]:
		for item in f.items:
			if item.get("gear","")==GEM and spell!="blink":
				continue
			if words_only(f,spell) and item.get("gear","")!=BRILLIANT:
				continue
			if (item.get("gear", "") == ORB) != orb:
				continue
			var count := mini(left, remaining(item))
			if count > 0:
				item["power_left"] = remaining(item) - count
				if item.get("gear","")==GEM:
					f.used_gear["rk_gem_glow"]=int(f.used_gear.get("rk_gem_glow",0))+1
				left -= count
			if left == 0:
				return spent
	return spent
