extends TestCase
## Setup checks independent of presentation and automatic combat.

func _world(s: GameState,t: TreasureToken) -> Vector3:
	return Vector3(t.pos.x,TreasureRules.token_height(s,t),t.pos.y)


func test_standard_objective_spacing() -> void:
	for id in ["treasure_skirmish","sunken_streets","dreams_well","underground_library","worm_hunts","genie_in_the_bottle","silent_tower"]:
		var s:=ScenarioLoader.load_id(id,db(),terrain())
		check_eq(s.treasures.size(),5,id)
		var central:=_world(s,s.treasures[0])
		for i in range(1,5):
			var t:=s.treasures[i]
			var at:=_world(s,t)
			check(not is_nan(at.y),id)
			if i<=2:
				check(at.distance_to(central)>=6.0-0.001 and at.distance_to(central)<=8.0+0.001,id+" near "+str(i))
			else:
				check(TreasureRules.edge_distance(s.board,t.pos)>9.0,id+" edge "+str(i))
			for j in range(i):
				check(at.distance_to(_world(s,s.treasures[j]))>6.0 if i>2 else at.distance_to(_world(s,s.treasures[j]))>=6.0-0.001,id+" spacing "+str(i)+"/"+str(j))


func test_special_objective_positions() -> void:
	var museum:=ScenarioLoader.load_id("living_museum",db(),terrain())
	check(museum.treasures[0].central)
	var well:=ScenarioLoader.load_id("dreams_well",db(),terrain())
	check_eq(well.treasures[0].pos.y,well.board.size.y*0.5)
	check_eq(DeploymentRules.choices(well),[0,2])
	var temple:=ScenarioLoader.load_id("complex_temple",db(),terrain())
	check_eq(temple.treasures.size(),6)
	for i in range(6):
		check(temple.treasures[i].frozen)
		check_eq(temple.treasures[i].pos,Vector2(14.0+4.0*(i%3),16.0+4.0*floori(i/3.0)))


func test_deployment_all_core_scenarios() -> void:
	for id in ScenarioBriefing.ENTRIES:
		var s:=ScenarioLoader.load_id(id,db(),terrain())
		var c:=GameController.new(s,Dice.new(19))
		var d:=c.begin_deployment(-1)
		check(d.done,id+" "+d.error)
		for f in s.figures:
			if f.side<0 or not f.in_play() or not d.zones.has(f.side):
				continue
			check(DeploymentRules.zone(s,int(d.zones[f.side]),f.pos),id+" zone "+str(f.id))
			check(DeploymentRules.legal(s,f,DeploymentRules.support(s,f.pos),[]),id+" stand "+str(f.id))
		var exposed:=0
		for a in s.side_figures(0):
			for b in s.side_figures(1):
				if LineOfSight.check_figures(s.board,a,b).clear:
					exposed+=1
		var objective_visible:=0
		for t in s.treasures:
			if not t.central:
				continue
			for f in s.figures:
				if f.side<0:
					continue
				var visible:=LineOfSight.check(s.board,f.pos,t.pos,f).clear if s.board.floor_layout.is_empty() else LineOfSight.floor_point_visible(s.board,s.board.floor_geometry(),f,_world(s,t),INF)
				if visible:
					objective_visible+=1
		print("Setup audit ",id,": ",exposed," visible opposing pairs; ",objective_visible," views of central objective at deployment.")

func test_red_king_deployment_matrix() -> void:
	var profile:=ContentProfile.new(["red_king"])
	var figures:=FigureDb.load_files(FigureDb.FIGURES,FigureDb.WEAPONS,profile)
	for stage: Dictionary in RedKingCampaign.stages():
		var id:=str(stage["id"])
		var s:=ScenarioLoader.load_id(id,figures,terrain())
		var c:=GameController.new(s,Dice.new(19))
		var d:=c.begin_deployment(-1)
		check(d.done,id+" "+d.error)
		for f in s.figures:
			if f.side<0 or not f.in_play() or not d.zones.has(f.side):
				continue
			var wizard:=Vector2.INF
			for other in s.side_figures(f.side):
				if other.def.role=="wizard":
					wizard=other.pos
					break
			check(DeploymentRules.zone(s,int(d.zones[f.side]),f.pos,wizard,f.def.role=="wizard"),id+" zone "+str(f.id))
			check(DeploymentRules.legal(s,f,DeploymentRules.support(s,f.pos),[]),id+" stand "+str(f.id))


func test_standard_scenarios_have_distinct_playable_maps() -> void:
	var ids: Array[String]=[]
	for id in ["treasure_skirmish","worm_hunts","genie_in_the_bottle"]:
		var s:=ScenarioLoader.load_id(id,db(),terrain())
		check(not ids.has(s.board.id),id)
		ids.append(s.board.id)
		for t in s.treasures:
			check(s.board.can_stand(t.pos,TreasureRules.TOKEN_RADIUS),id+" token "+str(t.id))


func test_seeded_standard_treasure_placement() -> void:
	for id in ["treasure_skirmish","sunken_streets","worm_hunts","genie_in_the_bottle","dreams_well","underground_library","silent_tower"]:
		var layouts: Array=[]
		for seed_value in [7,19,41]:
			var s:=ScenarioLoader.load_id(id,db(),terrain())
			var original:=_world(s,s.treasures[0])
			check(StandardTreasurePlacement.prepare(s,Dice.new(seed_value)),id)
			var center:=_world(s,s.treasures[0])
			if s.scenario_special in StandardTreasurePlacement.ANCHORED:
				check_eq(center,original,id+" anchor")
			else:
				check_eq(s.treasures[0].pos,s.board.size*0.5,id+" centre")
			var positions: Array=[]
			for i in 5:
				var t:=s.treasures[i]
				var at:=_world(s,t)
				positions.append(at)
				check(not is_nan(at.y),id)
				if i in [1,2]:
					check(at.distance_to(center)>=6.0 and at.distance_to(center)<=8.0,id+" inner")
				if i>2:
					check(TreasureRules.edge_distance(s.board,t.pos)>9.0,id+" outer")
				for j in range(i):
					var separation:=at.distance_to(_world(s,s.treasures[j]))
					check(separation>6.0 if i>2 else separation>=6.0,id+" separation")
			check(StandardTreasurePlacement.prepare(s,Dice.new(99)),id+" repeat")
			for i in 5:
				check_eq(_world(s,s.treasures[i]),positions[i],id+" unchanged")
			layouts.append(positions)
		check(layouts[0]!=layouts[1] or layouts[1]!=layouts[2],id+" variation")
