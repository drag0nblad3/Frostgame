extends TestCase
## Direct geometric assertions of named scenarios, not general treasure placement.


func test_mausoleum_door_and_corner_objectives() -> void:
	var s:=ScenarioLoader.load_id("mausoleum",db(),terrain())
	var center:=s.board.size*0.5
	var crypt: TerrainPiece=null
	for p in s.board.pieces:
		if p.kind.id=="ruin" and p.rect.has_point(center):
			crypt=p
			break
	check(crypt!=null)
	if crypt==null:
		return
	check_eq(crypt.rect.size,Vector2(6,6))
	check_eq(s.reinforcement_points.size(),4)
	for i in range(4):
		var t:=s.treasures[i]
		check(not t.central)
		check(Geom.point_rect_distance(t.pos,crypt.rect)<=TreasureRules.TOKEN_RADIUS+0.001)
		check(not crypt.rect.has_point(t.pos))
	for i in range(4,6):
		check(Geom.point_rect_distance(s.treasures[i].pos,crypt.rect)<=9.0)
	check_eq(s.side_figures(-1).size(),6)


func test_keep_discs_and_museum_statues() -> void:
	var keep:=ScenarioLoader.load_id("the_keep",db(),terrain())
	var discs: Array[Vector2]=[]
	for p in keep.board.pieces:
		if p.kind.id=="arcane_disc":
			check(p.circular)
			check(p.rect.size.x>=2.0 and p.rect.size.x<=3.0)
			discs.append(p.rect.get_center())
	check_eq(discs.size(),4)
	for i in range(1,5):
		check(discs.has(keep.treasures[i].pos))
	for at in discs:
		check(is_equal_approx(at.distance_to(keep.board.size*0.5),6.0))
	var museum:=ScenarioLoader.load_id("living_museum",db(),terrain())
	var statues: Array[Vector2]=[]
	for p in museum.board.pieces:
		if p.kind.id=="museum_statue":
			statues.append(p.rect.get_center())
	check_eq(statues.size(),5)
	check(statues.has(museum.board.size*0.5))
	for at in statues:
		var found:=false
		for token in museum.treasures:
			if token.pos.distance_to(at)<=1.0:
				found=true
		check(found)


func test_red_king_authored_special_dimensions() -> void:
	var figures:=FigureDb.load_files(FigureDb.FIGURES,FigureDb.WEAPONS,ContentProfile.new(["red_king"]))
	var veil:=ScenarioLoader.load_id("red_king_veil",figures,terrain())
	check_eq(veil.board.size,Vector2(24,36))
	for i in veil.treasures.size():
		for j in range(i):
			check(veil.treasures[i].pos.distance_to(veil.treasures[j].pos)>=12.0)
	var mind:=ScenarioLoader.load_id("red_king_mind",figures,terrain())
	check_eq(mind.board.size,Vector2(24,24))
	check_eq(mind.board.pieces.size(),0)
	check_eq(mind.treasures.size(),8)
	var bridge:=ScenarioLoader.load_id("red_king_bridge",figures,terrain())
	check_eq(bridge.board.size,Vector2(30,36))
	check(bridge.board.over_void(Vector2(12.5,33)))
	check(not bridge.board.over_void(Vector2(15,33)))
	check(bridge.board.over_void(Vector2(17.5,33)))
	var tethers:=ScenarioLoader.load_id("red_king_tethers",figures,terrain())
	var count:=0
	for f in tethers.figures:
		if f.def.id=="red_king_pylon":
			count+=1
			var distance:=f.pos.distance_to(tethers.board.size*0.5)
			check(distance<0.01 or absf(distance-8.0)<0.3)
	check_eq(count,5)
