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
			if cost > allowance + 0.001 or not s.board.can_stand(at, Figure.BASE_RADIUS):
				continue
			var clear := true
			if RedKingBridge.crosses_void(s.board,f.pos,at):
				continue
			if BattleBoundary.blocks_segment(s.board.boundaries,f.pos,at,"movement",f):
				continue
			if RedKingSinkhole.active(s) and Geometry2D.get_closest_point_to_segment(RedKingSinkhole.center(s),f.pos,at).distance_to(RedKingSinkhole.center(s))<RedKingSinkhole.RADIUS+Figure.BASE_RADIUS-0.001:
				continue
			for other in s.figures:
				if other != f and other.in_play() and absf(other.elevation - s.board.height_at(at)) < 0.5 and other.pos.distance_to(at) < Contact.OVERLAP:
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
					if other != f and other.in_play() and absf(other.elevation - s.board.height_at(at)) < 0.5 and other.side != f.side and Contact.touching(other.pos, at) and not IllusionRules.visible_to(s.figures, f, other):
						clear = false
						break
			if clear:
				result.cost[n] = cost
				result.prev[n] = null
	return result
