extends TestCase


func _game(rolls: Array, role: String = "wizard") -> GameController:
	var c := make_game(make_board(), [fig(role, 0, Vector2(10, 10)), fig("thug", 0, Vector2(12, 10)), fig("thug", 1, Vector2(20, 10))], LoadedDice.new(rolls))
	c.state.spell_catalog = JsonFile.read("res://data/spells.json")
	c.state.spellbooks[0] = {"heal": 8, "strength": 10, "elemental_bolt": 12, "elemental_shield": 10}
	c.state.active_id = 1
	c.state.active().actions_left = 2
	return c


func test_empower_heal() -> void:
	var c := _game([6])
	c.state.figure(2).health = 4
	check(c.start_cast("heal", 2))
	check(not c.can_move())
	check(c.finish_cast(2))
	check_eq(c.state.figure(1).health, 12)
	check_eq(c.state.figure(2).health, 9)
	check(not c.can_cast("strength", 2))


func test_failure_damage() -> void:
	var c := _game([3], "apprentice")
	check(c.start_cast("strength", 2))
	check(c.finish_cast(0))
	check_eq(c.state.figure(1).health, 11)
	check(not c.state.figure(2).spell_effects.has("strength"))


func test_buff_and_shield() -> void:
	var c := _game([14, 14])
	check(c.start_cast("strength", 2))
	check(c.finish_cast(0))
	check_eq(c.state.figure(2).effective_fight(), 4)
	c.state.active().acted = false
	check(c.start_cast("elemental_shield", 1))
	check(c.finish_cast(0))
	c._hurt(c.state.figure(1), 5, c.state.figure(3))
	check_eq(c.state.figure(1).health, 12)
	check_eq(c.state.figure(1).elemental_shield, 0)


func test_elemental_bolt_reaction() -> void:
	var c := _game([18,20,2,4])
	var t := c.state.figure(3)
	t.items.append({"gear":RedKingElemental.AMULET})
	c.state.reaction_side=1
	check(c.start_cast("elemental_bolt",3))
	check(c.finish_cast(0))
	check(c.awaiting_reaction())
	check_eq(t.health,10)
	check(not c.can_end_activation())
	check(c.answer_elemental_combat(true))
	check_eq(t.health,10)
	check(not ActiveGear.ready(t,RedKingElemental.AMULET))
	check(not c.awaiting_reaction())


func test_elemental_ball_resumes_remaining_targets() -> void:
	var c := _game([18,20,2,4,20,2])
	var t := c.state.figure(3)
	t.items.append({"gear":RedKingElemental.AMULET})
	var ally := fig("thug",1,Vector2(21,10),4)
	c.state.figures.append(ally)
	ally.battle_ref=weakref(c.state)
	c.state.spellbooks[0]["elemental_ball"]=10
	c.state.reaction_side=1
	check(c.start_cast("elemental_ball",3))
	check(c.finish_cast(0))
	check(c.awaiting_reaction())
	check_eq(ally.health,10)
	check(c.answer_elemental_combat(true))
	check_eq(t.health,10)
	check(ally.health<10)
	check(not c.state.scenario_data.has("rk_ball_queue"))
	check(not c.awaiting_reaction())
