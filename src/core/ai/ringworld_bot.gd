class_name RingworldBot
extends RefCounted
## Evacuate valuable figures while leaving a fighter to close the last gate.

static func sacrifice(s: GameState,side: int) -> Figure:
	var best: Figure=null
	var score := -INF
	for f in s.side_figures(side):
		if IllusionRules.phantom(f) or f.spell_effects.has("plane_walk"):
			continue
		var value := float(f.effective_fight()*3+f.health)
		if f.def.role in ["wizard","apprentice"]:
			value-=50.0
		if f.treasure_id>=0:
			value-=30.0
		if value>score:
			best=f
			score=value
	return best


static func protected_key(s: GameState,f: Figure,t: Figure) -> bool:
	return RedKingRingworld.active(s) and RedKingRingworld.key_master(t) and RedKingRingworld.remaining(s)==1 and s.side_figures(f.side).size()>1


static func play(c: GameController,f: Figure) -> bool:
	var s := c.state
	if not s.board.floor_layout.is_empty():
		return _play_floor(c,f)
	var keys := RedKingRingworld.remaining(s)
	if keys==0 or IllusionRules.phantom(f):
		return false
	var final_fighter := sacrifice(s,f.side)==f
	var evacuate := (f.treasure_id>=0 or (keys==1 and not final_fighter))
	if evacuate and (not final_fighter or s.side_figures(f.side).size()>1):
		for i in 2:
			if RedKingRingworld.escape(c,f):
				return true
			if not c.can_move() or not _approach_key(c,f):
				break
		return f.moves_taken>0
	# While more than one gate survives, unburdened soldiers can collect
	# local treasure; otherwise concentrate on a living key.
	if keys>1 and not Contact.in_combat(s.figures,f) and not f.def.traits.has("animal") and f.treasure_id<0:
		for token in s.treasures:
			if c.can_pick_up(token.id) and c.pick_up(token.id):
				return true
		var token := TreasureBot._nearest(c,f)
		if token!=null and c.can_move() and f.pos.distance_to(token.pos)<=10.0:
			var field := MovePlanner.distance_field(s.board,token.pos)
			var reach := c.reach()
			var best: Variant=null
			var distance: float=field.get(MovePlanner.node_at(f.pos),INF)
			for n: Vector2i in reach.nodes():
				var value: float=field.get(n,INF)
				if value<distance-0.05:
					best=n
					distance=value
			if best!=null and c.move_to(best):
				if c.can_pick_up(token.id):
					c.pick_up(token.id)
				return true
	# Do not finish the last key while other friendly figures remain.
	if keys==1 and s.side_figures(f.side).size()>1:
		if c.can_move():
			return _approach_key(c,f)
		return false
	# Let normal combat/casting take place when a key can be attacked now.
	for key in s.figures:
		if not key.in_play() or not RedKingRingworld.key_master(key) or key.ring_side!=f.ring_side:
			continue
		if c.can_fight(key.id) or c.can_shoot(key.id):
			return false
		if f.def.role in ["wizard","apprentice"] and c.can_cast("elemental_bolt",key.id):
			return false
	return c.can_move() and _approach_key(c,f)


static func _approach_key(c: GameController,f: Figure) -> bool:
	var s := c.state
	var same: Array[Figure]=[]
	for key in s.figures:
		if key.in_play() and RedKingRingworld.key_master(key) and key.ring_side==f.ring_side:
			same.append(key)
	if same.is_empty():
		return RedKingRingworld.switch(c,f)
	var reach := c.reach()
	var best: Variant=null
	var gain := 0.05
	for key in same:
		var field := MovePlanner.distance_field(s.board,key.pos)
		var before: float=field.get(MovePlanner.node_at(f.pos),INF)
		for n: Vector2i in reach.nodes():
			var distance: float=field.get(n,INF)
			if not is_finite(distance):
				continue
			var improvement := before-distance
			if improvement>gain:
				gain=improvement
				best=n
	return best!=null and c.move_to(best)


## Same evacuation policy, with the floor graph supplying legal approach nodes.
static func _play_floor(c: GameController,f: Figure) -> bool:
	var s:=c.state
	var keys:=RedKingRingworld.remaining(s)
	if keys==0 or IllusionRules.phantom(f):
		return false
	var final_fighter:=sacrifice(s,f.side)==f
	var evacuate:=f.treasure_id>=0 or (keys==1 and not final_fighter)
	if evacuate and (not final_fighter or s.side_figures(f.side).size()>1):
		for i in 2:
			if RedKingRingworld.escape(c,f):
				return true
			if not c.can_move() or not _approach_key_floor(c,f):
				break
		return f.moves_taken>0
	if keys>1 and not Contact.in_combat(s.figures,f) and f.treasure_id<0:
		for token in s.treasures:
			if c.can_pick_up(token.id):
				return c.pick_up(token.id)
		for token in s.treasures:
			if token.on_ground() and token.ring_side==f.ring_side and token.pos.distance_to(f.pos)<=10.0 and not f.def.traits.has("animal"):
				return false
	if keys==1 and s.side_figures(f.side).size()>1:
		return c.can_move() and _approach_key_floor(c,f)
	for key in s.figures:
		if key.in_play() and RedKingRingworld.key_master(key) and key.ring_side==f.ring_side:
			if c.can_fight(key.id) or c.can_shoot(key.id) or c.can_cast("elemental_bolt",key.id):
				return false
	return c.can_move() and _approach_key_floor(c,f)


static func _approach_key_floor(c: GameController,f: Figure) -> bool:
	var layout:=c.state.board.floor_geometry()
	var keys: Array[Figure]=[]
	for key in c.state.figures:
		if key.in_play() and RedKingRingworld.key_master(key) and key.ring_side==f.ring_side:
			keys.append(key)
	if keys.is_empty():
		return RedKingRingworld.switch(c,f)
	var reach:=c.layered_reach()
	if reach.cost.is_empty():
		return false
	var route:=LayeredReach.search(LayeredGrid.new(layout,f,c.state.figures),reach.start,100.0)
	var best: Variant=null
	var score:=INF
	for n: Vector3i in route.cost:
		if n==reach.start or float(route.cost[n])>=score:
			continue
		for key in keys:
			if Contact.touches_position(key,layout.point(n),layout.height(n),layout.surface_id(n)):
				score=float(route.cost[n])
				best=n
	if best==null:
		return false
	var path:=route.path_to(best)
	for i in range(path.size()-1,0,-1):
		if reach.can_reach(path[i]):
			return c.move_on_floor(path[i])
	return false
