extends TestCase


func _board() -> Board:
	var b:=make_board([],Vector2(20,16))
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,20,16],"level":0},{"id":"roof","rect":[0,2,20,12],"level":4}],"solids":[[0,3.8,2,20,0.2,12]]}
	return b


func test_wrap_sight_uses_real_elevation_and_range() -> void:
	var b:=_board()
	var a:=fig("wizard",0,Vector2(1,8))
	var z:=fig("knight",1,Vector2(19,8))
	a.surface_id="roof"
	z.surface_id="roof"
	a.elevation=4.0
	z.elevation=4.0
	var c:=make_game(b,[a,z],LoadedDice.new([20]))
	check(RealityCracks.apply(c,17))
	check(LineOfSight.check_figures(b,a,z).clear)
	check_eq(RealityCrackGeometry.world_distance(b,Vector3(1,4,8),Vector3(19,4,8)),2.0)
	z.pos=Vector2(11,8)
	z.elevation=0.0
	z.surface_id="street"
	check(not LineOfSight.check_figures(b,a,z).clear)


func test_exchange_moves_to_exact_support() -> void:
	var b:=_board()
	var a:=fig("wizard",0,Vector2(5,5))
	var z:=fig("knight",1,Vector2(8,5))
	a.surface_id="roof"
	a.elevation=4.0
	z.surface_id="street"
	z.elevation=0.0
	var c:=make_game(b,[a,z],LoadedDice.new([20]))
	var pair: Array[Figure]=[a,z]
	check(RealityFloorEffects.exchange(c,pair))
	check_eq(a.pos,Vector2(8,5))
	check_eq(a.surface_id,"street")
	check_eq(a.elevation,0.0)
	check_eq(z.pos,Vector2(5,5))
	check_eq(z.surface_id,"roof")
	check_eq(z.elevation,4.0)


func test_dynamic_portal_has_physical_support() -> void:
	var b:=_board()
	var c:=make_game(b,[],LoadedDice.new([20]))
	var p:=RealityCrackTerrain._make_disc(c,"reality_portal",Vector2(10,8),1.0)
	check(p!=null)
	if p==null:
		return
	check_eq(p.surface_id,"street")
	var layout:=b.floor_geometry()
	check(not layout.standable(layout.node("street",Vector2(10,8))))
	check(layout.standable(layout.node("roof",Vector2(10,8))))
	check(RealityFloorTerrain.move_disc(c,p,Vector2(13,8)))
	layout=b.floor_geometry()
	check(layout.standable(layout.node("street",Vector2(10,8))))
	check(not layout.standable(layout.node("street",Vector2(13,8))))
	RealityFloorTerrain.remove_disc(c.state,p)
	b.pieces.erase(p)
	check(b.floor_geometry().standable(b.floor_geometry().node("street",Vector2(13,8))))


func test_ruin_translation_carries_its_support() -> void:
	var b:=BoardLoader.from_dict({"size":[20,16],"floor_layout":{"surfaces":[{"id":"street","rect":[0,0,20,16],"level":0}]},"pieces":[{"kind":"platform","rect":[4,4,3,3],"id":"platform_test"}]},terrain())
	var p:=b.pieces[0]
	var layout:=b.floor_geometry()
	var index:=layout.index_of(p.dynamic_surface)
	check(index>=0)
	if index<0:
		return
	var f:=fig("wizard",0,Vector2(5.5,5.5))
	f.surface_id=p.dynamic_surface
	f.elevation=layout.surfaces[index].level
	var c:=make_game(b,[f],LoadedDice.new([20]))
	check(RealityFloorRuins.valid(c.state,p,Vector2(5,0)))
	RealityFloorRuins.shift(c,p,Vector2(5,0))
	check_eq(f.pos,Vector2(10.5,5.5))
	check_eq(f.surface_id,p.dynamic_surface)
	check(b.floor_geometry().standable(b.floor_geometry().node(f.surface_id,f.pos)))
