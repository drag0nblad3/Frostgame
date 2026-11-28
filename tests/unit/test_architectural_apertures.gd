extends TestCase


func test_window_blocks_feet_but_allows_sight() -> void:
	var errors: Array=[]
	var volumes:=FloorAssembly.aperture_volumes({"rect":[4,4,6,0.5],"height":3,"openings":[[2,4,0.7,2.2]]},errors)
	check_eq(errors,[])
	var layout:=FloorLayout.from_dict({"surfaces":[{"id":"street","rect":[0,0,16,16]}],"solids":volumes})
	check(LayeredSight.clear(layout,Vector3(7,1.5,3),Vector3(7,1,6)))
	check(not LayeredSight.clear(layout,Vector3(5,1.5,3),Vector3(5,1,6)))
	check(not layout.standable(layout.node("street",Vector2(7,4.5))))
	check(not LayeredSight.clear(layout,Vector3(7,2.5,3),Vector3(7,2.5,6)))


func test_stepped_arch_and_invalid_overlapping_openings() -> void:
	var errors: Array=[]
	var wall: Dictionary={"rect":[4,4,0.5,6],"axis":"y","height":3,"openings":[[1,2,0,1.9],[2,4,0,2.5],[4,5,0,1.9]]}
	var layout:=FloorLayout.from_dict({"surfaces":[{"id":"street","rect":[0,0,16,16]}],"solids":FloorAssembly.aperture_volumes(wall,errors)})
	check_eq(errors,[])
	check(layout.standable(layout.node("street",Vector2(4.5,7))))
	check(LayeredSight.clear(layout,Vector3(3,2.2,7),Vector3(6,2.2,7)))
	check(not LayeredSight.clear(layout,Vector3(3,2.2,5.5),Vector3(6,2.2,5.5)))
	wall["openings"]=[[1,3,0,2],[2,4,0,2]]
	check(FloorAssembly.aperture_volumes(wall,errors).is_empty())
	check(not errors.is_empty())


func test_silent_tower_gallery_has_real_open_ground_and_climb() -> void:
	var board:=BoardLoader.load_id("silent_tower",terrain())
	var layout:=board.floor_geometry()
	check_eq(layout.errors,[])
	var street:=layout.node("street",Vector2(6.5,9.5))
	var upper:=layout.node("west_ruin:broken_gallery",Vector2(7.5,9.5))
	check(layout.standable(street))
	check(layout.standable(upper))
	check_eq(layout.height(upper),3.0)
	check(layout.standable(layout.node("street",Vector2(6.5,8))))
	check(not LayeredSight.clear(layout,Vector3(6.5,1.5,9.5),Vector3(6.5,4.5,9.5)))
	var start:=layout.node("street",Vector2(8.5,9.5))
	if layout.errors.is_empty():
		check(LayeredReach.search(LayeredGrid.new(layout),start,20).can_reach(upper))
	check(layout.index_of("east_ruin:broken_gallery")>=0)
