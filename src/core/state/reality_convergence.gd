class_name RealityConvergence
extends RefCounted
## Six directional selections, with placement by the controlling player.
## Keep the remaining iterations and moved IDs as plain checkpoint data.

static func begin(c: GameController) -> void:
	c.state.scenario_data["rk_convergence"]={"remaining":6,"moved":[]}
	_continue(c)


static func _continue(c: GameController) -> void:
	var s := c.state
	var queue: Dictionary=s.scenario_data["rk_convergence"]
	var center := s.board.size*0.5
	while int(queue["remaining"])>0:
		queue["remaining"]-=1
		var end := center+RealityCracks.direction(c)*s.board.size.length()
		var best: Figure=null
		var score := INF
		for f in s.figures:
			if not f.in_play() or queue["moved"].has(f.id) or f.pos.distance_to(Geometry2D.get_closest_point_to_segment(f.pos,center,end))>3.0:
				continue
			var d := f.pos.distance_squared_to(center)
			if d<score:
				best=f
				score=d
		if best==null:
			continue
		if queue["moved"].is_empty():
			ForcedRelocation.relocate(c,best,center)
			queue["moved"].append(best.id)
			continue
		var options := placements(c,best,queue["moved"])
		if options.is_empty():
			c.emit("convergence_blocked",{"id":best.id})
			continue
		var side := best.side if best.side>=0 else _roll_off(c)
		if side==s.reaction_side and side>=0:
			s.scenario_data["rk_priority_choice"]={"kind":"convergence","id":best.id}
			c.emit("convergence_choice",{"id":best.id})
			return
		var at := _bot_position(s,best,options,side)
		ForcedRelocation.relocate(c,best,at)
		queue["moved"].append(best.id)
	s.scenario_data.erase("rk_convergence")
	RealityCracks.clear(c)


static func _roll_off(c: GameController) -> int:
	var sides: Array[int]=[]
	for side in c.state.side_count():
		sides.append(side)
	# Tied highest players roll again; bounded fallback protects custom dice.
	for attempt in 20:
		var best := -1
		var winners: Array[int]=[]
		for side in sides:
			var roll := c.dice.d20()
			if roll>best:
				best=roll
				winners.assign([side])
			elif roll==best:
				winners.append(side)
		sides=winners
		if sides.size()<=1:
			break
	return sides[0] if not sides.is_empty() else -1


static func placements(c: GameController,f: Figure,moved: Array) -> Array[Vector2]:
	var s := c.state
	var grid := MoveGrid.new(s.board,f,s.figures)
	var out: Array[Vector2]=[]
	for id: int in moved:
		var anchor := s.figure(id)
		if anchor==null or not anchor.in_play():
			continue
		var node := MovePlanner.node_at(anchor.pos)
		for x in range(-3,4):
			for y in range(-3,4):
				var n := node+Vector2i(x,y)
				var at := MoveGrid.to_pos(n)
				if out.has(at) or not grid.open(n) or BattleBoundary.blocks_end(s.board.boundaries,at):
					continue
				if absf(anchor.elevation-s.board.height_at(at))<0.5 and Contact.touching(anchor.pos,at) and anchor.pos.distance_to(at)>=Contact.OVERLAP:
					out.append(at)
	return out


static func points(c: GameController) -> Array[Vector2]:
	var choice: Dictionary=c.state.scenario_data.get("rk_priority_choice",{})
	if choice.get("kind","")!="convergence":
		return []
	var f := c.state.figure(int(choice["id"]))
	return placements(c,f,c.state.scenario_data["rk_convergence"]["moved"]) if f!=null and f.in_play() else []


static func answer(c: GameController,at: Vector2) -> bool:
	if not points(c).has(at):
		return false
	var s := c.state
	var f := s.figure(int(s.scenario_data["rk_priority_choice"]["id"]))
	s.scenario_data.erase("rk_priority_choice")
	ForcedRelocation.relocate(c,f,at)
	s.scenario_data["rk_convergence"]["moved"].append(f.id)
	_continue(c)
	if not s.scenario_data.has("rk_priority_choice"):
		c._flow.resume_priority()
	return true


static func _bot_position(s: GameState,f: Figure,options: Array[Vector2],side: int) -> Vector2:
	var best := options[0]
	var best_score := -INF
	for at in options:
		var danger := 0.0
		for other in s.figures:
			if other==f or not other.in_play() or absf(other.elevation-s.board.height_at(at))>=0.5:
				continue
			if Contact.touching(other.pos,at):
				danger+=1.0 if other.side==side else -2.0
		var score := danger if f.side==side else -danger
		if score>best_score:
			best_score=score
			best=at
	return best
