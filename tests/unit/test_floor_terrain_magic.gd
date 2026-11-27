extends TestCase


func _game() -> GameController:
	var b:=make_board([],Vector2(20,16))
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,20,16],"level":0},{"id":"roof","rect":[2,2,16,12],"level":3}],"solids":[[2,2.8,2,16,0.2,12]]}
	var f:=fig("wizard",0,Vector2(4,5))
	var a:=fig("thug",1,Vector2(10,5))
	var t:=fig("thug",1,Vector2(10,5))
	for unit in [f,a]:
		unit.surface_id="roof"
		unit.elevation=3.0
	t.surface_id="street"
	var c:=make_game(b,[f,a,t],LoadedDice.new([20,20,1]))
	c.state.spell_catalog=JsonFile.read("res://data/spells.json")
	c.state.spellbooks[0]={"mud":10,"fog":10,"explosive_rune":10}
	c.state.active_id=f.id
	f.actions_left=2
	return c


func test_mud_uses_support_and_removal_preserves_height() -> void:
	var c:=_game()
	var f:=c.state.active()
	var b:=c.state.board
	var n:=b.floor_geometry().node("roof",Vector2(10,5))
	check(c._magic.start_floor_at("mud",n),"legal roof mud")
	check(c.finish_cast(0))
	check_eq(b.pieces.size(),1)
	if b.pieces.is_empty():
		return
	var p:=b.pieces[0]
	check_eq(p.surface_id,"roof")
	check_eq(p.base_height,3.0)
	check_eq(TerrainMagic.floor_multiplier(b,Vector2(10,5),3.0),2.0)
	check_eq(TerrainMagic.floor_multiplier(b,Vector2(10,5),0.0),1.0)
	var restored:=BattleSnapshotParts.make_board(BattleSnapshotParts.board_data(b))
	check_eq(restored.pieces[0].surface_id,"roof")
	check_eq(restored.pieces[0].base_height,3.0)
	c._magic.terrain.remove(p)
	check_eq(f.elevation,3.0)
	check_eq(c.state.figure(2).elevation,3.0)
	check_eq(c.state.figure(3).elevation,0.0)


func test_roof_fog_does_not_block_street_ray() -> void:
	var c:=_game()
	var f:=c.state.active()
	var b:=c.state.board
	var layout:=b.floor_geometry()
	var n:=layout.node("roof",Vector2(7,5))
	check(c._magic.terrain.can_place_floor(f,"fog",n,true))
	c._magic.terrain.apply(f,"fog",Vector2(7,5),true,14,false,"roof")
	check(not LineOfSight.floor_ray(b,layout,Vector3(4,4,5),Vector3(10,4,5),f))
	check(LineOfSight.floor_ray(b,layout,Vector3(4,1,5),Vector3(10,1,5),f))
