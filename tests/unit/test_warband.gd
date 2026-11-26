extends TestCase


func test_all_schools_have_valid_initial_choices() -> void:
	var d := WarbandDraft.new(db())
	for school: String in d.schools:
		d.school = school
		d.choose_defaults()
		check_eq(d.spells.size(), 8, school)
		check(d.errors().is_empty(), school)


func test_budget_and_specialist_limit() -> void:
	var d := WarbandDraft.new(db())
	d.choose_defaults()
	d.soldiers.clear()
	check_eq(d.cost(), 100)
	for i in 4:
		check(d.hire("archer"))
	check_eq(d.cost(), 400)
	check(not d.hire("archer"))
	check(d.hire("thief"))
	check(d.errors().is_empty())
	check_eq(d.as_warband()["figures"].size(), 7)


func test_spell_constraints() -> void:
	var d := WarbandDraft.new(db())
	d.choose_defaults()
	check_eq(d.school_modifier("chronomancer"), 2)
	check_eq(d.school_modifier("necromancer"), 4)
	check_eq(d.school_modifier("illusionist"), 6)
	d.spells[1] = d.spells[0]
	check(not d.errors().is_empty())
