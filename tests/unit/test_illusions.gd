extends TestCase


func test_invisible_target_and_reveal() -> void:
	var c := make_game(make_board(), [fig("archer", 0, Vector2(10, 10)), fig("thug", 1, Vector2(14, 10)), fig("wizard", 0, Vector2(11, 10))], Dice.new(1))
	var target := c.state.figure(2)
	target.spell_effects["invisibility"] = true
	check(not IllusionRules.visible_to(c.state.figures, c.state.figure(1), target))
	check_eq(Shooting.blocked_reason(c.state.board, c.state.figures, c.state.figure(1), target), "not a target")
	c.state.figure(3).spell_effects["true_sight"] = true
	c._magic.illusions.sweep()
	check(not target.spell_effects.has("invisibility"))


func test_illusion_cannot_damage_or_collect() -> void:
	var c := make_game(make_board(), [fig("thug", 0, Vector2(10, 10)), fig("thug", 1, Vector2(11, 10))], Dice.new(1))
	var phantom := c.state.figure(1)
	phantom.summon_spell = "illusionary_soldier"
	var target := c.state.figure(2)
	c._hurt(target, 5, phantom)
	check_eq(target.health, 10)
	var token := TreasureToken.new(0, Vector2(10, 10))
	check(not TreasureRules.can_pick_up(c.state, phantom, token))
	c._hurt(phantom, 1, target)
	check(not phantom.in_play())


func test_illusion_staff_allows_second_and_penalizes_will() -> void:
	var f := fig("wizard",0,Vector2(10,10))
	var c := make_game(make_board(),[f],Dice.new(1))
	c.state.creature_db=db()
	f.items.append({"gear":SummonActions.ILLUSION_STAFF,"gear_info":RedKingRewards.catalog()[SummonActions.ILLUSION_STAFF]})
	var base := f.effective_will()
	c._magic.summons.spawn(f,"illusionary_soldier",Vector2(11.5,10),15,8)
	check(c._magic.summons.can_place(f,"illusionary_soldier",Vector2(8.5,10)))
	c._magic.summons.spawn(f,"illusionary_soldier",Vector2(8.5,10),15,8)
	check_eq(f.effective_will(),base-2)
	check(not c._magic.summons.can_place(f,"illusionary_soldier",Vector2(10,12)))
	c._hurt(f,f.health,f,false)
	check_eq(SummonActions.count_summoned(c.state,f,"illusionary_soldier",true),1)
