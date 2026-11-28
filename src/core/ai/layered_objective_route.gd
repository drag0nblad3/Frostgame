class_name LayeredObjectiveRoute
extends RefCounted
## Targeted search to legal treasure contact or an actual scenario exit.
## Topological shortcuts need a different heuristic and retain the general
## solver. Spell-aware searches also retain their wider exploration.

static func eligible(c: GameController,f: Figure,extracting: bool) -> bool:
	if BoardTopology.linked(c.state.board) or not c.state.board.floor_layout.get("jumps",[]).is_empty():
		return false
	if f.side<0 or extracting or not CasterLoadout.is_caster(f.def.role):
		return true
	for id: String in ["teleport","leap","bridge"]:
		if c._magic.available_spell(f,id):
			return false
	return true


static func treasure_search(s: GameState,f: Figure,grid: LayeredGrid,start: Vector3i,imperfect: bool=false) -> Dictionary:
	if f.side<0 or f.def.traits.has("animal") or RuleHooks.any("cannot_carry_treasure",[s,f]):
		return {}
	var layout:=grid.layout
	var tokens: Array[TreasureToken]=[]
	for t in s.treasures:
		if t.on_ground() and t.ring_side==f.ring_side:
			tokens.append(t)
	if tokens.is_empty():
		return {}
	if imperfect:
		var scores: Array[float]=[]
		for t in tokens:
			var n:=layout.node(t.surface_id,t.pos)
			var distance:=layout.point(start).distance_to(t.pos)
			if n.z>=0:
				distance=layout.world(start).distance_to(layout.world(n))
			scores.append(distance+2.0+2.0*BotPreference.variation(s,f,t.id,"treasure"))
		var selected: Array[TreasureToken]=[]
		for i in BotPreference.objective_indices(f,scores):
			selected.append(tokens[i])
		tokens=selected
	var penalties: Dictionary={}
	var goals: Dictionary={}
	for t in tokens:
		goals[t.id]=layout.node(t.surface_id,t.pos)
	if imperfect:
		layout.prepare_coarse_navigation()
	for t in tokens:
		penalties[t.id]=2.0+2.0*BotPreference.variation(s,f,t.id,"treasure") if imperfect else 0.0
	var heuristic:=func(n: Vector3i) -> float:
		var at:=layout.point(n)
		var best:=INF
		for t in tokens:
			# Guardians allow a slightly wider contact region than normal loot.
			var radius:=1.5 if t.frozen and s.scenario_special=="complex_temple" else 0.8
			var distance:=layout.coarse_distance(n,goals[t.id]) if imperfect else at.distance_to(t.pos)
			best=minf(best,maxf(0.0,distance-radius)+float(penalties[t.id]))
		return best
	var evaluate:=func(n: Vector3i) -> float:
		for t in tokens:
			if t.surface_id!=layout.surface_id(n):
				continue
			if t.frozen and s.scenario_special=="complex_temple":
				var guardian:=ScenarioColumns.contact(s.board,layout.point(n),layout.height(n))
				if guardian!=null and guardian.rect.get_center().distance_to(t.pos)<0.01:
					return float(penalties[t.id])
			elif t.pos.distance_to(layout.point(n))<=0.8:
				return float(penalties[t.id])
		return INF
	return LayeredCombatRoute.search_goal(grid,start,heuristic,evaluate,true,100.0,BotPreference.route_budget(f) if imperfect else 0)


static func exit_search(s: GameState,f: Figure,grid: LayeredGrid,start: Vector3i,imperfect: bool=false) -> Dictionary:
	var layout:=grid.layout
	var heuristic:=func(n: Vector3i) -> float:
		return maxf(0.0,TreasureRules.edge_distance(s.board,layout.point(n))-Figure.BASE_RADIUS-0.01)
	var evaluate:=func(n: Vector3i) -> float:
		return 0.0 if LayeredLoot.is_exit(s,layout,n,f.side) else INF
	return LayeredCombatRoute.search_goal(grid,start,heuristic,evaluate,true,100.0,BotPreference.route_budget(f) if imperfect else 0)


static func move(c: GameController,f: Figure,layout: FloorLayout,reach: LayeredReach,grid: LayeredGrid,quarry: Figure,extracting: bool) -> bool:
	if not extracting and BotPreference.prefers_combat(c.state,f) and LayeredCombatRoute.move(c,f,layout,reach,grid,quarry):
		return true
	var route:=exit_search(c.state,f,grid,reach.start,true) if extracting else treasure_search(c.state,f,grid,reach.start,true)
	if route.is_empty() or route["goal"]==reach.start:
		return LayeredCombatRoute.move(c,f,layout,reach,grid,quarry)
	var path: Array[Vector3i]=route["path"]
	if f.treasure_id>=0 and RunForIt.ready(c,true):
		var run:=LayeredMovement.reach(c,false,true,true)
		for i in range(path.size()-1,0,-1):
			if reach.can_reach(path[i]):
				break
			if run.can_reach(path[i]) and c.commit_movement("run_talisman",path[i]):
				return true
	for i in range(path.size()-1,0,-1):
		if reach.can_reach(path[i]):
			return c.move_from_fresh_reach(path[i],reach)
	return false
