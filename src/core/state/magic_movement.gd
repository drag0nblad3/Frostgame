class_name MagicMovement
extends RefCounted

var c: GameController


func _init(controller: GameController) -> void:
	c = controller


func landing(t: Figure, at: Vector2, allow_combat: bool = false) -> bool:
	var b := c.state.board
	if ScenarioNull.field_at(b, at) or not b.can_stand(at, Figure.BASE_RADIUS) or TerrainMagic.ward_blocks(b, t, at) or BattleBoundary.blocks_position(b.boundaries,at,t):
		return false
	for other in c.state.figures:
		if other == t or not other.in_play() or absf(other.elevation - b.height_at(at)) >= 0.5:
			continue
		var dist := other.pos.distance_to(at)
		if dist < Contact.OVERLAP or (not allow_combat and other.side != t.side and dist <= Contact.CONTACT):
			return false
	return true


func can_land(f: Figure, t: Figure, id: String, at: Vector2) -> bool:
	var b := c.state.board
	if not landing(t, at) or at.distance_to(t.pos) < 0.1:
		return false
	if id == "teleport":
		return f == t and f.pos.distance_to(at) <= 24.0 and LineOfSight.check(b, f.pos, at).clear
	if id != "leap" or t.side != f.side:
		return false
	var delta := Vector2(t.pos.distance_to(at), b.height_at(at) - t.elevation)
	var limit := 5.0 if t.treasure_id >= 0 else 10.0
	if delta.length() > limit:
		return false
	# Direct arc, never a path around corners. Reject obstacles above the arc.
	var steps := maxi(1, ceili(delta.x / 0.25))
	for i in range(1, steps):
		var ratio := float(i) / steps
		var p := t.pos.lerp(at, ratio)
		var h := lerpf(t.elevation, b.height_at(at), ratio) + 4.0 * ratio * (1.0 - ratio) * 3.0
		for piece in b.pieces_at(p):
			if piece.kind.blocks_move and piece.kind.height > h + 0.05:
				return false
	return true


func points(f: Figure, t: Figure, id: String, first_only: bool = false) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var grid := MoveGrid.new(c.state.board)
	var radius := ceili((24.0 if id == "teleport" else 10.0) / MoveGrid.STEP)
	var origin := MovePlanner.node_at(t.pos)
	for x in range(maxi(0, origin.x - radius), mini(grid.cols, origin.x + radius + 1)):
		for y in range(maxi(0, origin.y - radius), mini(grid.rows, origin.y + radius + 1)):
			var at := MoveGrid.to_pos(Vector2i(x, y))
			if can_land(f, t, id, at):
				result.append(at)
				if first_only:
					return result
	return result


func move(t: Figure, at: Vector2, exhaust: bool = false, falling: bool = false, sites: bool = true) -> void:
	if RedKingHerded.contact(c,t,at) or RedKingVeil.touch(c,t,at):
		return
	# A teleport has no intervening path; test its landing.
	RedKingFire.portal_contact(c,t,at,at,{})
	if not t.in_play():
		return
	t.spell_effects.erase("bones_of_the_earth")
	var old := t.pos
	var height := t.elevation
	t.pos = at
	t.elevation = c.state.board.height_at(at)
	RedKingMind.collect(c,t,at,at)
	if exhaust:
		t.magic_exhausted = true
		t.actions_left = 0
	c.emit("move", {"id": t.id, "path": PackedVector2Array([old, at]), "cost": 0.0})
	c._magic.terrain.trigger_landing(t)
	c._magic.illusions.after_move(t)
	if falling:
		var dmg := ElevationRules.fall_damage(height - t.elevation)
		if dmg > 0 and MagicEquipment.bonus(t, "slow_fall") == 0:
			c._hurt(t, dmg, t, false)
	if sites:
		ScenarioSites.end_move(c, t)


func force(t: Figure, direction: Vector2, distance: float) -> void:
	if direction.is_zero_approx():
		return
	var b := c.state.board
	var origin := t.pos
	var last := origin
	var highest := t.elevation
	var portal_hits := {}
	for i in range(1, floori(distance * 4.0) + 1):
		var at := origin + direction * (i * 0.25)
		if RedKingHerded.contact(c,t,at) or RedKingVeil.touch(c,t,at):
			return
		if BattleBoundary.blocks_segment(b.boundaries,origin,at,"movement",t) or ScenarioNull.field_at(b, at) or not b.can_stand(at, Figure.BASE_RADIUS) or TerrainMagic.ward_blocks(b, t, at) or b.height_at(at) > highest + 0.5:
			if not b.can_stand(at,Figure.BASE_RADIUS):
				RedKingFire.portal_contact(c,t,last,at,portal_hits)
			break
		RedKingFire.portal_contact(c,t,last,at,portal_hits)
		if not t.in_play():
			return
		# Other figures don't interrupt the trajectory; choose a legal final base.
		if landing(t, at, true):
			last = at
	if last != origin:
		move(t, last, false, true)


func swap(a: Figure, b: Figure) -> void:
	var pos := a.pos
	var other := b.pos
	move(a, other, false, false, false)
	move(b, pos, false, false, false)
	ScenarioSites.end_move(c, a)
	ScenarioSites.end_move(c, b)


func push(f: Figure, t: Figure) -> void:
	var a := c.dice.d20() + 10
	var d := c.dice.d20() + t.effective_fight() + t.roll_penalty()
	if a > d:
		force(t, (t.pos - f.pos).normalized(), float(maxi(0, a - t.effective_armour())))


func blink(f: Figure, t: Figure, roll: int) -> void:
	if t.side != f.side:
		c._magic.resistance.attempt(t, roll, _blink_result.bind(t))
	else:
		_blink_result(false, t)


func _blink_result(success: bool, t: Figure) -> void:
	if not success and t.in_play():
		force(t, Vector2.RIGHT.rotated(TAU * c.dice.pick(20) / 20.0), 4.0)


func can_swap(f: Figure, a: Figure, b: Figure) -> bool:
	return a != b and b.in_play() and not ScenarioNull.muted(a) and not ScenarioNull.muted(b) and Shooting.distance(a, b) <= 12.0 and Shooting.distance(f, b) <= 24.0 and LineOfSight.check(c.state.board, f.pos, b.pos).clear


func transpose(f: Figure, a: Figure, b: Figure, roll: int) -> void:
	_transpose_step(false, f, a, b, roll, 0)


func _transpose_step(success: bool, f: Figure, a: Figure, b: Figure, roll: int, index: int) -> void:
	if success or not a.in_play() or not b.in_play():
		return
	if index >= 2:
		swap(a, b)
		return
	var t := a if index == 0 else b
	if t.side >= 0 and t.side != f.side:
		c._magic.resistance.attempt(t, roll, _transpose_step.bind(f, a, b, roll, index + 1))
	else:
		_transpose_step(false, f, a, b, roll, index + 1)
