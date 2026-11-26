class_name CombatDisplacement
extends RefCounted
## Post-fight withdrawal and deterministic optional interception (pp. 47, 53).

var c: GameController


func _init(controller: GameController) -> void:
	c = controller


func clear() -> void:
	c.state.push_winner = -1
	c.state.push_loser = -1


func destination(own: bool) -> Variant:
	var s := c.state
	var winner := s.figure(s.push_winner)
	var loser := s.figure(s.push_loser)
	if winner == null or loser == null or not winner.in_play() or not loser.in_play():
		return null
	if own and Contact.enemies_of(s.figures, winner).size() > 1:
		return null
	var moving := winner if own else loser
	var other := loser if own else winner
	var dest := moving.pos + (moving.pos - other.pos).normalized()
	if ScenarioObjectives.inside_well(s, dest):
		return dest
	if c.state.board.height_at(dest) > moving.elevation + 0.001 or not _clear_path(moving, dest,not own):
		return null
	return dest


func push(own: bool) -> bool:
	var dest: Variant = destination(own)
	if dest == null:
		return false
	var moving := c.state.figure(c.state.push_winner if own else c.state.push_loser)
	var other := c.state.figure(c.state.push_loser if own else c.state.push_winner)
	var from := moving.pos
	var old_height := moving.elevation
	if RedKingBridge.active(c.state) and c.state.board.over_void(dest,Figure.BASE_RADIUS):
		var last := from
		for i in range(1,5):
			var at := from.lerp(dest,float(i)/4.0)
			if RedKingBridge.forced_void(c,moving,at,last):
				clear()
				return true
			last=at
	if RedKingVeil.touch(c,moving,dest):
		clear()
		return true
	RedKingFire.portal_contact(c,moving,from,dest,{})
	if not moving.in_play():
		clear()
		return true
	moving.pos = dest
	moving.elevation = c.state.board.height_at(dest)
	moving.disengaged[other.id] = moving.pos.distance_to(other.pos)
	other.disengaged[moving.id] = moving.disengaged[other.id]
	clear()
	c.emit("push_back", {"id": moving.id, "path": PackedVector2Array([from, moving.pos])})
	if ScenarioObjectives.inside_well(c.state, moving.pos):
		c._hurt(moving, moving.health, other, false)
		return true
	c._magic.terrain.trigger_landing(moving)
	var fall := ElevationRules.fall_damage(old_height - moving.elevation)
	if fall > 0 and MagicEquipment.bonus(moving, "slow_fall") == 0:
		c._hurt(moving, fall, other, false)
	ScenarioSites.end_move(c, moving)
	return true


func _clear_path(moving: Figure, dest: Vector2,allow_void: bool=false) -> bool:
	for i in range(1, 5):
		var p := moving.pos.lerp(dest, i / 4.0)
		if BattleBoundary.blocks_segment(c.state.board.boundaries,moving.pos,p,"movement",moving) or BattleBoundary.blocks_position(c.state.board.boundaries,p,moving):
			return false
		if allow_void and RedKingBridge.active(c.state) and c.state.board.over_void(p,Figure.BASE_RADIUS):
			return true
		if not c.state.board.can_stand(p, Figure.BASE_RADIUS):
			return false
		for f in c.state.figures:
			if f != moving and f.in_play() and absf(f.elevation - c.state.board.height_at(p)) < 0.5 and f.pos.distance_to(p) < Contact.OVERLAP:
				return false
	return true


## Current policy: eligible guards automatically intercept when enabled.
func intercept(mover: Figure, path: PackedVector2Array, ignored: Array[int] = []) -> Dictionary:
	for i in range(1, path.size()):
		var p := path[i]
		for guard in c.state.figures:
			if ignored.has(guard.id) or guard.spell_effects.has("plane_walk") or not guard.in_play() or guard.side == mover.side or Contact.in_combat(c.state.figures, guard) or not IllusionRules.visible_to(c.state.figures, guard, mover) or BeautyActions.protected_from(c.state, guard, mover):
				continue
			if absf(c.state.board.height_at(p) - guard.elevation) >= 0.5:
				continue
			var distance := p.distance_to(guard.pos)
			if distance > 2.0 or distance <= Contact.CONTACT:
				continue
			if mover.disengaged.has(guard.id) and distance >= float(mover.disengaged[guard.id]) - 0.001:
				continue
			var dest := p + (guard.pos - p).normalized()
			if absf(c.state.board.height_at(dest) - guard.elevation) < 0.5 and _clear_path(guard, dest):
				return {"index": i, "guard": guard, "dest": dest}
	return {}


func force_contact(info: Dictionary) -> void:
	var guard: Figure = info["guard"]
	var from := guard.pos
	if RedKingVeil.touch(c,guard,info["dest"]):
		return
	RedKingFire.portal_contact(c,guard,from,info["dest"],{})
	if not guard.in_play():
		return
	guard.pos = info["dest"]
	guard.elevation = c.state.board.height_at(guard.pos)
	c.emit("force_combat", {"id": guard.id, "path": PackedVector2Array([from, guard.pos])})
	c._magic.terrain.trigger_landing(guard)
	ScenarioSites.end_move(c, guard)
	c._magic.illusions.after_move(guard)
