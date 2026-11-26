class_name ScenarioSites
extends RefCounted
## Haunted dwellings and arcane transport discs (pp. 148, 150).

static func site_at(s: GameState, kind: String, at: Vector2) -> TerrainPiece:
	for p in s.board.pieces:
		if p.kind.id == kind and p.contains(at):
			return p
	return null


static func treasure_protected(s: GameState, at: Vector2) -> bool:
	return s.scenario_special == "the_keep" and site_at(s, "arcane_disc", at) != null


static func discover(c: GameController, at: Vector2, side: int) -> bool:
	var s := c.state
	if s.scenario_special != "haunted_houses" or side < 0 or s.creature_db == null:
		return false
	var hut := site_at(s, "haunted_floor", at)
	if hut == null or s.discovered_huts.has(hut.rect.position):
		return false
	s.discovered_huts[hut.rect.position] = true
	var roll := c.dice.d20()
	var kind := "" if roll <= 6 else ("ghoul" if roll <= 16 else "wraith")
	var found := false
	if kind != "":
		var grid := MoveGrid.new(s.board, null, s.figures)
		var target := hut.rect.get_center() + Vector2(0, 1.5)
		var points: Array[Vector2] = []
		for x in range(-3, 4):
			for y in range(-3, 4):
				var pos := hut.rect.get_center() + Vector2(x, y) * 0.5
				if grid.open(MovePlanner.node_at(pos)):
					points.append(pos)
		points.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.distance_squared_to(target) < b.distance_squared_to(target))
		if not points.is_empty():
			c._encounters._spawn_at(kind, points[0])
			found = true
	c.emit("hut_discovered", {"side": side, "at": hut.rect.get_center(), "roll": roll, "creature": kind if found else "", "xp": 15 if found else 0})
	return found


static func enter(c: GameController, f: Figure) -> bool:
	if not f.in_play() or f.elevation >= 0.5:
		return false
	return discover(c, f.pos, f.side)


static func end_move(c: GameController, f: Figure) -> void:
	if not f.in_play():
		return
	enter(c, f)
	var s := c.state
	if s.scenario_special != "the_keep" or f.elevation >= 0.5:
		return
	var disc := site_at(s, "arcane_disc", f.pos)
	if disc == null:
		return
	var roll := c.dice.d20()
	if roll >= 16:
		c.emit("disc_stay", {"id": f.id, "roll": roll})
		return
	var center := s.board.size * 0.5
	var from := disc.rect.get_center()
	var direction := -PI * 0.5 if roll <= 5 else (PI if roll <= 10 else PI * 0.5)
	var to := center + (from - center).rotated(direction)
	var dest := site_at(s, "arcane_disc", to)
	if dest == null:
		return
	var grid := MoveGrid.new(s.board, f, s.figures)
	var points: Array[Vector2] = []
	for x in range(-2, 3):
		for y in range(-2, 3):
			var at := to + Vector2(x, y) * 0.5
			if at.distance_to(to) <= dest.rect.size.x * 0.5 - Figure.BASE_RADIUS + 0.001 and grid.open(MovePlanner.node_at(at)):
				points.append(MoveGrid.to_pos(MovePlanner.node_at(at)))
	if points.is_empty():
		c.emit("disc_stay", {"id": f.id, "roll": roll})
		return
	points.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.distance_squared_to(to) < b.distance_squared_to(to))
	var old := f.pos
	f.pos = points[0]
	f.elevation = s.board.height_at(f.pos)
	c.emit("move", {"id": f.id, "path": PackedVector2Array([old, f.pos]), "cost": 0.0})
	var xp := 0
	if f.side >= 0 and not s.disc_travellers.has(f.id):
		s.disc_travellers[f.id] = true
		xp = 30 if f.def.role == "wizard" else (20 if f.def.role == "apprentice" else 0)
	c.emit("disc_transport", {"id": f.id, "side": f.side, "roll": roll, "xp": xp})
	c._magic.terrain.trigger_landing(f)
	if f.in_play():
		c._magic.illusions.after_move(f)
