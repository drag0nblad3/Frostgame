class_name ScenarioGenie
extends RefCounted
## A unique wandering demon tied to the first discovery of its lamp (p. 149).


static func first_pickup(c: GameController, finder: Figure, token: TreasureToken) -> void:
	var s := c.state
	if s.scenario_special != "genie_in_the_bottle" or s.lamp_token >= 0 or s.creature_db == null:
		return
	var collected := 0
	for t in s.treasures:
		if t.ever_collected:
			collected += 1
	if collected < s.treasures.size() and c.dice.d20() < 15:
		return
	var grid := MoveGrid.new(s.board, null, s.figures)
	var candidates: Array[Vector2] = []
	var center := MovePlanner.node_at(finder.pos)
	for dx in range(-8, 9):
		for dy in range(-8, 9):
			var node := center + Vector2i(dx, dy)
			var at := MoveGrid.to_pos(node)
			if not grid.open(node):
				continue
			var dist := at.distance_to(finder.pos)
			if dist > 4.0 or absf(s.board.height_at(at) - finder.elevation) >= 0.5:
				continue
			var closer := true
			for other in s.figures:
				if other != finder and other.in_play() and absf(other.elevation - finder.elevation) < 0.5 and other.pos.distance_to(at) <= dist:
					closer = false
					break
			if closer:
				candidates.append(at)
	if candidates.is_empty():
		# Crowded sites use the nearest unoccupied node, never overlap a base.
		for dx in range(-8, 9):
			for dy in range(-8, 9):
				var node := center + Vector2i(dx, dy)
				if grid.open(node):
					candidates.append(MoveGrid.to_pos(node))
	if candidates.is_empty():
		return
	candidates.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		return absf(a.distance_to(finder.pos) - 1.75) < absf(b.distance_to(finder.pos) - 1.75))
	var genie := c._encounters._spawn_at("genie", candidates[0])
	s.lamp_token = token.id
	s.genie_id = genie.id
	c.emit("genie_released", {"id": genie.id, "side": finder.side, "treasure": token.id, "xp": 30})


static func record_kill(c: GameController, victim: Figure, by: Figure) -> void:
	var s := c.state
	if s.scenario_special != "genie_in_the_bottle" or by.id != s.genie_id or victim == by or victim.original_side < 0:
		return
	s.genie_kills += 1
	if s.genie_kills == 3:
		c.emit("genie_flee", {"id": by.id})


static func flee(c: GameController, f: Figure) -> bool:
	var s := c.state
	if f.id != s.genie_id or s.genie_kills < 3 or f.side >= 0:
		return false
	if Contact.in_combat(s.figures, f):
		return false
	if f.moves_taken == 0 and c.can_move():
		var r := c.reach()
		var best := Vector2i(-1, -1)
		var field := MovePlanner.exit_field(s)
		var distance: float = field.get(MovePlanner.node_at(f.pos), INF)
		for n in r.nodes():
			var d: float = field.get(n, INF)
			if d < distance:
				distance = d
				best = n
		if best.x >= 0:
			c.move_to(best)
			if c.awaiting_reaction() or not f.in_play():
				return true
	if Contact.in_combat(s.figures, f):
		return false
	if TreasureRules.edge_distance(s.board, f.pos) <= Figure.BASE_RADIUS + 0.01 and f.elevation < 0.5:
		f.exited = true
		f.actions_left = 0
		c.emit("exit", {"id": f.id})
		c.emit("genie_escaped", {"id": f.id})
		return true
	var target: Figure = null
	for t in s.figures:
		if t.side >= 0 and c.can_shoot(t.id) and (target == null or Shooting.distance(f, t) < Shooting.distance(f, target)):
			target = t
	if target != null:
		c.shoot(target.id)
	return true
