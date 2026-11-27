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
	var candidates: Array[Dictionary] = []
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
					candidates.append({"a":a,"b":b,"estimate":estimate})
	candidates.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:return a["estimate"]<b["estimate"])
	var checked := {}
	var budget := 0
	var best: Dictionary = {}
	var best_cost := baseline-MoveRules.allowance(f)-2.0
	for candidate in candidates:
		var key := str(candidate["a"])+":"+str(candidate["b"])
		if checked.has(key):
			continue
		checked[key]=true
		budget+=1
		if budget>24:
			break
		var bridge := LayeredBridge.proposal(c,candidate["a"],candidate["b"],layout)
		if bridge.is_empty():
			continue
		var data := c.state.board.floor_layout.duplicate(true)
		var bridges: Array=data.get("bridges",[])
		bridges.append(bridge)
		data["bridges"]=bridges
		var hypothetical := FloorLayout.from_dict(data)
		var route := LayeredReach.search(LayeredGrid.new(hypothetical,f,c.state.figures),long_route.start,best_cost)
		for goal in objectives:
			var cost: float=route.cost.get(goal,INF)
			if cost<best_cost:
				best_cost=cost
				best=candidate
		if budget>=8 and not best.is_empty():
			break
	return not best.is_empty() and c.bridge_on_floors(best["a"],best["b"]) and LayeredTactics.resolve(c)
