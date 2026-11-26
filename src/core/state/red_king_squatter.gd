class_name RedKingSquatter
extends RefCounted
## The Red King pp. 24–25. All persistent encounter flags live in scenario_data.
const ID := "red_king_squatter"
const ROOM := Rect2(15.5,14,5,8)


static func active(s: GameState) -> bool:
	return s.scenario_special==ID


static func awaken_near(c: GameController,at: Vector2,side: int) -> void:
	var s := c.state
	if not active(s) or side<0 or s.scenario_data.get("troll_awake",false):
		return
	for troll in s.figures:
		if troll.in_play() and troll.def.id=="snow_troll" and maxf(0.0,troll.pos.distance_to(at)-2.0*Figure.BASE_RADIUS)<=10.0:
			s.scenario_data["troll_awake"]=true
			c.emit("troll_awake",{"id":troll.id})
			return


static func dormant(c: GameController,f: Figure) -> bool:
	if not active(c.state) or f.def.id!="snow_troll":
		return false
	for unit in c.state.figures:
		if unit.in_play() and unit.side>=0:
			awaken_near(c,unit.pos,unit.side)
	return not c.state.scenario_data.get("troll_awake",false)


static func scent(s: GameState,f: Figure,t: Figure) -> bool:
	return active(s) and f.def.id=="snow_troll" and s.scenario_data.get("troll_awake",false) and Shooting.distance(f,t)<=10.0


static func _xp_once(c: GameController,side: int,key: String,xp: int) -> void:
	var flags: Dictionary=c.state.scenario_data.get("squatter_xp",{})
	var id := "%d:%s"%[side,key]
	if flags.has(id):
		return
	flags[id]=true
	c.state.scenario_data["squatter_xp"]=flags
	c.emit("squatter_xp",{"side":side,"xp":xp,"reason":key})


static func permit_step(c: GameController,f: Figure,at: Vector2) -> bool:
	if not active(c.state):
		return true
	var s := c.state
	if not ROOM.has_point(at) or ROOM.has_point(f.pos) or f.elevation>=0.5:
		awaken_near(c,at,f.side)
		return true
	var passed: Dictionary=s.scenario_data.get("squatter_passed",{})
	if not passed.has(f.id):
		var automatic := f.is_undead() or f.def.traits.has("construct")
		var roll := 20 if automatic else c.dice.d20()
		var success := automatic or StatRoll.succeeds(roll,f.effective_will()+f.roll_penalty(),14)
		c.emit("squatter_will",{"id":f.id,"roll":roll,"success":success})
		if not success:
			var failed: Dictionary=s.scenario_data.get("squatter_failed",{})
			failed[f.id]=s.turn
			s.scenario_data["squatter_failed"]=failed
			f.actions_left=0
			return false
		passed[f.id]=true
		s.scenario_data["squatter_passed"]=passed
	if f.side>=0 and f.def.role in ["wizard","apprentice"]:
		_xp_once(c,f.side,"central_room",20)
	awaken_near(c,at,f.side)
	return true


static func failed_this_turn(s: GameState,f: Figure) -> bool:
	return active(s) and int(s.scenario_data.get("squatter_failed",{}).get(f.id,-1))==s.turn


static func record_contact(c: GameController) -> void:
	if not active(c.state):
		return
	for f in c.state.figures:
		if not f.in_play() or f.side<0 or f.def.role not in ["wizard","apprentice"]:
			continue
		for enemy in Contact.enemies_of(c.state.figures,f):
			if enemy.def.id=="blood_marked_berserker":
				_xp_once(c,f.side,"berserker_combat",10)


static func record_kill(c: GameController,victim: Figure,attacker: Figure) -> void:
	if not active(c.state) or victim.side>=0 or attacker.side<0:
		return
	if victim.def.id=="blood_marked_berserker":
		c.emit("squatter_xp",{"side":attacker.side,"xp":5,"reason":"berserker_killed"})
	elif victim.def.id=="snow_troll":
		c.emit("squatter_xp",{"side":attacker.side,"xp":20,"reason":"troll_killed"})


static func end_turn(c: GameController) -> void:
	var s := c.state
	if not active(s) or s.turn<1 or s.turn>6 or s.creature_db==null or not s.creature_db.available("blood_marked_berserker"):
		return
	var corner := c.dice.pick(4)
	var target := Vector2(0.5 if corner%2==0 else s.board.size.x-0.5,0.5 if corner<2 else s.board.size.y-0.5)
	var grid := MoveGrid.new(s.board,null,s.figures)
	var nodes: Array[Vector2i]=[]
	var center := MovePlanner.node_at(target)
	for x in range(-6,7):
		for y in range(-6,7):
			var n := center+Vector2i(x,y)
			if grid.open(n):
				nodes.append(n)
	nodes.sort_custom(func(a: Vector2i,b: Vector2i) -> bool:return MoveGrid.to_pos(a).distance_squared_to(target)<MoveGrid.to_pos(b).distance_squared_to(target))
	if not nodes.is_empty():
		c._encounters._spawn_at("blood_marked_berserker",MoveGrid.to_pos(nodes[0]))


static func treasure_target(s: GameState,f: Figure) -> Variant:
	if not active(s) or f.def.id!="blood_marked_berserker":
		return null
	var best: Variant=null
	var distance := INF
	for token in s.treasures:
		if not token.unresolved():
			continue
		var carrier := s.figure(token.carrier_id)
		var at := carrier.pos if carrier!=null else token.pos
		var d := f.pos.distance_to(at)
		if d<distance:
			distance=d
			best=at
	return best


static func approach_treasure(s: GameState,f: Figure,r: MoveReach,at: Vector2) -> Variant:
	if f.pos.distance_to(at)<=Figure.BASE_RADIUS+TreasureRules.TOKEN_RADIUS+0.25:
		return null
	var field := MovePlanner.distance_field(s.board,at)
	var best_distance: float=field.get(MovePlanner.node_at(f.pos),INF)
	var best: Variant=null
	for node: Vector2i in r.nodes():
		var d: float=field.get(node,INF)
		if d<best_distance-0.25:
			best_distance=d
			best=node
	return best
