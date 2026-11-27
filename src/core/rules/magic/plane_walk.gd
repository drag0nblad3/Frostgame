class_name PlaneWalk
extends RefCounted


static func penalty(f: Figure, turn: int) -> int:
	return -5 * mini(3, f.plane_attempts) if f.last_plane_attempt == turn - 1 else 0


static func record(f: Figure, turn: int) -> void:
	f.plane_attempts = f.plane_attempts + 1 if f.last_plane_attempt == turn - 1 else 1
	f.last_plane_attempt = turn


static func reach(s: GameState, f: Figure, phased: bool = true) -> MoveReach:
	var result := MoveReach.new()
	result.start = f.pos
	var allowance := MoveRules.allowance(f)
	var center := MovePlanner.node_at(f.pos)
	var radius := ceili(allowance / MoveGrid.STEP) + 1
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			var n := center + Vector2i(x, y)
			var at := MoveGrid.to_pos(n)
			var cost := Vector2(f.pos.distance_to(at), f.elevation - s.board.height_at(at)).length()
			if cost > allowance + 0.001 or not s.board.can_stand(at, Figure.BASE_RADIUS) or BattleBoundary.blocks_end(s.board.boundaries,at):
				continue
			var clear := true
			if RedKingBridge.crosses_void(s.board,f.pos,at):
				continue
			if BattleBoundary.blocks_segment(s.board.boundaries,f.pos,at,"movement",f):
				continue
			if RedKingSinkhole.active(s) and Geometry2D.get_closest_point_to_segment(RedKingSinkhole.center(s),f.pos,at).distance_to(RedKingSinkhole.center(s))<RedKingSinkhole.RADIUS+Figure.BASE_RADIUS-0.001:
				continue
			for other in s.figures:
				if other != f and other.ring_side==f.ring_side and other.in_play() and absf(other.elevation - s.board.height_at(at)) < 0.5 and other.pos.distance_to(at) < Contact.OVERLAP:
					clear = false
					break
			if clear and not phased:
				var steps := maxi(1, ceili(f.pos.distance_to(at) / 0.25))
				for i in range(1, steps + 1):
					var sample := f.pos.lerp(at, float(i) / steps)
					if TerrainMagic.ward_blocks(s.board, f, sample):
						clear = false
						break
				for other in s.figures:
					if other != f and other.ring_side==f.ring_side and other.in_play() and absf(other.elevation - s.board.height_at(at)) < 0.5 and other.side != f.side and Contact.touching(other.pos, at) and not IllusionRules.visible_to(s.figures, f, other):
						clear = false
						break
			if clear:
				result.cost[n] = cost
				result.prev[n] = null
	return result


static func uses_direct(f: Figure) -> bool:
	return f.spell_effects.has("plane_walk") or f.spell_effects.has("potion_burrowing") or f.def.traits.has("ethereal") or f.def.traits.has("burrowing")


## Same straight-distance allowance as exposed terrain. Horizontal phasing
## may traverse masonry, but cannot substitute for a climb through a ceiling.
static func floor_reach(s: GameState,f: Figure) -> LayeredReach:
	var layout:=s.board.floor_geometry()
	var result:=LayeredReach.new()
	result.start=layout.node(f.surface_id,f.pos)
	if not layout.standable(result.start):
		return result
	var origin:=Vector3(f.pos.x,f.elevation,f.pos.y)
	var allowance:=MoveRules.allowance(f)
	var phased:=f.spell_effects.has("plane_walk")
	result.cost[result.start]=0.0
	for n in BattlePlacement.nodes(s.board,f.pos,allowance):
		if n==result.start or not layout.standable(n):
			continue
		var at:=layout.point(n)
		var dest:=layout.world(n)
		var cost:=origin.distance_to(dest)
		if cost>allowance+0.001 or not is_equal_approx(dest.y,origin.y) or s.board.over_void(at,Figure.BASE_RADIUS) or BattleBoundary.blocks_end(s.board.boundaries,at) or BattleBoundary.blocks_segment(s.board.boundaries,f.pos,at,"movement",f):
			continue
		var legal:=true
		for other in s.figures:
			if other==f or other.ring_side!=f.ring_side or not other.in_play() or absf(other.elevation-dest.y)>=0.5:
				continue
			if other.pos.distance_to(at)<Contact.OVERLAP or (not phased and other.side!=f.side and Contact.touching(other.pos,at) and not IllusionRules.visible_to(s.figures,f,other)):
				legal=false
				break
		if not legal:
			continue
		var steps:=maxi(1,ceili(cost*4.0))
		for i in range(1,steps+1):
			var point:=origin.lerp(dest,float(i)/steps)
			var sample:=Vector2(point.x,point.z)
			if s.board.over_void(sample,Figure.BASE_RADIUS) or ScenarioNull.field_at(s.board,sample) or (not phased and TerrainMagic.ward_blocks(s.board,f,sample,point.y)):
				legal=false
				break
		if legal:
			result.cost[n]=cost
			result.prev[n]=result.start
	return result
