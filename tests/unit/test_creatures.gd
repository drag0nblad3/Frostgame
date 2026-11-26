extends TestCase


func test_creatures_activate_by_health() -> void:
	var c := make_game(make_board(), [fig("thug", 0, Vector2(10, 10)), fig("thug", 1, Vector2(20, 20)), fig("giant_rat", -1, Vector2(15, 15)), fig("ghoul", -1, Vector2(16, 15))], LoadedDice.new([12, 4, 11, 5]))
	c.start_game()
	check(c.activate(1))
	c.end_activation()
	check(c.activate(2))
	c.end_activation()
	check_eq(c.state.phase, Phase.CREATURE)
	check_eq(c.activatable()[0].id, 4)
	check(c.activate(4))
	c.end_activation()
	check_eq(c.activatable()[0].id, 3)
	check(c.activate(3))
	c.end_activation()
	check_eq(c.state.turn, 2)


func test_uncontrolled_creatures_are_not_enemies() -> void:
	var a := fig("giant_rat", -1, Vector2(10, 10))
	var b := fig("ghoul", -1, Vector2(11, 10))
	var figs: Array[Figure] = [a, b]
	check(not Contact.in_combat(figs, a))


func test_pack_members_follow_leader_before_other_creatures() -> void:
	var c := make_game(make_board(), [fig("thug", 0, Vector2(3, 3)), fig("thug", 1, Vector2(30, 30)), fig("wolf", -1, Vector2(15, 15)), fig("giant_rat", -1, Vector2(16, 15)), fig("giant_rat", -1, Vector2(17, 15)), fig("ghoul", -1, Vector2(20, 20))], Dice.new(7))
	var s := c.state
	s.phase = Phase.CREATURE
	s.figure(6).health = 2
	check_eq(PackRules.members(s, s.figure(3)).size(), 3)
	check(c.activate(3))
	var leader := s.active()
	check(s.pack_queue.has(leader.id))
	check_eq(s.pack_leader, leader.id)
	check_eq(s.pack_queue.size(), 3)
	PackRules.remember(s, leader, s.figure(1))
	var direction := PackRules.heading(c, leader)
	c.end_activation()
	var follower := c.activatable()[0]
	check(follower.id in [3, 4, 5])
	check_eq(PackRules.pursuit(s, follower), s.figure(1))
	check_eq(PackRules.heading(c, follower), direction)
	check(c.activate(follower.id))
	c.end_activation()
	check(c.activate(c.activatable()[0].id))
	c.end_activation()
	check(s.pack_queue.is_empty())
	check_eq(c.activatable()[0].id, 6)


func test_creature_attacks_lowest_health_not_highest_value() -> void:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(11, 10)), fig("thug", 0, Vector2(9, 10)), fig("ghoul", -1, Vector2(10, 10))], Dice.new(3))
	c.state.figure(1).health = 5
	c.state.figure(2).health = 4
	check_eq(CreatureBot.weakest(c.state, c.state.figure(3)).id, 2)


func test_pack_checkpoint_preserves_remaining_members() -> void:
	var s := ScenarioLoader.load_id("treasure_skirmish", db(), terrain())
	var c := GameController.new(s, Dice.new(9))
	var a := c._encounters._spawn_at("giant_rat", Vector2(0.5, 17))
	var b := c._encounters._spawn_at("giant_rat", Vector2(0.5, 18))
	var third := c._encounters._spawn_at("giant_rat", Vector2(0.5, 19))
	s.phase = Phase.CREATURE
	check(c.activate(a.id))
	var leader := s.active()
	PackRules.remember(s, leader, s.figure(1))
	var direction := PackRules.heading(c, leader)
	c.end_activation()
	var restored := BattleSnapshot.rebuild(BattleSnapshot.capture(c), db())
	check(restored != null)
	check_eq(restored.state.pack_leader, leader.id)
	check_eq(restored.state.pack_queue, s.pack_queue)
	check_eq(restored.state.pack_heading, direction)
	check_eq(restored.state.pack_target, 1)
	var next := restored.activatable()[0]
	check(next.id in [a.id, b.id, third.id] and next.id != leader.id)
