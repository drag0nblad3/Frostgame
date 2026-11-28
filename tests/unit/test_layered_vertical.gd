extends TestCase


func _gate() -> GameController:
	return LayeredBattle.create(db(),terrain(),17)


func test_partial_climb_and_restore() -> void:
	var c := _gate()
	var f := c.state.figure(2)
	c.state.active_id=f.id
	f.surface_id="street"
	f.pos=Vector2(13.5,8)
	f.elevation=0.0
	f.actions_left=2
	f.moves_taken=1
	var layout := FloorLayout.from_dict(c.state.board.floor_layout)
	check(layout.errors.is_empty(),str(layout.errors))
	var hanging := layout.node("climb:east_wall:1",f.pos)
	check(c.layered_reach().can_reach(hanging))
	check(c.move_on_floor(hanging))
	check_eq(f.elevation,1.0)
	check_eq(f.actions_left,1)
	var restored := BattleSnapshot.rebuild(BattleSnapshot.capture(c),db())
	check(restored!=null)
	if restored!=null:
		check_eq(restored.state.active().surface_id,"climb:east_wall:1")
		check_eq(restored.state.active().elevation,1.0)
	f.actions_left=2
	f.moves_taken=0
	check(c.move_on_floor(layout.node("upper",Vector2(12.5,8))))
	check_eq(f.elevation,3.0)


func test_push_over_ledge_damages_and_changes_floor() -> void:
	var c := _gate()
	var a := c.state.figure(2)
	var b := c.state.figure(5)
	a.surface_id="upper"
	a.pos=Vector2(11.5,8)
	a.elevation=3.0
	b.surface_id="upper"
	b.pos=Vector2(12.5,8)
	b.elevation=3.0
	c.state.push_winner=a.id
	c.state.push_loser=b.id
	var hp := b.health
	check(c.can_push(false))
	check(c.resolve_push(false))
	check_eq(b.surface_id,"street")
	check_eq(b.elevation,0.0)
	check_eq(b.health,hp-ElevationRules.fall_damage(3.0))


func test_jump_needs_runup_and_consumes_movement() -> void:
	var b := make_board()
	b.floor_layout={"surfaces":[{"id":"west","rect":[0,0,6,6],"level":3},{"id":"east","rect":[7,0,6,6],"level":3}],"jumps":[{"from":["west",5.5,3],"to":["east",7.5,3]}]}
	var f := fig("thug",0,Vector2(3.5,3))
	f.surface_id="west"
	f.elevation=3.0
	var c := make_game(b,[f],Dice.new(1))
	c.state.active_id=1
	f.actions_left=2
	var layout := FloorLayout.from_dict(b.floor_layout)
	var target := layout.node("east",Vector2(7.5,3))
	check(LayeredJump.plans(c).has(target))
	f.pos=Vector2(4.5,3)
	check(not LayeredJump.plans(c).has(target))
	f.pos=Vector2(3.5,3)
	check(c.jump_on_floor(target))
	check_eq(f.surface_id,"east")
	check_eq(f.actions_left,1)
	check_eq(f.moves_taken,1)


func test_geometry_gap_jump_without_authored_link() -> void:
	var b:=make_board()
	b.floor_layout={"surfaces":[{"id":"west","rect":[0,0,6,6],"level":3},{"id":"east","rect":[7,0,6,6],"level":3}]}
	var f:=fig("thug",0,Vector2(3.5,3))
	f.surface_id="west"
	f.elevation=3.0
	var c:=make_game(b,[f],Dice.new(1))
	c.state.active_id=1
	f.actions_left=2
	var target:=b.floor_geometry().node("east",Vector2(7.5,3))
	check(LayeredJump.plans(c,true).has(target))
	check(c.commit_movement("jump",target))
	check_eq(f.surface_id,"east")

func test_short_jump_requires_no_runup() -> void:
	var b:=make_board()
	b.floor_layout={"surfaces":[{"id":"west","rect":[0,0,6,6],"level":3},{"id":"east","rect":[6,0,6,6],"level":3}],"jumps":[{"from":["west",5.5,3],"to":["east",6.5,3]}]}
	var f:=fig("thug",0,Vector2(5.5,3))
	f.surface_id="west"
	f.elevation=3.0
	var c:=make_game(b,[f],Dice.new(1))
	c.state.active_id=1
	f.actions_left=2
	check(LayeredJump.plans(c).has(b.floor_geometry().node("east",Vector2(6.5,3))))

