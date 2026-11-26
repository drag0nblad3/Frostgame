class_name RedKingRingworld
extends RefCounted
## Scenario twelve (Red King pp.57–60): two overlapping realities.
const ID := "red_king_ringworld"
const MARKERS := [Vector2(15,18),Vector2(5.1,6.1),Vector2(24.9,6.1),Vector2(5.1,29.9),Vector2(24.9,29.9)]


static func active(s: GameState) -> bool:
	return s!=null and s.scenario_special==ID


static func key_master(f: Figure) -> bool:
	return f!=null and f.def.id=="red_king_key_master"


static func setup(s: GameState) -> void:
	s.board.wrap_short_edges=true
	s.board.ringworld=true
	for token in s.treasures:
		token.ring_side=1 if token.id in [0,2,3] else 0
		token.central=true
	s.board.invalidate_terrain()


static func remaining(s: GameState) -> int:
	var count := 0
	for f in s.figures:
		if key_master(f) and f.in_play():
			count+=1
	return count


static func can_switch(c: GameController,f: Figure) -> bool:
	if not active(c.state) or f==null or f!=c.state.active() or not c.can_move() or c.state.group.in_progress():
		return false
	for other in c.state.figures:
		if other!=f and other.in_play() and other.ring_side!=f.ring_side and other.pos.distance_to(f.pos)<Contact.OVERLAP:
			return false
	return true


static func switch(c: GameController,f: Figure) -> bool:
	if not can_switch(c,f):
		return false
	f.actions_left-=1
	f.moves_taken+=1
	_change_plane(c,f)
	return true


static func _change_plane(c: GameController,f: Figure) -> void:
	f.ring_side=1-f.ring_side
	f.disengaged.clear()
	for other in c.state.figures:
		other.disengaged.erase(f.id)
	for id in f.carried_treasures():
		c.state.treasure(id).ring_side=f.ring_side
	c.emit("ring_switch",{"id":f.id,"plane":f.ring_side})


static func can_escape(c: GameController,f: Figure) -> bool:
	if not active(c.state) or f==null or not f.in_play() or f.side<0 or f!=c.state.active() or c.awaiting_reaction() or f.spell_effects.has("plane_walk") or IllusionRules.phantom(f):
		return false
	for other in c.state.figures:
		if key_master(other) and other.in_play() and Contact.figures_touch(f,other):
			return true
	return false


static func escape(c: GameController,f: Figure) -> bool:
	if not can_escape(c,f):
		return false
	for id in f.carried_treasures():
		c._loot.secure(c.state.treasure(id),f.side)
	f.exited=true
	f.actions_left=0
	c.emit("exit",{"id":f.id})
	return true


static func creature_turn(c: GameController,f: Figure) -> bool:
	if not active(c.state):
		return false
	if key_master(f):
		var enemy := CreatureBot.weakest(c.state,f)
		if enemy!=null:
			if c.can_fight(enemy.id):
				c.fight(enemy.id)
			if c.awaiting_reaction() or not f.in_play() or Contact.in_combat(c.state.figures,f):
				return true
		_random_move(c,f)
		return true
	if not f.def.id.begins_with("hrut_"):
		return false
	for other in c.state.figures:
		if other.side>=0 and other.in_play() and other.ring_side==f.ring_side:
			return false
	switch(c,f)
	return false


static func _random_move(c: GameController,f: Figure) -> void:
	if not c.can_move():
		return
	var direction := Vector2.RIGHT.rotated(TAU*float(c.dice.pick(20))/20.0)
	var reach := c.reach()
	var best: Variant=null
	var score := 0.0
	for node: Vector2i in reach.nodes():
		var at := MoveGrid.to_pos(node)
		var delta := at-f.pos
		if absf(delta.y)>c.state.board.size.y*0.5:
			delta.y-=signf(delta.y)*c.state.board.size.y
		if delta.length()<0.01 or delta.normalized().dot(direction)<0.85:
			continue
		var value := delta.dot(direction)
		if value>score:
			score=value
			best=node
	if best==null:
		return
	c.move_to(best)
	if f.in_play() and not c.awaiting_reaction() and minf(f.pos.x,c.state.board.size.x-f.pos.x)<=Figure.BASE_RADIUS+0.01:
		var clear := true
		for other in c.state.figures:
			if other!=f and other.in_play() and other.ring_side!=f.ring_side and other.pos.distance_to(f.pos)<Contact.OVERLAP:
				clear=false
		if clear:
			_change_plane(c,f)


