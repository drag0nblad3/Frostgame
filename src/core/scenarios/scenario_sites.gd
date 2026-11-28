class_name ScenarioSites
extends RefCounted
## Haunted dwellings and arcane transport discs (pp. 148, 150).

static func site_at(s: GameState,kind: String,at: Vector2,height: float=NAN) -> TerrainPiece:
	for p in s.board.pieces:
		if p.kind.id==kind and p.contains(at) and (s.board.floor_layout.is_empty() or is_nan(height) or absf(height-p.base_height)<0.5):
			return p
	return null


static func treasure_protected(s: GameState,at: Vector2,height: float=NAN) -> bool:
	return (s.scenario_special=="the_keep" and site_at(s,"arcane_disc",at,height)!=null) or ScenarioNull.protected_treasure(s,at)


## The occupant waits against the inner wall opposite the actual entrance.
static func hut_spawn_target(hut: TerrainPiece) -> Vector2:
	var center:=hut.rect.get_center()
	var inset:=Figure.BASE_RADIUS
	match hut.entrance:
		"south": return Vector2(center.x,hut.rect.position.y+inset)
		"west": return Vector2(hut.rect.end.x-inset,center.y)
		"east": return Vector2(hut.rect.position.x+inset,center.y)
		_: return Vector2(center.x,hut.rect.end.y-inset)


static func discover(c: GameController,at: Vector2,side: int,height: float=0.0) -> bool:
	var s := c.state
	if s.scenario_special != "haunted_houses" or side < 0 or s.creature_db == null:
		return false
	var hut := site_at(s,"haunted_floor",at,height)
	if hut == null or s.discovered_huts.has(hut.rect.position):
		return false
	s.discovered_huts[hut.rect.position] = true
	var roll := c.dice.d20()
	var kind := "" if roll <= 6 else ("ghoul" if roll <= 16 else "wraith")
	var found := false
	if kind!="" and not s.board.floor_layout.is_empty():
		var layout:=s.board.floor_geometry()
		var center:=hut.rect.get_center()
		var target:=hut_spawn_target(hut)
		var options:=BattlePlacement.nearby_floor(s,center,hut.base_height,hut.rect.size.length()*0.5,hut.surface_id)
		options.sort_custom(func(a: Vector3i,b: Vector3i) -> bool: return layout.point(a).distance_squared_to(target)<layout.point(b).distance_squared_to(target))
		for n in options:
			if hut.rect.grow(-Figure.BASE_RADIUS+0.001).has_point(layout.point(n)):
				c._encounters._spawn_on_floor(kind,n)
				found=true
				break
	elif kind != "":
		var grid := MoveGrid.new(s.board, null, s.figures)
		var target := hut_spawn_target(hut)
		var points: Array[Vector2] = []
		var inside:=hut.rect.grow(-Figure.BASE_RADIUS+0.001)
		for x in range(ceili(inside.position.x*2.0),floori(inside.end.x*2.0)+1):
			for y in range(ceili(inside.position.y*2.0),floori(inside.end.y*2.0)+1):
				var pos := Vector2(x,y)*0.5
				if grid.open(MovePlanner.node_at(pos)):
					points.append(pos)
		points.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.distance_squared_to(target) < b.distance_squared_to(target))
		if not points.is_empty():
			c._encounters._spawn_at(kind, points[0])
			found = true
	c.emit("hut_discovered", {"side": side, "at": hut.rect.get_center(), "roll": roll, "creature": kind if found else "", "xp": 15 if found else 0})
	return found


static func enter(c: GameController, f: Figure) -> bool:
	if not f.in_play() or (c.state.board.floor_layout.is_empty() and f.elevation>=0.5):
		return false
	return discover(c,f.pos,f.side,f.elevation)


static func end_move(c: GameController, f: Figure) -> void:
	if not f.in_play():
		return
	ScenarioNull.enter(c, f)
	if not f.in_play():
		return
	enter(c, f)
	ScenarioColumns.challenge(c, f)
	if not f.in_play():
		return
	var s := c.state
	if s.scenario_special!="the_keep" or (s.board.floor_layout.is_empty() and f.elevation>=0.5):
		return
	var disc := site_at(s,"arcane_disc",f.pos,f.elevation)
	if disc == null:
		return
	var roll := c.dice.d20()
	if roll >= 16:
		c.emit("disc_stay", {"id": f.id, "roll": roll})
		return
	var center := s.board.size * 0.5
	var from := disc.rect.get_center()
	var direction := -PI * 0.5 if roll <= 5 else (PI if roll <= 10 else PI * 0.5)
	var to := center + (from - center).rotated(direction)
	var dest := site_at(s, "arcane_disc", to)
	if dest == null:
		return
	var choices: Array[Dictionary]=[]
	if not s.board.floor_layout.is_empty():
		var layout:=s.board.floor_geometry()
		var options:=BattlePlacement.nearby_floor(s,to,dest.base_height,dest.rect.size.x*0.5-Figure.BASE_RADIUS,dest.surface_id,f)
		var floor_grid:=LayeredGrid.new(layout,f,s.figures)
		for n in options:
			if floor_grid.open(n):
				choices.append(CoreScenarioChoice.point(s,layout.point(n),layout.surface_id(n)))
	else:
		var grid:=MoveGrid.new(s.board,f,s.figures)
		for x in range(-2,3):
			for y in range(-2,3):
				var at:=to+Vector2(x,y)*0.5
				if at.distance_to(to)<=dest.rect.size.x*0.5-Figure.BASE_RADIUS+0.001 and grid.open(MovePlanner.node_at(at)):
					choices.append(CoreScenarioChoice.point(s,at))
	if choices.is_empty():
		c.emit("disc_stay",{"id":f.id,"roll":roll})
		return
	if CoreScenarioChoice.offer(c,"disc",f.side,f.id,-1,roll,choices):
		return
	choices.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return Vector2(a["at"]).distance_squared_to(to)<Vector2(b["at"]).distance_squared_to(to))
	land_disc(c,f,choices[0],roll)


static func land_disc(c: GameController,f: Figure,p: Dictionary,roll: int) -> void:
	var old:=f.pos
	var before:=Vector3(old.x,f.elevation,old.y)
	var previous:=f.surface_id
	f.pos=p["at"]
	f.surface_id=p["surface"]
	var world: Vector3=p["world"]
	f.elevation=world.y
	if f.surface_id.is_empty():
		c.emit("move",{"id":f.id,"path":PackedVector2Array([old,f.pos]),"cost":0.0})
	else:
		c.emit("layered_move",{"id":f.id,"path":PackedVector3Array([before,world]),"surfaces":[previous,f.surface_id],"cost":0.0})
	_finish_disc(c,f,roll)


static func _finish_disc(c: GameController,f: Figure,roll: int) -> void:
	var s:=c.state
	var xp := 0
	if f.side >= 0 and not s.disc_travellers.has(f.id):
		s.disc_travellers[f.id] = true
		xp = 30 if f.def.role == "wizard" else (20 if f.def.role == "apprentice" else 0)
	c.emit("disc_transport", {"id": f.id, "side": f.side, "roll": roll, "xp": xp})
	c._magic.terrain.trigger_landing(f)
	if f.in_play():
		c._magic.illusions.after_move(f)
