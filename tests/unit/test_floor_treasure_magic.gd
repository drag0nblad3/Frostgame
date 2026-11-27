extends TestCase


func test_telekinesis_respects_deck_and_retains_surface() -> void:
	var b:=make_board([],Vector2(20,12))
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,20,12],"level":0},{"id":"roof","rect":[2,2,12,8],"level":3}],"solids":[[2,2.8,2,12,0.2,8]]}
	var f:=fig("wizard",0,Vector2(5,5))
	f.surface_id="roof"
	f.elevation=3.0
	var c:=make_game(b,[f],LoadedDice.new([20]))
	c.state.spell_catalog=JsonFile.read("res://data/spells.json")
	c.state.spellbooks[0]={"telekinesis":10}
	c.state.active_id=f.id
	f.actions_left=2
	var upper:=TreasureToken.new(0,Vector2(7,5))
	upper.surface_id="roof"
	upper.central=false
	var lower:=TreasureToken.new(1,Vector2(7,5))
	lower.surface_id="street"
	c.state.treasures.assign([upper,lower])
	check(c._magic.treasure_options("telekinesis").has(upper))
	check(not c._magic.treasure_options("telekinesis").has(lower))
	var layout:=b.floor_geometry()
	check(not c._magic.start_floor_treasure("telekinesis",0,layout.node("street",Vector2(8,5))))
	check(c._magic.start_floor_treasure("telekinesis",0,layout.node("roof",Vector2(8,5))))
	check(c.finish_cast(0))
	check_eq(upper.surface_id,"roof")
	check_eq(upper.pos,Vector2(8,5))
	check_eq(lower.surface_id,"street")
	check_eq(lower.pos,Vector2(7,5))
