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


func test_bottle_imp_respects_rings_and_support_geometry() -> void:
	var b:=make_board()
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,36,36],"level":0},{"id":"deck","rect":[4,4,4,4],"level":3}]}
	var f:=fig("thug",0,Vector2(6,6))
	f.surface_id="deck"
	f.elevation=3.0
	var other:=fig("thug",1,Vector2(7,6),2)
	other.surface_id="deck"
	other.elevation=3.0
	other.ring_side=1
	var c:=make_game(b,[f,other],Dice.new(19))
	c.state.creature_db=db()
	c.state.active_id=f.id
	f.actions_left=2
	f.items.append({"gear":"gear_rk_bottle_imp"})
	var layout:=b.floor_geometry()
	var at:=layout.node("deck",Vector2(7,6))
	var below:=layout.node("street",Vector2(7,6))
	check(GearActions.bottle_floor_points(c).has(at))
	check(not GearActions.bottle_floor_points(c).has(below))
	other.ring_side=0
	check(not GearActions.bottle_floor_points(c).has(at))
	check(not GearActions.bottle_on_floor(c,at))
	check_eq(f.actions_left,2)
	check_eq(f.items.size(),1)
	other.ring_side=1
	check(GearActions.bottle_on_floor(c,at))
	var imp:=c.state.figures[-1]
	check_eq(imp.surface_id,"deck")
	check_eq(imp.elevation,3.0)
	check_eq(imp.ring_side,f.ring_side)
	check_eq(imp.side,-1)
	check_eq(f.items.size(),0)
	check_eq(f.actions_left,1)


func test_slow_fall_ring_protects_against_actual_falls() -> void:
	var b:=make_board()
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,36,36],"level":0},{"id":"deck","rect":[8,8,5,5],"level":3}]}
	var f:=fig("thug",0,Vector2(12.5,10))
	f.surface_id="deck"
	f.elevation=3.0
	var c:=make_game(b,[f],Dice.new(19))
	c.state.active_id=f.id
	f.actions_left=2
	var hp:=f.health
	var gear: Variant=JsonFile.read("res://data/magic_equipment.json")
	f.items.append({"gear":"gear_ring_slow_fall","gear_info":gear["gear_ring_slow_fall"]})
	check_eq(LayeredFall.damage(c.state,f,20.0),0)
	var landing:=b.floor_geometry().node("street",Vector2(13.5,10))
	check(c.commit_movement("drop_down",landing))
	check_eq(f.surface_id,"street")
	check_eq(f.health,hp)
	check_eq(f.moves_taken,1)


func test_teleport_ring_measures_actual_height_and_preserves_action() -> void:
	var b:=make_board()
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,36,36],"level":0},{"id":"deck","rect":[4,4,4,4],"level":3}]}
	var f:=fig("thug",0,Vector2(6,6))
	f.surface_id="deck"
	f.elevation=3.0
	var c:=make_game(b,[f],Dice.new(19))
	c.state.active_id=f.id
	f.actions_left=2
	f.items.append({"gear":"gear_ring_teleportation"})
	var layout:=b.floor_geometry()
	var far:=layout.node("street",Vector2(14,6))
	var near:=layout.node("street",Vector2(12,6))
	check(not GearActions.teleport_on_floor(c,far))
	check_eq(f.actions_left,2)
	check(ActiveGear.ready(f,"gear_ring_teleportation"))
	check(GearActions.teleport_floor_points(c).has(near))
	check(GearActions.teleport_on_floor(c,near))
	check_eq(f.surface_id,"street")
	check_eq(f.elevation,0.0)
	check_eq(f.actions_left,1)
	check(not f.magic_exhausted)
	check(not ActiveGear.ready(f,"gear_ring_teleportation"))
