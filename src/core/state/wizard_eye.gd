class_name WizardEye
extends RefCounted

var c: GameController


func _init(controller: GameController) -> void:
	c = controller


func options(f: Figure) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var b := c.state.board
	for p in b.pieces:
		if p.kind.id.begins_with("null_") or p.kind.id == "temple_column" or p.circular or p.ramp or p.kind.height < 0.5 or p.kind.id.begins_with("spell_") and p.kind.id != "spell_wall":
			continue
		var center := p.rect.get_center()
		for direction: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var at := center + direction * (absf(direction.x) * p.rect.size.x * 0.5 + absf(direction.y) * p.rect.size.y * 0.5 + 0.15)
			if b.contains(at) and f.pos.distance_to(at) <= 12.0 and LineOfSight.check(b, f.pos, at,f).clear:
				result.append({"kind": "eye_face", "target": f.id, "piece": p, "at": at, "direction": direction, "label": "%s at %.1f, %.1f — %s face" % [p.kind.name, at.x, at.y, ["east", "south", "west", "north"][posmod(roundi(direction.angle() / (PI * 0.5)), 4)]]})
	return result


static func marker(b: Board, f: Figure) -> TerrainPiece:
	for p in b.pieces:
		if p.kind.id == "spell_wizard_eye" and p.caster_id == f.id and b.pieces.has(p.eye_host):
			return p
	return null


static func origin(b: Board, f: Figure, at: Vector2, max_range: float = 24.0) -> Vector2:
	if Vector2(f.pos.distance_to(at), f.elevation - b.height_at(at)).length() <= max_range and LineOfSight.check(b, f.pos, at,f).clear:
		return f.pos
	var eye := marker(b, f)
	if eye != null:
		var pos := eye.rect.get_center()
		if eye.eye_direction.dot(at - pos) >= -0.001 and Vector2(pos.distance_to(at), b.height_at(pos) - b.height_at(at)).length() <= max_range and LineOfSight.check(b, pos, at,f).clear:
			return pos
	return f.pos


static func visible(b: Board, f: Figure, at: Vector2, max_range: float = 24.0) -> bool:
	var start := origin(b, f, at, max_range)
	return Vector2(start.distance_to(at), b.height_at(start) - b.height_at(at)).length() <= max_range and LineOfSight.check(b, start, at,f).clear


func create(f: Figure, option: Dictionary) -> void:
	var b := c.state.board
	var previous := marker(b, f)
	if previous != null:
		b.pieces.erase(previous)
	var host: TerrainPiece = option["piece"]
	if not b.pieces.has(host):
		return
	var k := TerrainKind.new()
	k.id = "spell_wizard_eye"
	k.name = "Wizard Eye"
	k.height = 0.25
	var at: Vector2 = option["at"]
	var p := TerrainPiece.new(k, Rect2(at - Vector2(0.15, 0.15), Vector2(0.3, 0.3)))
	p.circular = true
	p.cast_turn = c.state.turn
	p.caster_id = f.id
	p.eye_host = host
	p.eye_direction = option["direction"]
	b.pieces.append(p)
	b.invalidate_terrain()
	c.emit("terrain_changed", {"spell": "wizard_eye", "created": true})


static func remove_attached(b: Board, host: TerrainPiece) -> void:
	for p in b.pieces.duplicate():
		if p.kind.id == "spell_wizard_eye" and p.eye_host == host:
			b.pieces.erase(p)
