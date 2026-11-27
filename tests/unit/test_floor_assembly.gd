extends TestCase


func test_repeated_rotated_gatehouses_have_independent_routes() -> void:
	var source: Dictionary=JsonFile.read(BoardLoader.DIR+"stacked_gatehouse.json")
	source["size"]=[50,50]
	source["floor_layout"]["surfaces"][0]["rect"]=[0,0,50,50]
	source["floor_assemblies"]=[
		{"kit":"gatehouse","prefix":"west:","origin":[5,5]},
		{"kit":"gatehouse","prefix":"east:","origin":[35,25],"quarter_turns":1}]
	var original := source.duplicate(true)
	var board := BoardLoader.from_dict(source,terrain())
	var layout := board.floor_geometry()
	check_eq(layout.errors,[])
	check_eq(source,original)
	var west := layout.node("west:stairs",Vector2(2,8))
	var east := layout.node("east:stairs",Vector2(32,22))
	check(layout.standable(west))
	check(layout.standable(east))
	if layout.standable(west) and layout.standable(east):
		check_eq(layout.height(west),layout.height(east))
		check(layout.links.has(west))
		check(layout.links.has(east))
		var upper := layout.node("east:upper",Vector2(32,26))
		check(layout.standable(upper))
		check_eq(layout.height(upper),3.0)
	check(layout.index_of("climb:west:east_wall:1")>=0)
	check(layout.index_of("climb:east:east_wall:1")>=0)
	check_eq(layout.solids.size(),8)


func test_authored_tower_preserves_surface_order_and_connections() -> void:
	for id in ["silent_tower","layered_silent_tower"]:
		var board := BoardLoader.load_id(id,terrain())
		var layout := board.floor_geometry()
		check_eq(layout.errors,[],id)
		check_eq(layout.index_of("street"),0)
		check_eq(layout.index_of("tower_first"),5)
		check_eq(layout.index_of("tower_second"),6)
		check_eq(layout.index_of("tower_roof"),7)
		var roof := layout.node("tower_roof",Vector2(18,18))
		check(layout.standable(roof))
		if layout.standable(roof):
			check_eq(layout.height(roof),10.0)
		check_eq(board.floor_layout["tower_region"],[14,14,8,8])
		check(layout.links.has(layout.node("stair_lower",Vector2(14.5,11.5))))


func test_floor_kit_errors_are_reported() -> void:
	var source := {"floor_layout":{"surfaces":[{"id":"street","rect":[0,0,20,20]}]},"floor_assemblies":[{"kit":"missing","prefix":"bad:","origin":[0,0]}]}
	var board := BoardLoader.from_dict(source,terrain())
	check(not board.floor_geometry().errors.is_empty())
