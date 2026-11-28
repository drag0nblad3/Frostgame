extends TestCase

func test_goal_directed_contact_matches_exhaustive_cost() -> void:
	var b:=BoardLoader.from_dict({"shared_climbing":true,"size":[24,24],"pieces":[{"kind":"ruin","rect":[8,7,2,7]}]},terrain())
	var f:=fig("knight",0,Vector2(5,10))
	var enemy:=fig("thug",1,Vector2(14,10))
	f.surface_id="street"
	enemy.surface_id="street"
	var c:=make_game(b,[f,enemy],Dice.new(2))
	var l:=b.floor_geometry()
	var grid:=LayeredGrid.new(l,f,c.state.figures)
	var start:=l.node("street",f.pos)
	var foes: Array[Figure]=[enemy]
	var weights: Array[float]=[2.0]
	var targeted:=LayeredCombatRoute.search(grid,start,foes,weights)
	var all:=LayeredReach.search(grid,start,100.0)
	var best:=INF
	for n: Vector3i in all.cost:
		if Contact.touches_position(enemy,l.point(n),l.height(n),l.surface_id(n)):
			best=minf(best,float(all.cost[n])+2.0)
	check(not targeted.is_empty())
	if not targeted.is_empty():
		check(is_equal_approx(float(targeted["score"]),best))
		check(int(targeted["visited"])<all.cost.size())

func test_floor_cost_cache_respects_levitation_and_invalidation() -> void:
	var b:=BoardLoader.from_dict({"shared_climbing":true,"size":[16,16],"pieces":[{"kind":"rubble","rect":[5,5,4,4]}]},terrain())
	var f:=fig("knight",0,Vector2(6,6))
	f.surface_id="street"
	var c:=make_game(b,[f],Dice.new(2))
	var l:=b.floor_geometry()
	var a:=l.node("street",f.pos)
	var next:=l.node("street",Vector2(6.5,6))
	var g:=LayeredGrid.new(l,f,c.state.figures)
	check_eq(g._terrain_cost(a,next,l.world(a),l.world(next)),1.0)
	check(not b.floor_step_costs.is_empty())
	g.running=true
	check_eq(g._terrain_cost(a,next,l.world(a),l.world(next)),0.5)
	b.pieces.clear()
	b.invalidate_terrain()
	check(b.floor_step_costs.is_empty())
	g.running=false
	check_eq(g._terrain_cost(a,next,l.world(a),l.world(next)),0.5)


func test_treasure_and_library_exit_search_match_exhaustive() -> void:
	var b:=BoardLoader.load_id("underground_library",terrain())
	var f:=fig("knight",0,Vector2(18,5))
	f.surface_id="street"
	var c:=make_game(b,[f],Dice.new(2))
	c.state.scenario_special="underground_library"
	var t:=TreasureToken.new(0,Vector2(18,18))
	t.surface_id="street"
	c.state.treasures.append(t)
	var l:=b.floor_geometry()
	var grid:=LayeredGrid.new(l,f,c.state.figures)
	var start:=l.node("street",f.pos)
	var all:=LayeredReach.search(grid,start,100.0)
	var treasure:=LayeredObjectiveRoute.treasure_search(c.state,f,grid,start)
	var exit:=LayeredObjectiveRoute.exit_search(c.state,f,grid,start)
	var best_t:=INF
	var best_e:=INF
	for n: Vector3i in all.cost:
		if l.surface_id(n)==t.surface_id and l.point(n).distance_to(t.pos)<=0.8:
			best_t=minf(best_t,float(all.cost[n]))
		if LayeredLoot.is_exit(c.state,l,n,f.side):
			best_e=minf(best_e,float(all.cost[n]))
	check(not treasure.is_empty())
	check(not exit.is_empty())
	if not treasure.is_empty():
		check(is_equal_approx(float(treasure["cost"]),best_t))
		check(int(treasure["visited"])<all.cost.size())
	if not exit.is_empty():
		check(is_equal_approx(float(exit["cost"]),best_e))
		check(int(exit["visited"])<all.cost.size())
		check(LayeredLoot.is_exit(c.state,l,exit["goal"],f.side))


func test_bounded_search_returns_legal_prefix_without_limiting_player_reach() -> void:
	var b:=make_board()
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,36,36],"level":0}]}
	var f:=fig("knight",0,Vector2(5,5))
	f.surface_id="street"
	var c:=make_game(b,[f],Dice.new(2))
	var l:=b.floor_geometry()
	var start:=l.node("street",f.pos)
	var goal:=l.node("street",Vector2(30,5))
	var grid:=LayeredGrid.new(l,f,c.state.figures)
	var heuristic:=func(n: Vector3i) -> float:return l.point(n).distance_to(l.point(goal))
	var evaluate:=func(n: Vector3i) -> float:return 0.0 if n==goal else INF
	var result:=LayeredCombatRoute.search_goal(grid,start,heuristic,evaluate,false,100.0,12)
	check(not result.is_empty())
	if not result.is_empty():
		check(result["partial"])
		check(int(result["expanded"])<=12)
		var path: Array[Vector3i]=result["path"]
		check_eq(path[0],start)
		for i in range(1,path.size()):
			var next:=path[i]
			check(grid.neighbors(path[i-1]).any(func(edge: Dictionary) -> bool:return edge["to"]==next))
	var limited:=LayeredReach.search(grid,start,100.0,false,12)
	var full:=LayeredReach.search(grid,start,100.0)
	check(limited.truncated)
	check(not full.truncated)
	check(limited.cost.size()<full.cost.size())
	check(full.can_reach(goal))
	check_eq(f.pos,Vector2(5,5))


