extends TestCase


func test_all_spell_schools_have_original_icons() -> void:
	var catalog: Dictionary = JsonFile.read("res://data/spells.json")
	for id: String in catalog:
		check(ActionArt.ICONS.has(catalog[id]["school"]))
		check(ActionArt.command("spell_"+id,catalog) != null)
	check(ActionArt.command("move",catalog) != null)
	check(ActionArt.command("fight",catalog) != ActionArt.command("shoot",catalog))


func test_every_base_resource_has_icon() -> void:
	for id: String in BaseResources.catalog():
		check(ResourceArt.ICONS.has(id))
		check(ResourceArt.icon(id) != null)
