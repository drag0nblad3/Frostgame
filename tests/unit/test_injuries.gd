extends TestCase


func test_injury_modifiers_and_treatment() -> void:
	var unit := {"id": 0, "type": "wizard", "dead": false, "injuries": 0}
	check_eq(InjuryRules.roll(unit, LoadedDice.new([3])), "smashed leg")
	check_eq(InjuryRules.roll(unit, LoadedDice.new([7])), "crushed arm")
	check_eq(InjuryRules.roll(unit, LoadedDice.new([17])), "niggling injury")
	check_eq(InjuryRules.bonuses(unit, {"fight": 1})["fight"], 0)
	check_eq(InjuryRules.bonuses(unit, {})["move"], -2)
	check_eq(InjuryRules.starting_loss(unit), 3)
	var d := {"units": [unit], "gold": 50}
	check(InjuryRules.treat(d, 0))
	check_eq(d["gold"], 20)
	check_eq(InjuryRules.starting_loss(unit), 0)


func test_repeated_jaw_and_eye() -> void:
	var f := fig("wizard", 0, Vector2(10, 10))
	f.injury_types = {"smashed_jaw": 2, "lost_eye": 1}
	check_eq(f.early_limit(), 1)
	check_eq(f.shooting_defence_penalty(), -1)
	var unit := {"injuries": 2, "injury_types": {"smashed_jaw": 2}}
	check_eq(InjuryRules.roll(unit, LoadedDice.new([19, 20])), "lost eye")
	check(not InjuryRules.blind(unit))
