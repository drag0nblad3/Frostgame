class_name MoveRules
extends RefCounted
## How far a figure may move with one movement action.


## First move action uses the full Move stat; a second one in the same
## activation is at half Move.
## TODO(rules): confirm the half-Move second action and rounding in 2e.
static func allowance(f: Figure) -> float:
	var speed := float(f.def.move)
	if f.treasure_id >= 0:
		speed *= 0.5
	return speed if f.moves_taken == 0 else speed * 0.5


## Figures in combat can't simply walk away.
## TODO(rules): leaving combat (and any free strike) is not modelled yet.
static func can_move(f: Figure, figures: Array[Figure]) -> bool:
	return not Contact.in_combat(figures, f)
