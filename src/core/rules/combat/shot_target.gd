class_name ShotTarget
extends RefCounted
## A shot into melee selects one member of the connected combat (p. 59).

static func participants(figures: Array[Figure], declared: Figure) -> Array[Figure]:
	var result: Array[Figure] = [declared]
	var i := 0
	while i < result.size():
		for enemy in Contact.enemies_of(figures, result[i]):
			if not result.has(enemy):
				result.append(enemy)
		i += 1
	result.sort_custom(func(a: Figure, b: Figure) -> bool: return a.id < b.id)
	return result


static func randomize(dice: Dice, figures: Array[Figure], declared: Figure) -> Figure:
	var options := participants(figures, declared)
	return options[0] if options.size() == 1 else options[dice.pick(options.size())]
