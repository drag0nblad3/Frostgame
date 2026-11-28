extends TestCase


func test_diagonal_prism_collision_is_not_its_bounding_box() -> void:
	var p:=ArchitecturePrism.from_dict({"profile":[[2,0,2],[5,0,5],[5.3,0,4.7],[2.3,0,1.7]],"extrusion":[0,3,0]})
	check(p.valid)
	check(p.overlaps(AABB(Vector3(3,0.1,3),Vector3(0.4,1.6,0.4))))
	check(not p.overlaps(AABB(Vector3(2.2,0.1,4.2),Vector3(0.4,1.6,0.4))))
	check(p.intersects_ray(Vector3(2,1,4),Vector3(4,1,2)))
	check(not p.intersects_ray(Vector3(2,4,4),Vector3(4,4,2)))
	check(p.mesh().get_surface_count()==1)


func test_sloping_roof_ray_and_clearance_share_geometry() -> void:
	var p:=ArchitecturePrism.from_dict({"profile":[[0,2,0],[4,4,0],[4,4,3],[0,2,3]],"extrusion":[0,0.2,0]})
	check(p.valid)
	check(p.intersects_ray(Vector3(2,0,1),Vector3(2,5,1)))
	check(not p.overlaps(AABB(Vector3(2,0.002,1),Vector3(0.4,1.6,0.4))))
	check(p.overlaps(AABB(Vector3(2,2.7,1),Vector3(0.4,1.6,0.4))))


func test_silent_tower_convex_ruins_have_real_geometry() -> void:
	var b:=BoardLoader.load_id("silent_tower",terrain())
	var l:=b.floor_geometry()
	check_eq(l.errors,[])
	check(l.convex_solids.size()>=20)
	# The centre of the arch is a passage; its masonry blocks higher rays.
	check(l.clearance(Vector3(6.5,0,28.9),Figure.BASE_RADIUS,1.6))
	check(LayeredSight.clear(l,Vector3(6.5,1.4,28.2),Vector3(6.5,1.4,29.5)))
	check(not LayeredSight.clear(l,Vector3(6.5,2.9,28.2),Vector3(6.5,2.9,29.5)))


func test_crumble_creates_real_breach_in_angled_wall() -> void:
	var entry: Dictionary={"profile":[[4,0,4],[8,0,8],[8.3,0,7.7],[4.3,0,3.7]],"extrusion":[0,3,0],"crumble_id":"test_wall"}
	var board:=BoardLoader.from_dict({"size":[16,16],"floor_layout":{"surfaces":[{"id":"street","rect":[0,0,16,16]}],"convex_solids":[entry]}},terrain())
	check_eq(board.pieces.size(),1)
	var f:=fig("wizard",0,Vector2(4,8))
	f.surface_id="street"
	var c:=make_game(board,[f],LoadedDice.new([20]))
	var center:=Vector3(6.15,0,5.85)
	check(not board.floor_geometry().clearance(center,0.25,1.6))
	c._magic.crumble.apply(board.pieces[0])
	check_eq(board.floor_geometry().convex_solids.size(),2)
	check(board.floor_geometry().clearance(center,0.25,1.6))
	check(LayeredSight.clear(board.floor_geometry(),center+Vector3(-2,1,2),center+Vector3(2,1,-2)))
	check(not LayeredSight.clear(board.floor_geometry(),Vector3(4,1,6),Vector3(6,1,4)))


func test_clearance_spatial_index_matches_full_scan() -> void:
	var b:=BoardLoader.load_id("silent_tower",terrain())
	var l:=b.floor_geometry()
	check(l.solids.size()+l.convex_solids.size()+l.circular_solids.size()>=16)
	# Add a circular obstacle with an unequal stored z extent before any
	# indexed query, exercising the original x-radius interpretation.
	l.circular_solids.append(AABB(Vector3(13,0,13),Vector3(2,3,1)))
	var samples:=0
	for x in range(0,73,2):
		for z in range(0,73,2):
			for h: float in [0.0,2.0,4.0]:
				var at:=Vector3(float(x)*0.5,h,float(z)*0.5)
				for radius: float in [0.25,0.5,1.0,1.5]:
					var expected:=l._clearance_volumes(at,radius,1.6,l.solids,l.circular_solids,l.convex_solids)
					if l.profiled_ground!=null and at.y<l.profiled_ground.height_at(Vector2(at.x,at.z))-0.002:
						expected=false
					check_eq(l.clearance(at,radius,1.6),expected)
					samples+=1
	check(samples>10000)
	check(not l._clearance_cells.is_empty())
	var largest:=0
	for key in l._clearance_cells:
		var bucket: Array=l._clearance_cells[key]
		largest=maxi(largest,bucket[0].size()+bucket[1].size()+bucket[2].size())
	print("clearance broad phase: ",l.solids.size()+l.circular_solids.size()+l.convex_solids.size()," volumes, ",l._clearance_cells.size()," bins, largest ",largest,"; ",samples," parity checks")


func test_clearance_index_is_rebuilt_with_changed_geometry() -> void:
	var b:=make_board()
	var solids: Array=[]
	for i in 16:
		solids.append([float(i)*2.0,0,2,1,2,1])
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,36,36],"level":0}],"solids":solids}
	var l:=b.floor_geometry()
	var at:=Vector3(0.5,0,2.5)
	check(not l.clearance(at,0.5,1.6))
	# Replace a solid while keeping the authored array count unchanged.
	# The Board owns geometry revisions, not the spatial index.
	b.floor_layout["solids"][0]=[0,0,20,1,2,1]
	var revised:=b.floor_geometry()
	check(revised!=l)
	check(revised.clearance(at,0.5,1.6))
	check(not l.clearance(at,0.5,1.6))
