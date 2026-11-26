class_name EncounterActions
extends RefCounted
## Optional first-pickup encounters (p. 176). Prototype encounter pool in JSON.

var c: GameController
var pool: Array = []


func _init(controller: GameController) -> void:
	c = controller
	if c.state.random_encounters:
		pool = JsonFile.read("res://data/encounters.json").get("entries", [])


func on_pickup() -> void:
	if not c.state.random_encounters or c.state.creature_db == null or pool.is_empty() or c.dice.d20() < 10:
		return
	var entry: Dictionary = pool[c.dice.pick(pool.size())]
	var edge := c.dice.pick(4)
	for i in int(entry.get("count", 1)):
		_spawn(entry["type"], edge)


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
	var id := 1
	for f in s.figures:
		id = maxi(id, f.id + 1)
	var creature := Figure.new(id, s.creature_db.get_def(type), -1, at, s.creature_db.unarmed())
	creature.elevation = s.board.height_at(at)
	s.figures.append(creature)
	c.emit("creature_spawn", {"id": id})
