extends TestCase


func test_two_treasures_and_cancel() -> void:
	var c := make_game(make_board(), [fig("thug", 0, Vector2(10, 10)), fig("thug", 1, Vector2(25, 25))], Dice.new(1))
	var f := c.state.figure(1)
	c.state.active_id = f.id
	f.actions_left = 2
	var a := TreasureToken.new(0, f.pos)
	var b := TreasureToken.new(1, f.pos)
	c.state.treasures.assign([a, b])
	f.treasure_id = a.id
	a.carrier_id = f.id
	f.items.append({"potion": "shrinking"})
	check(c._potions.drink("shrinking"))
	check_eq(MoveRules.allowance(f), 6.0)
	check(c.pick_up(b.id))
	check_eq(f.carried_treasures().size(), 2)
	check_eq(MoveRules.allowance(f), 3.0)
	c._loot.cancel_shrinking(f)
	check_eq(f.treasure_id, a.id)
	check_eq(f.second_treasure_id, -1)
	check(b.on_ground())
	check_eq(MoveRules.allowance(f), 3.0)
	c._loot.drop_on_death(f)
	check(a.on_ground())
	check_eq(f.treasure_id, -1)
