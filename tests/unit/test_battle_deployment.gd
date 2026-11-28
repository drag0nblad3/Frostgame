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


func test_mausoleum_player_treasure_and_guard_setup() -> void:
	var s:=ScenarioLoader.load_id("mausoleum",db(),terrain())
	var c:=GameController.new(s,LoadedDice.new([17,4]))
	var fixed: Array[Vector2]=[]
	for i in 4:
		fixed.append(s.treasures[i].pos)
	var d:=c.begin_deployment(0,true)
	check_eq(d.treasure_stage,4)
	check(d.rolls.is_empty())
	var options:=d.treasure_options()
	check(not options.is_empty())
	if options.is_empty():
		return
	var chosen:=options[0]
	check(d.place_treasure(chosen))
	check_eq(d.treasure_stage,0)
	check_eq(s.treasures[4].pos,chosen["at"])
	check_eq(s.side_figures(-1)[4].pos,chosen["guard"])
	for i in 4:
		check_eq(s.treasures[i].pos,fixed[i])
	for i in [4,5]:
		var t:=s.treasures[i]
		var guard:=s.side_figures(-1)[i]
		check(Geom.point_rect_distance(t.pos,MausoleumSetup.building(s))<=9.0)
		check(guard.pos.distance_to(t.pos)<=1.0)
		check(s.board.floor_geometry().standable(s.board.floor_geometry().node(guard.surface_id,guard.pos)))


func test_mausoleum_elevated_treasure_and_guard_share_support() -> void:
	var s:=ScenarioLoader.load_id("mausoleum",db(),terrain())
	var layout:=s.board.floor_geometry()
	var choices:=MausoleumSetup.options(s,4)
	var upper: Dictionary={}
	for p in choices:
		if float(p["height"])>0.5 and str(p["surface"])!="street":
			upper=p
			break
	check(not upper.is_empty())
	if upper.is_empty():
		return
	check(MausoleumSetup.choose(s,Dice.new(41),upper))
	var token:=s.treasures[4]
	var guard:=s.side_figures(-1)[4]
	check_eq(token.surface_id,upper["surface"])
	check_eq(guard.surface_id,token.surface_id)
	check_eq(guard.pos,upper["guard"])
	check_eq(guard.elevation,upper["guard_height"])
	check(layout.standable(layout.node(token.surface_id,token.pos)))
	check(layout.standable(layout.node(guard.surface_id,guard.pos)))
	check(guard.pos.distance_to(token.pos)<=1.0)
	check(absf(guard.elevation-TreasureRules.token_height(s,token))<0.5)
	check(not token.surface_id.begins_with("climb:"))
