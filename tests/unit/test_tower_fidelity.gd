extends TestCase


func test_silent_tower_treasure_distances_are_three_dimensional() -> void:
	var db:=FigureDb.load_files(FigureDb.FIGURES,FigureDb.WEAPONS)
	var s:=ScenarioLoader.load_id("silent_tower",db,TerrainDb.load_file())
	var central:=s.treasures[0]
	check_eq(TreasureRules.token_height(s,central),10.0)
	for i in [1,2]:
		var t:=s.treasures[i]
		var distance:=Vector3(t.pos.x,TreasureRules.token_height(s,t),t.pos.y).distance_to(Vector3(central.pos.x,10,central.pos.y))
		check(distance>=6.0 and distance<=8.0)
	check(not s.scenario_data.has("support_errors"),str(s.scenario_data.get("support_errors","")))
