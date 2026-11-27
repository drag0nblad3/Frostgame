extends TestCase


func _game() -> GameController:
	var b:=make_board([],Vector2(20,12))
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,20,12],"level":0},{"id":"roof","rect":[2,2,6,8],"level":3}],"solids":[[2,2.8,2,6,0.2,8]]}
	var a:=fig("wizard",0,Vector2(5,5))
	var t:=fig("thug",1,Vector2(7,5))
	for f in [a,t]:
		f.surface_id="roof"
		f.elevation=3.0
	var c:=make_game(b,[a,t],LoadedDice.new([20,20,1]))
	c.state.active_id=a.id
	a.actions_left=2
	c.state.spell_catalog=JsonFile.read("res://data/spells.json")
	c.state.spellbooks[0]={"push":10,"transpose":10}
	return c


func test_forced_magic_falls_at_ledge_and_keeps_floor() -> void:
	var c:=_game()
	var t:=c.state.figure(2)
	var hp:=t.health
	c._magic.movement.force(t,Vector2.RIGHT,5.0)
	check_eq(t.surface_id,"street")
	check_eq(t.elevation,0.0)
	check_eq(t.health,hp-ElevationRules.fall_damage(3.0))
	check(c.state.board.floor_geometry().standable(c.state.board.floor_geometry().node(t.surface_id,t.pos)))


func test_swap_changes_both_surface_id_and_elevation() -> void:
	var c:=_game()
	var a:=c.state.figure(1)
	var t:=c.state.figure(2)
	t.surface_id="street"
	t.pos=Vector2(10,5)
	t.elevation=0.0
	c._magic.movement.swap(a,t)
	check_eq(a.surface_id,"street")
	check_eq(a.elevation,0.0)
	check_eq(a.pos,Vector2(10,5))
	check_eq(t.surface_id,"roof")
	check_eq(t.elevation,3.0)
	check_eq(t.pos,Vector2(5,5))
