extends TestCase


func _pair(a: String, b: String) -> Array[Figure]:
	var figs: Array[Figure] = [fig(a, 0, Vector2(10, 10), 1), fig(b, 1, Vector2(11, 10), 2)]
	return figs


func test_winner_deals_total_minus_armour() -> void:
	var figs := _pair("knight", "thug")
	var r := Melee.resolve(LoadedDice.new([15, 10]), figs, figs[0], figs[1])
	check_eq(r["a_total"], 19, "knight 15 + Fight 4")
	check_eq(r["b_total"], 12, "thug 10 + Fight 2")
	check_eq(r["b_dmg"], 9, "19 - Armour 10")
	check_eq(r["a_dmg"], 0, "loser deals nothing")


func test_two_handed_adds_damage() -> void:
	var figs := _pair("barbarian", "thug")
	var r := Melee.resolve(LoadedDice.new([10, 5]), figs, figs[0], figs[1])
	check_eq(r["b_dmg"], 14 + 2 - 10, "+2 two-handed")


func test_tie_hurts_both() -> void:
	var figs := _pair("thug", "thug")
	var r := Melee.resolve(LoadedDice.new([12, 12]), figs, figs[0], figs[1])
	check_eq(r["a_dmg"], 4, "14 - 10")
	check_eq(r["b_dmg"], 4, "14 - 10")


func test_critical_is_optional() -> void:
	var figs := _pair("thug", "thug")
	var normal := Melee.resolve(LoadedDice.new([20, 1]), figs, figs[0], figs[1])
	check_eq(normal["b_dmg"], 12, "normal damage")
	var critical := Melee.resolve(LoadedDice.new([20, 1]), figs, figs[0], figs[1], true)
	check_eq(critical["b_dmg"], 17, "optional +5 damage")


func test_critical_overrides_higher_total() -> void:
	var figs := _pair("thug", "knight")
	var r := Melee.resolve(LoadedDice.new([20, 19]), figs, figs[0], figs[1], true)
	check_eq(r["b_dmg"], 14)
	check_eq(r["a_dmg"], 0)


func test_support_cancels() -> void:
	var figs: Array[Figure] = [
		fig("thug", 0, Vector2(10, 10), 1), fig("thug", 1, Vector2(11, 10), 2),
		fig("thug", 0, Vector2(11, 11), 3), fig("thug", 1, Vector2(10, 9), 4),
	]
	check_eq(Melee.fight_mod(figs, figs[0], figs[1]), 2)
	check_eq(Melee.fight_mod(figs, figs[1], figs[0]), 2)


func test_support_bonus() -> void:
	var figs: Array[Figure] = [
		fig("thug", 0, Vector2(10, 10), 1), fig("thug", 1, Vector2(11, 10), 2),
		fig("thug", 0, Vector2(11, 11), 3),
	]
	check_eq(Melee.support(figs, figs[0], figs[1]), 2, "friend touching the enemy")
	figs.append(fig("thug", 1, Vector2(11, 12), 4))
	check_eq(Melee.support(figs, figs[0], figs[1]), 0, "friend busy with another enemy")


func test_staff_reduces_damage_both_ways() -> void:
	var figs := _pair("thug", "wizard")
	var r := Melee.resolve(LoadedDice.new([15, 1]), figs, figs[0], figs[1])
	check_eq(r["b_dmg"], 17 - 10 - 1, "hitting a staff wielder")


func test_fight_through_controller() -> void:
	var c := make_game(make_board(), _pair("knight", "thug"), LoadedDice.new([15, 10]))
	c.state.active_id = 1
	c.state.active().actions_left = 2
	check(c.fight(2), "fight allowed")
	check_eq(c.state.figure(2).health, 1, "10 - 9")
	check(not c.can_act(), "one fight per activation")


func test_defender_selects_weapon_before_any_roll() -> void:
	var c:=make_game(make_board(),_pair("thug","knight"),LoadedDice.new([15,10]))
	c.state.reaction_side=1
	c.state.active_id=1
	c.state.active().actions_left=2
	check(c.fight(2))
	check(c.awaiting_reaction())
	check(c.state.pending_combat.is_empty())
	check_eq((c.dice as LoadedDice).queue,[15,10])
	check(not BattleEquipmentAction.execute(c,"melee_choice",{"weapon":"staff"}))
	check_eq((c.dice as LoadedDice).queue,[15,10])
	check(BattleEquipmentAction.execute(c,"melee_choice",{"weapon":"dagger"}))
	check_eq(c.state.figure(2).melee.id,"dagger")
	check((c.dice as LoadedDice).queue.is_empty())
	check(MeleeWeaponChoice.pending(c).is_empty())

func test_weapon_selection_does_not_remove_carried_encumbrance() -> void:
	var figs:=_pair("barbarian","thug")
	var f:=figs[0]
	for w in f.def.weapons:
		if w.id=="dagger":
			f.melee=w
	check(f.treasure_encumbered(),"still carries two-handed weapon")
	f.destroyed_weapons.append("two_handed")
	check(not f.treasure_encumbered())
