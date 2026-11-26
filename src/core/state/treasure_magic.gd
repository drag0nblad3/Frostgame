class_name TreasureMagic
extends RefCounted

var c: GameController


func _init(controller: GameController) -> void:
	c = controller


func can_target(f: Figure, id: String, token: TreasureToken) -> bool:
	var s := c.state
	if not token.unresolved():
		return false
	if id == "telekinesis":
		return token.on_ground() and not s.museum and (token.id != 0 or token.ever_collected) and Vector2(f.pos.distance_to(token.pos), f.elevation - s.board.height_at(token.pos)).length() <= 16.0 and LineOfSight.check(s.board, f.pos, token.pos).clear
	if id == "fools_gold":
		var carrier := s.figure(token.carrier_id)
		return carrier != null and carrier.in_play() and IllusionRules.visible_to(s.figures, f, carrier) and LineOfSight.check(s.board, f.pos, carrier.pos).clear
	return false


func origin(token: TreasureToken) -> Vector2:
	var carrier := c.state.figure(token.carrier_id)
	return token.pos if carrier == null else carrier.pos


func can_place(f: Figure, id: String, token: TreasureToken, at: Vector2) -> bool:
	if not can_target(f, id, token):
		return false
	var s := c.state
	var from := origin(token)
	var limit := 6.0 if id == "telekinesis" else 4.0
	if Vector2(from.distance_to(at), s.board.height_at(from) - s.board.height_at(at)).length() > limit + 0.001 or not s.board.can_stand(at, TreasureRules.TOKEN_RADIUS):
		return false
	if not LineOfSight.check(s.board, f.pos, at).clear:
		return false
	for t in s.figures:
		if t.in_play() and absf(t.elevation - s.board.height_at(at)) < 0.5 and t.pos.distance_to(at) < Figure.BASE_RADIUS + TreasureRules.TOKEN_RADIUS:
			return false
	if id == "telekinesis":
		for i in range(1, maxi(2, ceili(from.distance_to(at) * 4))):
			if not LineOfSight.check(s.board, f.pos, from.lerp(at, float(i) / maxi(2, ceili(from.distance_to(at) * 4)))).clear:
				return false
	return true


func points(f: Figure, id: String, token: TreasureToken, first_only: bool = false) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var center := MovePlanner.node_at(origin(token))
	var radius := 12 if id == "telekinesis" else 8
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var at := MoveGrid.to_pos(center + Vector2i(dx, dy))
			if can_place(f, id, token, at):
				out.append(at)
				if first_only:
					return out
	return out


func apply(f: Figure, id: String, token: TreasureToken, at: Vector2, roll: int) -> void:
	if id == "fools_gold":
		var t := c.state.figure(token.carrier_id)
		c._magic.resistance.attempt(t, roll, _drop_result.bind(t, at))
	else:
		token.pos = at
		c.emit("treasure_moved", {"treasure": token.id, "at": at})


func _drop_result(success: bool, t: Figure, at: Vector2) -> void:
	if not success and t.in_play() and t.treasure_id >= 0:
		c._loot._drop(t, at)
