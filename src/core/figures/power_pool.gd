class_name PowerPool
extends RefCounted
## Rechargeable power is used first, then permanent orb charges, then Health.

const CAPACITY := {"gear_staff_power1": 1, "gear_staff_power2": 2, "gear_staff_power3": 3, "gear_ring_power1": 1, "gear_wand_power1": 1, "gear_orb_power6": 6}
const ORB := "gear_orb_power6"


static func remaining(item: Dictionary) -> int:
	var id := str(item.get("gear", ""))
	return int(item.get("power_left", CAPACITY.get(id, 0)))


static func available(f: Figure) -> int:
	if f.def.role not in ["wizard", "apprentice"] or ScenarioNull.muted(f):
		return 0
	var total := 0
	for item in f.items:
		total += remaining(item)
	return total


static func spend(f: Figure, amount: int) -> int:
	var left := mini(amount, available(f))
	var spent := left
	for orb in [false, true]:
		for item in f.items:
			if (item.get("gear", "") == ORB) != orb:
				continue
			var count := mini(left, remaining(item))
			if count > 0:
				item["power_left"] = remaining(item) - count
				left -= count
			if left == 0:
				return spent
	return spent
