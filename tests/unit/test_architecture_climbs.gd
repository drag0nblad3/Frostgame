extends TestCase

func _layout(enabled: bool=true) -> FloorLayout:
	return FloorLayout.from_dict({"auto_architecture_climbs":enabled,"surfaces":[{"id":"street","rect":[0,0,20,20],"level":0},{"id":"roof","rect":[8,5,4,6],"level":3}],"solids":[[8,0,5,4,3,6]]})

func test_unmarked_wall_has_legal_climb_and_partial_stops() -> void:
	var l:=_layout()
	check(l.errors.is_empty(),str(l.errors))
	var start:=l.node("street",Vector2(7.5,8))
	var roof:=l.node("roof",Vector2(8.5,8))
	var grid:=LayeredGrid.new(l)
	var partial:=LayeredReach.search(grid,start,4.0)
	var hanging:=false
	for n: Vector3i in partial.cost:
		if l.surface_id(n).begins_with("climb:auto:") and l.height(n)>0 and l.height(n)<3.0:
			hanging=true
	check(hanging,"can finish midway up an unmarked wall")
	check(not partial.can_reach(roof))
	var complete:=LayeredReach.search(grid,start,9.0)
	check(complete.can_reach(roof))
	check(not LayeredReach.search(LayeredGrid.new(_layout(false)),start,9.0).can_reach(roof))

func test_derived_ids_are_deterministic() -> void:
	var a:=_layout()
	var b:=_layout()
	check_eq(a.surfaces.size(),b.surfaces.size())
	for i in a.surfaces.size():
		check_eq(a.surfaces[i].id,b.surfaces[i].id)
	check(a.surfaces.size()>2)

func test_tower_automatically_generates_extra_climbs() -> void:
	var board:=BoardLoader.load_id("layered_silent_tower",terrain())
	var l:=board.floor_geometry()
	check(l.errors.is_empty(),str(l.errors))
	var count:=0
	for surface in l.surfaces:
		if surface.id.begins_with("climb:auto:"):
			count+=1
	check(count>0,"tower masonry has extra climb routes")
