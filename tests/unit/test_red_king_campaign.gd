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
