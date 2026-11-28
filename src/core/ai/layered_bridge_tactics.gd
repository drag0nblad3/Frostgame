class_name LayeredBridgeTactics
extends RefCounted
## Search bounded candidate crossings and compare the actual floor graph.
## No live mutation until the controller accepts a spell.

static func try_cast(c: GameController,f: Figure,layout: FloorLayout,long_route: LayeredReach,grid: LayeredGrid) -> bool:
	if not LayeredBridge.eligible(c) or f.health<=3:
		return false
	var objectives := LayeredTactics.loot_nodes(c.state,layout,grid)
	if objectives.is_empty():
		return false
	var baseline := 100.0
	for n in objectives:
		baseline=minf(baseline,float(long_route.cost.get(n,100.0)))
	if baseline<=MoveRules.allowance(f)*2.0:
		return false
	# Only test endpoints near the caster and facing a different loot floor.
	# Sort inexpensive estimates before the more expensive full searches.
	var unique: Dictionary={}
	for a: Vector3i in long_route.cost:
		var approach: float=long_route.cost[a]
		if approach>MoveRules.allowance(f) or a.z!=long_route.start.z:
			continue
		var directions: Array[Vector2i]=[Vector2i(12,0),Vector2i(-12,0),Vector2i(0,12),Vector2i(0,-12)]
		if ActiveGear.ready(f,TerrainMagic.EXTENDED):
			directions.append_array([Vector2i(18,0),Vector2i(-18,0),Vector2i(0,18),Vector2i(0,-18)])
		for delta: Vector2i in directions:
			for goal in objectives:
				if goal.z==a.z:
					continue
				var b := Vector3i(a.x+delta.x,a.y+delta.y,goal.z)
				if not layout.standable(b):
					continue
				var estimate := approach+layout.world(a).distance_to(layout.world(b))+layout.world(b).distance_to(layout.world(goal))
				if estimate+MoveRules.allowance(f)+2.0<baseline:
					var key: Array=[a,b]
					if not unique.has(key) or estimate<float(unique[key]["estimate"]):
						unique[key]={"a":a,"b":b,"estimate":estimate}
	var candidates: Array=unique.values()
	candidates.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:return a["estimate"]<b["estimate"])
	var budget := 0
	var route_budget:=0
	var best: Dictionary = {}
	var best_cost := baseline-MoveRules.allowance(f)-2.0
	for candidate in candidates:
		budget+=1
		if budget>24 or route_budget>=8:
			break
		var bridge := LayeredBridge.proposal(c,candidate["a"],candidate["b"],layout)
		if bridge.is_empty():
			continue
		var data := c.state.board.floor_layout.duplicate(true)
		var bridges: Array=data.get("bridges",[])
		bridges.append(bridge)
		data["bridges"]=bridges
		var hypothetical := FloorLayout.from_dict(data)
		route_budget+=1
		var cost:=objective_cost(LayeredGrid.new(hypothetical,f,c.state.figures),long_route.start,objectives,best_cost)
		if cost<best_cost:
			best_cost=cost
			best=candidate
		if budget>=8 and not best.is_empty():
			break
	return not best.is_empty() and BattleSpellAction.execute(c,"bridge",{"at":best["a"],"end":best["b"]}) and LayeredTactics.resolve(c)


## Search only as far as a useful loot destination, rather than filling
## the whole hypothetical floor graph for every proposed bridge.
static func objective_cost(grid: LayeredGrid,start: Vector3i,objectives: Array[Vector3i],limit: float) -> float:
	if objectives.is_empty():
		return INF
	var goals: Dictionary={}
	var points:=PackedVector2Array()
	for n in objectives:
		if grid.open(n) and (grid.board==null or not BattleBoundary.blocks_end(grid.board.boundaries,grid.layout.point(n))):
			goals[n]=true
			points.append(grid.layout.point(n))
	if goals.is_empty():
		return INF
	var linked:=grid.board!=null and BoardTopology.linked(grid.board)
	var heuristic:=func(n: Vector3i) -> float:
		if linked:
			return 0.0
		var at:=grid.layout.point(n)
		var best:=INF
		for point in points:
			best=minf(best,at.distance_to(point))
		return best
	var evaluate:=func(n: Vector3i) -> float:
		return 0.0 if goals.has(n) else INF
	var route:=LayeredCombatRoute.search_goal(grid,start,heuristic,evaluate,true,limit)
	return float(route.get("cost",INF))
