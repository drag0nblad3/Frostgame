extends TestCase


func _fixture() -> GameController:
	var packs := ContentProfile.registered().duplicate(true)
	packs["red_king"]["status"]="ready"
	var defs := FigureDb.load_files(FigureDb.FIGURES,FigureDb.WEAPONS,ContentProfile.new(["red_king"],packs))
	var s := ScenarioLoader.load_id("red_king_mind",defs,terrain())
	var c := GameController.new(s,Dice.new(38))
	RedKingMind.prepare(c)
	return c


func test_solo_actions_and_memories() -> void:
	var c := _fixture()
	var s := c.state
	check_eq(s.board.size,Vector2(24,24))
	check_eq(s.side_figures(0).size(),1)
	check_eq(s.side_figures(-1).size(),3)
	check_eq(s.treasures.size(),8)
	var f := RedKingMind.wizard(s)
	f.actions_left=2
	s.active_id=f.id
	RedKingMind.activation(c,f)
	check_eq(f.actions_left,3)
	check(c.can_move())
	f.moves_taken=1
	check(not c.can_move())
	f.acted=true
	f.non_moves=1
	check(c.can_act())
	f.non_moves=2
	check(not c.can_act())
	var token := s.treasures[0]
	RedKingMind.collect(c,f,token.pos-Vector2.RIGHT,token.pos+Vector2.RIGHT)
	check_eq(token.secured_by,0)
	check_eq(f.treasure_id,-1)
	check(not c.can_pick_up(s.treasures[1].id))


func test_deck_checkpoint_and_reward_draw() -> void:
	var c := _fixture()
	var s := c.state
	check_eq(s.scenario_data["mind_deck"]["remaining"].size(),10)
	RedKingMind.end_turn(c)
	check_eq(s.scenario_data["mind_deck"]["remaining"].size(),9)
	var saved := BattleSnapshot.capture(c)
	check(not saved.is_empty())
	var restored := BattleSnapshot.rebuild(saved,s.creature_db)
	check(restored!=null)
	if restored!=null:
		check_eq(restored.state.scenario_data,s.scenario_data)
	c._loot.secure(s.treasures[0],0)
	c._loot.secure(s.treasures[1],0)
	RedKingMind.finish(c)
	check_eq(s.scenario_data["mind_rewards"].size(),2)
	check(s.scenario_data["mind_rewards"][0]!=s.scenario_data["mind_rewards"][1])
	s.turn=8
	c._flow.start_turn()
	check(s.over)
	check_eq(s.turn,8)


func test_bonus_round_no_injury_or_normal_rewards() -> void:
	var c := _fixture()
	c.state.over=true
	c.state.scenario_data["mind_rewards"]=["A","Q","8","7","6","5"]
	var data := {"red_king_secured_kalamon":true,"xp":100,"gold":50,"games":5,"units":[{"dead":false}]}
	check(RedKingMindRewards.settle(data,c,0))
	check_eq(data["xp"],125)
	check_eq(data["gold"],50)
	check_eq(data["games"],5)
	check(not data["units"][0]["dead"])
	check(data["red_king_secret_hrut"])
	check(data["red_king_survival_reroll"])
	check(not data.has("red_king_pending_rewards"))
	check_eq(data["loot"].size(),2)
	check(RedKingRewards.catalog()[data["loot"][1]["gear"]]["artefact"])
	check(not RedKingMindRewards.settle(data,c,0))
