extends TestCase


func test_cocktail_requires_visible_floor_and_spends_only_on_valid_throw() -> void:
	var b:=make_board([],Vector2(20,16))
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,20,16],"level":0},{"id":"roof","rect":[2,2,16,12],"level":3}],"solids":[[2,2.8,2,16,0.2,12]]}
	var f:=fig("wizard",0,Vector2(5,5))
	f.surface_id="roof"
	f.elevation=3.0
	var c:=make_game(b,[f],LoadedDice.new([20]))
	c.state.active_id=f.id
	f.actions_left=2
	f.items.append({"potion":"explosive_cocktail"})
	var layout:=b.floor_geometry()
	check(not c._potions.cocktail_on_floor(layout.node("street",Vector2(8,5))))
	check(not c._potions.cocktail_on_floor(layout.node("roof",Vector2(14,5))))
	check_eq(f.items.size(),1)
	check_eq(f.actions_left,2)
	check(c._potions.cocktail_on_floor(layout.node("roof",Vector2(8,5))))
	check_eq(f.items.size(),0)
	check_eq(f.actions_left,1)


func test_burrowing_potion_uses_floor_direct_movement() -> void:
	var b:=make_board([],Vector2(20,16))
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,20,16],"level":0}],"solids":[[6,0,3,1,3,4]]}
	var f:=fig("wizard",0,Vector2(5,5))
	f.surface_id="street"
	var c:=make_game(b,[f],LoadedDice.new([20]))
	c.state.active_id=f.id
	f.actions_left=2
	f.items.append({"potion":"burrowing"})
	check(c._potions.drink("burrowing"))
	check(f.spell_effects.has("potion_burrowing"))
	check(PlaneWalk.uses_direct(f))
	check(c.layered_reach().can_reach(b.floor_geometry().node("street",Vector2(8,5))))
