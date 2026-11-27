extends TestCase


func _story(veil: bool) -> Dictionary:
	var packs := ContentProfile.registered().duplicate(true)
	packs["red_king"]["status"]="ready"
	var campaign := CampaignProgress.new()
	var profile := ContentProfile.new(["red_king"],packs)
	campaign.start({"name":"Story","figures":[{"type":"wizard"}]},profile)
	check(RedKingCampaign.start(campaign.data,profile,veil))
	return campaign.data


func test_optional_paths_and_ragged_transition() -> void:
	var d := _story(false)
	check_eq(RedKingCampaign.next_id(d),"red_king_squatter")
	check(not RedKingCampaign.advance(d,"red_king_hill"))
	check(RedKingCampaign.advance(d,"red_king_squatter"))
	check(RedKingCampaign.advance(d,"red_king_investigations"))
	check_eq(RedKingCampaign.next_id(d),"red_king_back_into_fire")
	check(RedKingCampaign.advance(d,"red_king_back_into_fire"))
	check(RedKingCampaign.advance(d,"red_king_demons_and_mad_man"))
	check_eq(RedKingCampaign.next_id(d),"red_king_herded")
	check(RaggedWarbands.active(d))
	while not RedKingCampaign.next_id(d).is_empty():
		check(RedKingCampaign.advance(d,RedKingCampaign.next_id(d)))
	check_eq(d["red_king_history"].size(),10)


func test_veil_lock_and_ryce_bonus_round() -> void:
	var d := _story(true)
	RedKingCampaign.advance(d,"red_king_squatter")
	check(RedKingCampaign.suppress_base_after(d,"red_king_investigations"))
	RedKingCampaign.advance(d,"red_king_investigations")
	check(RedKingCampaign.economy_locked(d))
	check(not RaggedWarbands.active(d))
	RedKingCampaign.advance(d,"red_king_veil")
	check(not RedKingCampaign.economy_locked(d))
	RedKingCampaign.advance(d,"red_king_back_into_fire")
	d["red_king_secured_kalamon"]=true
	RedKingCampaign.advance(d,"red_king_demons_and_mad_man")
	check_eq(RedKingCampaign.next_id(d),"red_king_mind")
	RedKingCampaign.advance(d,"red_king_mind")
	check_eq(RedKingCampaign.next_id(d),"red_king_herded")
	check(RaggedWarbands.active(d))


func test_mind_rewards_consumption_and_fight_scope() -> void:
	var d := _story(false)
	d["red_king_secret_hrut"]=true
	check(not RedKingMindRewards.secret_selected(d))
	d["red_king_use_secret_hrut"]=true
	check(RedKingMindRewards.secret_selected(d))
	d["red_king_survival_reroll"]=true
	check_eq(RedKingMindRewards.survival_roll(d,19,Dice.new(2)),19)
	check(not d.has("red_king_survival_reroll"))
	d["red_king_survival_reroll"]=true
	check(RedKingMindRewards.survival_roll(d,3,Dice.new(2))>=3)
	check(not d.has("red_king_survival_reroll"))
	var packs := ContentProfile.registered().duplicate(true)
	packs["red_king"]["status"]="ready"
	var defs := FigureDb.load_files(FigureDb.FIGURES,FigureDb.WEAPONS,ContentProfile.new(["red_king"],packs))
	var f := fig("wizard",0,Vector2(10,10))
	var hrut := Figure.new(2,defs.get_def("hrut_warrior"),-1,Vector2(11,10),defs.unarmed())
	var rival := fig("thug",1,Vector2(9,10))
	var c := make_game(make_board(),[f,hrut,rival],Dice.new(3))
	check_eq(Melee.secret_hrut_bonus(f,hrut),0)
	c.state.scenario_data["secret_hrut_0"]=true
	check_eq(Melee.secret_hrut_bonus(f,hrut),1)
	check_eq(Melee.secret_hrut_bonus(f,rival),0)
	check_eq(Melee.secret_hrut_bonus(rival,hrut),0)


