class_name CombatDisplacement
extends RefCounted
## Post-fight withdrawal and deterministic optional interception (pp. 47, 53).

var c: GameController


func _init(controller: GameController) -> void:
	c = controller


func clear() -> void:
	c.state.push_winner = -1
	c.state.push_loser = -1
	c.state.push_tie=false
	c.state.push_tie_second=false


const BOOTS := "gear_rk_slippery_boots"


static func boots(f: Figure) -> bool:
	return f!=null and ActiveGear.has(f,BOOTS) and not MagicEquipment.suppressed(f)


static func distance_allowed(s: GameState,own: bool,distance: float) -> bool:
	if s.push_tie and not own:
		return false
	if is_equal_approx(distance,1.0):
		return not s.push_tie or boots(s.figure(s.push_winner))
	return own and boots(s.figure(s.push_winner)) and distance>=0.5 and distance<=3.0


func destination(own: bool,distance: float=1.0) -> Variant:
	var s := c.state
	if not distance_allowed(s,own,distance):
		return null
	var winner := s.figure(s.push_winner)
	var loser := s.figure(s.push_loser)
	if winner == null or loser == null or not winner.in_play() or not loser.in_play():
		return null
	if own and Contact.enemies_of(s.figures, winner).size() > 1:
		return null
	var moving := winner if own else loser
	var other := loser if own else winner
	var dest := moving.pos + (moving.pos - other.pos).normalized()*distance
	if ScenarioObjectives.inside_well(s, dest):
		return dest
	if c.state.board.height_at(dest) > moving.elevation + 0.001 or not _clear_path(moving, dest,not own):
		return null
	return dest


func push(own: bool,distance: float=1.0) -> bool:
	var dest: Variant = destination(own,distance)
	if dest == null:
		return false
	var moving := c.state.figure(c.state.push_winner if own else c.state.push_loser)
	var other := c.state.figure(c.state.push_loser if own else c.state.push_winner)
	var from := moving.pos
	var old_height := moving.elevation
	if RuleHooks.any("forced_move_void", [c, moving, from, dest]) or RuleHooks.any("forced_move_blocked", [c, moving, dest]):
		clear()
		return true
	RuleHooks.run("forced_contact", [c, moving, from, dest])
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
	var steps := maxi(4,ceili(moving.pos.distance_to(dest)*4.0))
	for i in range(1,steps+1):
		var p := moving.pos.lerp(dest,float(i)/steps)
		if BattleBoundary.blocks_segment(c.state.board.boundaries,moving.pos,p,"movement",moving) or BattleBoundary.blocks_position(c.state.board.boundaries,p,moving):
			return false
		if allow_void and RuleHooks.any("forced_path_void", [c, p]):
			return true
		if not c.state.board.can_stand(p, Figure.BASE_RADIUS):
			return false
		for f in c.state.figures:
			if f != moving and f.ring_side==moving.ring_side and f.in_play() and absf(f.elevation - c.state.board.height_at(p)) < 0.5 and f.pos.distance_to(p) < Contact.OVERLAP:
				return false
	return true


## Same guard eligibility, regardless of route geometry.
func guard_can_intercept(mover: Figure,guard: Figure,ignored: Array[int]) -> bool:
	return guard.ring_side==mover.ring_side and not ignored.has(guard.id) and not guard.spell_effects.has("plane_walk") and guard.in_play() and guard.side!=mover.side and not Contact.in_combat(c.state.figures,guard) and IllusionRules.visible_to(c.state.figures,guard,mover) and not BeautyActions.protected_from(c.state,guard,mover)


func intercept(mover: Figure, path: PackedVector2Array, ignored: Array[int] = []) -> Dictionary:
	for i in range(1, path.size()):
		var p := path[i]
		for guard in c.state.figures:
			if not guard_can_intercept(mover,guard,ignored):
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
	if info.has("floor"):
		force_floor_contact(info)
		return
	var guard: Figure = info["guard"]
	var from := guard.pos
	if RuleHooks.any("forced_move_blocked", [c, guard, info["dest"]]):
		return
	RuleHooks.run("forced_contact", [c, guard, from, info["dest"]])
	if not guard.in_play():
		return
	guard.pos = info["dest"]
	guard.elevation = c.state.board.height_at(guard.pos)
	c.emit("force_combat", {"id": guard.id, "path": PackedVector2Array([from, guard.pos])})
	c._magic.terrain.trigger_landing(guard)
	ScenarioSites.end_move(c, guard)
	c._magic.illusions.after_move(guard)


## A floor route must not invite a guard through the deck above or below.
func intercept_floor(mover: Figure,path: PackedVector3Array,surfaces: Array[String],ignored: Array[int]) -> Dictionary:
	var layout:=c.state.board.floor_geometry()
	for i in range(1,path.size()):
		var point:=path[i]
		var p:=Vector2(point.x,point.z)
		for guard in c.state.figures:
			if not guard_can_intercept(mover,guard,ignored) or absf(guard.elevation-point.y)>=0.5:
				continue
			var distance:=p.distance_to(guard.pos)
			if distance>2.0 or distance<=Contact.CONTACT or (mover.disengaged.has(guard.id) and distance>=float(mover.disengaged[guard.id])-0.001):
				continue
			var n:=layout.node(guard.surface_id,p+(guard.pos-p).normalized())
			var grid:=LayeredGrid.new(layout,guard,c.state.figures)
			if not grid.open(n):
				continue
			var dest:=layout.point(n)
			var h:=layout.height(n)
			if absf(h-point.y)>=0.5 or dest.distance_to(p)<Contact.OVERLAP or not Contact.touching(dest,p):
				continue
			if guard.surface_id!=surfaces[i] and not LineOfSight.floor_ray(c.state.board,layout,Vector3(dest.x,h+0.5,dest.y),point+Vector3.UP*0.5,guard,false):
				continue
			var from:=Vector3(guard.pos.x,guard.elevation,guard.pos.y)
			var to:=layout.world(n)
			var clear:=true
			var steps:=maxi(4,ceili(from.distance_to(to)*4.0))
			for step in range(1,steps+1):
				var at:=from.lerp(to,float(step)/steps)
				if not layout.clearance(at,Figure.BASE_RADIUS,1.6) or not grid.segment_allowed(from,at):
					clear=false
					break
				for other in grid.others:
					if absf(other.elevation-at.y)<0.5 and other.pos.distance_to(Vector2(at.x,at.z))<Contact.OVERLAP:
						clear=false
						break
				if not clear:
					break
			if clear:
				return {"index":i,"guard":guard,"dest":dest,"floor":guard.surface_id,"height":h}
	return {}


func force_floor_contact(info: Dictionary) -> void:
	var guard: Figure=info["guard"]
	if not guard.in_play():
		return
	var from:=Vector3(guard.pos.x,guard.elevation,guard.pos.y)
	guard.pos=info["dest"]
	guard.elevation=float(info["height"])
	guard.surface_id=str(info["floor"])
	var to:=Vector3(guard.pos.x,guard.elevation,guard.pos.y)
	c.emit("layered_move",{"id":guard.id,"path":PackedVector3Array([from,to]),"surfaces":[guard.surface_id,guard.surface_id],"cost":0.0})
	RedKingFire.portal_contact(c,guard,Vector2(from.x,from.z),guard.pos,{},from.y,guard.elevation)
	c._magic.terrain.trigger_landing(guard)
	ScenarioSites.end_move(c,guard)
	c._magic.illusions.after_move(guard)
