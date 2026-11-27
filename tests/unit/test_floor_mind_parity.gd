extends TestCase


func test_memory_collection_uses_real_support() -> void:
	var b:=make_board([],Vector2(20,16))
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,20,16],"level":0},{"id":"roof","rect":[2,2,16,12],"level":4}],"solids":[[2,3.8,2,16,0.2,12]]}
	var f:=fig("wizard",0,Vector2(5,5))
	f.surface_id="roof"
	f.elevation=4.0
	var c:=make_game(b,[f],LoadedDice.new([20]))
	c.state.scenario_special=RedKingMind.ID
	var below:=TreasureToken.new(0,Vector2(6,5))
	below.surface_id="street"
	var above:=TreasureToken.new(1,Vector2(6,5))
	above.surface_id="roof"
	c.state.treasures.assign([below,above])
	RedKingMind.collect(c,f,Vector2(5,5),Vector2(7,5),4.0,4.0)
	check(below.on_ground())
	check_eq(above.secured_by,0)
