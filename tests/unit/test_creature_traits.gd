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
