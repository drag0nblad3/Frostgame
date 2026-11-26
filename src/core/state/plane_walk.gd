class_name PlaneWalk
extends RefCounted


static func penalty(f: Figure, turn: int) -> int:
	return -5 * mini(3, f.plane_attempts) if f.last_plane_attempt == turn - 1 else 0


static func record(f: Figure, turn: int) -> void:
	f.plane_attempts = f.plane_attempts + 1 if f.last_plane_attempt == turn - 1 else 1
	f.last_plane_attempt = turn


static func reach(s: GameState, f: Figure) -> MoveReach:
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
			for other in s.figures:
				if other != f and other.in_play() and absf(other.elevation - s.board.height_at(at)) < 0.5 and other.pos.distance_to(at) < Contact.OVERLAP:
					clear = false
					break
			if clear:
				result.cost[n] = cost
				result.prev[n] = null
	return result
