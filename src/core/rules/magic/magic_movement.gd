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


func move(t: Figure,at: Vector2,exhaust: bool=false,falling: bool=false,sites: bool=true,visual_spell: String="") -> void:
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
	c.emit("move", {"id":t.id,"path":PackedVector2Array([old,at]),"cost":0.0,"visual_spell":visual_spell,"start_height":height,"end_height":t.elevation})
	c._magic.terrain.trigger_landing(t)
	c._magic.illusions.after_move(t)
	if falling:
		var dmg := ElevationRules.fall_damage(height - t.elevation - (3.0 if c.state.board.low_gravity else 0.0))
		if dmg > 0 and MagicEquipment.bonus(t, "slow_fall") == 0:
			c._hurt(t, dmg, t, false)
	if sites:
		ScenarioSites.end_move(c, t)


## Explicit floor arrival. Same exhaustion, status removal, illusion and
## scenario consequences as exposed-surface magic movement.
func move_floor(t: Figure,n: Vector3i,exhaust: bool=false,falling: bool=false,visual_spell: String="",path: PackedVector3Array=PackedVector3Array(),sites: bool=true,fall_distance: float=NAN) -> void:
	var layout:=c.state.board.floor_geometry()
	if not layout.standable(n):
		return
	var landing:=layout.point(n)
	if RedKingHerded.contact(c,t,landing) or RedKingVeil.touch(c,t,landing):
		return
	var start:=Vector3(t.pos.x,t.elevation,t.pos.y)
	var old:=t.surface_id
	t.spell_effects.erase("bones_of_the_earth")
	t.pos=layout.point(n)
	t.elevation=layout.height(n)
	t.surface_id=layout.surface_id(n)
	if exhaust:
		t.magic_exhausted=true
		t.actions_left=0
	var check_portal_landing:=path.is_empty() or not visual_spell.is_empty()
	if path.is_empty():
		path=PackedVector3Array([start,layout.world(n)])
	c.emit("layered_move",{"id":t.id,"path":path,"surfaces":[old,t.surface_id],"cost":0.0,"teleport":visual_spell=="teleport" or visual_spell=="transpose","leap":visual_spell=="leap"})
	if check_portal_landing:
		RedKingFire.portal_contact(c,t,t.pos,t.pos,{},t.elevation,t.elevation)
	RedKingMind.collect(c,t,t.pos,t.pos,t.elevation,t.elevation)
	c._magic.terrain.trigger_landing(t)
	c._magic.illusions.after_move(t)
	if falling:
		LayeredFall.apply(c,t,start.y-t.elevation if is_nan(fall_distance) else fall_distance,t)
	if sites:
		ScenarioSites.end_move(c,t)


func force(t: Figure, direction: Vector2, distance: float,ivory_caster: Figure=null) -> void:
	if direction.is_zero_approx():
		return
	if not c.state.board.floor_layout.is_empty():
		force_floor(t,direction,distance,ivory_caster)
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


func force_floor(t: Figure,direction: Vector2,distance: float,ivory_caster: Figure=null) -> void:
	_apply_force_route(t,FloorDisplacement.trace(c,t,direction,distance),ivory_caster)


