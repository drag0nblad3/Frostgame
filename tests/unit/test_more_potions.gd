extends TestCase


func test_absorption_and_invulnerability() -> void:
	var c := make_game(make_board(), [fig("thug", 0, Vector2(10, 10)), fig("thug", 1, Vector2(11, 10))], Dice.new(1))
	var t := c.state.figure(2)
	t.spell_effects["potion_elemental_absorption"] = 5
	check_eq(PotionActions.absorb(t, 3), 0)
	check_eq(PotionActions.absorb(t, 4), 2)
	check(not t.spell_effects.has("potion_elemental_absorption"))
	t.spell_effects["potion_invulnerability"] = true
	var a := c.state.figure(1)
	check_eq(Melee.resolve(LoadedDice.new([18, 1]), c.state.figures, a, t)["b_dmg"], 0)
	a.spell_effects["potion_fairy_dust"] = a.melee.id
	check(Melee.resolve(LoadedDice.new([18, 1]), c.state.figures, a, t)["b_dmg"] > 0)


func test_poison_and_darkness() -> void:
	var c := make_game(make_board(), [fig("thug", 0, Vector2(10, 10)), fig("thug", 1, Vector2(24, 10))], Dice.new(1))
	c.state.active_id = 1
	var f := c.state.active()
	f.actions_left = 2
	f.items.append({"potion": "poison"})
	f.items.append({"potion": "darkness"})
	check(c._potions.coat("poison", false))
	check_eq(f.poison_weapon, f.melee.id)
	c._weapon_damage(c.state.figure(2), 1, f, f.melee)
	check(c.state.figure(2).poisoned)
	check_eq(f.poison_weapon, "")
	check(c._potions.drink("darkness"))
	check(not LineOfSight.check(c.state.board, f.pos, c.state.figure(2).pos).clear)
