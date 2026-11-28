extends TestCase

func test_flat_board_opt_in_preserves_pieces_and_creates_roofs() -> void:
	var d: Dictionary={"id":"climbing_test","size":[16,16],"pieces":[{"kind":"library_shelf","rect":[7,5,1.5,6]},{"kind":"rubble","rect":[2,2,2,2]}]}
	var old:=BoardLoader.from_dict(d,terrain())
	d["shared_climbing"]=true
	var b:=BoardLoader.from_dict(d,terrain())
	check(old.floor_layout.is_empty())
	check(not b.floor_layout.is_empty())
	check_eq(b.pieces.size(),old.pieces.size())
	for i in old.pieces.size():
		check_eq(old.pieces[i].rect,b.pieces[i].rect)
		check_eq(old.pieces[i].kind.id,b.pieces[i].kind.id)
	var l:=b.floor_geometry()
	check(l.errors.is_empty(),str(l.errors))
	var top:=l.node(b.pieces[0].dynamic_surface,Vector2(7.5,8))
	check(l.standable(top))
	var start:=l.node("street",Vector2(6.5,8))
	check(LayeredReach.search(LayeredGrid.new(l),start,8.0).can_reach(top))

func test_library_shelves_support_climbing_and_doorway_only_exits() -> void:
	var s:=ScenarioLoader.load_id("underground_library",db(),terrain())
	var l:=s.board.floor_geometry()
	check(l.errors.is_empty(),str(l.errors))
	check(not s.scenario_data.has("support_errors"),str(s.scenario_data.get("support_errors",[])))
	check_eq(s.treasures[0].surface_id,"street")
	check(s.treasures[0].frozen)
	var roof:=l.node(s.board.pieces[0].dynamic_surface,Vector2(7.5,12))
	check(l.standable(roof))
	var start:=l.node("street",Vector2(6.5,12))
	check(LayeredReach.search(LayeredGrid.new(l),start,8.0).can_reach(roof))
	check(LayeredLoot.is_exit(s,l,l.node("street",Vector2(18,0.5)),0))
	check(not LayeredLoot.is_exit(s,l,l.node("street",Vector2(8,0.5)),0))
	check(not LayeredLoot.is_exit(s,l,roof,0))

func test_uneven_legacy_board_not_silently_flattened() -> void:
	var b:=BoardLoader.from_dict({"shared_climbing":true,"size":[12,12],"pieces":[{"kind":"sunken_ground","rect":[2,2,4,4],"level":-1}]},terrain())
	check(b.floor_layout.is_empty())
	check_eq(b.height_at(Vector2(3,3)),-1.0)

func test_main_silent_tower_has_derived_climbs() -> void:
	var b:=BoardLoader.load_id("silent_tower",terrain())
	var l:=b.floor_geometry()
	check(l.errors.is_empty(),str(l.errors))
	check(l.surfaces.any(func(s: FloorSurface) -> bool: return s.id.begins_with("climb:auto:")))