func test_ragged_recovered_members_and_replacement_wizard() -> void:
	var d := _story(false)
	while RedKingCampaign.next_id(d)!="red_king_herded":
		RedKingCampaign.advance(d,RedKingCampaign.next_id(d))
	for i in 11:
		d["units"].append({"id":i+1,"type":"thug","miss":0,"dead":false,"injuries":0})
	check_eq(RaggedWarbands.deployed_ids(d).size(),10)
	check(RaggedWarbands.deployed_ids(d).has(0))
	d["units"][0]["dead"]=true
	var draft := WarbandDraft.new(db())
	draft.choose_defaults()
	check(CampaignSuccession.replace_ragged(d,draft.as_warband()))
	check_eq(RedKingCampaign.next_id(d),"red_king_herded")
	check_eq(d["units"].size(),1)
	check(d["ragged_no_apprentice"])
	check_eq(RaggedWarbands.fill(d,db(),Dice.new(24)),9)
	check_eq(RaggedWarbands.deployed_ids(d).size(),10)


func test_optional_mindscape_skip_and_saved_story_cursor() -> void:
	var d := _story(false)
	check(not RedKingCampaign.skip_mind(d))
	while RedKingCampaign.next_id(d)!="red_king_demons_and_mad_man":
		check(RedKingCampaign.advance(d,RedKingCampaign.next_id(d)))
	d["red_king_secured_kalamon"]=true
	check(RedKingCampaign.advance(d,"red_king_demons_and_mad_man"))
	d["pending_treasure"]=[{"token":0}]
	check(not RedKingCampaign.skip_mind(d))
	d["pending_treasure"]=[]
	check(RedKingCampaign.skip_mind(d))
	check(not d["red_king_history"].has("red_king_mind"))
	check(d["red_king_mind_skipped"])
	check(not d["red_king_secured_kalamon"])
	check_eq(RedKingCampaign.next_id(d),"red_king_herded")
	check(RaggedWarbands.active(d))
	var progress := CampaignProgress.new()
	progress.data=d
	var path := "user://red_king_story_cursor_test.json"
	check(progress.save(path))
	var restored := CampaignProgress.new()
	check(restored.load_save(path))
	check_eq(RedKingCampaign.next_id(restored.data),"red_king_herded")
	check(RaggedWarbands.active(restored.data))
	check(not RedKingCampaign.skip_mind(restored.data))
	DirAccess.remove_absolute(path)


## Exercise the installed pack, actual scenario loading, settlement and JSON
## round-trips through every chapter. Battle outcomes are scripted here;
## the scenario simulation workflow separately exercises tactical play.
func test_story_campaign_lifecycle_with_real_scenarios() -> void:
	var profile := ContentProfile.new(["red_king"])
	var defs := FigureDb.load_files(FigureDb.FIGURES,FigureDb.WEAPONS,profile)
	var draft := WarbandDraft.new(defs)
	draft.choose_defaults()
	var roster := draft.as_warband()
	roster["figures"]=[{"type":"wizard"},{"type":"apprentice"}]
	for i in 8:
		roster["figures"].append({"type":"thug"})
	var p := CampaignProgress.new()
	p.start(roster,profile)
	check(RedKingCampaign.start(p.data,profile,true))
	var path := "user://red_king_lifecycle_test.json"
	for stage: Dictionary in RedKingCampaign.stages():
		var id := str(stage["id"])
		check_eq(RedKingCampaign.next_id(p.data),id)
		check(p.can_deploy(),id+": "+"; ".join(p.deployment_blockers()))
		var source: Dictionary = JsonFile.read(ScenarioLoader.DIR+id+".json")
		source["warbands"][0]=p.deployment()
		var s := ScenarioLoader.from_dict(source,defs,terrain())
		check(not s.scenario_data.has("deployment_error"),id)
		var c := GameController.new(s,Dice.new(47))
		s.over=true
		if id=="red_king_squatter" or id=="red_king_back_into_fire":
			for token in s.treasures:
				if token.central:
					token.secured_by=0
					break
		if id=="red_king_demons_and_mad_man":
			check(s.scenario_data.get("reduced_hunters_0",false))
			var rescue := s.treasure(int(s.scenario_data["ryce_token"]))
			rescue.lost=false
			rescue.secured_by=0
		if id=="red_king_mind":
			check_eq(s.side_figures(0).size(),1)
			s.scenario_data["mind_rewards"]=["8","7"]
		if id=="red_king_herded":
			check(RaggedWarbands.active(p.data))
			check(s.scenario_data.get("secret_hrut_0",false))
		if id=="red_king_ringworld":
			s.scenario_data["ring_success"]=true
		check(p.settle(c,LoadedDice.new([1])),id+" settlement")
		if id=="red_king_squatter" or id=="red_king_back_into_fire":
			check(not p.can_deploy())
			check(p.resolve_treasure(false,Dice.new(1)))
		if id=="red_king_mind":
			check(p.data.get("red_king_secret_hrut",false))
			p.data["red_king_use_secret_hrut"]=true
		if id=="red_king_herded":
			check(not p.data.has("red_king_secret_hrut"))
		check(p.save(path),id+" save")
		var restored := CampaignProgress.new()
		check(restored.load_save(path),id+" reload")
		p=restored
	check_eq(p.data["red_king_history"].size(),12)
	check_eq(p.data["games"],11)
	check(p.data.get("red_king_completed",false))
	check(RedKingCampaign.reconcile(p.data,defs))
	check(not RaggedWarbands.active(p.data))
	check(RedKingCampaign.return_to_skirmishes(p.data,defs))
	check(p.can_deploy())
	check(ContentProfile.from_campaign(p.data).enabled.has("red_king"))
	DirAccess.remove_absolute(path)


