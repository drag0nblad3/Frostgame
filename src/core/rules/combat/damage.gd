class_name Damage
extends RefCounted
## Combat damage; optional criticals (Second Edition p. 55).

static func amount(total: int, weapon_damage: int, armour: int, natural: int, critical_hits: bool = false) -> int:
	var dmg := maxi(total + weapon_damage - armour, 0)
	if critical_hits and natural == 20:
		dmg += 5
	return dmg


## Apply damage; returns true if the figure is taken out of action.
static func apply(f: Figure, dmg: int) -> bool:
	f.health -= dmg
	if f.health <= 0:
		f.health = 0
		f.out_of_action = true
	return f.out_of_action
