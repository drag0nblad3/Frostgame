class_name ScenarioObjectives
extends RefCounted
## Scenario-specific actions and creature emergence.


static func well(s: GameState) -> TerrainPiece:
	if s.scenario_special == "dreams_well":
		for p in s.board.pieces:
			if p.kind.id == "dreams_well":
				return p
	return null


static func inside_well(s: GameState, at: Vector2) -> bool:
	var p := well(s)
	return p != null and p.contains(at)


static func can_drink(c: GameController) -> bool:
	var f := c.state.active()
	var p := well(c.state)
	if f == null or p == null or not c.can_act() or f.def.role not in ["wizard", "apprentice"] or c.state.well_drinkers.has(f.id) or Contact.in_combat(c.state.figures, f):
		return false
	return f.elevation < 0.5 and f.pos.distance_to(p.rect.get_center()) <= p.rect.size.x * 0.5 + Figure.BASE_RADIUS + 0.1


static func drink(c: GameController) -> bool:
	if not can_drink(c):
		return false
	var f := c.state.active()
	c._spend(f)
	c.state.well_drinkers[f.id] = true
	c.emit("well_drink", {"id": f.id, "side": f.side, "xp": 50 if f.def.role == "wizard" else 30})
	return true


static func spawn_worm(c: GameController) -> void:
	var s := c.state
	if s.scenario_special != "worm_hunts" or s.worm_spawned or s.creature_db == null:
		return
	var collected := 0
	var candidates: Array[TreasureToken] = []
	for token in s.treasures:
		if token.ever_collected:
			collected += 1
		if token.unresolved():
			candidates.append(token)
	if candidates.is_empty() or c.dice.d20() + collected < 16:
		return
	var token := candidates[c.dice.pick(candidates.size())]
	var carrier := s.figure(token.carrier_id)
	var origin := carrier.pos if carrier != null else token.pos
	var grid := MoveGrid.new(s.board, null, s.figures)
	var center := MovePlanner.node_at(origin)
	var points: Array[Vector2i] = []
	for x in range(-3, 4):
		for y in range(-3, 4):
			var node := center + Vector2i(x, y)
			var dist := MoveGrid.to_pos(node).distance_to(origin)
			if dist >= 0.75 and dist <= 1.5 and grid.open(node) and absf(s.board.height_at(MoveGrid.to_pos(node)) - s.board.height_at(origin)) < 0.5:
				points.append(node)
	if points.is_empty():
		return
	points.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return MoveGrid.to_pos(a).distance_to(origin) < MoveGrid.to_pos(b).distance_to(origin))
	var worm := c._encounters._spawn_at("giant_worm", MoveGrid.to_pos(points[0]))
	s.worm_spawned = true
	c.emit("worm_emerges", {"id": worm.id, "treasure": token.id})