func test_voluntary_fall_has_cost_damage_and_no_preview_mutation() -> void:
	var b:=make_board()
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,36,36],"level":0},{"id":"deck","rect":[8,8,5,5],"level":3}]}
	var f:=fig("thug",0,Vector2(12.5,10))
	f.surface_id="deck"
	f.elevation=3.0
	var c:=make_game(b,[f],Dice.new(1))
	c.state.active_id=1
	f.actions_left=2
	var target:=b.floor_geometry().node("street",Vector2(13.5,10))
	var hp:=f.health
	var options:=LayeredDrop.plans(c)
	check(options.has(target))
	check_eq(f.health,hp)
	check_eq(f.surface_id,"deck")
	check_eq(f.actions_left,2)
	if options.has(target):
		check_eq(options[target]["cost"],4.0)
		check(c.commit_movement("drop_down",target))
		check_eq(f.surface_id,"street")
		check_eq(f.health,hp-4)
		check_eq(f.moves_taken,1)
		check_eq(f.actions_left,1)


func _jump_reaction(guard_on_landing: bool) -> GameController:
	var b:=make_board()
	b.floor_layout={"surfaces":[{"id":"west","rect":[0,0,6,6],"level":3},{"id":"east","rect":[7,0,6,6],"level":3}],"jumps":[{"from":["west",5.5,3],"to":["east",7.5,3]}]}
	var f:=fig("thug",0,Vector2(3.5,3))
	f.surface_id="west"
	f.elevation=3.0
	var g:=fig("thug",1,Vector2(9.5,3) if guard_on_landing else Vector2(4.5,5),2)
	g.surface_id="east" if guard_on_landing else "west"
	g.elevation=3.0
	var c:=make_game(b,[f,g],Dice.new(19))
	c.state.active_id=f.id
	f.actions_left=2
	c.state.forced_combat=true
	c.state.reaction_side=1
	return c


func test_runup_interception_stops_before_jump() -> void:
	var c:=_jump_reaction(false)
	var f:=c.state.active()
	var target:=c.state.board.floor_geometry().node("east",Vector2(7.5,3))
	check(c.jump_on_floor(target))
	check(not c.state.pending_intercept.is_empty())
	check_eq(f.pos,Vector2(3.5,3))
	check_eq(f.actions_left,2)
	if c.state.pending_intercept.is_empty():
		return
	check(c.answer_intercept(true))
	check_eq(f.surface_id,"west")
	check_eq(f.moves_taken,1)
	check_eq(f.actions_left,1)
	check(Contact.in_combat(c.state.figures,f))


func test_landing_interception_may_be_declined() -> void:
	for accept in [false,true]:
		var c:=_jump_reaction(true)
		var f:=c.state.active()
		var target:=c.state.board.floor_geometry().node("east",Vector2(7.5,3))
		check(c.jump_on_floor(target))
		check(not c.state.pending_intercept.is_empty())
		check_eq(f.moves_taken,0)
		if c.state.pending_intercept.is_empty():
			continue
		check(c.answer_intercept(accept))
		check_eq(f.surface_id,"east")
		check_eq(f.pos,Vector2(7.5,3))
		check_eq(f.moves_taken,1)
		check_eq(f.actions_left,1)
		check_eq(Contact.in_combat(c.state.figures,f),accept)


func test_drop_landing_interception_retains_fall_damage() -> void:
	var b:=make_board()
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,36,36],"level":0},{"id":"deck","rect":[8,8,5,5],"level":3}]}
	var f:=fig("thug",0,Vector2(12.5,10))
	f.surface_id="deck"
	f.elevation=3.0
	var g:=fig("thug",1,Vector2(15.5,10),2)
	g.surface_id="street"
	var c:=make_game(b,[f,g],Dice.new(19))
	c.state.active_id=f.id
	f.actions_left=2
	c.state.forced_combat=true
	c.state.reaction_side=1
	var hp:=f.health
	var dest:=b.floor_geometry().node("street",Vector2(13.5,10))
	check(c.commit_movement("drop_down",dest))
	check(not c.state.pending_intercept.is_empty())
	check_eq(f.health,hp)
	if c.state.pending_intercept.is_empty():
		return
	check(c.answer_intercept(true))
	check_eq(f.surface_id,"street")
	check_eq(f.health,hp-4)
	check_eq(f.moves_taken,1)
	check(Contact.in_combat(c.state.figures,f))


func test_jump_with_followthrough_uses_one_move() -> void:
	var c:=_jump_reaction(true)
	var f:=c.state.active()
	c.state.figure(2).pos=Vector2(12.5,5)
	var layout:=c.state.board.floor_geometry()
	var dest:=layout.node("east",Vector2(9,3))
	var too_far:=layout.node("east",Vector2(10,3))
	var options:=c.movement_options("jump")
	check(options.cost.has(dest))
	check(not options.cost.has(too_far))
	check_eq(f.pos,Vector2(3.5,3))
	check_eq(f.actions_left,2)
	if not options.cost.has(dest):
		return
	check(absf(float(options.cost[dest])-5.5)<0.001)
	check_eq(options.path(dest)[-1],layout.world(dest))
	check(c.commit_movement("jump",dest))
	check_eq(f.pos,Vector2(9,3))
	check_eq(f.surface_id,"east")
	check_eq(f.moves_taken,1)
	check_eq(f.actions_left,1)


