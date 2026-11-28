extends TestCase


func test_gallery_support_collapse_is_local_and_persistent() -> void:
	var board:=BoardLoader.load_id("silent_tower",terrain())
	var f:=fig("wizard",0,Vector2(6.5,9.5))
	f.surface_id="west_ruin:broken_gallery"
	f.elevation=3.0
	var c:=make_game(board,[f],LoadedDice.new([20,20,20]))
	var target: TerrainPiece=null
	for p in board.pieces:
		if p.dynamic_surface=="west_ruin:gallery_pier":
			target=p
			break
	check(target!=null)
	if target==null:
		return
	var before:=board.floor_geometry()
	check(before.standable(before.node(f.surface_id,f.pos)))
	c._magic.crumble.apply(target)
	var layout:=board.floor_geometry()
	check_eq(layout.errors,[])
	check_eq(layout.index_of("west_ruin:broken_gallery"),-1)
	check_eq(layout.index_of("climb:west_ruin:gallery_climb:1"),-1)
	check(layout.index_of("east_ruin:broken_gallery")>=0)
	check(layout.index_of("tower_roof")>=0)
	check_eq(f.surface_id,"street")
	check_eq(f.elevation,0.0)
	check(f.in_play())
	var restored:=BattleSnapshotParts.make_board(BattleSnapshotParts.board_data(board))
	check_eq(restored.floor_geometry().index_of("west_ruin:broken_gallery"),-1)
	check_eq(restored.floor_geometry().errors,[])


func test_collapse_graph_removes_dependent_bridges_and_wall_routes() -> void:
	var layout: Dictionary={"surfaces":[{"id":"deck","requires_support":"pier"}],"convex_solids":[{"crumble_id":"pier2","requires_support":"pier"}],"bridges":[{"surface":{"id":"bridge:7"},"links":[{"from":["deck",1,1],"to":["bridge:7",2,1]}]}],"walls":[{"id":"wall:8","support":"bridge:7"}],"climbs":[{"id":"ladder","from":["street",1,1],"to":["deck",1,1]}]}
	var result:=ArchitectureCollapse.affected(layout,"pier")
	check(result["supports"].has("pier2"))
	check(result["floors"].has("deck"))
	check(result["floors"].has("bridge:7"))
	check(result["floors"].has("wall:8"))
	check(result["climbs"].has("ladder"))
