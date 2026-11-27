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
