extends TestCase


func test_standard_zone_rolloff_and_opposite_edges() -> void:
	var s:=ScenarioLoader.load_id("treasure_skirmish",db(),terrain())
	var c:=GameController.new(s,LoadedDice.new([8,8,17,4]))
	var d:=c.begin_deployment(0)
	check_eq(d.rolls,[17,4])
	check_eq(d.active,0)
	check_eq(d.available(),[0,1,2,3])
	check(d.choose(1))
	check(not d.done)
	check(not d.choose(0))
	for f in s.side_figures(0):
		check(DeploymentRules.zone(s,1,f.pos))
		check(not d.points(f.id).is_empty())
	check(d.confirm())
	check_eq(d.zones[1],3)
	for f in s.side_figures(1):
		check(DeploymentRules.zone(s,3,f.pos))
	check_eq(s.turn,0)


func test_deployment_special_zones() -> void:
	var s:=make_game(make_board(),[],Dice.new(4)).state
	s.side_names.assign(["A","B"])
	check(DeploymentRules.zone(s,0,Vector2(6,3)))
	check(not DeploymentRules.zone(s,0,Vector2(5.5,3)))
	check(not DeploymentRules.zone(s,0,Vector2(12,3.5)))
	s.scenario_special="underground_library"
	check(DeploymentRules.zone(s,0,Vector2(18,6)))
	check(not DeploymentRules.zone(s,0,Vector2(25,0.5)))
	s.scenario_special="red_king_bridge"
	check(DeploymentRules.zone(s,0,Vector2(2.5,3)))
	check(not DeploymentRules.zone(s,0,Vector2(3.5,3.5)))
	s.scenario_special="red_king_herded"
	check(DeploymentRules.zone(s,0,Vector2(3.5,3.5)))
	s.scenario_special="red_king_ringworld"
	check(DeploymentRules.zone(s,0,Vector2(18,10),Vector2.INF,true))
	check(not DeploymentRules.zone(s,0,Vector2(18,9.5),Vector2.INF,true))
	check(DeploymentRules.zone(s,0,Vector2(12,12),Vector2(12,15)))
	check(not DeploymentRules.zone(s,0,Vector2(12,11.5),Vector2(12,15)))


func test_treasure_choices_precede_edge_roll() -> void:
	var s:=ScenarioLoader.load_id("genie_in_the_bottle",db(),terrain())
	var c:=GameController.new(s,LoadedDice.new([17,4]))
	var d:=c.begin_deployment(0,true)
	check_eq(d.treasure_stage,1)
	check(d.rolls.is_empty())
	var options:=d.treasure_options()
	check(not options.is_empty())
	if options.is_empty():
		return
	check(d.place_treasure(options[0]))
	check_eq(d.treasure_stage,3)
	check(d.rolls.is_empty())
	var first:=s.treasures[1].pos
	var second:=s.treasures[2].pos
	options=d.treasure_options()
	check(not options.is_empty())
	if options.is_empty():
		return
	check(d.place_treasure(options[0]))
	check_eq(d.treasure_stage,0)
	check_eq(s.treasures[1].pos,first)
	check_eq(s.treasures[2].pos,second)
	check_eq(d.rolls,[17,4])
