extends TestCase


func test_flat_scatter_avoids_terrain_and_ramps() -> void:
	var board := BoardLoader.load_id("frozen_ruins",TerrainDb.load_file())
	check(not EnvironmentDressing.flat_ground(board,Vector2(5,13),0.4))
	check(not EnvironmentDressing.flat_ground(board,Vector2(0.1,1),0.4))
	check(EnvironmentDressing.flat_ground(board,Vector2(2,2),0.4))
	var sunken := BoardLoader.load_id("sunken_streets",TerrainDb.load_file())
	for piece in sunken.pieces:
		if piece.ramp:
			check(not EnvironmentDressing.flat_ground(sunken,piece.rect.get_center(),0.4))


func test_dressing_is_visual_only_and_batched() -> void:
	var board := BoardLoader.load_id("frozen_ruins",TerrainDb.load_file())
	var count := board.pieces.size()
	var root := EnvironmentDressing.build(board,"treasure_skirmish")
	check_eq(board.pieces.size(),count)
	check(root.get_child_count()>0)
	check(root.get_child_count()<12)
	check(root.find_children("*","CollisionObject3D",true,false).is_empty())
	root.free()
