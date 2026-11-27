extends TestCase


func test_melee_reroll_before_damage() -> void:
	var a := fig("thug", 0, Vector2(10, 10), 1)
	var b := fig("thug", 1, Vector2(11, 10), 2)
	a.items.append({"gear": "gear_fate_stone"})
	var c := make_game(make_board(), [a, b], LoadedDice.new([2, 12, 18]))
	c.state.reaction_side = 0
	c.state.active_id = 1
	a.actions_left = 2
	check(c.fight(2))
	check(c.awaiting_reaction())
	check_eq(a.health, 10)
	check_eq(b.health, 10)
	check(not c.can_end_activation())
	check(c.answer_fate_combat(true))
	check_eq(a.health, 10)
	check(not b.in_play())
	check(not ActiveGear.ready(a, "gear_fate_stone"))
	check(c.state.pending_combat.is_empty())


func test_defender_can_keep_shooting_roll() -> void:
	var a := fig("archer", 0, Vector2(10, 10), 1)
	var b := fig("thug", 1, Vector2(14, 10), 2)
	b.items.append({"gear": "gear_fate_stone"})
	var c := make_game(make_board(), [a, b], LoadedDice.new([10, 20]))
	c.state.reaction_side = 1
	c.state.active_id = 1
	a.actions_left = 2
	check(c.shoot(2))
	check(c.awaiting_reaction())
	check(c.answer_fate_combat(false))
	check_eq(b.health, 10)
	check(ActiveGear.ready(b, "gear_fate_stone"))
	check(c.state.pending_combat.is_empty())


func test_elemental_weapon_reaction_after_roll() -> void:
	var a := fig("thug",0,Vector2(10,10),1)
	var b := fig("thug",1,Vector2(11,10),2)
	a.spell_effects["elemental_hammer"]=true
	b.items.append({"gear":RedKingElemental.AMULET})
	var c := make_game(make_board(),[a,b],LoadedDice.new([10,2,4]))
	c.state.reaction_side=1
	c.state.active_id=1
	a.actions_left=2
	check(c.fight(2))
	check(c.state.pending_combat.has("absorb_target"))
	check_eq(b.health,10)
	check(not c.answer_fate_combat(false))
	check(c.answer_elemental_combat(true))
	check(not ActiveGear.ready(b,RedKingElemental.AMULET))
	check(c.state.pending_combat.is_empty())
	check(b.health>0)


func test_elemental_weapon_decline_retains_amulet() -> void:
	var a := fig("thug",0,Vector2(10,10),1)
	var b := fig("thug",1,Vector2(11,10),2)
	a.spell_effects["elemental_hammer"]=true
	b.items.append({"gear":RedKingElemental.AMULET})
	var c := make_game(make_board(),[a,b],LoadedDice.new([10,2]))
	c.state.reaction_side=1
	c.state.active_id=1
	a.actions_left=2
	check(c.fight(2))
	check(c.answer_elemental_combat(false))
	check(ActiveGear.ready(b,RedKingElemental.AMULET))
	check(b.health<10)
