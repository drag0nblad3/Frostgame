extends TestCase

func _game() -> GameController:
	var b:=make_board([],Vector2(20,20))
	b.floor_layout={"auto_architecture_climbs":true,"surfaces":[{"id":"street","rect":[0,0,20,20],"level":0}],"solids":[[10,0,2,0.5,3,16]]}
	var a:=fig("thug",0,Vector2(9.5,10.5),1)
	var z:=fig("thug",1,Vector2(8.5,10.5),2)
	a.surface_id="street"
	z.surface_id="street"
	var c:=make_game(b,[a,z],Dice.new(5))
	return c

func test_climber_death_drops_treasure_on_real_ground() -> void:
	var c:=_game()
	var a:=c.state.figure(1)
	var l:=c.state.board.floor_geometry()
	for n in l.nodes_at(a.pos):
		if l.surface_id(n).begins_with("climb:") and is_equal_approx(l.height(n),2.0):
			a.surface_id=l.surface_id(n)
			a.elevation=2.0
			break
	check_eq(a.elevation,2.0)
	var token:=TreasureToken.new(0,a.pos)
	token.carrier_id=a.id
	a.treasure_id=0
	c.state.treasures.append(token)
	c._loot.drop_on_death(a)
	check_eq(token.surface_id,"street")
	check_eq(token.pos,a.pos)
	check(token.on_ground())
	check_eq(TreasureRules.token_height(c.state,token),0.0)

func test_hanging_figures_can_be_pushed_off_wall() -> void:
	var c:=_game()
	var a:=c.state.figure(1)
	var b:=c.state.figure(2)
	var l:=c.state.board.floor_geometry()
	# Adjacent positions on the same face are a valid fight; a lateral push
	# that leaves the climbing support drops to the lower deck.
	for f in [a,b]:
		f.pos=Vector2(9.5,10.5 if f==a else 9.5)
		for n in l.nodes_at(f.pos):
			if l.surface_id(n).begins_with("climb:") and is_equal_approx(l.height(n),3.0):
				f.surface_id=l.surface_id(n)
				f.elevation=3.0
				break
	check_eq(a.elevation,3.0)
	check_eq(b.elevation,3.0)
	check(Contact.figures_touch(a,b))
	c.state.push_winner=b.id
	c.state.push_loser=a.id
	var hp:=a.health
	check(c.resolve_push(false))
	check_eq(a.surface_id,"street")
	check_eq(a.elevation,0.0)
	check_eq(a.health,hp-ElevationRules.fall_damage(3.0))

func test_climbing_filter_groups_nodes_without_hiding_normal_floor() -> void:
	var l:=_game().state.board.floor_geometry()
	check(FloorViewFilter.has_climbing(l))
	check(FloorViewFilter.valid(l,FloorViewFilter.CLIMBING))
	check(FloorViewFilter.matches(FloorViewFilter.CLIMBING,"climb:example:1"))
	check(not FloorViewFilter.matches(FloorViewFilter.CLIMBING,"street"))
	check(FloorViewFilter.matches("","street"))
