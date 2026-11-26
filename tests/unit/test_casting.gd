extends TestCase


func test_apprentice_modifier() -> void:
	check_eq(CastingRoll.modified(12, 0, true), 10)
	check_eq(CastingRoll.modified(12, 20), 22)


func test_failure_bands() -> void:
	for pair: Array in [[4, 0], [5, 1], [9, 1], [10, 2], [19, 2], [20, 5]]:
		check_eq(CastingRoll.failure_damage(pair[0]), pair[1])
	check_eq(CastingRoll.failure_damage(20, true), 0)


func test_empowerment_and_minimum() -> void:
	var r := CastingRoll.resolve(7, 8, 1, 10)
	check(r["success"])
	check_eq(r["roll"], 14)
	check_eq(r["health_spent"], 1)
	check_eq(CastingRoll.max_empowerment(16, 8), 2)
	check_eq(CastingRoll.max_empowerment(10, 1), 1)
	check_eq(CastingRoll.max_empowerment(10, 8, true), 0)


func test_stat_roll_automatic_results() -> void:
	check(StatRoll.succeeds(20, -5, 30))
	check(not StatRoll.succeeds(1, 10, 2, 20))
	check(StatRoll.succeeds(10, 2, 14, 2))
	check(not StatRoll.succeeds(10, 20, 21))