func _apply_force_route(t: Figure,route: Dictionary,ivory_caster: Figure=null) -> void:
	if route.is_empty():
		return
	var path: PackedVector3Array=route["path"]
	if route.get("void_at")!=null and RedKingBridge.forced_void(c,t,route["void_at"],Vector2(path[-1].x,path[-1].z),route["node"]):
		return
	var seen: Dictionary={}
	for i in range(1,path.size()):
		var from:=Vector2(path[i-1].x,path[i-1].z)
		var at:=Vector2(path[i].x,path[i].z)
		if RedKingHerded.contact(c,t,at) or RedKingVeil.touch(c,t,at):
			return
		RedKingFire.portal_contact(c,t,from,at,seen,path[i-1].y,path[i].y)
		if not t.in_play():
			return
	if path.size()>1:
		move_floor(t,route["node"],false,true,"",path,true,float(route.get("fall_distance",NAN)))
	if t.in_play() and route.get("blocked_at")!=null:
		var blocked: Vector3=route["blocked_at"]
		var last: Vector3=path[-1]
		RedKingFire.portal_contact(c,t,Vector2(last.x,last.z),Vector2(blocked.x,blocked.z),seen,last.y,blocked.y)
		if RedKingSinkhole.touches(c.state,Vector2(blocked.x,blocked.z),blocked.y) and not RedKingSinkhole.touches(c.state,t.pos,t.elevation):
			RedKingSinkhole.contact(c,t,true)
	if route["collision"] and ivory_caster!=null and t.in_play():
		c.emit("gear_used",{"id":ivory_caster.id,"target":t.id,"gear":"gear_rk_ivory_hand","damage":3})
		c._hurt(t,3,ivory_caster,false)


func swap(a: Figure, b: Figure) -> void:
	if not c.state.board.floor_layout.is_empty():
		var layout:=c.state.board.floor_geometry()
		var n:=layout.node(a.surface_id,a.pos)
		var m:=layout.node(b.surface_id,b.pos)
		if not BattlePlacement.floor_open(c.state,m,a,Figure.BASE_RADIUS,1.6,true,b) or not BattlePlacement.floor_open(c.state,n,b,Figure.BASE_RADIUS,1.6,true,a):
			return
		# Swap positions before evaluating either figure's arrival effects.
		var old_a:=Vector3(a.pos.x,a.elevation,a.pos.y)
		var old_b:=Vector3(b.pos.x,b.elevation,b.pos.y)
		var surface_a:=a.surface_id
		var surface_b:=b.surface_id
		a.pos=layout.point(m)
		a.elevation=layout.height(m)
		a.surface_id=surface_b
		b.pos=layout.point(n)
		b.elevation=layout.height(n)
		b.surface_id=surface_a
		for t in [a,b]:
			t.spell_effects.erase("bones_of_the_earth")
		c.emit("layered_move",{"id":a.id,"path":PackedVector3Array([old_a,old_b]),"surfaces":[surface_a,surface_b],"cost":0.0,"teleport":true})
		c.emit("layered_move",{"id":b.id,"path":PackedVector3Array([old_b,old_a]),"surfaces":[surface_b,surface_a],"cost":0.0,"teleport":true})
		for t in [a,b]:
			RedKingMind.collect(c,t,t.pos,t.pos,t.elevation,t.elevation)
			RedKingFire.portal_contact(c,t,t.pos,t.pos,{},t.elevation,t.elevation)
			if t.in_play():
				c._magic.terrain.trigger_landing(t)
		c._magic.illusions.after_move(a)
		c._magic.illusions.after_move(b)
		ScenarioSites.end_move(c,a)
		ScenarioSites.end_move(c,b)
		return
	var pos := a.pos
	var other := b.pos
	move(a,other,false,false,false,"transpose")
	move(b,pos,false,false,false,"transpose")
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
		var distance:=float(maxi(0,a-t.effective_armour()))
		var direction:=BattleSpace.center(t)-BattleSpace.center(f)
		if not c.state.board.floor_layout.is_empty() and absf(direction.y)>0.5:
			_apply_force_route(t,FloorDisplacement.trace_vertical(c,t,direction,distance),f if ivory else null)
		else:
			force(t,(t.pos-f.pos).normalized(),distance,f if ivory else null)


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
	return a != b and a.ring_side==b.ring_side and f.ring_side==b.ring_side and b.in_play() and not ScenarioNull.muted(a) and not ScenarioNull.muted(b) and Shooting.distance(a, b) <= 12.0 and Shooting.distance(f, b) <= 24.0 and LineOfSight.check_figures(c.state.board,f,b).clear


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
