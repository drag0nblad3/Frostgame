extends TestCase


func _board() -> Board:
	return BoardLoader.load_id("stacked_gatehouse",terrain())


func _place(f: Figure,layout: FloorLayout,id: String,p: Vector2) -> void:
	f.surface_id=id
	f.pos=p
	f.elevation=layout.height(layout.node(id,p))


func test_stacked_nodes_are_distinct_and_standable() -> void:
	var layout := FloorLayout.from_dict(_board().floor_layout)
	check(layout.errors.is_empty(),str(layout.errors))
	var nodes := layout.nodes_at(Vector2(8,8))
	check_eq(nodes.size(),2)
	check_eq(layout.height(layout.node("street",Vector2(8,8))),0.0)
	check_eq(layout.height(layout.node("upper",Vector2(8,8))),3.0)
	check(not layout.standable(layout.node("street",Vector2(12.5,8))),"wall blocks ground")
	check(layout.standable(layout.node("upper",Vector2(12.5,8))),"wall ends under deck")


func test_connected_floors_require_route() -> void:
	var layout := FloorLayout.from_dict(_board().floor_layout)
	var grid := LayeredGrid.new(layout)
	var start := layout.node("street",Vector2(8,8))
	var target := layout.node("upper",Vector2(8,8))
	check(not LayeredReach.search(grid,start,4.0).can_reach(target))
	var r := LayeredReach.search(grid,start,24.0)
	check(r.can_reach(target))
	if r.can_reach(target):
		var path := r.path_to(target)
		check_eq(path[0],start)
		check_eq(path.back(),target)
		check(path.any(func(n: Vector3i) -> bool:return layout.surface_id(n)=="stairs"))
		var reverse := LayeredReach.search(grid,target,24.0)
		check(is_equal_approx(float(reverse.cost.get(start,INF)),float(r.cost[target])))
	layout.links.clear()
	check(not LayeredReach.search(grid,start,100.0).can_reach(target))


func test_stacked_occupancy_and_solid_floor_sight() -> void:
	var b := _board()
	var layout := FloorLayout.from_dict(b.floor_layout)
	var a := fig("archer",0,Vector2(8,8))
	var enemy := fig("thug",1,Vector2(8,8))
	_place(a,layout,"street",a.pos)
	_place(enemy,layout,"upper",enemy.pos)
	var grid := LayeredGrid.new(layout,a,[a,enemy])
	check(grid.open(layout.node("street",a.pos)))
	check(not grid.open(layout.node("upper",a.pos)))
	check(not Contact.figures_touch(a,enemy))
	check(not LineOfSight.check_figures(b,a,enemy).clear)
	check_eq(Shooting.blocked_reason(b,[a,enemy],a,enemy),"no line of sight")
	check(LayeredSight.clear(layout,Vector3(6,1.5,8),Vector3(10,1.0,8)))
	check(LayeredSight.clear(layout,Vector3(6,4.5,8),Vector3(10,4.0,8)))
	check(LayeredSight.clear(layout,Vector3(1,3.5,8),Vector3(5.5,4.0,8)),"open air beside deck")


func test_treasure_and_checkpoint_keep_surface() -> void:
	var b := _board()
	var layout := FloorLayout.from_dict(b.floor_layout)
	var a := fig("thug",0,Vector2(8,8))
	_place(a,layout,"street",a.pos)
	var c := make_game(b,[a],Dice.new(1))
	var token := TreasureToken.new(0,a.pos)
	token.surface_id="upper"
	c.state.treasures.append(token)
	check(not TreasureRules.can_pick_up(c.state,a,token))
	_place(a,layout,"upper",a.pos)
	check(TreasureRules.can_pick_up(c.state,a,token))
	var loaded := BattleSnapshot.rebuild(BattleSnapshot.capture(c),db())
	check(loaded!=null)
	if loaded!=null:
		check_eq(loaded.state.figure(1).surface_id,"upper")
		check_eq(loaded.state.treasure(0).surface_id,"upper")
		check_eq(loaded.state.board.floor_layout,b.floor_layout)


func test_controller_commits_floor_move_and_action_cost() -> void:
	var b := _board()
	var layout := FloorLayout.from_dict(b.floor_layout)
	var f := fig("thug",0,Vector2(2,8))
	_place(f,layout,"stairs",f.pos)
	var c := make_game(b,[f],Dice.new(1))
	c.state.active_id=1
	f.actions_left=2
	var target := layout.node("upper",Vector2(5.5,8))
	check(c.layered_reach().can_reach(target))
	check(c.move_on_floor(target))
	check_eq(f.surface_id,"upper")
	check_eq(f.elevation,3.0)
	check_eq(f.pos,Vector2(5.5,8))
	check_eq(f.actions_left,1)
	check_eq(f.moves_taken,1)
	check_eq(MoveRules.allowance(f),3.0)
	check(not c.move_to(MovePlanner.node_at(Vector2(6,8))),"legacy moves blocked")
	check(not c.move_on_floor(layout.node("street",Vector2(5.5,8))),"no implicit floor switch")
	check_eq(f.actions_left,1)
	var event: GameEvent = c.history.back()
	check_eq(event.type,"layered_move")
	check_eq(event.data["surfaces"].back(),"upper")
	var loaded := BattleSnapshot.rebuild(BattleSnapshot.capture(c),db())
	check(loaded!=null)
	if loaded!=null:
		check_eq(loaded.state.active().surface_id,"upper")
		check_eq(loaded.state.active().elevation,3.0)


func test_invalid_floor_links_are_rejected() -> void:
	var d := _board().floor_layout
	d["links"].append({"from":["unknown",1,1],"to":["upper",8,8]})
	var layout := FloorLayout.from_dict(d)
	check(not layout.errors.is_empty())


func test_bot_routes_to_correct_level() -> void:
	var layout := FloorLayout.from_dict(_board().floor_layout)
	var start := layout.node("street",Vector2(8,8))
	var target := layout.node("upper",Vector2(8,8))
	var grid := LayeredGrid.new(layout)
	var r := LayeredReach.search(grid,start,6.0)
	var next: Variant = LayeredBot.best_step(layout,r,target,grid)
	check(next!=null and next!=start)
	if next!=null:
		check(r.can_reach(next))
		check(layout.point(next).x<8.0)