func test_interception_after_jump_stops_remaining_walk() -> void:
	var c:=_jump_reaction(true)
	var f:=c.state.active()
	c.state.figure(2).pos=Vector2(10,3)
	var target:=c.state.board.floor_geometry().node("east",Vector2(8.5,3))
	check(c.commit_movement("jump",target))
	check(not c.state.pending_intercept.is_empty())
	if c.state.pending_intercept.is_empty():
		return
	check(c.answer_intercept(true))
	check_eq(f.pos,Vector2(8,3))
	check_eq(f.surface_id,"east")
	check_eq(f.moves_taken,1)
	check_eq(f.actions_left,1)
	check(Contact.in_combat(c.state.figures,f))


func test_drop_and_walk_uses_remaining_budget() -> void:
	var b:=make_board()
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,36,36],"level":0},{"id":"deck","rect":[8,8,5,5],"level":3}]}
	var f:=fig("thug",0,Vector2(12.5,10))
	f.surface_id="deck"
	f.elevation=3.0
	var c:=make_game(b,[f],Dice.new(1))
	c.state.active_id=f.id
	f.actions_left=2
	var target:=b.floor_geometry().node("street",Vector2(15,10))
	var hp:=f.health
	var options:=c.movement_options("drop_down")
	check(options.cost.has(target))
	if not options.cost.has(target):
		return
	check(absf(float(options.cost[target])-5.5)<0.001)
	check(c.commit_movement("drop_down",target))
	check_eq(f.pos,Vector2(15,10))
	check_eq(f.surface_id,"street")
	check_eq(f.health,hp-4)
	check_eq(f.moves_taken,1)
	check_eq(f.actions_left,1)


func _approach_drop_game(with_guard: bool=false) -> GameController:
	var b:=make_board()
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,36,36],"level":0},{"id":"deck","rect":[8,8,5,5],"level":3}]}
	var f:=fig("thug",0,Vector2(11,10))
	f.surface_id="deck"
	f.elevation=3.0
	var figures: Array[Figure]=[f]
	if with_guard:
		var g:=fig("thug",1,Vector2(11.5,12),2)
		g.surface_id="deck"
		g.elevation=3.0
		figures.append(g)
	var c:=make_game(b,figures,Dice.new(19))
	c.state.active_id=f.id
	f.actions_left=2
	c.state.forced_combat=with_guard
	c.state.reaction_side=1
	return c


func test_approach_drop_and_walk_share_one_allowance() -> void:
	var c:=_approach_drop_game()
	var f:=c.state.active()
	var layout:=c.state.board.floor_geometry()
	var dest:=layout.node("street",Vector2(14,10))
	var too_far:=layout.node("street",Vector2(14.5,10))
	var hp:=f.health
	check(not LayeredDrop.plans(c).has(dest))
	var options:=c.movement_options("drop_down")
	check(options.cost.has(dest))
	check(not options.cost.has(too_far))
	check_eq(f.pos,Vector2(11,10))
	check_eq(f.health,hp)
	if not options.cost.has(dest):
		return
	check(absf(float(options.cost[dest])-6.0)<0.001)
	var preview:=options.path(dest)
	check_eq(preview[0],Vector3(11,3,10))
	check_eq(preview[-1],layout.world(dest))
	check(c.commit_movement("drop_down",dest))
	check_eq(f.pos,Vector2(14,10))
	check_eq(f.surface_id,"street")
	check_eq(f.health,hp-4)
	check_eq(f.moves_taken,1)
	check_eq(f.actions_left,1)


func test_interception_on_drop_approach_prevents_fall() -> void:
	var c:=_approach_drop_game(true)
	var f:=c.state.active()
	var dest:=c.state.board.floor_geometry().node("street",Vector2(13.5,10))
	var hp:=f.health
	check(c.commit_movement("drop_down",dest))
	check(not c.state.pending_intercept.is_empty())
	if c.state.pending_intercept.is_empty():
		return
	check(c.answer_intercept(true))
	check_eq(f.surface_id,"deck")
	check_eq(f.elevation,3.0)
	check_eq(f.health,hp)
	check_eq(f.moves_taken,1)
	check_eq(f.actions_left,1)
	check(Contact.in_combat(c.state.figures,f))


