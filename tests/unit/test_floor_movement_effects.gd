extends TestCase


func _game() -> GameController:
	var b:=make_board([],Vector2(20,16))
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,20,16],"level":0},{"id":"roof","rect":[0,0,20,16],"level":4}],"solids":[[0,3.8,0,20,0.2,16],[7,0,0,1,3,16]]}
	var f:=fig("wizard",0,Vector2(5,5))
	f.surface_id="street"
	var c:=make_game(b,[f],LoadedDice.new([20]))
	c.state.spell_catalog=JsonFile.read("res://data/spells.json")
	c.state.spellbooks[0]={"plane_walk":10,"mud":10}
	c.state.active_id=f.id
	f.actions_left=2
	return c


func test_plane_walk_crosses_wall_not_ceiling() -> void:
	var c:=_game()
	var f:=c.state.active()
	var layout:=c.state.board.floor_geometry()
	var far:=layout.node("street",Vector2(9,5))
	var roof:=layout.node("roof",Vector2(5,5))
	check(not c.layered_reach().can_reach(far))
	check(c.start_cast("plane_walk",f.id))
	check(c.finish_cast(0))
	check(c.layered_reach().can_reach(far))
	check(not c.layered_reach().can_reach(roof))
	check(c.move_on_floor(far))
	check_eq(f.pos,Vector2(9,5))
	check_eq(f.surface_id,"street")


func test_active_mud_does_not_disable_movement() -> void:
	var c:=_game()
	var f:=c.state.active()
	f.pos=Vector2(12,6)
	var layout:=c.state.board.floor_geometry()
	c._magic.terrain.apply(f,"mud",Vector2(13,6),false,14,false,"street")
	check_eq(c.state.board.pieces.size(),1)
	var reach:=c.layered_reach()
	var dest:=layout.node("street",Vector2(13,6))
	check(reach.can_reach(dest))
	if reach.can_reach(dest):
		check_eq(float(reach.cost[dest]),2.0)
		check(c.move_on_floor(dest))
		check_eq(f.pos,Vector2(13,6))


func test_suggestion_cannot_cross_masonry_or_ceiling() -> void:
	var c:=_game()
	var f:=c.state.active()
	f.pos=Vector2(6,5)
	var layout:=c.state.board.floor_geometry()
	var options:=SpellAvailability.floor_suggestion_points(c._magic,f)
	check(options.has(layout.node("street",Vector2(4,5))))
	check(not options.has(layout.node("street",Vector2(9,5))))
	check(not options.has(layout.node("roof",Vector2(6,5))))
