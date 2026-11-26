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


func test_natural_20_doubles() -> void:
	var figs := _pair("thug", "thug")
	var r := Melee.resolve(LoadedDice.new([20, 1]), figs, figs[0], figs[1])
	check_eq(r["b_dmg"], (22 - 10) * 2, "critical hit")


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
