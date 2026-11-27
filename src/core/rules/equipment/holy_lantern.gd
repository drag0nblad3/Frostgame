class_name HolyLantern
extends RefCounted
const ITEM := "gear_rk_lantern_of_holy_light"
const OPEN := "rk_lantern_open"
const CLOSE := "rk_lantern_close"
const FLEE := "rk_lantern_flee"


static func lit(f: Figure) -> bool:
	return f!=null and f.in_play() and f.used_gear.get(OPEN,false) and ActiveGear.has(f,ITEM) and not MagicEquipment.suppressed(f)


static func glow(f: Figure) -> bool:
	return f.spell_effects.has("glow") or lit(f)


static func can_toggle(c: GameController) -> bool:
	var f := c.state.active()
	return f!=null and f.in_play() and not c.awaiting_reaction() and c.state.pending_cast.is_empty() and c.state.push_winner<0 and c.state.pending_gutter<0 and (ActiveGear.ready(f,ITEM) or lit(f))


static func toggle(c: GameController) -> bool:
	if not can_toggle(c):
		return false
	var f := c.state.active()
	if lit(f):
		f.used_gear[CLOSE]=not f.used_gear.get(CLOSE,false)
		return true
	if not ActiveGear.spend(f,ITEM):
		return false
	f.used_gear[OPEN]=true
	c.emit("gear_used",{"id":f.id,"gear":ITEM,"lit":true})
	mark(c,f,f.pos)
	return true


static func mark(c: GameController,f: Figure,at: Vector2,height: float=NAN) -> void:
	if not lit(f):
		return
	if is_nan(height):
		height=f.elevation
	for t in c.state.figures:
		if t!=f and t.in_play() and t.ring_side==f.ring_side and (t.is_demon() or t.is_undead()) and Vector2(t.pos.distance_to(at),t.elevation-height).length()<=3.0:
			t.used_gear[FLEE]={"source":f.id,"at":at}


static func observe(c: GameController,type: String,data: Dictionary) -> void:
	if type not in ["move","layered_move","push_back","force_combat","forced_relocation"]:
		return
	var f := c.state.figure(int(data.get("id",-1)))
	if not lit(f):
		return
	if data.has("path"):
		for at in data["path"]:
			if at is Vector3:
				mark(c,f,Vector2(at.x,at.z),at.y)
			else:
				mark(c,f,at)
	else:
		mark(c,f,f.pos)


static func ward(f: Figure,at: Vector2,height: float) -> bool:
	if f==null or not (f.is_undead() or f.is_demon()):
		return false
	var s := RedKingVeil.of(f)
	if s==null:
		return false
	for bearer in s.figures:
		if bearer==f or bearer.ring_side!=f.ring_side or not lit(bearer) or absf(bearer.elevation-height)>=0.5:
			continue
		var distance := bearer.pos.distance_to(at)
		if distance<1.5+Figure.BASE_RADIUS and distance<=bearer.pos.distance_to(f.pos)+0.001:
			return true
	return false


static func flee(c: GameController,f: Figure) -> void:
	if not f.in_play() or f.actions_left<=0 or not f.used_gear.has(FLEE):
		return
	var order: Dictionary=f.used_gear[FLEE]
	f.used_gear.erase(FLEE)
	var bearer := c.state.figure(order["source"])
	if not lit(bearer) or not (f.is_undead() or f.is_demon()):
		return
	var direction := (f.pos-bearer.pos).normalized()
	if direction.is_zero_approx():
		direction=Vector2.RIGHT
	if not c.state.board.floor_layout.is_empty():
		_flee_floor(c,f,direction)
		c.emit("gear_used",{"id":bearer.id,"gear":ITEM,"target":f.id,"flee":true})
		return
	var grid := MoveGrid.new(c.state.board,f,c.state.figures)
	var origin := f.pos
	var last := origin
	var path := PackedVector2Array([origin])
	var cost := 0.0
	for step in range(1,ceili(MoveRules.allowance(f)*4)+1):
		var at := origin+direction*float(step)*0.25
		if not c.state.board.can_stand(at,Figure.BASE_RADIUS) or BattleBoundary.blocks_segment(c.state.board.boundaries,last,at,"movement",f):
			break
		var blocked := false
		for other in c.state.figures:
			if other!=f and other.in_play() and other.ring_side==f.ring_side and absf(other.elevation-c.state.board.height_at(at))<0.5 and other.pos.distance_to(at)<Contact.OVERLAP:
				blocked=true
				break
		var step_cost := grid.segment_cost(last,at)
		if blocked or not is_finite(step_cost) or cost+step_cost>MoveRules.allowance(f)+0.001:
			break
		cost+=step_cost
		last=at
		path.append(at)
	if path.size()>1 and not f.spell_effects.has("bones_of_the_earth"):
		c._apply_move(f,path,cost,{})
	else:
		f.actions_left-=1
	c.emit("gear_used",{"id":bearer.id,"gear":ITEM,"target":f.id,"flee":true})


static func _flee_floor(c: GameController,f: Figure,direction: Vector2) -> void:
	var s:=c.state
	var layout:=s.board.floor_geometry()
	var start:=layout.node(f.surface_id,f.pos)
	if not layout.standable(start) or f.spell_effects.has("bones_of_the_earth"):
		f.actions_left-=1
		return
	var path:=PackedVector3Array([layout.world(start)])
	var surfaces: Array[String]=[f.surface_id]
	var last:=start
	var cost:=0.0
	var allowance:=MoveRules.allowance(f)
	for step in range(1,ceili(allowance*4.0)+1):
		var at:=MoveGrid.to_pos(MovePlanner.node_at(f.pos+direction*float(step)*0.25))
		if at==layout.point(last):
			continue
		var next:=layout.node(layout.surface_id(last),at)
		if not BattlePlacement.floor_open(s,next,f):
			break
		var a:=layout.world(last)
		var b:=layout.world(next)
		if BattleBoundary.blocks_segment(s.board.boundaries,layout.point(last),at,"movement",f) or not layout.clearance(a.lerp(b,0.5),Figure.BASE_RADIUS,1.6):
			break
		var middle:=a.lerp(b,0.5)
		var edge:=a.distance_to(b)*maxf(layout.surfaces[next.z].rough,TerrainMagic.floor_multiplier(s.board,Vector2(middle.x,middle.z),middle.y))
		if cost+edge>allowance+0.001:
			break
		cost+=edge
		last=next
		path.append(b)
		surfaces.append(layout.surface_id(next))
	if path.size()>1:
		LayeredMovement._apply(c,f,path,surfaces,cost,{},false,false,false)
	else:
		f.actions_left-=1


static func end_turn(c: GameController) -> void:
	for f in c.state.figures:
		if not f.used_gear.get(OPEN,false):
			continue
		if f.used_gear.get(CLOSE,false) or c.dice.d20()<=3:
			f.used_gear.erase(OPEN)
			f.used_gear.erase(CLOSE)
			c.emit("gear_used",{"id":f.id,"gear":ITEM,"lit":false})
