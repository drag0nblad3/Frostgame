class_name MagicMovement
extends RefCounted

var c: GameController


func _init(controller: GameController) -> void:
	c = controller


func landing(t: Figure, at: Vector2, allow_combat: bool = false) -> bool:
	var b := c.state.board
	if ScenarioNull.field_at(b, at) or not b.can_stand(at, Figure.BASE_RADIUS) or TerrainMagic.ward_blocks(b, t, at) or BattleBoundary.blocks_position(b.boundaries,at,t) or BattleBoundary.blocks_end(b.boundaries,at):
		return false
	for other in c.state.figures:
		if other == t or other.ring_side!=t.ring_side or not other.in_play() or absf(other.elevation - b.height_at(at)) >= 0.5:
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
		return f == t and RealityCrackGeometry.sight_distance(b,f.pos,at)<=24.0 and LineOfSight.check(b,f.pos,at,f).clear
	if id != "leap" or t.side != f.side:
		return false
	if RedKingBridge.crosses_void(b,t.pos,at) or BattleBoundary.blocks_segment(b.boundaries,t.pos,at,"movement",t):
		return false
	if RedKingSinkhole.active(c.state) and Geometry2D.get_closest_point_to_segment(RedKingSinkhole.center(c.state),t.pos,at).distance_to(RedKingSinkhole.center(c.state))<RedKingSinkhole.RADIUS+Figure.BASE_RADIUS-0.001:
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
		var dmg := ElevationRules.fall_damage(height - t.elevation - (3.0 if c.state.board.low_gravity else 0.0))
		if dmg > 0 and MagicEquipment.bonus(t, "slow_fall") == 0:
			c._hurt(t, dmg, t, false)
	if sites:
		ScenarioSites.end_move(c, t)


func force(t: Figure, direction: Vector2, distance: float,ivory_caster: Figure=null) -> void:
	if direction.is_zero_approx():
		return
	var b := c.state.board
	var origin := t.pos
	var last := origin
	var highest := t.elevation
	var portal_hits := {}
	var collision := false
	for i in range(1, floori(distance * 4.0) + 1):
		var at := origin + direction * (i * 0.25)
		if not BattleBoundary.blocks_segment(b.boundaries,last,at,"movement",t) and RedKingBridge.forced_void(c,t,at,last):
			return
		if RedKingHerded.contact(c,t,at) or RedKingVeil.touch(c,t,at):
			return
		if RedKingSinkhole.touches(c.state,at) and not RedKingSinkhole.touches(c.state,last):
			if landing(t,at,true):
				move(t,at,false,true)
			else:
				RedKingSinkhole.contact(c,t,true)
			return
		if BattleBoundary.blocks_segment(b.boundaries,origin,at,"movement",t) or ScenarioNull.field_at(b, at) or not b.can_stand(at, Figure.BASE_RADIUS) or TerrainMagic.ward_blocks(b, t, at) or b.height_at(at) > highest + 0.5:
			collision=not b.can_stand(at,Figure.BASE_RADIUS) or b.height_at(at)>highest+0.5
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
		move(t,last,false,true)
	if collision and ivory_caster!=null and t.in_play():
		c.emit("gear_used",{"id":ivory_caster.id,"target":t.id,"gear":"gear_rk_ivory_hand","damage":3})
		c._hurt(t,3,ivory_caster,false)


func swap(a: Figure, b: Figure) -> void:
	var pos := a.pos
	var other := b.pos
	move(a, other, false, false, false)
	move(b, pos, false, false, false)
	ScenarioSites.end_move(c, a)
	ScenarioSites.end_move(c, b)


static func ivory_hand(f: Figure) -> bool:
	if MagicEquipment.suppressed(f):
		return false
	for item in f.items:
		if item.get("gear","")=="gear_rk_ivory_hand" or (item.get("ivory_graft",false) and not f.destroyed_weapons.has("staff")):
			return true
	return false


func push(f: Figure, t: Figure) -> void:
	var ivory := ivory_hand(f)
	var a := c.dice.d20() + (11 if ivory else 10)
	var d := c.dice.d20() + t.effective_fight() + t.roll_penalty()
	if a > d:
		force(t,(t.pos-f.pos).normalized(),float(maxi(0,a-t.effective_armour())),f if ivory else null)


func blink(f: Figure,t: Figure,roll: int,extend: bool=false,reroll: bool=false) -> void:
	var gem := ActiveGear.has(f,PowerPool.GEM) and not MagicEquipment.suppressed(f)
	if t.side!=f.side:
		c._magic.resistance.attempt(t,roll,_blink_result.bind(f,t,extend and gem,reroll and gem),0,false,"blink")
	else:
		_blink_result(false,f,t,extend and gem,reroll and gem)


func _blink_result(success: bool,f: Figure,t: Figure,extend: bool,reroll: bool) -> void:
	if not success and t.in_play():
		if RedKingDirection.offer(c,"blink",t,f,extend):
			return
		var direction := RedKingDirection.direction(c)
		if reroll:
			direction=RedKingDirection.direction(c)
		finish_blink(f,t,direction,extend,reroll)


func finish_blink(f: Figure,t: Figure,direction: Vector2,extend: bool,reroll: bool) -> void:
	if extend or reroll:
		f.used_gear["rk_gem_glow"]=int(f.used_gear.get("rk_gem_glow",0))+1
		c.emit("gear_used",{"id":f.id,"gear":PowerPool.GEM})
	force(t,direction,6.0 if extend else 4.0)


func can_swap(f: Figure, a: Figure, b: Figure) -> bool:
	return a != b and a.ring_side==b.ring_side and f.ring_side==b.ring_side and b.in_play() and not ScenarioNull.muted(a) and not ScenarioNull.muted(b) and Shooting.distance(a, b) <= 12.0 and Shooting.distance(f, b) <= 24.0 and LineOfSight.check(c.state.board, f.pos, b.pos).clear


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
