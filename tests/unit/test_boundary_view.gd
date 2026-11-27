extends TestCase


func test_boundary_data_and_view() -> void:
	var board := BoardLoader.from_dict({"size":[36,36],"boundaries":[{"a":[18,0],"b":[18,36],"sight":true,"movement":true}]},terrain())
	check_eq(board.boundaries.size(),1)
	check_eq(board.boundaries[0]["a"],Vector2(18,0))
	var view := BoundaryView.build(board)
	check(view.get_child_count()>0)
	check(view.get_child_count()<=20)
	view.free()


func test_reality_hazard_models() -> void:
	var b := make_board()
	var kind := TerrainKind.new()
	kind.id="reality_hoof"
	kind.height=3.0
	var piece := TerrainPiece.new(kind,Rect2(8.5,8.5,3.0,3.0))
	var model := Node3D.new()
	RealityHazardView.hoof(model,piece,b)
	check(model.get_child_count()>5)
	check(model.get_child_count()<20)
	model.free()
	var token := TerrainPiece.new(kind,Rect2(4.7,4.7,0.6,0.6))
	var rune := Node3D.new()
	RealityHazardView.worm(rune,token,b)
	check_eq(rune.get_child_count(),4)
	rune.free()
