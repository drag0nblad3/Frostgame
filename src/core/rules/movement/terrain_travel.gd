class_name TerrainTravel
extends RefCounted
## Split travel at profile edges; charge real incline distance and climbing at discontinuities.


static func cost(board: Board,a: Vector2,b: Vector2,mover: Figure = null,running: bool=false) -> float:
	if a.is_equal_approx(b):
		return 0.0
	var cuts: Array[float] = [0.0,1.0]
	var d := b-a
	var bounds:=Rect2(Vector2(minf(a.x,b.x),minf(a.y,b.y)),Vector2(absf(d.x),absf(d.y))).grow(0.002)
	var crosses_terrain:=false
	for p in board.pieces:
		if not (p.kind.walkable_top or p.kind.ground_surface or p.kind.move_mult != 1.0):
			continue
		if not bounds.intersects(p.rect,true):
			continue
		if not Geom.crosses(a,b,p.rect.grow(0.001)) and not p.contains(a) and not p.contains(b):
			continue
		crosses_terrain=true
		if absf(d.x)>0.00001:
			for x: float in [p.rect.position.x,p.rect.end.x]:
				_add(cuts,(x-a.x)/d.x)
		if absf(d.y)>0.00001:
			for y: float in [p.rect.position.y,p.rect.end.y]:
				_add(cuts,(y-a.y)/d.y)
	if not crosses_terrain:
		return a.distance_to(b)
	cuts.sort()
	var previous_surface := board.surface_at(a)
	var previous := board.height_at(a)
	var total := 0.0
	var levitate := running or (mover != null and mover.levitates())
	var expert := mover != null and mover.def.traits.has("expert_climber")
	for i in range(1,cuts.size()):
		var start := a.lerp(b,cuts[i-1])
		var end := a.lerp(b,cuts[i])
		var mid := (start+end)*0.5
		var surface := board.surface_at(mid)
		var h0 := surface.surface_height(start) if surface != null else 0.0
		var h1 := surface.surface_height(end) if surface != null else 0.0
		total += _climb(h0-previous,levitate or expert or _legacy_stair(previous_surface) or _legacy_stair(surface))
		total += Vector2(start.distance_to(end),h1-h0).length()*(1.0 if levitate else board.move_mult_at(mid))
		previous = h1
		previous_surface = surface
	total += _climb(board.height_at(b)-previous,levitate or expert or _legacy_stair(previous_surface) or _legacy_stair(board.surface_at(b)))
	return total


static func _add(cuts: Array[float],t: float) -> void:
	if t<=0.00001 or t>=0.99999:
		return
	for old in cuts:
		if absf(old-t)<0.00001:
			return
	cuts.append(t)


# Existing terraces mark a complete, abstract stair connection. Keep that
# discount when a separate bridge or ground profile activates this solver.
# A real ramp grants normal movement along its slope, not over its side bank.
static func _legacy_stair(p: TerrainPiece) -> bool:
	return p != null and p.kind.stairs and not p.ramp


static func _climb(delta: float,unpenalized: bool) -> float:
	return 0.0 if absf(delta)<0.001 else ceilf(absf(delta))*(1.0 if unpenalized else 2.0)
