extends TestCase


func test_default_zones_and_corner_exceptions() -> void:
	var size:=Vector2(36,36)
	check(DeploymentRules.zone("silent_tower",size,0,Vector2(6,3)))
	check(not DeploymentRules.zone("silent_tower",size,0,Vector2(5.5,2)))
	check(not DeploymentRules.zone("silent_tower",size,0,Vector2(18,4.5)))
	check(DeploymentRules.zone("silent_tower",size,1,Vector2(33,18)))
	check(DeploymentRules.zone("underground_library",size,0,Vector2(18,5)))
	check(not DeploymentRules.zone("underground_library",size,0,Vector2(10,2)))
	check(DeploymentRules.zone("red_king_bridge",size,0,Vector2(2,2)))
	check(not DeploymentRules.zone("red_king_bridge",size,0,Vector2(3,3)))
	check(DeploymentRules.zone("red_king_herded",size,1,Vector2(33,3)))


func test_deployment_draft_is_atomic_and_rejects_overlap() -> void:
	var db:=FigureDb.load_files(FigureDb.FIGURES,FigureDb.WEAPONS)
	var s:=ScenarioLoader.load_id("silent_tower",db,TerrainDb.load_file())
	var c:=GameController.new(s,Dice.new(31))
	var before:=s.figures[0].pos
	var p:=DeploymentPlan.new(s,"silent_tower",0,c.dice)
	check(p.complete(),p.error)
	check_eq(s.figures[0].pos,before)
	check_eq(s.turn,0)
	var members:=s.side_figures(0)
	if not p.complete():
		return
	var occupied: Vector2=p.placements[members[1].id]["at"]
	check(not p.move(members[0].id,occupied))
	check(not p.move(members[0].id,Vector2(18,18)))
	check(c.apply_deployment(p),p.error)
	for f in s.figures:
		if f.side>=0:
			check(DeploymentRules.zone("silent_tower",s.board.size,p.edge[f.side],f.pos))
			check_eq(f.surface_id,"street")


func test_well_and_investigation_edges() -> void:
	check_eq(DeploymentRules.choices("dreams_well"),[1,3])
	check_eq(DeploymentRules.choices("red_king_investigations"),[0,2])


func test_ringworld_formation() -> void:
	var profile:=ContentProfile.new(["red_king"])
	var catalog:=FigureDb.load_files(FigureDb.FIGURES,FigureDb.WEAPONS,profile)
	var s:=ScenarioLoader.load_id("red_king_ringworld",catalog,TerrainDb.load_file())
	var c:=GameController.new(s,Dice.new(31))
	var plan:=DeploymentPlan.new(s,"red_king_ringworld",0,c.dice)
	check(plan.complete(),plan.error)
	if not plan.complete():
		return
	check(c.apply_deployment(plan))
	for side in 2:
		var wizard:Figure=null
		for f in s.side_figures(side):
			if f.def.role=="wizard":
				wizard=f
		check(wizard!=null)
		if wizard==null:
			continue
		check(wizard.pos.distance_to(s.board.size*0.5)<=8.001)
		for f in s.side_figures(side):
			check(f.pos.distance_to(wizard.pos)<=3.001)
			for rival in s.side_figures(1-side):
				check(f.pos.distance_to(rival.pos)>=6.999)
