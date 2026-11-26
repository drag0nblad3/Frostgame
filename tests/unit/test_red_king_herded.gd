extends TestCase


func _fixture() -> GameController:
	var packs := ContentProfile.registered().duplicate(true)
	packs["red_king"]["status"]="ready"
	var defs := FigureDb.load_files(FigureDb.FIGURES,FigureDb.WEAPONS,ContentProfile.new(["red_king"],packs))
	return GameController.new(ScenarioLoader.load_id("red_king_herded",defs,terrain()),Dice.new(38))


func test_veil_movement_and_contact() -> void:
	var c := _fixture()
	var s := c.state
	check_eq(s.board.size,Vector2(30,36))
	check_eq(s.treasures.size(),5)
	check(s.board.darkness)
	check_eq(s.scenario_data["herd_pool"].size(),8)
	for i in range(1,21):
		check_eq(RedKingHerded.distance_for(i),2 if i<=4 else (3 if i<=8 else (4 if i<=14 else (5 if i<=18 else 6))))
	var f := s.figures[0]
	f.pos=Vector2(15,4)
	var hp := f.health
	for other in s.figures:
		if other!=f and other.side>=0:
			other.pos=Vector2(2,20)
	RedKingHerded.advance(c,4)
	check_eq(s.scenario_data["herd_veil"],4.0)
	check_eq(f.health,hp-6)
	check(f.pos.y>4.5)
	check(not LineOfSight.check(s.board,Vector2(15,5),Vector2(15,19)).clear)
	check(ScenarioObjectives.exit_allowed(s,Vector2(15,35.5),0))
	check(not ScenarioObjectives.exit_allowed(s,Vector2(0.5,15),0))
	RedKingHerded.advance(c,8)
	check(not f.in_play())


func test_ragged_recruitment_and_retained_items() -> void:
	var c := _fixture()
	var campaign := CampaignProgress.new()
	campaign.start({"name":"Test","figures":[{"type":"wizard"},{"type":"thug"}],"gold":400},c.state.content_profile)
	var d := campaign.data
	d["loot"].append({"kind":"potion","potion":"healing","owner":1})
	d["loot"].append({"kind":"potion","potion":"healing","owner":-1})
	RaggedWarbands.enter(d)
	RaggedWarbands.soldier_survival(d["units"][1],8)
	check(not d["units"][1]["dead"])
	check(d["units"][1]["ragged_absent"])
	check(RaggedWarbands.absent_owner(d,d["loot"][0]))
	check(not CampaignInventory.assign_item(d,0,0,c.state.creature_db))
	check(d["loot"][1]["ragged_sealed"])
	check_eq(RaggedWarbands.fill(d,c.state.creature_db,Dice.new(23)),9)
	check_eq(RaggedWarbands.ready_count(d),10)
	check_eq(d["gold"],400)
	check(not campaign.can_hire("thug",c.state.creature_db))
	check(not campaign.dismiss(2))
	check(not CampaignInventory.buy(d,"healing"))
	check(not RaggedWarbands.has_unassigned(d))
	d["loot"].append({"kind":"potion","potion":"healing","owner":-1})
	check(RaggedWarbands.has_unassigned(d))
	check(RaggedWarbands.discard(d,d["loot"].size()-1))
	check(not RaggedWarbands.has_unassigned(d))
