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
