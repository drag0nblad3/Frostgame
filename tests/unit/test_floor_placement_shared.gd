extends TestCase


func _game() -> GameController:
	var b:=make_board([],Vector2(20,12))
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,20,12],"level":0},{"id":"roof","rect":[2,2,12,8],"level":3}],"solids":[[2,2.8,2,12,0.2,8]]}
	var f:=fig("wizard",0,Vector2(5,5))
	f.surface_id="roof"
	f.elevation=3.0
	var c:=make_game(b,[f],LoadedDice.new([20]))
	c.state.creature_db=db()
	c.state.spell_catalog=JsonFile.read("res://data/spells.json")
	c.state.spellbooks[0]={"raise_zombie":10,"teleport":10}
	c.state.active_id=f.id
	f.actions_left=2
	return c


func test_summon_stays_on_selected_roof() -> void:
	var c:=_game()
	var f:=c.state.active()
	var layout:=c.state.board.floor_geometry()
	var roof:=layout.node("roof",Vector2(6,5))
	var below:=layout.node("street",Vector2(6,5))
	check(not c._magic.summons.can_place_floor(f,"raise_zombie",below))
	check(c._magic.summons.can_place_floor(f,"raise_zombie",roof))
	check(SpellAvailability.menu_options(c._magic,f).has("raise_zombie"))
	check(c._magic.start_floor_at("raise_zombie",roof))
	check(c.finish_cast(0))
	check_eq(c.state.figures.size(),2)
	if c.state.figures.size()==2:
		var z:=c.state.figures[1]
		check_eq(z.surface_id,"roof")
		check_eq(z.elevation,3.0)
		check_eq(z.summoned_by,f.id)
		check_eq(z.side,f.side)


func test_ring_and_potion_share_teleport_validation() -> void:
	var c:=_game()
	var f:=c.state.active()
	var layout:=c.state.board.floor_geometry()
	var roof:=layout.node("roof",Vector2(8,5))
	var below:=layout.node("street",Vector2(8,5))
	f.items.append({"gear":"gear_ring_teleportation"})
	check(not GearActions.teleport_on_floor(c,below))
	check(GearActions.teleport_on_floor(c,roof))
	check_eq(f.surface_id,"roof")
	check_eq(f.pos,Vector2(8,5))
	check_eq(f.actions_left,1)
	c=_game()
	f=c.state.active()
	f.items.append({"potion":"teleportation"})
	check(not c._potions.teleport_on_floor(below))
	check(c._potions.teleport_on_floor(roof))
	check_eq(f.elevation,3.0)
	check_eq(f.actions_left,0)
	check(f.magic_exhausted)
