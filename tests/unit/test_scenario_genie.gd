extends TestCase


func test_genie_fifth_pickup_and_single_lamp() -> void:
	var s := ScenarioLoader.load_id("genie_in_the_bottle", db(), terrain())
	var c := GameController.new(s, LoadedDice.new([1, 1, 1, 1]))
	var f := s.figure(1)
	f.pos = Vector2(18, 18)
	for token in s.treasures:
		check(not token.central)
		token.ever_collected = true
		ScenarioGenie.first_pickup(c, f, token)
	check_eq(s.lamp_token, s.treasures.size() - 1)
	var genie := s.figure(s.genie_id)
	check(genie != null)
	check_eq(genie.def.health, 14)
	check_eq(genie.def.shoot, 3)
	check(genie.def.traits.has("immune_normal"))
	var count := s.figures.size()
	ScenarioGenie.first_pickup(c, f, s.treasure(0))
	check_eq(s.figures.size(), count)
	check_eq(c.history.back().data["xp"], 30)


func test_genie_kills_and_escape() -> void:
	var s := ScenarioLoader.load_id("genie_in_the_bottle", db(), terrain())
	var c := GameController.new(s, LoadedDice.new([20]))
	var f := s.figure(1)
	f.pos = Vector2(18, 18)
	s.treasure(0).ever_collected = true
	ScenarioGenie.first_pickup(c, f, s.treasure(0))
	var genie := s.figure(s.genie_id)
	for i in [2, 3, 4]:
		c._hurt(s.figure(i), 100, genie)
	check_eq(s.genie_kills, 3)
	genie.pos = Vector2(0.5, 18)
	genie.actions_left = 2
	s.active_id = genie.id
	check(ScenarioGenie.flee(c, genie))
	check(genie.exited)
	var restored := BattleSnapshot.rebuild(BattleSnapshot.capture(c), db())
	check_eq(restored.state.genie_kills, 3)
	check_eq(restored.state.lamp_token, 0)


func test_genie_spawn_distance_and_closest() -> void:
	var s:=ScenarioLoader.load_id("genie_in_the_bottle",db(),terrain())
	var c:=GameController.new(s,LoadedDice.new([20]))
	var finder:=s.figure(1)
	finder.pos=Vector2(18,18)
	finder.elevation=s.board.height_at(finder.pos)
	s.treasure(0).ever_collected=true
	ScenarioGenie.first_pickup(c,finder,s.treasure(0))
	var genie:=s.figure(s.genie_id)
	check(genie!=null)
	if genie==null:
		return
	var at:=Vector3(genie.pos.x,genie.elevation,genie.pos.y)
	var d:=at.distance_to(Vector3(finder.pos.x,finder.elevation,finder.pos.y))
	check(d<=2.0)
	for other in s.figures:
		if other!=finder and other!=genie and other.in_play():
			check(at.distance_to(Vector3(other.pos.x,other.elevation,other.pos.y))>d)


func test_player_selects_genie_spawn() -> void:
	var s:=ScenarioLoader.load_id("genie_in_the_bottle",db(),terrain())
	var c:=GameController.new(s,LoadedDice.new([20]))
	s.reaction_side=0
	var f:=s.figure(1)
	f.pos=Vector2(18,18)
	f.elevation=s.board.height_at(f.pos)
	s.treasure(0).ever_collected=true
	ScenarioGenie.first_pickup(c,f,s.treasure(0))
	check(c.awaiting_reaction())
	var d:=CoreScenarioChoice.pending(c)
	check_eq(d.get("kind",""),"genie")
	check(not BattleScenarioAction.execute(c,"core_choice",{"index":-1}))
	if not d.is_empty():
		var chosen: Vector3=d["options"][0]["world"]
		check(BattleScenarioAction.execute(c,"core_choice",{"index":0}))
		var genie:=s.figure(s.genie_id)
		check(genie!=null)
		if genie!=null:
			check_eq(Vector3(genie.pos.x,genie.elevation,genie.pos.y),chosen)
		check(not c.awaiting_reaction())
