extends TestCase


func _board() -> Board:
	var b:=make_board([],Vector2(20,16))
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,20,16],"level":0},{"id":"roof","rect":[2,2,16,12],"level":4}],"solids":[[2,3.8,2,16,0.2,12]]}
	return b


func test_scenario_identity_no_longer_disables_floor_movement() -> void:
	for special: String in [RedKingSinkhole.ID,RedKingBridge.ID,RedKingHill.ID,RedKingMadMan.ID]:
		var b:=_board()
		var f:=fig("wizard",0,Vector2(5,5))
		f.surface_id="roof"
		f.elevation=4.0
		var c:=make_game(b,[f],LoadedDice.new([20]))
		c.state.scenario_special=special
		c.state.active_id=f.id
		f.actions_left=2
		check(c.layered_reach().can_reach(b.floor_geometry().node("roof",Vector2(6,5))),special)


func test_simultaneous_shift_preserves_floor_and_avoids_overlap() -> void:
	var b:=_board()
	var a:=fig("wizard",0,Vector2(5,5))
	var z:=fig("knight",1,Vector2(8,5))
	a.surface_id="roof"
	z.surface_id="roof"
	a.elevation=4.0
	z.elevation=4.0
	var c:=make_game(b,[a,z],LoadedDice.new([20]))
	var units: Array[Figure]=[a,z]
	check(ForcedRelocation.group_floor(c,units,{a.id:z.pos,z.id:a.pos}))
	check_eq(a.pos,Vector2(8,5))
	check_eq(z.pos,Vector2(5,5))
	check_eq(a.surface_id,"roof")
	check_eq(z.elevation,4.0)


func test_orb_does_not_touch_figure_above_it() -> void:
	var b:=_board()
	var f:=fig("wizard",0,b.size*0.5)
	f.surface_id="roof"
	f.elevation=4.0
	var c:=make_game(b,[f],LoadedDice.new([20]))
	c.state.scenario_special=RedKingSinkhole.ID
	check(RedKingSinkhole.touches(c.state,f.pos,0.0))
	check(not RedKingSinkhole.touches(c.state,f.pos,4.0))
	var health:=f.health
	RedKingSinkhole.contact(c,f)
	check_eq(f.health,health)
