extends TestCase


func test_tower_objectives_have_real_vertical_spacing() -> void:
	var s:=ScenarioLoader.load_id("silent_tower",db(),terrain())
	check(not s.scenario_data.has("support_errors"))
	var central:=s.treasures[0]
	check_eq(TreasureRules.token_height(s,central),10.0)
	for i in range(1,5):
		var t:=s.treasures[i]
		var a:=Vector3(t.pos.x,TreasureRules.token_height(s,t),t.pos.y)
		var distance:=a.distance_to(Vector3(central.pos.x,10,central.pos.y))
		check(distance>=6.0)
		if i<=2:
			check(distance<=8.0)
		else:
			check(TreasureRules.edge_distance(s.board,t.pos)>9.0)
		for j in range(1,i):
			var other:=s.treasures[j]
			check(a.distance_to(Vector3(other.pos.x,TreasureRules.token_height(s,other),other.pos.y))>=6.0)
	check(s.board.floor_geometry().solids.size()>30)


func test_tower_keeps_main_entry_and_roof_support() -> void:
	var s:=ScenarioLoader.load_id("silent_tower",db(),terrain())
	var l:=s.board.floor_geometry()
	for row in [["street",Vector2(18,15.5)],["tower_roof",Vector2(18,18)],["west_walk",Vector2(12,17.5)],["east_walk",Vector2(23,19.5)]]:
		check(l.standable(l.node(str(row[0]),row[1]),Figure.BASE_RADIUS,1.6),str(row))
