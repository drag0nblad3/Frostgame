class_name BattleBoundary
extends RefCounted
## Zero-width scenario boundaries with separate movement and sight policies.
## Entries use Vector2 endpoints and optional trait/spell exemptions.
const EPS := 0.0001


static func _exempt(line: Dictionary,figure: Figure,kind: String="movement") -> bool:
	if figure==null:
		return false
	if figure.def.id in line.get("allow_figures",[]):
		return true
	for spell: String in line.get("allow_"+kind+"_spells",[]):
		if figure.spell_effects.has(spell):
			return true
	for trait_id: String in line.get("allow_traits",[]):
		if figure.def.traits.has(trait_id):
			return true
	for spell: String in line.get("allow_spells",[]):
		if figure.spell_effects.has(spell):
			return true
	return false


static func blocks_segment(lines: Array[Dictionary],a: Vector2,b: Vector2,kind: String,figure: Figure=null) -> bool:
	for line in lines:
		if not line.get(kind,false) or _exempt(line,figure,kind):
			continue
		if kind=="sight" and line.has("sight_exempt_center") and a.distance_to(line["sight_exempt_center"])<=float(line.get("sight_exempt_radius",0.0))+EPS:
			continue
		var start: Vector2=line["a"]
		var end: Vector2=line["b"]
		if Geometry2D.segment_intersects_segment(a,b,start,end)!=null:
			return true
		if Geometry2D.get_closest_point_to_segment(a,start,end).distance_to(a)<EPS or Geometry2D.get_closest_point_to_segment(b,start,end).distance_to(b)<EPS:
			return true
		if Geometry2D.get_closest_point_to_segment(start,a,b).distance_to(start)<EPS or Geometry2D.get_closest_point_to_segment(end,a,b).distance_to(end)<EPS:
			return true
	return false


static func blocks_position(lines: Array[Dictionary],at: Vector2,figure: Figure=null) -> bool:
	for line in lines:
		if not line.get("movement",false) or _exempt(line,figure):
			continue
		if Geometry2D.get_closest_point_to_segment(at,line["a"],line["b"]).distance_to(at)<Figure.BASE_RADIUS-EPS:
			return true
	return false


## Opposite-edge destination for a future wrapping topology.
## Caller decides whether an axis wraps and validates occupancy at landing.
static func wrapped(at: Vector2,size: Vector2,wrap_x: bool,wrap_y: bool) -> Vector2:
	return Vector2(fposmod(at.x,size.x) if wrap_x else at.x,fposmod(at.y,size.y) if wrap_y else at.y)


static func blocks_end(lines: Array[Dictionary],at: Vector2) -> bool:
	for line in lines:
		if line.get("stop",false) and Geometry2D.get_closest_point_to_segment(at,line["a"],line["b"]).distance_to(at)<Figure.BASE_RADIUS-EPS:
			return true
	return false
