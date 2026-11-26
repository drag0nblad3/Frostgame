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



static func can_break_ice(c: GameController) -> bool:
	var f := c.state.active()
	var token := c.state.treasure(0)
	return c.state.scenario_special == "underground_library" and f != null and token != null and token.frozen and token.on_ground() and c.can_act() and not Contact.in_combat(c.state.figures, f) and not IllusionRules.phantom(f) and absf(f.elevation - c.state.board.height_at(token.pos)) < 0.5 and f.pos.distance_to(token.pos) <= Figure.BASE_RADIUS + TreasureRules.TOKEN_RADIUS + 0.01


static func break_ice(c: GameController) -> bool:
	if not can_break_ice(c):
		return false
	var f := c.state.active()
	var raw := c.dice.d20()
	var success := StatRoll.succeeds(raw, f.effective_fight() + f.roll_penalty(), 14)
	c._spend(f)
	if success:
		c.state.treasure(0).frozen = false
	c.emit("break_ice", {"id": f.id, "roll": raw, "success": success})
	return true


static func exit_distance(s: GameState, at: Vector2) -> float:
	if s.scenario_special != "underground_library":
		return TreasureRules.edge_distance(s.board, at)
	var size := s.board.size
	var distance := INF
	for door: Vector2 in [Vector2(size.x * 0.5, 0), Vector2(size.x * 0.5, size.y), Vector2(0, size.y * 0.5), Vector2(size.x, size.y * 0.5)]:
		distance = minf(distance, at.distance_to(door))
	return distance


static func exit_allowed(s: GameState, at: Vector2,side: int=-1) -> bool:
	if RedKingVeil.active(s):
		return RedKingVeil.exit_allowed(s,at,side)
	if RedKingInvestigations.active(s):
		return RedKingInvestigations.exit_allowed(s,at,side)
	if s.scenario_special != "underground_library":
		return true
	var size := s.board.size
	var margin := Figure.BASE_RADIUS + 0.01
	return ((at.y <= margin or at.y >= size.y - margin) and absf(at.x - size.x * 0.5) <= 3.0) or ((at.x <= margin or at.x >= size.x - margin) and absf(at.y - size.y * 0.5) <= 3.0)


static func library_roll(raw: int, dice: Dice) -> int:
	return dice.d20() if raw in [1, 2, 3, 4, 5, 8, 9, 10, 11, 12, 13] else raw
