extends TestCase


func test_library_four_passable_openings() -> void:
	var b:=BoardLoader.load_id("underground_library",terrain())
	for row: Array in [[Vector2(18,0.5),Vector2(18,2),Vector2(12,0.5)],[Vector2(35.5,18),Vector2(34,18),Vector2(35.5,12)],[Vector2(18,35.5),Vector2(18,34),Vector2(12,35.5)],[Vector2(0.5,18),Vector2(2,18),Vector2(0.5,12)]]:
		check(b.can_stand(row[0],Figure.BASE_RADIUS))
		check(b.can_stand(row[1],Figure.BASE_RADIUS))
		check(not b.can_stand(row[2],Figure.BASE_RADIUS))
		check(LineOfSight.check(b,row[0],row[1]).clear)


func test_tent_two_opposing_openings_and_closed_sides() -> void:
	var b:=BoardLoader.load_id("red_king_investigations",terrain())
	var center:=Vector2(18,18)
	check(b.can_stand(center,Figure.BASE_RADIUS))
	for at: Vector2 in [Vector2(18,14),Vector2(18,22)]:
		check(LineOfSight.check(b,at,center).clear)
		check(b.can_stand(at.lerp(center,0.5),Figure.BASE_RADIUS))
	for at: Vector2 in [Vector2(14,18),Vector2(22,18)]:
		check(not LineOfSight.check(b,at,center).clear)
	for p in b.pieces:
		if p.kind.id=="tent_canvas":
			check(Rect2(15,15,6,6).encloses(p.rect))


func test_temple_four_corner_exits_and_portal_circle() -> void:
	var b:=BoardLoader.load_id("red_king_back_into_fire",terrain())
	for at: Vector2 in [Vector2(0.5,2),Vector2(2,0.5),Vector2(35.5,2),Vector2(34,0.5),Vector2(0.5,34),Vector2(2,35.5),Vector2(35.5,34),Vector2(34,35.5)]:
		check(b.can_stand(at,Figure.BASE_RADIUS),str(at))
	for p in b.pieces:
		if p.kind.id=="red_king_portal":
			check(absf(p.rect.get_center().distance_to(b.size*0.5)-6.0)<0.1)
			check_eq(p.rect.size,Vector2(2,2))
			check(p.rect.get_center().y>18.0)


func test_guardians_have_three_inches_between_edges() -> void:
	var b:=BoardLoader.load_id("complex_temple",terrain())
	var cols: Array[TerrainPiece]=[]
	for p in b.pieces:
		if p.kind.id=="temple_column":
			cols.append(p)
	check_eq(cols.size(),6)
	for i in range(cols.size()):
		for j in range(i):
			var a:=cols[i].rect
			var z:=cols[j].rect
			var gap:=Vector2(maxf(0.0,maxf(a.position.x-z.end.x,z.position.x-a.end.x)),maxf(0.0,maxf(a.position.y-z.end.y,z.position.y-a.end.y))).length()
			check(gap>=3.0)
