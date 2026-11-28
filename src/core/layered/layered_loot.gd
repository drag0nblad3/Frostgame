class_name LayeredLoot
extends RefCounted


static func exit_nodes(c: GameController) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	var f := c.state.active()
	if f==null or f.side<0 or f.control_spell=="mind_control" or f.spell_effects.has("plane_walk") or FuryRules.target(c.state,f)!=null or RedKingMind.active(c.state):
		return out
	var layout := c.state.board.floor_geometry()
	var r := c.layered_reach()
	for n: Vector3i in r.cost:
		if is_exit(c.state,layout,n,f.side) and float(r.cost[n])+Figure.BASE_RADIUS<=MoveRules.allowance(f)+0.001:
			var blocked := false
			for enemy in c.state.figures:
				if enemy.in_play() and enemy.ring_side==f.ring_side and enemy.side!=f.side and Contact.touches_position(enemy,layout.point(n),layout.height(n),layout.surface_id(n)):
					blocked=true
					break
			if not blocked:
				out.append(n)
	return out


static func is_exit(s: GameState,layout: FloorLayout,n: Vector3i,side: int=-1) -> bool:
	if not layout.standable(n):
		return false
	# Only authored extraction surfaces may lead off the table.
	var allowed: Array = s.board.floor_layout.get("exit_surfaces",["street"])
	return allowed.has(layout.surface_id(n)) and TreasureRules.edge_distance(s.board,layout.point(n))<=Figure.BASE_RADIUS+0.01 and ScenarioObjectives.exit_allowed(s,layout.point(n),side)


static func exit(c: GameController,n: Vector3i) -> bool:
	if not exit_nodes(c).has(n):
		return false
	var f := c.state.active()
	var layout := c.state.board.floor_geometry()
	if n!=layout.node(f.surface_id,f.pos):
		return LayeredMovement.move(c,n,false,false,false,true)
	c.spend_move(f)
	complete(c,f)
	return true


static func complete(c: GameController,f: Figure) -> void:
	var layout:=c.state.board.floor_geometry()
	if f.in_play() and is_exit(c.state,layout,layout.node(f.surface_id,f.pos),f.side) and not Contact.in_combat(c.state.figures,f):
		c._loot.complete_exit(f)


## Route an escaping creature to an authored edge without granting treasure extraction.
static func advance_to_exit(c: GameController,f: Figure) -> bool:
	var layout:=c.state.board.floor_geometry()
	var reach:=c.layered_reach()
	if reach.cost.is_empty():
		return false
	var grid:=LayeredGrid.new(layout,f,c.state.figures)
	if not BoardTopology.linked(c.state.board):
		var route:=LayeredObjectiveRoute.exit_search(c.state,f,grid,reach.start)
		if route.is_empty():
			return false
		var targeted: Array[Vector3i]=route["path"]
		for i in range(targeted.size()-1,0,-1):
			if reach.can_reach(targeted[i]):
				return c.move_on_floor(targeted[i])
		return false
	var long_route:=LayeredReach.search(grid,reach.start,100.0)
	var best: Variant=null
	var value:=INF
	for node: Vector3i in long_route.cost:
		if float(long_route.cost[node])<value and is_exit(c.state,layout,node,f.side):
			best=node
			value=float(long_route.cost[node])
	if best==null:
		return false
	var path:=long_route.path_to(best)
	for i in range(path.size()-1,0,-1):
		if reach.can_reach(path[i]):
			return c.move_on_floor(path[i])
	return false
