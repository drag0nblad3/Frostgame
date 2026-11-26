extends TestCase


func test_verified_recruitment() -> void:
	check_eq(db().get_def("apprentice").cost, 100)
	check_eq(db().get_def("thief").cost, 0)
	check_eq(db().get_def("archer").cost, 75)
	check_eq(db().get_def("man_at_arms").armour, 12)
	check_eq(db().get_def("barbarian").move, 6)
	check(db().get_def("templar").specialist)
	check(not db().get_def("apothecary").specialist)
	check(db().get_def("war_hound").traits.has("animal"))
	check_eq(db().get_def("war_hound").weapons[0].fight_mod, 0)
