extends TestCase


func test_magic_ai_heals_wounded_carrier() -> void:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("thug", 0, Vector2(12, 10)), fig("thug", 1, Vector2(18, 18))], LoadedDice.new([18]))
	c.state.spell_catalog = JsonFile.read("res://data/spells.json")
	c.state.spellbooks[0] = {"heal": 8, "bone_dart": 10}
	c.state.active_id = 1
	var f := c.state.active()
	f.actions_left = 2
	var ally := c.state.figure(2)
	ally.health = 2
	ally.treasure_id = 0
	var chosen := MagicBot.plan(c, f)
	check_eq(chosen.get("spell"), "heal")
	check_eq(chosen.get("target"), ally.id)
	check(MagicBot.play(c, f))
	check(ally.health > 2)


func test_exit_field_respects_library_doors() -> void:
	var s := ScenarioLoader.load_id("underground_library", db(), terrain())
	var field := MovePlanner.exit_field(s)
	check_eq(field.get(MovePlanner.node_at(Vector2(18, 0.5))), 0.0)
	check(float(field.get(MovePlanner.node_at(Vector2(8, 0.5)), INF)) > 0.0)


func test_bot_avoids_treasure_guarded_by_immune_creature() -> void:
	var c := make_game(make_board(), [fig("thug", 0, Vector2(10, 10)), fig("thug", 1, Vector2(30, 30)), fig("wraith", -1, Vector2(14, 10))], Dice.new(4))
	var s := c.state
	s.treasures.append(TreasureToken.new(0, Vector2(13, 10)))
	s.treasures.append(TreasureToken.new(1, Vector2(10, 18)))
	check_eq(TreasureBot._nearest(c, s.figure(1)).id, 1)
	check(not BotTargets.can_harm(s.figure(1), s.figure(3), s.figure(1).melee))


func test_distance_field_does_not_shortcut_a_wall() -> void:
	var b := make_board([["hut_wall", 10, 3, 0.5, 30]])
	var field := MovePlanner.distance_field(b, Vector2(9, 18))
	check(float(field.get(MovePlanner.node_at(Vector2(11, 18)), INF)) > 20.0)


func test_leap_ai_repositions_carrier_and_exhausts_it() -> void:
	var b:=make_board()
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,36,36],"level":0}]}
	var f:=fig("wizard",0,Vector2(8,16))
	var t:=fig("thug",0,Vector2(8,10),2)
	var enemy:=fig("thug",1,Vector2(11,10),3)
	for figure in [f,t,enemy]:
		figure.surface_id="street"
	var c:=make_game(b,[f,t,enemy],LoadedDice.new([20]))
	c.state.spell_catalog=JsonFile.read("res://data/spells.json")
	c.state.spellbooks[0]={"leap":8}
	c.state.active_id=f.id
	f.actions_left=2
	t.treasure_id=0
	t.activated=true
	var before:=TreasureRules.edge_distance(b,t.pos)
	var choice:=MagicBot.leap_plan(c,f)
	check_eq(choice.get("spell"),"leap")
	check_eq(choice.get("target"),t.id)
	check_eq(choice,MagicBot.leap_plan(c,f))
	check_eq(t.pos,Vector2(8,10))
	if choice.is_empty():
		return
	check(MagicBot.play(c,f))
	check(TreasureRules.edge_distance(b,t.pos)<before)
	check(t.magic_exhausted)
	check_eq(t.actions_left,0)
	check_eq(f.actions_left,1)


func test_leap_ai_skips_unthreatened_non_carriers() -> void:
	var b:=make_board()
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,36,36],"level":0}]}
	var f:=fig("wizard",0,Vector2(10,10))
	f.surface_id="street"
	var c:=make_game(b,[f],Dice.new(19))
	c.state.spell_catalog=JsonFile.read("res://data/spells.json")
	c.state.spellbooks[0]={"leap":8}
	c.state.active_id=f.id
	f.actions_left=2
	check(MagicBot.leap_plan(c,f).is_empty())


func test_leap_escape_estimate_respects_library_doors_and_floor() -> void:
	var b:=make_board()
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,36,36],"level":0},{"id":"roof","rect":[0,0,36,36],"level":4}]}
	var f:=fig("wizard",0,Vector2(4,8))
	f.surface_id="street"
	var c:=make_game(b,[f],Dice.new(19))
	c.state.scenario_special="underground_library"
	var exits:=MagicBot._leap_exit_segments(c.state,b.floor_geometry(),f.side)
	check(not exits.is_empty())
	var wall:=MagicBot._leap_exit_distance(exits,Vector3(0.5,0,8))
	var doorway:=MagicBot._leap_exit_distance(exits,Vector3(0.5,0,18))
	check(wall>5.0)
	check(doorway<0.01)
	check(MagicBot._leap_exit_distance(exits,Vector3(0.5,4,18))>=4.0)
	for segment in exits:
		for point in segment:
			check_eq(point.y,0.0)
			check(ScenarioObjectives.exit_allowed(c.state,Vector2(point.x,point.z),f.side))
