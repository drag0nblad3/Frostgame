extends TestCase


func test_catalog_routes_every_spell() -> void:
	var catalog: Dictionary = JsonFile.read("res://data/spells.json")
	check_eq(catalog.size(), 80)
	for id: String in catalog:
		check(catalog[id]["kind"] != "unimplemented", id)
		if catalog[id]["kind"] == "ritual":
			check(Rituals.BEFORE.has(id) or Rituals.AFTER.has(id), id)
