class_name Contact
extends RefCounted
## Base contact between figures. Two 1" bases count as touching when their
## centres are within CONTACT (a quarter-inch gap allowed for free placement).

const CONTACT := 1.25
## Bases closer than this would overlap.
const OVERLAP := 0.95


static func touching(a: Vector2, b: Vector2) -> bool:
	return a.distance_to(b) <= CONTACT


## Enemies in base contact with `f`.
static func enemies_of(figures: Array[Figure], f: Figure) -> Array[Figure]:
	var out: Array[Figure] = []
	for o in figures:
		if o.in_play() and o.side != f.side and touching(o.pos, f.pos):
			out.append(o)
	return out


static func in_combat(figures: Array[Figure], f: Figure) -> bool:
	return not enemies_of(figures, f).is_empty()
