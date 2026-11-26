class_name StatRoll
extends RefCounted
## Target-number stat tests and Will resistance, pp. 44 and 65.

static func succeeds(natural: int, modifier: int, target: int, empowerment: int = 0) -> bool:
	if natural == 20:
		return true
	if natural == 1:
		return false
	return natural + mini(modifier, 10) + maxi(empowerment, 0) >= target


static func health_test(f: Figure,natural: int,target: int) -> bool:
	return succeeds(natural,f.health+MagicEquipment.bonus(f,"health_test")+f.roll_penalty(),target)
