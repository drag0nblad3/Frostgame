class_name RedKingMadMan
extends RefCounted
## Scenario Five: capture objective and temporary opposing hunting parties.
const ID := "red_king_demons_and_mad_man"
const OCCURRENCE := [20,18,16,14,12,8,4,1]
const OCCURRENCE_MULTI := [20,19,17,16,14,11,8,4]


static func active(s: GameState) -> bool:
	return s!=null and s.scenario_special==ID


static func is_ryce(f: Figure) -> bool:
	return f!=null and f.def.traits.has("kalamon_ryce")


static func hunter(f: Figure) -> bool:
	return f!=null and f.spell_effects.has("red_king_hunter")


static func rescue(s: GameState,token: TreasureToken) -> bool:
	return active(s) and token!=null and token.id==int(s.scenario_data.get("ryce_token",-1))


static func unresolved(s: GameState) -> bool:
	var npc := s.figure(int(s.scenario_data.get("ryce_id",-1)))
	var token := s.treasure(int(s.scenario_data.get("ryce_token",-1)))
	return (npc!=null and npc.in_play()) or (token!=null and token.unresolved())


static func knock_out(c: GameController,npc: Figure,attacker: Figure) -> void:
	if not is_ryce(npc) or not npc.in_play() or hunter(attacker):
		return
	var token := c.state.treasure(int(c.state.scenario_data.get("ryce_token",-1)))
	if token==null:
		return
	npc.health=0
	npc.out_of_action=true
	token.pos=npc.pos
	token.lost=false
	c.emit("out_of_action",{"id":npc.id,"by":attacker.id})
	c.emit("ryce_unconscious",{"id":npc.id,"treasure":token.id,"at":token.pos})


static func end_turn(c: GameController) -> void:
	var s := c.state
	if not active(s):
		return
	var npc := s.figure(int(s.scenario_data.get("ryce_id",-1)))
	if npc!=null and npc.in_play():
		wander(c,npc,Vector2.RIGHT.rotated(TAU*float(c.dice.pick(20))/20.0))
	if s.turn==2 and not s.scenario_data.get("hunters_deployed",false):
		deploy_hunters(c)
	var clock := int(s.scenario_data.get("crack_clock",1))
	var table := OCCURRENCE_MULTI if s.side_count()>2 else OCCURRENCE
	var threshold: int=table[mini(clock-1,table.size()-1)]
	var trigger := false
	for side in s.side_count():
		if c.dice.d20()>threshold:
			trigger=true
	if trigger:
		reality_crack(c,c.dice.pick(2)==0)
		s.scenario_data["crack_clock"]=1
	else:
		s.scenario_data["crack_clock"]=clock+1


static func wander(c: GameController,npc: Figure,direction: Vector2) -> void:
	var s := c.state
	var start := npc.pos
	var last := start
	var travelled := 0.0
	for i in range(1,25):
		var at := start+direction*float(i)*0.25
		if at.x<Figure.BASE_RADIUS or at.y<Figure.BASE_RADIUS or at.x>s.board.size.x-Figure.BASE_RADIUS or at.y>s.board.size.y-Figure.BASE_RADIUS:
			npc.exited=true
			c.emit("exit",{"id":npc.id})
			c.emit("ryce_escaped",{"id":npc.id})
			return
		if not s.board.can_stand(at,Figure.BASE_RADIUS):
			break
		var occupied := false
		for f in s.figures:
			if f!=npc and f.in_play() and absf(f.elevation-s.board.height_at(at))<0.5 and f.pos.distance_to(at)<Contact.OVERLAP:
				occupied=true
				break
		if occupied:
			break
		travelled+=0.25+absf(s.board.height_at(at)-s.board.height_at(last))
		if travelled>6.001:
			break
		last=at
	npc.pos=last
	npc.elevation=s.board.height_at(last)
	if last!=start:
		c.emit("move",{"id":npc.id,"path":PackedVector2Array([start,last]),"cost":travelled})


static func deploy_hunters(c: GameController) -> void:
	var s := c.state
	if s.creature_db==null or not s.creature_db.available("hrut_stinger") or not s.creature_db.available("hrut_warrior"):
		return
	s.scenario_data["hunters_deployed"]=true
	var corners := [Vector2(0.5,0.5),Vector2(s.board.size.x-0.5,0.5),Vector2(0.5,s.board.size.y-0.5),s.board.size-Vector2.ONE*0.5]
	var available := corners.duplicate()
	for side: int in s.order:
		if available.is_empty():
			break
		var enemy_center := s.board.size*0.5
		for f in s.figures:
			if f.in_play() and f.side>=0 and f.side!=side and f.def.role=="wizard":
				enemy_center=f.pos
				break
		available.sort_custom(func(a: Vector2,b: Vector2) -> bool:return a.distance_squared_to(enemy_center)<b.distance_squared_to(enemy_center))
		var corner: Vector2=available.pop_front()
		var count := 2 if s.scenario_data.get("reduced_hunters_%d"%side,false) else 3
		for i in count:
			var grid := MoveGrid.new(s.board,null,s.figures)
			var origin := MovePlanner.node_at(corner)
			var best: Variant=null
			var distance := INF
			for x in range(-12,13):
				for y in range(-12,13):
					var n := origin+Vector2i(x,y)
					var d := MoveGrid.to_pos(n).distance_squared_to(corner)
					if d<=36.0 and d<distance and grid.open(n):
						best=n
						distance=d
			if best!=null:
				var unit := c._encounters._spawn_at("hrut_stinger" if i==0 else "hrut_warrior",MoveGrid.to_pos(best),side)
				unit.spell_effects["red_king_hunter"]=true
	c.emit("hrut_hunt",{})


static func reality_crack(c: GameController,horizontal: bool) -> void:
	var s := c.state
	var moving: Array[Figure]=[]
	var origins := {}
	for f in s.figures:
		if not f.in_play():
			continue
		var value := f.pos.y if horizontal else f.pos.x
		var extent := s.board.size.y if horizontal else s.board.size.x
		if minf(value,extent-value)<=8.0:
			moving.append(f)
			origins[f.id]=f.pos
	# Reserve the transformed positions simultaneously before resolving
	# blocked landings, preserving adjacent combat pairs where terrain permits.
	for f in moving:
		f.pos=s.board.size-f.pos
		f.elevation=s.board.height_at(f.pos)
	for f in moving:
		var intended := f.pos
		f.pos=ForcedRelocation.destination(s,f,intended)
		f.elevation=s.board.height_at(f.pos)
		c.emit("forced_relocation",{"id":f.id,"from":origins[f.id],"at":f.pos,"height":f.elevation})
	for side in s.side_count():
		for f in s.side_figures(side):
			if f.def.role in ["wizard","apprentice"]:
				c.emit("mad_man_xp",{"side":side,"xp":10})
				break
	c.emit("mad_man_crack",{"horizontal":horizontal})
