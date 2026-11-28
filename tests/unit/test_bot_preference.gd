extends TestCase

func test_preferences_are_bounded_stable_and_leave_creatures_unchanged() -> void:
	var f:=fig("knight",0,Vector2(4,4))
	var c:=make_game(make_board(),[f],Dice.new(19))
	var before:=c.dice._rng.state
	var first:=BotPreference.variation(c.state,f,8,"shot")
	check_eq(first,BotPreference.variation(c.state,f,8,"shot"))
	var different:=false
	for turn in range(1,10):
		c.state.turn=turn
		var v:=BotPreference.appeal(c.state,f,8,"shot")
		check(v>=0.68 and v<=1.32)
		different=different or not is_equal_approx(v,1.0+0.22*first)
	check(different)
	check_eq(c.dice._rng.state,before)
	f.side=-1
	check_eq(BotPreference.appeal(c.state,f,8,"shot"),1.0)

func test_firing_sample_is_bounded_and_contains_only_supplied_positions() -> void:
	var f:=fig("archer",0,Vector2(4,4))
	var c:=make_game(make_board(),[f],Dice.new(19))
	var nodes: Array=[]
	for i in 200:
		nodes.append(Vector3i(i,1,0))
	var sample:=BotPreference.positions(c.state,f,nodes)
	check(sample.size()>=20 and sample.size()<=BotPreference.SHOT_POSITIONS)
	check_eq(sample,BotPreference.positions(c.state,f,nodes))
	for n in sample:
		check(nodes.has(n))
	f.side=-1
	check_eq(BotPreference.positions(c.state,f,nodes),nodes)

func test_contact_neighborhood_respects_overlapping_floors() -> void:
	var b:=make_board()
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,36,36],"level":0},{"id":"deck","rect":[8,8,5,5],"level":3}]}
	var f:=fig("knight",0,Vector2(9,10))
	var enemy:=fig("thug",1,Vector2(10,10))
	f.surface_id="street"
	enemy.surface_id="deck"
	enemy.elevation=3.0
	var c:=make_game(b,[f,enemy],Dice.new(19))
	var l:=b.floor_geometry()
	var grid:=LayeredGrid.new(l,f,c.state.figures)
	check(grid.open(l.node("street",enemy.pos)))
	check(not grid.stops(l.node("street",f.pos)))
	check(not grid.open(l.node("deck",enemy.pos)))
	check(grid.stops(l.node("deck",Vector2(9,10))))


func test_individual_tendencies_are_independent_of_type_and_turn() -> void:
	var f:=fig("knight",0,Vector2(4,4))
	var other:=fig("archer",0,Vector2(6,4))
	var c:=make_game(make_board(),[f,other],Dice.new(5))
	var original:=BotPreference.profile(f)
	check(original!=BotPreference.profile(other))
	c.state.turn=10
	check_eq(BotPreference.profile(f),original)
	var definition:=f.def
	f.def=other.def
	check_eq(BotPreference.profile(f),original)
	f.def=definition
	f.campaign_id=24
	other.campaign_id=24
	check_eq(BotPreference.profile(f),BotPreference.profile(other))
