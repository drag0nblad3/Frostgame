class_name RedKingHerded
extends RefCounted
## Act III chase encounter. The trailing edge is consumed permanently.
const ID := "red_king_herded"


static func active(s: GameState) -> bool:
	return s!=null and s.scenario_special==ID


static func setup(s: GameState) -> void:
	s.scenario_data["herd_veil"]=0.0
	var pool: Array[Dictionary]=[]
	for f in s.figures:
		if f.side<0 and f.def.id.begins_with("hrut_"):
			pool.append({"type":f.def.id,"id":f.id})
	for id in ["hrut_longhammer","hrut_stinger","hrut_stinger"]:
		pool.append({"type":id,"id":-1})
	s.scenario_data["herd_pool"]=pool


static func distance_for(roll: int) -> int:
	return 2 if roll<=4 else (3 if roll<=8 else (4 if roll<=14 else (5 if roll<=18 else 6)))


static func end_turn(c: GameController) -> void:
	if not active(c.state):
		return
	advance(c,distance_for(c.dice.d20()))
	if float(c.state.scenario_data["herd_veil"])<c.state.board.size.y:
		reinforce(c)


static func advance(c: GameController,distance: int) -> void:
	var s := c.state
	var y := minf(s.board.size.y,float(s.scenario_data.get("herd_veil",0.0))+distance)
	s.scenario_data["herd_veil"]=y
	var lines: Array[Dictionary]=[{"a":Vector2(0,y),"b":Vector2(s.board.size.x,y),"lethal":true}]
	s.board.set_boundaries(lines)
	c.emit("boundary_changed",{"veil_y":y})
	c.emit("herd_veil",{"distance":distance,"y":y})
	for f in s.figures:
		if f.in_play():
			contact(c,f,f.pos)
	for t in s.treasures:
		if t.on_ground() and t.pos.y+TreasureRules.TOKEN_RADIUS<y:
			c._loot.lose(t)


static func contact(c: GameController,f: Figure,at: Vector2) -> bool:
	if not active(c.state) or not f.in_play():
		return false
	var s := c.state
	var y := float(s.scenario_data.get("herd_veil",0.0))
	if y<=0.0 or at.y>y+Figure.BASE_RADIUS:
		return false
	c.emit("herd_contact",{"id":f.id})
	if at.y+Figure.BASE_RADIUS<=y or y>=s.board.size.y:
		c._hurt(f,f.health,f,false)
		return true
	c._hurt(f,6,f,false)
	if not f.in_play():
		return true
	# Search only the surviving side of the veil. Blocked landings are
	# resolved by the nearest legal point rather than overlap a miniature.
	var grid := MoveGrid.new(s.board,f,s.figures)
	var desired := Vector2(at.x,y+Figure.BASE_RADIUS+0.01)
	var center := MovePlanner.node_at(desired)
	var best: Variant=null
	var score := INF
	for dx in range(-12,13):
		for dy in range(0,13):
			var n := center+Vector2i(dx,dy)
			var p := MoveGrid.to_pos(n)
			var d := p.distance_squared_to(desired)
			if p.y>y+Figure.BASE_RADIUS and d<score and grid.open(n):
				best=n
				score=d
	if best==null:
		c._hurt(f,f.health,f,false)
	else:
		var from := f.pos
		f.pos=MoveGrid.to_pos(best)
		f.elevation=s.board.height_at(f.pos)
		c.emit("forced_relocation",{"id":f.id,"from":from,"at":f.pos,"height":f.elevation})
	return true


static func reinforce(c: GameController) -> void:
	var s := c.state
	for slot: Dictionary in s.scenario_data.get("herd_pool",[]):
		var old := s.figure(int(slot["id"]))
		if old!=null and old.in_play():
			continue
		if not s.creature_db.available(slot["type"]) or c.dice.d20()<17:
			continue
		var corner := Vector2(0.5 if c.dice.pick(2)==0 else s.board.size.x-0.5,s.board.size.y-0.5)
		var grid := MoveGrid.new(s.board,null,s.figures)
		var center := MovePlanner.node_at(corner)
		var best: Variant=null
		var score := INF
		for dx in range(-8,9):
			for dy in range(-8,9):
				var n := center+Vector2i(dx,dy)
				var at := MoveGrid.to_pos(n)
				var d := at.distance_squared_to(corner)
				if at.y>float(s.scenario_data["herd_veil"])+Figure.BASE_RADIUS and d<score and grid.open(n):
					best=n
					score=d
		if best!=null:
			var f := c._encounters._spawn_at(slot["type"],MoveGrid.to_pos(best))
			slot["id"]=f.id


static func exit_xp(s: GameState,side: int) -> int:
	var xp := 0
	for f in s.figures:
		if f.original_side==side and f.exited:
			xp+=30 if f.def.role=="wizard" else (25 if f.def.role=="apprentice" else 10)
	return xp
