extends TestCase

func test_melee_display_uses_resolved_rolls() -> void:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("thug", 1, Vector2(11, 10))], Dice.new(3))
	var event := GameEvent.new("fight", {"id": 1, "target": 2, "a_roll": 17, "b_roll": 6, "a_total": 19, "b_total": 8, "a_dmg": 0, "b_dmg": 9, "winner": 1})
	var summary := RollSummary.describe(c.state, event)
	check(summary.contains("17 → 19"))
	check(summary.contains("6 → 8"))
	check(summary.contains("Damage: 0 / 9"))
