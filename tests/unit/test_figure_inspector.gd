extends TestCase


func test_inspection_reports_effective_stats_and_traits() -> void:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("vampire", -1, Vector2(12, 10)), fig("thug", 1, Vector2(25, 25))], Dice.new(4))
	var f := c.state.figure(1)
	f.spell_effects["fleet_feet"] = true
	f.health = 8
	f.elemental_shield = 3
	f.poisoned = true
	var summary := FigureInspector.describe(c.state, f)
	check(summary.contains("Health  8 / 14"))
	check(summary.contains("Move 8.0"))
	check(summary.contains("Elemental shield: 3"))
	check(summary.contains("Poisoned"))
	check(FigureInspector.describe(c.state, c.state.figure(2)).contains("Immune to mundane weapons"))
	check_eq(f.health, 8)


func test_guide_has_contextual_hints() -> void:
	check(FieldGuide.tip("move").contains("half speed"))
	check(FieldGuide.tip("empower").contains("Health"))
	check_eq(FieldGuide.tip("unknown"), "")
