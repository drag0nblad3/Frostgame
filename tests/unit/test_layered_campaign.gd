extends TestCase


func test_candidate_preserves_roster_and_central_treasure() -> void:
	var data: Dictionary=JsonFile.read(ScenarioLoader.DIR+"silent_tower.json")
	var roster: Dictionary=data["warbands"][0].duplicate(true)
	roster["figures"][0]["campaign_id"]=99
	roster["figures"][0]["stat_bonus"]={"health":2}
	var s := LayeredCampaign.build(data,roster,db(),terrain())
	check_eq(s.board.id,"layered_silent_tower")
	check_eq(s.figures[0].campaign_id,99)
	check_eq(s.figures[0].health,db().get_def(roster["figures"][0]["type"]).health+2)
	check_eq(s.figures[0].surface_id,"street")
	check_eq(s.treasures.size(),5)
	check(s.treasures[0].central)
	check_eq(s.treasures[0].surface_id,"tower_roof")
	var layout := FloorLayout.from_dict(s.board.floor_layout)
	check(layout.errors.is_empty(),str(layout.errors))
	for f in s.figures:
		check(layout.standable(layout.node(f.surface_id,f.pos)))
