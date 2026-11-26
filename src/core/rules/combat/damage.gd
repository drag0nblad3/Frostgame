class_name Damage
extends RefCounted
## Damage from a won fight or shot.


## Winner's total plus weapon damage, minus the loser's Armour; a natural 20
## doubles it (critical hit).
## TODO(rules): check the 2e critical-hit rule (double damage on a natural 20).
static func amount(total: int, weapon_damage: int, armour: int, natural: int) -> int:
	var dmg := maxi(total + weapon_damage - armour, 0)
	if natural == 20:
		dmg *= 2
	return dmg


## Apply damage; returns true if the figure is taken out of action.
static func apply(f: Figure, dmg: int) -> bool:
	f.health -= dmg
	if f.health <= 0:
		f.health = 0
		f.out_of_action = true
	return f.out_of_action
