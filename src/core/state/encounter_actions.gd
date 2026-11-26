class_name EncounterActions
extends RefCounted
## Optional first-pickup encounters (p. 176). Three-tier encounter table in JSON.

var c: GameController
var pool: Array = []


func _init(controller: GameController) -> void:
	c = controller
	if c.state.random_encounters:
		pool = JsonFile.read("res://data/encounters.json").get("tiers", [])


func on_pickup() -> void:
	if not c.state.random_encounters or c.state.creature_db == null or pool.is_empty() or c.dice.d20() < 10:
		return
	var entry := encounter(c.dice.d20(), c.dice.d20())
	if entry.is_empty() or not c.state.creature_db.available(str(entry.get("type",""))):
		return
	var edge := c.dice.pick(4)
	for i in int(entry.get("count", 1)):
		_spawn(entry["type"], edge)


func encounter(tier_roll: int, creature_roll: int) -> Dictionary:
	var tier := 0 if tier_roll <= 12 else (1 if tier_roll <= 18 else 2)
	return pool[tier][clampi(creature_roll, 1, 20) - 1]


func _spawn(type: String, edge: int) -> void:
	var s := c.state
	var b := s.board
	var size := b.size
	var mid := Vector2(0.5, size.y / 2.0)
	var along := Vector2.DOWN
	match edge:
		1: mid.x = size.x - 0.5
		2:
			mid = Vector2(size.x / 2.0, 0.5)
			along = Vector2.RIGHT
		3:
			mid = Vector2(size.x / 2.0, size.y - 0.5)
			along = Vector2.RIGHT
	var grid := MoveGrid.new(b, null, s.figures)
	var at := mid
	var found := false
	for i in range(0, 80):
		var offset := float(floori((i + 1) / 2.0)) * 0.5 * (1 if i % 2 == 0 else -1)
		at = mid + along * offset
		if grid.open(MovePlanner.node_at(at)):
			found = true
			break
	if not found:
		return
	_spawn_at(type, at)


func on_end_turn() -> void:
	var s := c.state
	if s.reinforcement_points.is_empty() or s.creature_db == null:
		return
	var at := s.reinforcement_points[c.dice.pick(s.reinforcement_points.size())]
	var grid := MoveGrid.new(s.board, null, s.figures)
	var candidates: Array[Vector2] = [at]
	for dx in range(-3, 4):
		for dy in range(-3, 4):
			candidates.append(at + Vector2(dx, dy) * 0.5)
	candidates.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.distance_squared_to(at) < b.distance_squared_to(at))
	for p in candidates:
		if grid.open(MovePlanner.node_at(p)) and s.board.can_stand(p, Figure.BASE_RADIUS):
			_spawn_at("skeleton", MoveGrid.to_pos(MovePlanner.node_at(p)))
			return


func _spawn_at(type: String, at: Vector2, side: int = -1) -> Figure:
	var s := c.state
	var id := 1
	for f in s.figures:
		id = maxi(id, f.id + 1)
	var creature := Figure.new(id, s.creature_db.get_def(type), side, at, s.creature_db.unarmed())
	creature.elevation = s.board.height_at(at)
	creature.battle_ref = weakref(s)
	s.figures.append(creature)
	c.emit("creature_spawn", {"id": id})
	return creature


## The Living Museum: failed Will tests spend the collection action; success animates one statue.
func museum_pickup(f: Figure) -> bool:
	var raw := c.dice.d20()
	var success := StatRoll.succeeds(raw, f.effective_will() + f.roll_penalty(), 8)
	c.emit("museum_test", {"id": f.id, "roll": raw, "success": success})
	if not success:
		return false
	var statues: Array[TerrainPiece] = []
	for p in c.state.board.pieces:
		if p.kind.id == "museum_statue":
			statues.append(p)
	if statues.is_empty():
		return true
	var statue := statues[c.dice.pick(statues.size())]
	var at := statue.rect.get_center()
	c.state.board.pieces.erase(statue)
	c.state.board.invalidate_terrain()
	c.emit("terrain_changed", {"spell": "museum_statue", "created": false})
	_spawn_at("medium_construct", at)
	return true
