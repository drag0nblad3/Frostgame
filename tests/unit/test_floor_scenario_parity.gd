extends TestCase


func _stacked() -> Board:
	var b:=make_board([],Vector2(20,16))
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,20,16],"level":0},{"id":"roof","rect":[2,2,16,12],"level":3}],"solids":[[2,2.8,2,16,0.2,12]]}
	return b


func test_library_ice_and_exit_respect_support_and_doors() -> void:
	var b:=_stacked()
	var f:=fig("knight",0,Vector2(5,5))
	f.surface_id="roof"
	f.elevation=3.0
	var c:=make_game(b,[f],LoadedDice.new([20]))
	c.state.scenario_special="underground_library"
	var token:=TreasureToken.new(0,Vector2(5.5,5))
	token.surface_id="street"
	token.frozen=true
	c.state.treasures.append(token)
	c.state.active_id=f.id
	f.actions_left=2
	check(not c.break_ice(),"ice on lower floor cannot be broken")
	check_eq(f.actions_left,2)
	token.surface_id="roof"
	check(c.break_ice())
	check(not token.frozen)
	check_eq(f.actions_left,1)
	var layout:=b.floor_geometry()
	check(LayeredLoot.is_exit(c.state,layout,layout.node("street",Vector2(10,0.5)),0))
	check(not LayeredLoot.is_exit(c.state,layout,layout.node("street",Vector2(3,0.5)),0))
	check(not LayeredLoot.is_exit(c.state,layout,layout.node("roof",Vector2(10,2.5)),0))


func test_worm_emerges_on_actual_treasure_support() -> void:
	var b:=_stacked()
	var f:=fig("knight",0,Vector2(5,5))
	f.surface_id="street"
	var c:=make_game(b,[f],LoadedDice.new([20,1]))
	c.state.creature_db=db()
	c.state.scenario_special="worm_hunts"
	var token:=TreasureToken.new(0,Vector2(8,5))
	token.surface_id="roof"
	c.state.treasures.append(token)
	ScenarioObjectives.spawn_worm(c)
	check(c.state.worm_spawned)
	check_eq(c.state.figures.size(),2)
	if c.state.figures.size()==2:
		var worm:=c.state.figures[1]
		check_eq(worm.surface_id,"roof")
		check_eq(worm.elevation,3.0)


func test_genie_spawn_stays_on_finders_floor() -> void:
	var b:=_stacked()
	var f:=fig("knight",0,Vector2(5,5))
	f.surface_id="roof"
	f.elevation=3.0
	var c:=make_game(b,[f],LoadedDice.new([20]))
	c.state.creature_db=db()
	c.state.scenario_special="genie_in_the_bottle"
	var token:=TreasureToken.new(0,Vector2(5.5,5))
	token.surface_id="roof"
	token.ever_collected=true
	c.state.treasures.append(token)
	ScenarioGenie.first_pickup(c,f,token)
	check(c.state.genie_id>=0)
	var creature:=c.state.figure(c.state.genie_id)
	if creature!=null:
		check_eq(creature.surface_id,"roof")
		check_eq(creature.elevation,3.0)
