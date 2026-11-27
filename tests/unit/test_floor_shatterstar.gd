extends TestCase


func test_two_casts_on_same_floor_spend_one_cast_action() -> void:
	var b:=make_board([],Vector2(20,16))
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,20,16],"level":0},{"id":"roof","rect":[2,2,16,12],"level":3}],"solids":[[2,2.8,2,16,0.2,12]]}
	var f:=fig("wizard",0,Vector2(5,5))
	var ally:=fig("thug",0,Vector2(8,5))
	for t in [f,ally]:
		t.surface_id="roof"
		t.elevation=3.0
	var c:=make_game(b,[f,ally],LoadedDice.new([18,19]))
	c.state.spell_catalog=JsonFile.read("res://data/spells.json")
	c.state.spellbooks[0]={"fleet_feet":10}
	c.state.active_id=f.id
	f.actions_left=2
	f.items.append({"potion":"shatterstar"})
	check(c._potions.drink("shatterstar"))
	check(not c.start_cast("fleet_feet",f.id))
	check(c.start_cast("fleet_feet",ally.id))
	check(c.finish_cast(0))
	check(c.finish_cast(0))
	check(f.spell_effects.has("fleet_feet"))
	check(ally.spell_effects.has("fleet_feet"))
	check_eq(f.actions_left,0)
	check_eq(f.non_moves,1)


func test_teleport_resolution_rechecks_occupied_destination() -> void:
	var b:=make_board([],Vector2(20,16))
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,20,16],"level":0}]}
	var f:=fig("wizard",0,Vector2(5,5))
	var ally:=fig("thug",0,Vector2(10,5))
	f.surface_id="street"
	ally.surface_id="street"
	var c:=make_game(b,[f,ally],LoadedDice.new([20]))
	var n:=b.floor_geometry().node("street",Vector2(8,5))
	ally.pos=Vector2(8,5)
	LayeredMagic.apply_teleport(c,f,{"floor_destination":n,"surface_id":"street"})
	check_eq(f.pos,Vector2(5,5))
