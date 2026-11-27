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


## Shared spatial contact test. Surfaces disambiguate stacked routes;
## physical base overlap still applies across adjacent surface identities.
static func touches_position(f: Figure,at: Vector2,height: float,surface: String="") -> bool:
	return absf(f.elevation-height)<0.5 and (surface.is_empty() or f.surface_id.is_empty() or f.surface_id==surface) and touching(f.pos,at)


static func figures_touch(a: Figure, b: Figure) -> bool:
	if a.ring_side!=b.ring_side:
		return false
	return touches_position(a,b.pos,b.elevation,b.surface_id)
