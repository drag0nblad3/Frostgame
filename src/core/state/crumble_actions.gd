class_name CrumbleActions
extends RefCounted

var c: GameController


func _init(controller: GameController) -> void:
	c = controller


func options(f: Figure) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var board := c.state.board
	for p in board.pieces:
		if p.kind.id != "spell_wall" and (p.cast_turn >= 0 or not p.kind.blocks_move or p.kind.height < 1.0):
			continue
		var near := Vector2(clampf(f.pos.x, p.rect.position.x, p.rect.end.x), clampf(f.pos.y, p.rect.position.y, p.rect.end.y)).lerp(f.pos, 0.02)
		if not LineOfSight.check(board, f.pos, near).clear:
			continue
		out.append({"kind": "terrain", "target": f.id, "piece": p, "label": "%s at %.1f, %.1f" % [p.kind.name, p.rect.get_center().x, p.rect.get_center().y]})
	return out


func apply(p: TerrainPiece) -> void:
	var s := c.state
	if not s.board.pieces.has(p):
		return
	if p.kind.id == "spell_wall":
		c._magic.terrain.remove(p)
		return
	# Remove a doorway-width strip through the simplified solid ruin footprint.
	var r := p.rect
	var along_x := r.size.x >= r.size.y
	var length := r.size.x if along_x else r.size.y
	var remaining := maxf(0.0, (length - 1.5) * 0.5)
	s.board.pieces.erase(p)
	if remaining > 0.01:
		var a := Rect2(r.position, Vector2(remaining, r.size.y) if along_x else Vector2(r.size.x, remaining))
		var b := Rect2(r.end - a.size, a.size)
		s.board.pieces.append(TerrainPiece.new(p.kind, a))
		s.board.pieces.append(TerrainPiece.new(p.kind, b))
	s.board.invalidate_terrain()
	c.emit("terrain_changed", {"spell": "crumble", "created": false})
	for t in s.figures:
		if not t.in_play() or t.elevation <= s.board.height_at(t.pos):
			continue
		var mod := t.effective_move() + t.roll_penalty() - int(t.injury_types.get("lost_toes", 0))
		var saved := StatRoll.succeeds(c.dice.d20(), mod, 22)
		if saved:
			var moved := false
			for i in 16:
				var at := t.pos + Vector2.RIGHT.rotated(TAU * i / 16.0)
				if s.board.height_at(at) >= t.elevation and c._magic.movement.landing(t, at, true):
					c._magic.movement.move(t, at)
					moved = true
					break
			if moved:
				continue
		var h := s.board.height_at(t.pos)
		var damage := ElevationRules.fall_damage(t.elevation - h)
		t.elevation = h
		c.emit("terrain_fall", {"id": t.id})
		if damage > 0 and MagicEquipment.bonus(t, "slow_fall") == 0:
			c._hurt(t, damage, t, false)
