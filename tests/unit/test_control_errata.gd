extends TestCase


func test_reclaim_permanent_member() -> void:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("wizard", 1, Vector2(20, 10)), fig("thug", 0, Vector2(14, 10))], LoadedDice.new([1, 1]))
	var t := c.state.figure(3)
	var enemy := c.state.figure(2)
	var ally := c.state.figure(1)
	c._magic.summons.apply_control(enemy, t, "mind_control", 18)
	check_eq(t.side, 1)
	check(c._magic.summons.can_control(ally, t, "mind_control"))
	c._magic.summons.apply_control(ally, t, "mind_control", 18)
	check_eq(t.side, 0)
	check_eq(t.controller_id, -1)


func test_controlled_summon_loses_origin() -> void:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("wizard", 1, Vector2(20, 10)), fig("zombie", 0, Vector2(14, 10))], LoadedDice.new([1]))
	var t := c.state.figure(3)
	t.summoned_by = 1
	t.summon_spell = "raise_zombie"
	c._magic.summons.apply_control(c.state.figure(2), t, "control_undead", 18)
	check_eq(t.side, 1)
	check_eq(t.summoned_by, -1)
	c._magic.summons.release(t)
	check_eq(t.side, -1)
