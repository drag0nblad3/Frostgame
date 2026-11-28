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


func test_pursuit_does_not_take_second_move() -> void:
	var c:=make_game(make_board(),[fig("thug",0,Vector2(22,10)),fig("ghoul",-1,Vector2(5,10))],Dice.new(3))
	c.state.phase=Phase.CREATURE
	check(c.activate(2))
	var f:=c.state.figure(2)
	var start:=f.pos
	CreatureBot.play(c,f)
	check(f.pos.distance_to(start)>0.0)
	check_eq(f.actions_left,1)


func test_layered_random_movement_stops_at_wall() -> void:
	var b:=make_board()
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,36,36],"level":0}],"solids":[[8,0,9,0.5,3,2]]}
	var f:=fig("ghoul",-1,Vector2(6,10))
	f.surface_id="street"
	var c:=make_game(b,[f],Dice.new(3))
	c.state.active_id=f.id
	f.actions_left=2
	var layout:=b.floor_geometry()
	var reach:=c.layered_reach()
	var far:=layout.node("street",Vector2(9,10))
	check(reach.can_reach(far),"a detour around the wall exists")
	var dest: Variant=LayeredBattleBot.wander_destination(c,f,layout,reach,Vector2.RIGHT)
	check_eq(dest,layout.node("street",Vector2(7.5,10)))
	check_eq(f.pos,Vector2(6,10))
	if dest!=null:
		check(c.move_on_floor(dest))
		check_eq(f.pos,Vector2(7.5,10))


func test_layered_random_movement_stops_at_ledge() -> void:
	var b:=make_board()
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,36,36],"level":0},{"id":"deck","rect":[4,4,4,4],"level":2}]}
	var f:=fig("ghoul",-1,Vector2(6,6))
	f.surface_id="deck"
	f.elevation=2.0
	var c:=make_game(b,[f],Dice.new(3))
	c.state.active_id=f.id
	f.actions_left=2
	var layout:=b.floor_geometry()
	check_eq(LayeredBattleBot.wander_destination(c,f,layout,c.layered_reach(),Vector2.RIGHT),layout.node("deck",Vector2(7.5,6)))


func test_flat_random_movement_stops_at_wall() -> void:
	var b:=make_board([["hut_wall",8,9,0.5,2]])
	var f:=fig("ghoul",-1,Vector2(6,10))
	var c:=make_game(b,[f],Dice.new(3))
	c.state.active_id=f.id
	f.actions_left=2
	var r:=c.reach()
	check(r.can_reach(MovePlanner.node_at(Vector2(9,10))))
	var n: Variant=CreatureBot.wander_destination(c,f,r,Vector2.RIGHT)
	check(n!=null)
	if n!=null:
		check(MoveGrid.to_pos(n).x<=7.5)
		check_eq(MoveGrid.to_pos(n).y,10.0)
