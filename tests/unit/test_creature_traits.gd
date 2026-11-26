extends TestCase


func test_powerful_and_strong() -> void:
	var a := fig("ice_toad", -1, Vector2(10, 10), 1)
	var b := fig("thug", 0, Vector2(11, 10), 2)
	var figs: Array[Figure] = [a, b]
	var r := Melee.resolve(LoadedDice.new([12, 1]), figs, a, b)
	check_eq(r["b_dmg"], 8)
	var troll := fig("snow_troll", -1, Vector2(10, 10), 1)
	figs[0] = troll
	r = Melee.resolve(LoadedDice.new([12, 1]), figs, troll, b)
	check_eq(r["b_dmg"], 8)


func test_armour_cap() -> void:
	var knight := fig("knight", 0, Vector2.ZERO)
	knight.spell_effects = {"shield": true, "combat_awareness": true}
	check_eq(knight.effective_armour(), 15)


func test_encounter_table_and_definitions() -> void:
	var s := ScenarioLoader.load_id("treasure_skirmish", db(), terrain())
	var c := GameController.new(s, Dice.new(3))
	check_eq(c._encounters.encounter(12, 11)["count"], 4)
	check_eq(c._encounters.encounter(13, 4)["type"], "wraith")
	check_eq(c._encounters.encounter(19, 14)["type"], "frost_giant")
	check_eq(c._encounters.encounter(20, 7)["type"], "vampire")
	for tier in [1, 13, 19]:
		for roll in range(1, 21):
			var entry := c._encounters.encounter(tier, roll)
			check_eq(db().get_def(entry["type"]).id, entry["type"])


func test_boar_charge_bonus() -> void:
	var a := fig("boar", -1, Vector2(10, 10), 1)
	var b := fig("thug", 0, Vector2(11, 10), 2)
	var figs: Array[Figure] = [a, b]
	a.moves_taken = 1
	var result := Melee.resolve(LoadedDice.new([10, 1]), figs, a, b)
	check_eq(result["a_total"], 14)
	check_eq(result["b_total"], 1 + b.effective_fight() + b.melee.fight_mod)
	check_eq(Melee.fight_mod(figs, a, b), 2)


func test_vampire_mind_lock() -> void:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("vampire", -1, Vector2(12, 10))], Dice.new(4))
	check(not c._magic.summons.can_control(c.state.figure(1), c.state.figure(2), "mind_control"))
	check(WeaponActions.magic_attack(c.state.figure(2), c.state.figure(2).melee))
