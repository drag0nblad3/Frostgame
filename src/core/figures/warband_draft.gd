class_name WarbandDraft
extends RefCounted
## Starting wizard and recruitment validation (Second Edition pp. 17–32).

const BUDGET := 400
const MAX_SOLDIERS := 8
const MAX_SPECIALISTS := 4

var wizard_name := "New Wizard"
var school := "elementalist"
var apprentice := true
var soldiers: Array[String] = ["thug", "thief"]
var spells: Array[String] = []
var wizard_weapons: Array = CasterLoadout.PRESETS["Staff"].duplicate()
var apprentice_weapons: Array = CasterLoadout.PRESETS["Staff"].duplicate()
var schools: Dictionary
var catalog: Dictionary
var db: FigureDb


func _init(figures: FigureDb) -> void:
	db = figures
	schools = db.content_profile.filter("schools",JsonFile.read("res://data/schools.json"))
	catalog = db.content_profile.filter("spells",JsonFile.read("res://data/spells.json"))


func school_modifier(other: String) -> int:
	if other == school:
		return 0
	if schools[school]["aligned"].has(other):
		return 2
	if schools[school]["opposed"] == other:
		return 6
	return 4


func candidates(slot: int) -> Array[String]:
	var result: Array[String] = []
	var aligned: Array = schools[school]["aligned"]
	for id: String in catalog:
		var other: String = catalog[id]["school"]
		if (slot < 3 and other == school) or (slot >= 3 and slot < 6 and other == aligned[slot - 3]) or (slot >= 6 and school_modifier(other) == 4):
			result.append(id)
	result.sort_custom(func(a: String, b: String) -> bool:
		var live_a: bool = catalog[a]["kind"] != "unimplemented" or Rituals.BEFORE.has(a) or Rituals.AFTER.has(a)
		var live_b: bool = catalog[b]["kind"] != "unimplemented" or Rituals.BEFORE.has(b) or Rituals.AFTER.has(b)
		return live_a if live_a != live_b else a < b)
	return result


func choose_defaults() -> void:
	spells.clear()
	var neutral: Array[String] = []
	for slot in 8:
		for id in candidates(slot):
			var other: String = catalog[id]["school"]
			if spells.has(id) or (slot >= 6 and neutral.has(other)):
				continue
			spells.append(id)
			if slot >= 6:
				neutral.append(other)
			break


func casting_number(id: String) -> int:
	return int(catalog[id]["number"]) + school_modifier(catalog[id]["school"])


func cost() -> int:
	var total := db.get_def("apprentice").cost if apprentice else 0
	for id in soldiers:
		total += db.get_def(id).cost
	return total


func specialists() -> int:
	var count := 0
	for id in soldiers:
		if db.get_def(id).specialist:
			count += 1
	return count


func errors() -> Array[String]:
	var result: Array[String] = []
	if wizard_name.strip_edges().is_empty():
		result.append("Name your wizard.")
	if not schools.has(school):
		result.append("Choose a school.")
		return result
	if soldiers.size() > MAX_SOLDIERS or specialists() > MAX_SPECIALISTS or cost() > BUDGET:
		result.append("Recruitment exceeds budget or roster limits.")
	if not CasterLoadout.valid(wizard_weapons) or CasterLoadout.weapon_slots(wizard_weapons) > 5 or (apprentice and (not CasterLoadout.valid(apprentice_weapons) or CasterLoadout.weapon_slots(apprentice_weapons) > 4)):
		result.append("Spellcaster equipment exceeds item capacity.")
	if spells.size() != 8:
		result.append("Select eight spells.")
		return result
	for id in soldiers:
		if not db.available(id):
			result.append("Recruit requires an enabled content pack: "+id)
	for id in wizard_weapons+apprentice_weapons:
		if not db.content_profile.allows("weapons",str(id)):
			result.append("Weapon requires an enabled content pack: "+str(id))
	var used := {}
	var neutral := {}
	for slot in spells.size():
		var id := spells[slot]
		if not candidates(slot).has(id) or used.has(id):
			result.append("Spell slots must be distinct and match school rules.")
			break
		used[id] = true
		if slot >= 6:
			var other: String = catalog[id]["school"]
			if neutral.has(other):
				result.append("Choose two different neutral schools.")
				break
			neutral[other] = true
	return result


func can_hire(id: String) -> bool:
	if not db.available(id):
		return false
	var d := db.get_def(id)
	return d.role == "soldier" and soldiers.size() < MAX_SOLDIERS and cost() + d.cost <= BUDGET and (not d.specialist or specialists() < MAX_SPECIALISTS)


func hire(id: String) -> bool:
	if not can_hire(id):
		return false
	soldiers.append(id)
	return true


func as_warband() -> Dictionary:
	var types: Array[String] = ["wizard"]
	if apprentice:
		types.append("apprentice")
	types.append_array(soldiers)
	var units: Array = []
	for i in types.size():
		var entry := {"type": types[i], "at": [4.5 + 3.0 * i, 3.0]}
		if types[i] == "wizard":
			entry["weapons"] = wizard_weapons.duplicate()
		elif types[i] == "apprentice":
			entry["weapons"] = apprentice_weapons.duplicate()
		units.append(entry)
	var book := {}
	for id in spells:
		book[id] = casting_number(id)
	return {"name": wizard_name, "school": school, "spells": book, "figures": units, "gold": BUDGET - cost()}


func restore_roster(saved: Dictionary) -> bool:
	var other := WarbandDraft.new(db)
	other.wizard_name=str(saved.get("name","New Wizard"))
	other.school=str(saved.get("school","elementalist"))
	if not other.schools.has(other.school):
		return false
	other.apprentice=false
	other.soldiers.clear()
	for entry: Dictionary in saved.get("figures",[]):
		var id := str(entry.get("type",""))
		if id=="wizard":
			other.wizard_weapons=entry.get("weapons",other.wizard_weapons).duplicate()
		elif id=="apprentice":
			other.apprentice=true
			other.apprentice_weapons=entry.get("weapons",other.apprentice_weapons).duplicate()
		elif db.available(id) and db.get_def(id).role=="soldier":
			other.soldiers.append(id)
		else:
			return false
	var book: Dictionary=saved.get("spells",{})
	for slot in 8:
		for id in other.candidates(slot):
			if book.has(id) and not other.spells.has(id):
				other.spells.append(id)
				break
	if not other.errors().is_empty():
		return false
	wizard_name=other.wizard_name
	school=other.school
	apprentice=other.apprentice
	soldiers.assign(other.soldiers)
	spells.assign(other.spells)
	wizard_weapons=other.wizard_weapons.duplicate()
	apprentice_weapons=other.apprentice_weapons.duplicate()
	return true
