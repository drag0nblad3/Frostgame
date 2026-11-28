extends TestCase


func test_ruin_interior_and_breach_are_real() -> void:
	var b:=BoardLoader.from_dict({"id":"ruin_test","size":[16,16],"pieces":[{"ruin_kit":"breached_manor","rect":[4,4,6,5]}]},terrain())
	var inside:=Vector2(7,6.5)
	var outside:=Vector2(7,10)
	check(b.can_stand(inside,Figure.BASE_RADIUS))
	check(b.can_stand(Vector2(7,8.5),Figure.BASE_RADIUS))
	check(LineOfSight.check(b,outside,inside).clear)
	check(not LineOfSight.check(b,Vector2(3,6.5),inside).clear)
	check(not b.can_stand(Vector2(4.35,6.5),Figure.BASE_RADIUS))
	var heights: Array[float]=[]
	for p in b.pieces:
		if not heights.has(p.kind.height):
			heights.append(p.kind.height)
	check(heights.size()>=4)


func test_rotated_kits_stay_in_footprint() -> void:
	var catalog:=JsonFile.read(TerrainAssembly.RUIN_KITS)
	for key in catalog:
		for turns in 4:
			var bounds:=Rect2(3,5,6,5)
			var entries:=TerrainAssembly.expand_ruin({"ruin_kit":key,"rect":[3,5,6,5],"quarter_turns":turns},catalog)
			check(entries.size()>=5)
			for p: Dictionary in entries:
				var r: Array=p["rect"]
				var rect:=Rect2(r[0],r[1],r[2],r[3])
				check(bounds.grow(0.001).encloses(rect))
				check(rect.get_area()>0.0)


func test_three_maps_have_structural_ruins() -> void:
	for id in ["frozen_ruins","sunken_streets","the_keep"]:
		var board:=BoardLoader.load_id(id,terrain())
		var remnants:=0
		for p in board.pieces:
			if p.kind.id=="ruin_broken_wall":
				remnants+=1
		check(remnants>=4,id)