func test_pursuit_intermission_releases_base_and_preserves_legal_roster() -> void:
	var profile := ContentProfile.new(["red_king"])
	var defs := FigureDb.load_files(FigureDb.FIGURES,FigureDb.WEAPONS,profile)
	var p := CampaignProgress.new()
	var roster := {"name":"Pursuit","figures":[{"type":"wizard"},{"type":"apprentice"}]}
	for i in 9:
		roster["figures"].append({"type":"thug"})
	roster["figures"].append({"type":"war_hound"})
	p.start(roster,profile)
	check(RedKingCampaign.start(p.data,profile,true,true))
	p.data["base"]="inn"
	p.data["resources"]=["kennel","carrier_pigeons"]
	p.data["gold"]=1000
	check(RedKingCampaign.advance(p.data,"red_king_squatter"))
	check(RedKingCampaign.suppress_base_after(p.data,"red_king_investigations"))
	check(RedKingCampaign.advance(p.data,"red_king_investigations"))
	check(RedKingCampaign.temporary_lock(p.data))
	check(not BaseResources.owns(p.data,"kennel"))
	check(not p.can_hire("thug",defs))
	check(not p.dismiss(2))
	check(p.can_deploy())
	check_eq(p.deployment()["figures"].size(),11)
	check(not RedKingCampaign.suppress_base_after(p.data,"red_king_veil"))
	check(RedKingCampaign.advance(p.data,"red_king_veil"))
	check(not RedKingCampaign.economy_locked(p.data))
	check(BaseResources.owns(p.data,"kennel"))
	check(RedKingCampaign.suppress_base_after(p.data,"red_king_back_into_fire"))
	check(RedKingCampaign.advance(p.data,"red_king_back_into_fire"))
	check(RedKingCampaign.temporary_lock(p.data))
	check(p.can_deploy())
	check(not RedKingCampaign.suppress_base_after(p.data,"red_king_demons_and_mad_man"))
	check(RedKingCampaign.advance(p.data,"red_king_demons_and_mad_man"))
	check(RaggedWarbands.active(p.data))
	check(RedKingCampaign.suppress_base_after(p.data,"red_king_herded"))
	var normal := _story(false)
	check(RedKingCampaign.advance(normal,"red_king_squatter"))
	check(RedKingCampaign.advance(normal,"red_king_investigations"))
	check(not RedKingCampaign.suppress_base_after(normal,"red_king_back_into_fire"))
	check(RedKingCampaign.advance(normal,"red_king_back_into_fire"))
	check(not RedKingCampaign.economy_locked(normal))
