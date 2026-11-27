extends TestCase


func test_worm_emerges_on_ground_not_roof() -> void:
	var b:=make_board([],Vector2(20,16))
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,20,16],"level":0},{"id":"roof","rect":[2,2,16,12],"level":3}],"solids":[[2,2.8,2,16,0.2,12]]}
	var f:=fig("wizard",0,Vector2(5,5))
	f.surface_id="roof"
	f.elevation=3.0
	var c:=make_game(b,[f],LoadedDice.new([20]))
	c.state.creature_db=db()
	WormRider._place_token(c,Vector2(9,5),0)
	check_eq(b.pieces[0].surface_id,"street")
	WormRider.end_turn(c)
	check_eq(c.state.figures.size(),2)
	if c.state.figures.size()==2:
		check_eq(c.state.figures[1].surface_id,"street")
		check_eq(c.state.figures[1].elevation,0.0)
