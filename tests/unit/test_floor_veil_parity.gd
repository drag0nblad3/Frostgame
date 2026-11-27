extends TestCase


func test_forced_relocation_preserves_support() -> void:
	var b:=make_board([],Vector2(20,16))
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,20,16],"level":0},{"id":"roof","rect":[2,2,16,12],"level":4}],"solids":[[2,3.8,2,16,0.2,12]]}
	var f:=fig("wizard",0,Vector2(5,5))
	f.surface_id="roof"
	f.elevation=4.0
	var c:=make_game(b,[f],LoadedDice.new([20]))
	check(ForcedRelocation.relocate(c,f,Vector2(8,5)))
	check_eq(f.surface_id,"roof")
	check_eq(f.elevation,4.0)
	check_eq(f.pos,Vector2(8,5))


func test_herd_veil_applies_at_height() -> void:
	var b:=make_board([],Vector2(20,16))
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,20,16],"level":0},{"id":"roof","rect":[2,2,16,12],"level":4}],"solids":[[2,3.8,2,16,0.2,12]]}
	var f:=fig("wizard",0,Vector2(5,5))
	f.surface_id="roof"
	f.elevation=4.0
	var c:=make_game(b,[f],LoadedDice.new([20]))
	c.state.scenario_special=RedKingHerded.ID
	c.state.scenario_data["herd_veil"]=5.0
	var hp:=f.health
	check(RedKingHerded.contact(c,f,f.pos))
	check_eq(f.health,hp-6)
	check_eq(f.surface_id,"roof")
	check_eq(f.elevation,4.0)
	check(f.pos.y>5.5)
