class_name RedKingVeil
extends RefCounted
## Hidden scenario prototype, Red King pp.29–31.
const ID := "red_king_veil"


static func active(s: GameState) -> bool:
	return s!=null and s.scenario_special==ID


static func of(f: Figure) -> GameState:
	return f.battle_ref.get_ref() as GameState if f.battle_ref!=null else null


static func prepare(c: GameController) -> void:
	var s := c.state
	if not active(s) or s.scenario_data.has("veil_y"):
		return
	s.scenario_data["veil_y"]=12.0
	var slots: Array[Dictionary]=[]
	for edge in 2:
		for i in 3:
			slots.append({"type":"foulhorn" if i==0 else "blood_marked_berserker","edge":edge,"id":-1,"entered":false})
	s.scenario_data["veil_slots"]=slots
	_sync(c)


static func _sync(c: GameController) -> void:
	var s := c.state
	var y := float(s.scenario_data["veil_y"])
	var lines: Array[Dictionary]=[]
	if y<s.board.size.y:
		lines.append({"a":Vector2(0,y),"b":Vector2(s.board.size.x,y),"lethal":true})
	s.board.set_boundaries(lines)
	c.emit("boundary_changed",{"veil_y":y})


static func lethal(s: GameState,a: Vector2,b: Vector2) -> bool:
	if not active(s):
		return false
	var y := float(s.scenario_data.get("veil_y",12.0))
	return y<s.board.size.y and minf(a.y,b.y)<=y+Figure.BASE_RADIUS and maxf(a.y,b.y)>=y-Figure.BASE_RADIUS


static func touch(c: GameController,f: Figure,at: Vector2) -> bool:
	if not f.in_play() or not lethal(c.state,f.pos,at):
		return false
	c.emit("veil_contact",{"id":f.id})
	c._hurt(f,f.health,f,false)
	return true


static func advance(c: GameController,extra: int=0) -> void:
	var s := c.state
	if not active(s):
		return
	s.scenario_data["veil_y"]=minf(s.board.size.y,float(s.scenario_data.get("veil_y",12.0))+4.0+clampi(extra,0,3))
	_sync(c)


static func exit_allowed(s: GameState,at: Vector2,side: int) -> bool:
	return side!=1 and at.y>=s.board.size.y-Figure.BASE_RADIUS-0.01


static func xp(c: GameController,side: int) -> int:
	var value := c.state.secured_count(side)*25
	for f in c.state.figures:
		if f.original_side==side and f.exited:
			value+=60 if f.def.role=="wizard" else (40 if f.def.role=="apprentice" else 20)
	return value


static func before_phase(c: GameController) -> void:
	var s := c.state
	if not active(s) or s.phase not in [Phase.APPRENTICE,Phase.SOLDIER]:
		return
	for slot: Dictionary in s.scenario_data.get("veil_slots",[]):
		if slot["entered"] or (slot["type"]=="foulhorn")!=(s.phase==Phase.APPRENTICE):
			continue
		if s.turn==1 and c.dice.d20()<6:
			continue
		if _spawn(c,slot,false):
			var f := s.figure(slot["id"])
			f.spell_effects["veil_arrival"]=s.turn


static func _spawn(c: GameController,slot: Dictionary,returning: bool) -> bool:
	var s := c.state
	var y := minf(s.board.size.y,float(s.scenario_data.get("veil_y",12.0)))
	var edge := int(slot["edge"])
	var origin := Vector2(0.5 if edge==0 else s.board.size.x-0.5,minf(y-1.0,4.0+float(c.dice.pick(5))))
	if returning:
		match c.dice.pick(4):
			0: origin=Vector2(s.board.size.x*0.5,0.5)
			1: origin=Vector2(s.board.size.x*0.5,y-1.0)
			2: origin=Vector2(0.5,y*0.5)
			3: origin=Vector2(s.board.size.x-0.5,y*0.5)
	if not s.board.floor_layout.is_empty():
		var landing: Variant=BattlePlacement.nearest_ground(s,origin,4.0,func(p: Vector2) -> bool: return p.y<y-Figure.BASE_RADIUS)
		if landing==null:
			return false
		var layout:=s.board.floor_geometry()
		var spawned:=c._encounters._spawn_at(slot["type"],layout.point(landing),1,0,layout.surface_id(landing),layout.height(landing))
		slot["id"]=spawned.id
		slot["entered"]=true
		c.emit("veil_arrival",{"id":spawned.id,"returning":returning})
		return true
	var grid := MoveGrid.new(s.board,null,s.figures)
	var best: Variant=null
	var distance := INF
	var center := MovePlanner.node_at(origin)
	for dx in range(-8,9):
		for dy in range(-8,9):
			var node := center+Vector2i(dx,dy)
			var at := MoveGrid.to_pos(node)
			if at.y>=y-Figure.BASE_RADIUS or not grid.open(node):
				continue
			var d := at.distance_squared_to(origin)
			if d<distance:
				distance=d
				best=node
	if best==null:
		return false
	var f := c._encounters._spawn_at(slot["type"],MoveGrid.to_pos(best),1)
	slot["id"]=f.id
	slot["entered"]=true
	c.emit("veil_arrival",{"id":f.id,"returning":returning})
	return true


