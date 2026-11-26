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
	if f.spell_effects.has("plane_walk"):
		return out
	for o in figures:
		if o.in_play() and not o.spell_effects.has("plane_walk") and o.side != f.side and figures_touch(o, f):
			out.append(o)
	return out


static func in_combat(figures: Array[Figure], f: Figure) -> bool:
	return not enemies_of(figures, f).is_empty()


static func figures_touch(a: Figure, b: Figure) -> bool:
	if not a.surface_id.is_empty() and not b.surface_id.is_empty() and a.surface_id!=b.surface_id:
		return false
	return absf(a.elevation - b.elevation) < 0.5 and touching(a.pos, b.pos)