func test_generated_oblique_jump() -> void:
	var b:=make_board()
	b.floor_layout={"surfaces":[{"id":"west","rect":[0,0,4,6],"level":3},{"id":"east","rect":[5,0,6,6],"level":3}]}
	var f:=fig("thug",0,Vector2(1.5,1))
	f.surface_id="west"
	f.elevation=3.0
	var c:=make_game(b,[f],Dice.new(19))
	c.state.active_id=f.id
	f.actions_left=2
	var layout:=b.floor_geometry()
	var target:=layout.node("east",Vector2(5.5,3))
	var options:=LayeredJump.plans(c,true)
	check(options.has(target))
	if not options.has(target):
		return
	check(absf(float(options[target]["cost"])-sqrt(20.0))<0.001)
	check(c.jump_on_floor(target))
	check_eq(f.pos,Vector2(5.5,3))
	check_eq(f.surface_id,"east")
	check_eq(f.moves_taken,1)


func test_weighted_landing_search_matches_independent_reach() -> void:
	var c:=_approach_drop_game()
	var f:=c.state.active()
	f.pos=Vector2(12.5,10)
	var layout:=c.state.board.floor_geometry()
	var base:=LayeredDrop.plans(c)
	check(base.size()>1)
	var allowance:=MoveRules.allowance(f)
	var grid:=LayeredGrid.new(layout,f,c.state.figures)
	var expected: Dictionary={}
	var origin:=layout.node(f.surface_id,f.pos)
	for landing: Vector3i in base:
		var paid:=float(base[landing]["cost"])
		expected[landing]=minf(paid,float(expected.get(landing,INF)))
		var remaining:=allowance-paid
		if remaining<MoveGrid.STEP-0.001 or bool(base[landing]["end_activation"]) or grid.stops(landing):
			continue
		var reach:=LayeredReach.search(grid,landing,remaining)
		for n: Vector3i in reach.cost:
			if n!=origin:
				expected[n]=minf(paid+float(reach.cost[n]),float(expected.get(n,INF)))
	var actual:=LayeredMovement.extend_aerial(c,base)
	check_eq(actual.size(),expected.size())
	for n: Vector3i in expected:
		check(actual.has(n))
		if actual.has(n):
			check(absf(float(actual[n]["cost"])-float(expected[n]))<0.001)
			var preview: PackedVector3Array=actual[n].get("preview",actual[n]["path"])
			check_eq(preview[-1],layout.world(n))


func _two_jump_game(with_guard: bool=false) -> GameController:
	var b:=make_board()
	b.floor_layout={"surfaces":[{"id":"west","rect":[0,0,4,6],"level":3},{"id":"middle","rect":[4,0,2,6],"level":3},{"id":"east","rect":[6,0,5,6],"level":3}],"jumps":[{"from":["west",3.5,3],"to":["middle",4.5,3]},{"from":["middle",5.5,3],"to":["east",6.5,3]}]}
	var f:=fig("thug",0,Vector2(3.5,3))
	f.surface_id="west"
	f.elevation=3.0
	var figures: Array[Figure]=[f]
	if with_guard:
		var guard:=fig("thug",1,Vector2(8.5,3),2)
		guard.surface_id="east"
		guard.elevation=3.0
		figures.append(guard)
	var c:=make_game(b,figures,Dice.new(19))
	c.state.active_id=f.id
	f.actions_left=2
	c.state.forced_combat=with_guard
	c.state.reaction_side=1
	return c


func test_two_jumps_and_followthrough_spend_once() -> void:
	var c:=_two_jump_game()
	var f:=c.state.active()
	var layout:=c.state.board.floor_geometry()
	var dest:=layout.node("east",Vector2(8,3))
	var options:=c.movement_options("jump")
	check(options.cost.has(dest))
	check_eq(f.pos,Vector2(3.5,3))
	check_eq(f.actions_left,2)
	if not options.cost.has(dest):
		return
	check(absf(float(options.cost[dest])-4.5)<0.001)
	check_eq(options.path(dest)[-1],layout.world(dest))
	check(c.commit_movement("jump",dest))
	check_eq(f.pos,Vector2(8,3))
	check_eq(f.surface_id,"east")
	check_eq(f.moves_taken,1)
	check_eq(f.actions_left,1)


func test_second_jump_landing_interception() -> void:
	var c:=_two_jump_game(true)
	var f:=c.state.active()
	var dest:=c.state.board.floor_geometry().node("east",Vector2(6.5,3))
	check(c.commit_movement("jump",dest))
	check(not c.state.pending_intercept.is_empty())
	check_eq(f.moves_taken,0)
	if c.state.pending_intercept.is_empty():
		return
	check(c.answer_intercept(true))
	check_eq(f.surface_id,"east")
	check_eq(f.pos,Vector2(6.5,3))
	check_eq(f.moves_taken,1)
	check_eq(f.actions_left,1)
	check(Contact.in_combat(c.state.figures,f))
