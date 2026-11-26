class_name TerrainMagic
extends RefCounted
## Dynamic terrain on the exposed-surface heightfield.
const SPELLS := ["wall", "fog", "mud"]
var c: GameController


func _init(controller: GameController) -> void:
	c = controller


func footprint(id: String, at: Vector2, rotated: bool) -> Rect2:
	var size := Vector2(6, 6) if id == "mud" else (Vector2(1, 6) if rotated else Vector2(6, 1))
	return Rect2(at - size * 0.5, size)


func can_place(f: Figure, id: String, at: Vector2, rotated: bool) -> bool:
	var b := c.state.board
	var rect := footprint(id, at, rotated)
	if not b.contains(rect.position) or not b.contains(rect.end):
		return false
	if id == "mud":
		return LineOfSight.check(b, f.pos, at).clear
	var seen := false
	for i in range(-6, 7):
		var p := at + (Vector2.DOWN if rotated else Vector2.RIGHT) * i * 0.5
		var distance := f.pos.distance_to(p)
		if id == "fog" and distance > 24.0:
			return false
		if (id == "fog" or distance <= 10.0) and LineOfSight.check(b, f.pos, p).clear:
			seen = true
	if not seen:
		return false
	if id == "wall":
		for t in c.state.figures:
			if t.in_play() and rect.grow(Figure.BASE_RADIUS).has_point(t.pos):
				return false
		for p in b.pieces:
			if p.kind.blocks_move and p.rect.intersects(rect):
				return false
	return true


func points(f: Figure, id: String, rotated: bool, first_only: bool) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var b := c.state.board
	for x in range(1, int(b.size.x)):
		for y in range(1, int(b.size.y)):
			var at := Vector2(x, y)
			if can_place(f, id, at, rotated):
				out.append(at)
				if first_only:
					return out
	return out


func apply(f: Figure, id: String, at: Vector2, rotated: bool) -> void:
	var kind := TerrainKind.new()
	kind.id = "spell_" + id
	kind.name = id.capitalize()
	kind.height = 0.04 if id == "mud" else 3.0
	kind.blocks_los = id != "mud"
	kind.blocks_move = id == "wall"
	kind.walkable_top = id == "wall"
	kind.move_mult = 2.0 if id == "mud" else 1.0
	var p := TerrainPiece.new(kind, footprint(id, at, rotated))
	p.circular = id == "mud"
	p.cast_turn = c.state.turn
	p.caster_id = f.id
	c.state.board.pieces.append(p)
	c.state.board.invalidate_terrain()
	c.emit("terrain_changed", {"spell": id, "created": true})


func expire() -> void:
	var s := c.state
	for p in s.board.pieces.duplicate():
		if p.cast_turn < 0:
			continue
		if p.kind.id == "spell_fog" or (p.kind.id == "spell_wall" and p.cast_turn < s.turn):
			if c.dice.d20() <= 4:
				remove(p)


func remove(p: TerrainPiece) -> void:
	var s := c.state
	s.board.pieces.erase(p)
	s.board.invalidate_terrain()
	c.emit("terrain_changed", {"spell": p.kind.id.trim_prefix("spell_"), "created": false})
	for t in s.figures:
		if not t.in_play():
			continue
		var new_height := s.board.height_at(t.pos)
		var fall := ElevationRules.fall_damage(t.elevation - new_height)
		if not is_equal_approx(t.elevation, new_height):
			t.elevation = new_height
			c.emit("terrain_fall", {"id": t.id})
		if fall > 0:
			c._hurt(t, fall, t, false)
