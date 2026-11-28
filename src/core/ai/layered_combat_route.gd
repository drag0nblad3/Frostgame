class_name LayeredCombatRoute
extends RefCounted
## Goal-directed combat routing. Legal endpoints and edges use the same
## grid as player movement; a horizontal lower bound never discounts a
## climb or ignores an obstruction.

static func move(c: GameController,f: Figure,layout: FloorLayout,reach: LayeredReach,grid: LayeredGrid,quarry: Figure) -> bool:
	if f.ranged!=null and f.actions_left>=2 and c.can_act() and (not f.ranged.needs_reload or f.loaded):
		var spot: Variant=LayeredBattleBot._shooting_spot(c,f,layout,reach)
		if spot!=null:
			return c.move_on_floor(spot)
	var enemies: Array[Figure]=[]
	var weights: Array[float]=[]
	for enemy in c.state.figures:
		if not enemy.in_play() or enemy.side==f.side or enemy.ring_side!=f.ring_side or WormRider.ignored(f,enemy) or RingworldBot.protected_key(c.state,f,enemy) or (RedKingMadMan.hunter(f) and RedKingMadMan.is_ryce(enemy)):
			continue
		if (quarry!=null and enemy!=quarry) or (quarry==null and not IllusionRules.visible_to(c.state.figures,f,enemy)):
			continue
		enemies.append(enemy)
		weights.append(maxf(0.0,float(enemy.health)*0.25+2.0*BotPreference.variation(c.state,f,enemy.id,"charge"))+(0.0 if BotTargets.can_harm(f,enemy,f.melee) else 20.0))
	var route:=search(grid,reach.start,enemies,weights)
	var goal: Variant=route.get("goal")
	if goal==null:
		return false
	var path: Array[Vector3i]=route["path"]
	for i in range(path.size()-1,0,-1):
		if reach.can_reach(path[i]):
			return c.move_on_floor(path[i])
	return false


static func lower_bound(layout: FloorLayout,n: Vector3i,enemies: Array[Figure],weights: Array[float]) -> float:
	var at:=layout.point(n)
	var best:=INF
	for i in enemies.size():
		best=minf(best,maxf(0.0,at.distance_to(enemies[i].pos)-Contact.CONTACT)+weights[i])
	return best


static func search(grid: LayeredGrid,start: Vector3i,enemies: Array[Figure],weights: Array[float]) -> Dictionary:
	if enemies.is_empty() or not grid.open(start):
		return {}
	var layout:=grid.layout
	var heuristic:=func(n: Vector3i) -> float:
		return lower_bound(layout,n,enemies,weights)
	var evaluate:=func(n: Vector3i) -> float:
		var weight:=INF
		for i in enemies.size():
			if Contact.touches_position(enemies[i],layout.point(n),layout.height(n),layout.surface_id(n)):
				weight=minf(weight,weights[i])
		return weight
	return search_goal(grid,start,heuristic,evaluate)


## Shared A* engine. The heuristic must be a lower bound on the remaining
## movement plus goal penalty. Infinite evaluation means not a goal.
static func search_goal(grid: LayeredGrid,start: Vector3i,heuristic: Callable,evaluate: Callable,allow_start: bool=false) -> Dictionary:
	if not grid.open(start):
		return {}
	var heap:=MinHeap.new()
	var distances: Dictionary={start:0.0}
	var prev: Dictionary={}
	var best:=INF
	var goal: Variant=null
	heap.push(float(heuristic.call(start)),start)
	while not heap.is_empty():
		var item:=heap.pop()
		var priority: float=item[0]
		var n: Vector3i=item[1]
		if priority>=best:
			break
		var distance: float=distances[n]
		if priority>distance+float(heuristic.call(n))+0.0001:
			continue
		var weight:=float(evaluate.call(n))
		if (allow_start or n!=start) and distance+weight<best:
			best=distance+weight
			goal=n
		if grid.stops(n):
			continue
		for edge in grid.neighbors(n):
			var next: Vector3i=edge["to"]
			var total:=distance+float(edge["cost"])
			if total>100.001 or total>=float(distances.get(next,INF)):
				continue
			var estimate:=total+float(heuristic.call(next))
			if estimate>=best:
				continue
			distances[next]=total
			prev[next]=n
			heap.push(estimate,next)
	if goal==null:
		return {}
	var path: Array[Vector3i]=[]
	var current: Vector3i=goal
	while current!=start:
		path.append(current)
		current=prev[current]
	path.append(start)
	path.reverse()
	return {"goal":goal,"path":path,"cost":distances[goal],"score":best,"visited":distances.size()}
