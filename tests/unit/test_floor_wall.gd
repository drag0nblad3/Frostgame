extends TestCase


func test_conjured_wall_blocks_climbs_and_falls() -> void:
	var b:=make_board([],Vector2(20,16))
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,20,16],"level":0}]}
	var f:=fig("wizard",0,Vector2(5,7))
	f.surface_id="street"
	var c:=make_game(b,[f],LoadedDice.new([20]))
	c.state.spell_catalog=JsonFile.read("res://data/spells.json")
	c.state.spellbooks[0]={"wall":10}
	c.state.active_id=f.id
	f.actions_left=2
	var n:=b.floor_geometry().node("street",Vector2(8,7))
	check(c._magic.start_floor_at("wall",n,true))
	check(c.finish_cast(0))
	check_eq(b.pieces.size(),1)
	if b.pieces.is_empty():
		return
	var p:=b.pieces[0]
	var id:=p.dynamic_surface
	var layout:=b.floor_geometry()
	check(layout.errors.is_empty(),str(layout.errors))
	check(layout.index_of(id)>=0)
	if layout.index_of(id)<0:
		return
	check(not layout.standable(layout.node("street",Vector2(8,7))))
	check(not LineOfSight.floor_ray(b,layout,Vector3(5,1,7),Vector3(11,1,7),f))
	var top:=layout.node(id,Vector2(8,7))
	check(layout.standable(top))
	var route:=LayeredReach.search(LayeredGrid.new(layout,f,c.state.figures),layout.node("street",f.pos),12.0)
	check(route.can_reach(top),"wall can be climbed")
	var restored:=BattleSnapshotParts.make_board(BattleSnapshotParts.board_data(b))
	check_eq(restored.pieces[0].dynamic_surface,id)
	check(restored.floor_geometry().index_of(id)>=0)
	f.pos=Vector2(8,7)
	f.elevation=3.0
	f.surface_id=id
	var hp:=f.health
	c._magic.terrain.remove(p)
	check_eq(f.surface_id,"street")
	check_eq(f.elevation,0.0)
	check_eq(f.health,hp-ElevationRules.fall_damage(3.0))
	check(b.floor_geometry().index_of(id)<0)
	check(b.floor_geometry().standable(b.floor_geometry().node("street",Vector2(8,7))))