static func waiting(s: GameState) -> Array[Figure]:
	var out: Array[Figure]=[]
	for f in s.side_figures(1):
		if not f.activated and ((f.def.id=="foulhorn" and s.phase==Phase.APPRENTICE) or (f.def.id!="foulhorn" and s.phase==Phase.SOLDIER)):
			out.append(f)
	return out


static func activation(c: GameController,f: Figure) -> void:
	if not active(c.state):
		return
	if int(f.spell_effects.get("veil_skip_turn",-1))==c.state.turn:
		f.actions_left=0
	if int(f.spell_effects.get("veil_arrival",-1))==c.state.turn:
		f.actions_left=mini(f.actions_left,1)


static func end_turn(c: GameController) -> void:
	var s := c.state
	if not active(s):
		return
	var y := float(s.scenario_data["veil_y"])
	var extra := 0
	if y<s.board.size.y:
		for f in s.side_figures(0):
			if f.pos.y>y-5.0:
				extra=mini(3,maxi(0,floori(s.board.size.y-y-4.0)))
				break
		advance(c,extra)
	var targets := s.side_figures(0)
	if not targets.is_empty():
		targets.sort_custom(func(a: Figure,b: Figure) -> bool: return a.pos.y>b.pos.y)
		var target := targets[0]
		if s.reaction_side==0 and targets.size()>1:
			var options: Array[int]=[]
			for figure in targets:
				options.append(figure.id)
			s.scenario_data["rk_end_choice"]={"kind":"veil","target":target.id,"extra":extra,"options":options}
			c.emit("veil_target_choice",{"id":target.id})
			return
		_resolve_reality(c,target,extra,false)
	_return_defeated(c)


static func answer_target(c: GameController,id: int) -> bool:
	var choice: Dictionary=c.state.scenario_data.get("rk_end_choice",{})
	if choice.get("kind","")!="veil" or not choice.get("options",[]).has(id):
		return false
	var target := c.state.figure(id)
	if target==null or not target.in_play() or target.side!=0:
		return false
	c.state.scenario_data.erase("rk_end_choice")
	_resolve_reality(c,target,int(choice["extra"]),id!=int(choice["target"]))
	_return_defeated(c)
	c._flow.resume_end_turn()
	return true


static func _resolve_reality(c: GameController,target: Figure,extra: int,switched: bool) -> void:
	var roll := mini(30,c.dice.d20()+3*extra+int(switched))
	c.emit("fractured_reality",{"id":target.id,"roll":roll,"extra":extra,"switched":switched})
	reality(c,target,roll)


static func _return_defeated(c: GameController) -> void:
	var s := c.state
	for slot: Dictionary in s.scenario_data.get("veil_slots",[]):
		if slot["entered"]:
			var old := s.figure(slot["id"])
			if old!=null and old.out_of_action and c.dice.d20()>=6:
				_spawn(c,slot,true)


static func reality(c: GameController,f: Figure,roll: int) -> void:
	if roll in range(1,4) or roll in range(10,13) or roll in range(22,25) or roll in range(16,19):
		var tn := 10 if roll<=3 else (12 if roll<=12 else (14 if roll<=18 else 16))
		var raw := c.dice.d20()
		var passed := StatRoll.succeeds(raw,f.effective_will()+f.roll_penalty(),tn)
		c.emit("reality_will",{"id":f.id,"roll":raw,"tn":tn,"success":passed})
		if not passed:
			if roll in range(16,19):
				f.spell_effects["veil_move_penalty"]=int(f.spell_effects.get("veil_move_penalty",0))+1
			else:
				f.spell_effects["veil_skip_turn"]=c.state.turn+1
	elif roll in range(4,7) or roll in range(13,16) or roll in range(25,28):
		var power := 0 if roll<=6 else (2 if roll<=15 else 4)
		c._magic._shot(f,f,power,f.pos,true,true,"fractured_reality")
	elif roll in range(7,10):
		_push(c,f)
	elif roll in range(19,22):
		var affected: Array[Figure]=[]
		for other in c.state.figures:
			if other.in_play() and (other==f or Shooting.distance(f,other)<=1.0):
				affected.append(other)
		for other in affected:
			_push(c,other)
	elif roll>=28:
		for other in c.state.side_figures(0):
			ForcedRelocation.relocate(c,other,other.pos+Vector2.UP*6.0)


static func _push(c: GameController,f: Figure) -> void:
	var attack := c.dice.d20()+10
	var defence := c.dice.d20()+f.effective_fight()+f.roll_penalty()
	if attack>defence:
		c._magic.movement.force(f,Vector2.UP,float(maxi(0,attack-f.effective_armour())))


static func finish(c: GameController) -> void:
	for token in c.state.treasures:
		if token.unresolved():
			c._loot.lose(token)