static func reinforcements(roll: int) -> Dictionary:
	var rows := [[0,["hrut_warrior","hrut_warrior"]],[1,["hrut_warrior","hrut_warrior"]],[3,["hrut_warrior","hrut_warrior"]],[2,["hrut_warrior","hrut_darter"]],[4,["hrut_warrior","hrut_darter"]],[0,["hrut_stinger","hrut_darter"]],[2,["hrut_stinger","hrut_darter"]],[1,["hrut_longhammer","hrut_stinger"]],[3,["hrut_longhammer","hrut_stinger"]],[4,["hrut_longhammer","hrut_warrior","hrut_warrior","hrut_warrior","hrut_warrior"]]]
	var row: Array=rows[clampi(floori(float(roll-1)/2.0),0,9)]
	return {"marker":row[0],"types":row[1]}


static func end_turn(c: GameController) -> void:
	var s := c.state
	if not active(s) or remaining(s)==0:
		return
	var roll := c.dice.d20()
	var row := reinforcements(roll)
	var plane := 1 if c.dice.d20()>=11 else 0
	var origin: Vector2=MARKERS[row["marker"]]
	for type: String in row["types"]:
		if not s.creature_db.available(type):
			continue
		var occupied: Array[Figure]=[]
		for f in s.figures:
			if f.ring_side==plane:
				occupied.append(f)
		var grid := MoveGrid.new(s.board,null,occupied)
		var center := MovePlanner.node_at(origin)
		var best: Variant=null
		var score := INF
		for dx in range(-6,7):
			for dy in range(-6,7):
				var n := center+Vector2i(dx,dy)
				var d := MoveGrid.to_pos(n).distance_squared_to(origin)
				if d<score and grid.open(n):
					best=n
					score=d
		if best!=null:
			c._encounters._spawn_at(type,MoveGrid.to_pos(best),-1,plane)
	c.emit("ring_reinforcements",{"roll":roll,"plane":plane,"marker":int(row["marker"])+1})


static func check_end(c: GameController) -> bool:
	var s := c.state
	if not active(s):
		return false
	var success := remaining(s)==0
	if not success:
		for f in s.figures:
			if f.side>=0 and f.in_play():
				return false
	s.scenario_data["ring_success"]=success
	if success:
		for f in s.figures:
			if f.in_play():
				if f.original_side>=0:
					f.spell_effects["ring_left_behind"]=true
				c._hurt(f,f.health,f,false)
	for token in s.treasures:
		if token.unresolved():
			c._loot.lose(token)
	c.emit("ring_finale",{"success":success})
	return true


static func xp(c: GameController,side: int) -> int:
	var spells := 0
	var kills := 0
	var exited := 0
	for e in c.history:
		var d := e.data
		if e.type=="cast_result" and d.get("success",false) and int(d.get("tn",7))>6:
			var caster := c.state.figure(d["id"])
			if caster!=null and caster.original_side==side:
				spells+=10
		if e.type=="out_of_action":
			var victim := c.state.figure(d["id"])
			var attacker := c.state.figure(d["by"])
			if key_master(victim) and attacker!=null and attacker.original_side==side:
				kills+=50
	for f in c.state.figures:
		if f.original_side==side and f.exited:
			exited+=10
	var success: bool=c.state.scenario_data.get("ring_success",false)
	return mini(500,mini(100,spells)+kills+(100+exited if success else 0))
