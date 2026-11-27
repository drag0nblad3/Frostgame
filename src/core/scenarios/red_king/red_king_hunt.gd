class_name RedKingHunt
extends RefCounted
## Sequential corner choice and deployment; all suspended state is checkpoint-safe.

static func begin(c: GameController) -> void:
	var s := c.state
	if s.creature_db==null or not s.creature_db.available("hrut_stinger") or not s.creature_db.available("hrut_warrior") or bool(s.scenario_data.get("hunters_deployed",false)):
		return
	s.scenario_data["hunters_deployed"]=true
	var priority: Array[int]=s.order.duplicate()
	if priority.is_empty():
		for side in s.side_count():
			priority.append(side)
	s.scenario_data["rk_hunt_queue"]={"sides":priority,"corners":[Vector2(0.5,0.5),Vector2(s.board.size.x-0.5,0.5),Vector2(0.5,s.board.size.y-0.5),s.board.size-Vector2.ONE*0.5]}
	_continue(c)


static func _continue(c: GameController) -> void:
	var s := c.state
	var queue: Dictionary=s.scenario_data["rk_hunt_queue"]
	while not queue["sides"].is_empty() and not queue["corners"].is_empty():
		var side: int=queue["sides"].pop_front()
		var corners: Array=queue["corners"]
		var count := 2 if s.scenario_data.get("reduced_hunters_%d"%side,false) else 3
		if side==s.reaction_side:
			var options: Array[Vector2]=[]
			for corner: Vector2 in corners:
				if not _points(c,corner).is_empty():
					options.append(corner)
			if not options.is_empty():
				s.scenario_data["rk_end_choice"]={"kind":"hunt_corner","options":options,"side":side,"remaining":count,"total":count}
				c.emit("hrut_corner_choice",{})
				return
			continue
		var enemy_center := s.board.size*0.5
		for f in s.figures:
			if f.in_play() and f.side>=0 and f.side!=side and f.def.role=="wizard":
				enemy_center=f.pos
				break
		corners.sort_custom(func(a: Vector2,b: Vector2) -> bool:return a.distance_squared_to(enemy_center)<b.distance_squared_to(enemy_center))
		var corner: Vector2=corners.pop_front()
		for i in count:
			var points := _points(c,corner)
			if points.is_empty():
				break
			points.sort_custom(func(a: Vector2,b: Vector2) -> bool:return a.distance_squared_to(corner)<b.distance_squared_to(corner))
			_spawn(c,side,points[0],i==0)
	s.scenario_data.erase("rk_hunt_queue")
	c.emit("hrut_hunt",{})


static func _points(c: GameController,corner: Vector2) -> Array[Vector2]:
	var grid := MoveGrid.new(c.state.board,null,c.state.figures)
	var center := MovePlanner.node_at(corner)
	var out: Array[Vector2]=[]
	for x in range(-12,13):
		for y in range(-12,13):
			var n := center+Vector2i(x,y)
			var at := MoveGrid.to_pos(n)
			if at.distance_squared_to(corner)<=36.001 and (grid.open(n) if c.state.board.floor_layout.is_empty() else BattlePlacement.ground_at(c.state,at)!=null):
				out.append(at)
	return out


static func points(c: GameController) -> Array[Vector2]:
	var choice: Dictionary=c.state.scenario_data.get("rk_end_choice",{})
	var out: Array[Vector2]=[]
	if choice.get("kind","")=="hunt_corner":
		out.assign(choice["options"])
	elif choice.get("kind","")=="hunt_place":
		out=_points(c,choice["corner"])
	return out


static func answer(c: GameController,at: Vector2) -> bool:
	var s := c.state
	var choice: Dictionary=s.scenario_data.get("rk_end_choice",{})
	if not points(c).has(at):
		return false
	if choice["kind"]=="hunt_corner":
		choice["kind"]="hunt_place"
		choice["corner"]=at
		s.scenario_data["rk_hunt_queue"]["corners"].erase(at)
		c.emit("hrut_place_choice",{})
		return true
	if choice["kind"]!="hunt_place":
		return false
	_spawn(c,int(choice["side"]),at,choice["remaining"]==choice["total"])
	choice["remaining"]-=1
	if int(choice["remaining"])>0 and not points(c).is_empty():
		c.emit("hrut_place_choice",{})
		return true
	s.scenario_data.erase("rk_end_choice")
	_continue(c)
	if not s.scenario_data.has("rk_end_choice"):
		RedKingMadMan._finish_turn(c)
		c._flow.resume_end_turn()
	return true


static func _spawn(c: GameController,side: int,at: Vector2,stinger: bool) -> void:
	var kind:="hrut_stinger" if stinger else "hrut_warrior"
	var unit: Figure
	if not c.state.board.floor_layout.is_empty():
		var n: Variant=BattlePlacement.ground_at(c.state,at)
		if n==null:
			return
		var layout:=c.state.board.floor_geometry()
		unit=c._encounters._spawn_at(kind,at,side,0,layout.surface_id(n),layout.height(n))
	else:
		unit=c._encounters._spawn_at(kind,at,side)
	unit.spell_effects["red_king_hunter"]=true
