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


func test_reference_covers_every_catalogue_spell() -> void:
	var catalog: Dictionary=JsonFile.read("res://data/spells.json")
	for id: String in catalog:
		var entry := SpellReference.entry(id)
		check(not entry.is_empty())
		for key in ["target","effect","duration"]:
			check(str(entry.get(key,"")).length()>10)
	check_eq(SpellReference.odds(12),45)
	check_eq(SpellReference.odds(12,-2),35)
	check_eq(SpellReference.guide_pages(catalog).size(),10)


func test_battle_reference_preserves_available_actions_and_known_tn() -> void:
	var defs := db()
	var s := GameState.new()
	s.spell_catalog=JsonFile.read("res://data/spells.json")
	s.spellbooks[0]={"heal":10,"brew_potion":14}
	var f := Figure.new(1,defs.get_def("apprentice"),0,Vector2.ZERO,defs.unarmed())
	var legal: Array[String]=["heal","enchant_ammo"]
	var rows := SpellReference.battle_entries(s,f,legal)
	check_eq(rows.size(),3)
	check_eq(rows[0]["tn"],10)
	check_eq(rows[0]["chance"],45)
	check(rows[0]["legal"])
	check(not rows[1]["legal"])
	check(rows[1]["ritual_only"])
	check_eq(rows[2]["id"],"enchant_weapon")
