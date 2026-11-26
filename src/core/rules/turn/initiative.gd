class_name Initiative
extends RefCounted
## Each turn every player rolls a d20; the highest acts first in every phase,
## then the rest in descending order. Ties for the lead are rerolled.
## TODO(rules): check how 2e orders 3+ players after the winner.


## Returns {order: Array[int] of sides, rolls: Array[int] last roll per side}.
static func roll(dice: Dice, sides: int, bonuses: Dictionary = {}) -> Dictionary:
	var rolls: Array[int] = []
	while true:
		rolls.clear()
		for s in sides:
			rolls.append(dice.d20() + int(bonuses.get(s, 0)))
		var best: int = rolls.max()
		if rolls.count(best) == 1:
			break
	var order: Array[int] = []
	for s in sides:
		order.append(s)
	order.sort_custom(func(a: int, b: int) -> bool: return rolls[a] > rolls[b] or (rolls[a] == rolls[b] and a < b))
	return {"order": order, "rolls": rolls}
