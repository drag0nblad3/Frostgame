class_name MoveRules
extends RefCounted
## How far a figure may move with one movement action.


## First move action uses the full Move stat; a second one in the same
## activation is at half Move.
## TODO(rules): confirm the half-Move second action and rounding in 2e.
static func allowance(f: Figure) -> float:
	var speed := float(f.effective_move())
	if f.carries_normal_treasure() and not RuleHooks.any("treasure_no_slowdown", [f]):
		if RuleHooks.any("treasure_light_slowdown", [f]):
			speed=maxf(1.0,speed-1.0)
		else:
			speed *= 0.5
	return speed if f.moves_taken == 0 else speed * 0.5


## Figures in combat can't simply walk away.
## TODO(rules): leaving combat (and any free strike) is not modelled yet.
static func can_move(f: Figure, figures: Array[Figure]) -> bool:
	return not f.spell_effects.has("bones_of_the_earth") and not Contact.in_combat(figures, f)
