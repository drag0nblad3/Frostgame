extends TestCase


func test_boundary_data_and_view() -> void:
	var board := BoardLoader.from_dict({"size":[36,36],"boundaries":[{"a":[18,0],"b":[18,36],"sight":true,"movement":true}]},terrain())
	check_eq(board.boundaries.size(),1)
	check_eq(board.boundaries[0]["a"],Vector2(18,0))
	var view := BoundaryView.build(board)
	check(view.get_child_count()>0)
	check(view.get_child_count()<=20)
	view.free()
