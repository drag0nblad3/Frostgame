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
	var b := make_board([["wall", 10, 3, 0.5, 30]])
	var field := MovePlanner.distance_field(b, Vector2(9.5, 18))
	check(float(field.get(MovePlanner.node_at(Vector2(11, 18)), INF)) > 20.0)
