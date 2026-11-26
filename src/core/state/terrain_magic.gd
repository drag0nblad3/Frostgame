class_name TerrainMagic
extends RefCounted
## Dynamic terrain on the exposed-surface heightfield.
const SPELLS := ["wall", "fog", "mud", "explosive_rune", "planar_tear", "grenade"]
var c: GameController


func _init(controller: GameController) -> void:
	c = controller


func footprint(id: String, at: Vector2, rotated: bool) -> Rect2:
	var size := Vector2(6, 6) if id == "mud" else (Vector2(1, 6) if rotated else Vector2(6, 1))
	if id in ["explosive_rune", "planar_tear", "grenade"]:
		size = Vector2(0.5, 0.5)
	return Rect2(at - size * 0.5, size)


func can_place(f: Figure, id: String, at: Vector2, rotated: bool) -> bool:
	var b := c.state.board
	var rect := footprint(id, at, rotated)
	if not b.contains(rect.position) or not b.contains(rect.end):
		return false
	if id == "mud":
		return f.pos.distance_to(at) <= 24 and LineOfSight.check(b, f.pos, at).clear
	if id == "grenade":
		return f.pos.distance_to(at) <= 14.0 and LineOfSight.check(b, f.pos, at).clear
	if id in ["explosive_rune", "planar_tear"]:
		if id == "explosive_rune":
			var count := 0
			for p in b.pieces:
				if p.kind.id == "spell_explosive_rune" and p.caster_id == f.id:
					count += 1
			if count >= 3:
				return false
		return f.pos.distance_to(at) <= (4.0 if id == "explosive_rune" else 24.0) and LineOfSight.check(b, f.pos, at).clear
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


func apply(f: Figure, id: String, at: Vector2, rotated: bool, roll: int = 14) -> void:
	if id == "grenade":
		var affected: Array[Figure] = []
		var s := c.state
		for t in s.figures:
			if not t.in_play() or Vector2(t.pos.distance_to(at), t.elevation - s.board.height_at(at)).length() > 1.5 + Figure.BASE_RADIUS:
				continue
			for member in ShotTarget.participants(s.figures, t):
				if not affected.has(member):
					affected.append(member)
		for t in affected:
			c._magic._shot(f, t, 3, at)
		return
	if id == "planar_tear":
		for t in c.state.figures:
			if not t.in_play() or Vector2(t.pos.distance_to(at), t.elevation - c.state.board.height_at(at)).length() > 2.0 + Figure.BASE_RADIUS:
				continue
			if not StatRoll.succeeds(c.dice.d20(), t.effective_will() + t.roll_penalty(), roll):
				c._hurt(t, roll if t.def.traits.has("demon") else 2, f, false)
		return
	var kind := TerrainKind.new()
	kind.id = "spell_" + id
	kind.name = id.capitalize()
	kind.height = 0.04 if id in ["mud", "explosive_rune"] else 3.0
	kind.blocks_los = id in ["wall", "fog"]
	kind.blocks_move = id == "wall"
	kind.walkable_top = id == "wall"
	kind.move_mult = 2.0 if id == "mud" else 1.0
	var p := TerrainPiece.new(kind, footprint(id, at, rotated))
	p.circular = id in ["mud", "explosive_rune"]
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
		if p.kind.id == "spell_explosive_rune":
			var owner := s.figure(p.caster_id)
			if (owner == null or not owner.in_play()) and c.dice.d20() >= 11:
				remove(p)
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
		if fall > 0 and MagicEquipment.bonus(t, "slow_fall") == 0:
			c._hurt(t, fall, t, false)


func triggered(t: Figure, at: Vector2) -> Array[TerrainPiece]:
	var result: Array[TerrainPiece] = []
	var s := c.state
	for p in s.board.pieces:
		if p.kind.id != "spell_explosive_rune":
			continue
		var owner := s.figure(p.caster_id)
		if owner == null or owner.original_side == t.original_side:
			continue
		var center := p.rect.get_center()
		if Vector2(at.distance_to(center), s.board.height_at(at) - s.board.height_at(center)).length() <= 1.0 + Figure.BASE_RADIUS:
			result.append(p)
	return result


func explode(p: TerrainPiece) -> void:
	if not c.state.board.pieces.has(p):
		return
	var s := c.state
	var owner := s.figure(p.caster_id)
	var center := p.rect.get_center()
	remove(p)
	c.emit("rune_exploded", {"at": center, "id": owner.id})
	for t in s.figures:
		if not t.in_play() or Vector2(t.pos.distance_to(center), t.elevation - s.board.height_at(center)).length() > 2.0 + Figure.BASE_RADIUS:
			continue
		c._magic._direct_attack(owner, t, 5)


## Animate movement in chunks, resolving triggers at the actual path location.
func travel(f: Figure, path: PackedVector2Array, cost: float) -> bool:
	var chunk := PackedVector2Array([f.pos])
	for i in range(1, path.size()):
		var at := path[i]
		chunk.append(at)
		var hits := triggered(f, at)
		if hits.is_empty():
			continue
		f.pos = at
		f.elevation = c.state.board.height_at(at)
		c.emit("move", {"id": f.id, "path": chunk, "cost": cost})
		chunk = PackedVector2Array([at])
		for p in hits:
			explode(p)
		if not f.in_play():
			return false
	f.pos = path[path.size() - 1]
	f.elevation = c.state.board.height_at(f.pos)
	if chunk.size() > 1:
		c.emit("move", {"id": f.id, "path": chunk, "cost": cost})
	return true


func trigger_landing(f: Figure) -> void:
	for p in triggered(f, f.pos):
		explode(p)
