class_name MoveRules
extends RefCounted
## How far a figure may move with one movement action.


## First move action uses the full Move stat; a second one in the same
## activation is at half Move.
## TODO(rules): confirm the half-Move second action and rounding in 2e.
static func allowance(f: Figure) -> float:
	if f.moves_taken == 0:
		return float(f.def.move)
	return f.def.move / 2.0


## Figures in combat can't simply walk away.
## TODO(rules): leaving combat (and any free strike) is not modelled yet.
static func can_move(f: Figure, figures: Array[Figure]) -> bool:
	return not Contact.in_combat(figures, f)
