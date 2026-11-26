class_name CastingRoll
extends RefCounted
## Pure casting arithmetic, Second Edition pp. 29, 44, 62–65.
## Effect selection and spending Health belong to the controller.

static func modified(natural: int, modifier: int, apprentice: bool = false) -> int:
	return natural + mini(modifier - (2 if apprentice else 0), 10)


static func max_empowerment(total: int, health: int, out_of_game: bool = false, ceiling: int = 18) -> int:
	if out_of_game:
		return 0
	return mini(maxi(health, 0), maxi(ceiling - total, 0))


static func failure_damage(shortfall: int, out_of_game: bool = false) -> int:
	if out_of_game or shortfall < 5:
		return 0
	if shortfall < 10:
		return 1
	if shortfall < 20:
		return 2
	return 5


## Generic casting only; individual spells may override the empowerment cap or natural rolls.
static func resolve(total: int, casting_number: int, empowerment: int, health: int, out_of_game: bool = false, ceiling: int = 18) -> Dictionary:
	var spent := clampi(empowerment, 0, max_empowerment(total, health, out_of_game, ceiling))
	var final_roll := total + spent
	var success := final_roll >= casting_number
	return {"success": success, "roll": maxi(final_roll, 14) if success else final_roll, "health_spent": spent, "failure_damage": failure_damage(casting_number - final_roll, out_of_game)}