func test_coarse_floor_navigation_tracks_directed_portals_and_invalidation() -> void:
	var b:=make_board()
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,36,36],"level":0},{"id":"upper","rect":[8,8,8,8],"level":3}],"links":[{"from":["street",7,10],"to":["upper",9,10],"kind":"stairs","one_way":true}]}
	var l:=b.floor_geometry()
	var a:=l.node("street",Vector2(7,10))
	var goal:=l.node("upper",Vector2(10,10))
	check(l.coarse_hops(goal.z).has(a.z))
	check(not l.coarse_hops(a.z).has(goal.z))
	var distant:=l.node("street",Vector2(3,10))
	check(l.coarse_distance(a,goal)<l.coarse_distance(distant,goal))
	b.floor_layout["links"]=[]
	var revised:=b.floor_geometry()
	check(revised!=l)
	check(not revised.coarse_hops(goal.z).has(a.z))


func test_shared_planning_budget_is_not_player_movement_limit() -> void:
	var b:=make_board()
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,36,36],"level":0}]}
	var f:=fig("knight",0,Vector2(5,5))
	f.surface_id="street"
	var c:=make_game(b,[f],Dice.new(2))
	var layout:=b.floor_geometry()
	var start:=layout.node("street",f.pos)
	var target:=layout.node("street",Vector2(30,5))
	var budget: Dictionary={"remaining":17}
	var grid:=LayeredGrid.new(layout,f,c.state.figures)
	grid.ai_work=budget
	var heuristic:=func(n: Vector3i) -> float:return layout.point(n).distance_to(layout.point(target))
	var evaluate:=func(n: Vector3i) -> float:return 0.0 if n==target else INF
	var first:=LayeredCombatRoute.search_goal(grid,start,heuristic,evaluate,false,100.0,12)
	check_eq(first.get("expanded"),12)
	check_eq(budget["remaining"],5)
	var next_grid:=LayeredGrid.new(layout,f,c.state.figures)
	next_grid.ai_work=budget
	var partial:=LayeredReach.search(next_grid,start,100.0,false,50)
	check(partial.truncated)
	check_eq(budget["remaining"],0)
	check(LayeredCombatRoute.search_goal(next_grid,start,heuristic,evaluate,false,100.0,12).is_empty())
	var local:=LayeredReach.search(next_grid,start,6.0)
	var independent:=LayeredReach.search(LayeredGrid.new(layout,f,c.state.figures),start,6.0)
	check_eq(local.cost,independent.cost)
	check_eq(local.prev,independent.prev)
	check(not local.truncated)
	check_eq(budget["remaining"],0)
	check_eq(f.pos,Vector2(5,5))


func test_coarse_same_floor_distance_guides_around_solid_wall() -> void:
	var b:=make_board()
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,36,36],"level":0}],"solids":[[9,0,4,2,4,14]]}
	var l:=b.floor_geometry()
	var a:=l.node("street",Vector2(6,10))
	var target:=l.node("street",Vector2(14,10))
	var direct:=l.point(a).distance_to(l.point(target))
	var detour:=l.coarse_distance(a,target)
	check(detour>direct+4.0)
	var count:=l._horizontal_fields.size()
	check_eq(l.coarse_distance(a,target),detour)
	check_eq(l._horizontal_fields.size(),count)
	b.floor_layout["solids"]=[]
	var revised:=b.floor_geometry()
	check(revised!=l)
	check_eq(revised.coarse_distance(a,target),direct)


func test_fresh_reach_declaration_matches_regular_movement() -> void:
	for reuse in [false,true]:
		var b:=make_board()
		b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,36,36],"level":0}]}
		var f:=fig("knight",0,Vector2(5,5))
		f.surface_id="street"
		var c:=make_game(b,[f],Dice.new(2))
		c.state.active_id=f.id
		f.actions_left=2
		var reach:=c.layered_reach()
		var node:=b.floor_geometry().node("street",Vector2(7,5))
		check(reach.can_reach(node))
		var before:=LayeredGrid.evaluations
		var moved:=c.move_from_fresh_reach(node,reach) if reuse else c.move_on_floor(node)
		check(moved)
		check_eq(f.pos,Vector2(7,5))
		check_eq(f.moves_taken,1)
		check_eq(f.actions_left,1)
		check_eq(c.command_history[-1]["key"],"move_on_floor")
		if reuse:
			check_eq(LayeredGrid.evaluations,before)
