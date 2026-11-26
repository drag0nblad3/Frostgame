extends TestCase


func test_tower_has_independent_floors_and_access_routes() -> void:
	var b := BoardLoader.load_id("layered_silent_tower",terrain())
	var layout := FloorLayout.from_dict(b.floor_layout)
	check(layout.errors.is_empty(),str(layout.errors))
	var nodes := layout.nodes_at(Vector2(18,18))
	check_eq(nodes.size(),4)
	var target := layout.node("tower_roof",Vector2(18,18))
	var start := layout.node("street",Vector2(18,18))
	check(not LayeredReach.search(LayeredGrid.new(layout),start,10.0).can_reach(target))
	check(LayeredReach.search(LayeredGrid.new(layout),start,100.0).can_reach(target))
	check(not LayeredSight.clear(layout,Vector3(18,1,18),Vector3(18,11,18)))
