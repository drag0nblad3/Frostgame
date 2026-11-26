class_name SummonActions
extends RefCounted
## Shared placement and temporary allegiance rules. All choices go through SpellActions.
const PLACEMENT := ["animate_skull", "imp", "raise_zombie", "summon_demon"]
const CONTROL := {"control_animal": "animal", "control_construct": "construct", "control_demon": "demon", "control_undead": "undead", "mind_control": ""}

var c: GameController


func _init(controller: GameController) -> void:
	c = controller


func controlled(f: Figure, id: String) -> Figure:
	for t in c.state.figures:
		if t.in_play() and t.controller_id == f.id and t.control_spell == id:
			return t
	return null


func summoned(f: Figure, id: String, whole_side: bool = false) -> Figure:
	for t in c.state.figures:
		if not t.in_play() or t.summon_spell != id:
			continue
		var owner := c.state.figure(t.summoned_by)
		if owner != null and (owner.id == f.id or (whole_side and owner.side == f.side)):
			return t
	return null


func can_control(f: Figure, t: Figure, id: String) -> bool:
	if t.side == f.side or t.controller_id >= 0 or controlled(f, id) != null:
		return false
	if id == "mind_control":
		return t.def.role not in ["wizard", "apprentice"] and not t.def.traits.has("mindless")
	return t.def.traits.has(CONTROL[id])


func can_place(f: Figure, id: String, at: Vector2) -> bool:
	var s := c.state
	if s.creature_db == null or not s.board.can_stand(at, Figure.BASE_RADIUS):
		return false
	if id == "animate_skull" and summoned(f, id) != null:
		return false
	if id == "raise_zombie" and summoned(f, id, true) != null:
		return false
	if id == "summon_demon" and controlled(f, "control_demon") != null:
		return false
	var dist := f.pos.distance_to(at)
	var height_delta := s.board.height_at(at) - f.elevation
	if id == "animate_skull" and Vector2(dist, height_delta).length() > 6.001:
		return false
	if id in ["raise_zombie", "summon_demon"] and (dist > (1.25 if id == "raise_zombie" else 2.0) or absf(height_delta) >= 0.5):
		return false
	if not LineOfSight.check(s.board, f.pos, at).clear:
		return false
	for t in s.figures:
		if not t.in_play():
			continue
		var d := Vector2(t.pos.distance_to(at), t.elevation - s.board.height_at(at)).length()
		if d < Contact.OVERLAP or (id == "imp" and d < 4.0):
			return false
		if id in ["raise_zombie", "summon_demon"] and t.side != f.side and d <= Contact.CONTACT:
			return false
	return true


func points(f: Figure, id: String, first_only: bool = false) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var grid := MoveGrid.new(c.state.board)
	var reach := 6.0 if id == "animate_skull" else (2.0 if id != "imp" else c.state.board.size.length())
	var origin := MovePlanner.node_at(f.pos)
	var radius := ceili(reach / MoveGrid.STEP)
	for x in range(maxi(0, origin.x - radius), mini(grid.cols, origin.x + radius + 1)):
		for y in range(maxi(0, origin.y - radius), mini(grid.rows, origin.y + radius + 1)):
			var at := MoveGrid.to_pos(Vector2i(x, y))
			if can_place(f, id, at):
				out.append(at)
				if first_only:
					return out
	return out


func apply_control(f: Figure, t: Figure, id: String, roll: int) -> void:
	if StatRoll.succeeds(c.dice.d20(), t.effective_will() + t.roll_penalty(), roll):
		return
	t.controller_id = f.id
	t.control_spell = id
	t.control_roll = roll
	t.side = f.side
	c.emit("allegiance", {"id": t.id, "side": t.side})


func release(t: Figure) -> void:
	t.side = t.original_side
	t.controller_id = -1
	t.control_spell = ""
	t.control_roll = 0
	c.emit("allegiance", {"id": t.id, "side": t.side})


func cancelable(f: Figure, t: Figure) -> bool:
	return t.in_play() and ((t.controller_id == f.id and t.control_spell != "mind_control") or (t.summoned_by == f.id and t.summon_spell == "animate_skull"))


func cancel(f: Figure, t: Figure) -> void:
	if t.summon_spell == "animate_skull" and t.summoned_by == f.id:
		vanish(t)
	else:
		release(t)


func vanish(t: Figure) -> void:
	c._loot.drop_on_death(t)
	t.exited = true
	c.emit("exit", {"id": t.id})


func spawn(f: Figure, id: String, at: Vector2, roll: int, tn: int) -> void:
	var type := id
	var side := -1
	match id:
		"imp":
			var old := summoned(f, id)
			if old != null:
				vanish(old)
		"raise_zombie":
			type = "zombie"
			side = f.side
		"summon_demon":
			var margin := roll - tn
			type = "major_demon" if margin >= 13 else ("minor_demon" if margin >= 6 else "imp")
			side = f.side
		"animate_skull":
			type = "animated_skull"
	var t := c._encounters._spawn_at(type, at, side)
	t.summoned_by = f.id
	t.summon_spell = id
	if id == "summon_demon":
		t.original_side = -1
		t.controller_id = f.id
		t.control_spell = "control_demon"
		t.control_roll = roll


func miscast_demon(f: Figure) -> void:
	var s := c.state
	var roll := c.dice.d20()
	var type := "imp" if roll <= 10 else ("minor_demon" if roll <= 17 else "major_demon")
	for i in 16:
		var at := f.pos + Vector2.RIGHT.rotated(TAU * i / 16.0)
		if not s.board.can_stand(at, Figure.BASE_RADIUS) or absf(s.board.height_at(at) - f.elevation) >= 0.5:
			continue
		var open := true
		for t in s.figures:
			if t.in_play() and t != f and t.pos.distance_to(at) < Contact.OVERLAP:
				open = false
		if open:
			c._encounters._spawn_at(type, at)
			return
