extends TestCase

func test_failed_swim_loses_actions_and_health() -> void:
	var f:=fig("tracker",0,Vector2(10,10))
	var c:=make_game(make_board([["deep_water",8,8,4,4]]),[f],LoadedDice.new([3]))
	f.actions_left=2
	c.state.turn=1
	Swimming.activate(c,f)
	check_eq(f.actions_left,0)
	check_eq(f.health,f.def.health-3)
	check_eq(Swimming.fight_penalty(f),-2)
	check(Swimming.prevents_bow(f))

func test_shallow_water_and_flying() -> void:
	var f:=fig("tracker",0,Vector2(10,10))
	var c:=make_game(make_board([["shallow_water",8,8,4,4]]),[f],LoadedDice.new([1]))
	f.actions_left=2
	Swimming.activate(c,f)
	check_eq(f.actions_left,2)
	check_eq(c.state.board.move_mult_at(f.pos,f),2.0)
	f.def=f.def.with_bonuses({})
	f.def.traits.append("flying")
	check_eq(c.state.board.move_mult_at(f.pos,f),1.0)
	check_eq(Swimming.fight_penalty(f),0)

func test_deep_water_not_on_upper_floor() -> void:
	var f:=fig("tracker",0,Vector2(10,10))
	var b:=make_board([["deep_water",8,8,4,4]])
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,36,36],"level":0},{"id":"deck","rect":[8,8,4,4],"level":3}]}
	var c:=make_game(b,[f],LoadedDice.new([1]))
	f.surface_id="deck"
	f.elevation=3.0
	f.actions_left=2
	Swimming.activate(c,f)
	check_eq(f.actions_left,2)
	check_eq(Swimming.figure_depth(f),0)
