extends TestCase


func _packs() -> Dictionary:
	return {"book_a":{"name":"Book A","content":{"figures":["new_soldier"],"spells":["new_spell"],"scenarios":["new_map"],"rules":["new_rule"]}},"book_b":{"name":"Book B","requires":["book_a"],"content":{"magic_equipment":["gear_new"]}}}


func test_core_only_and_independent_book_selection() -> void:
	var core := ContentProfile.new([],_packs())
	var a := ContentProfile.new(["book_a"],_packs())
	var b := ContentProfile.new(["book_b"],_packs())
	check(core.allows("figures","thug"))
	check(not core.allows("figures","new_soldier"))
	check(a.allows("figures","new_soldier"))
	check(not a.item_allowed("gear_new"))
	check(not core.item_allowed("scroll_new_spell"))
	check(a.item_allowed("grimoire_new_spell"))
	check(not core.rule("new_rule"))
	check(a.rule("new_rule"))
	check(not a.rule("unknown_rule"))
	check(not b.errors().is_empty())
	check(ContentProfile.new(["book_b","book_a"],_packs()).errors().is_empty())


func test_filter_and_dependency_protection() -> void:
	var before := ContentProfile.new(["book_a"],_packs())
	var after := ContentProfile.new([],_packs())
	check_eq(after.filter("scenarios",{"core_map":1,"new_map":2}),{"core_map":1})
	check(not ExpansionSafety.conflicts(before,after,{"figures":[{"type":"new_soldier"}]},{}).is_empty())
	check(not ExpansionSafety.conflicts(before,after,{},{"loot":[{"scroll":"new_spell"}]}).is_empty())
	check(ExpansionSafety.conflicts(before,after,{},{}).is_empty())
	check(not ExpansionSafety.conflicts(before,after,{},{"games":1}).is_empty())


func test_save_slot_paths_and_legacy_core_only() -> void:
	check(WarbandSlots.content_path(0)!=WarbandSlots.content_path(1))
	check(WarbandSlots.content_path(2)!=WarbandSlots.roster_path(2))
	var slot := WarbandSlots.COUNT-1
	var path := WarbandSlots.content_path(slot)
	if FileAccess.file_exists(path) or FileAccess.file_exists(WarbandSlots.roster_path(slot)) or FileAccess.file_exists(WarbandSlots.path_for(CampaignProgress.PATH,slot)):
		return
	check(WarbandSlots.content_profile(slot).enabled.is_empty())
	check(WarbandSlots.change_content([],slot).is_empty())
	check(FileAccess.file_exists(path))
	check(WarbandSlots.content_profile(slot).enabled.is_empty())
	check(not WarbandSlots.change_content(["unknown_book"],slot).is_empty())
	DirAccess.remove_absolute(path)


func test_installed_red_king_playtest_is_opt_in() -> void:
	var core := ContentProfile.new()
	var expansion := ContentProfile.new(["red_king"])
	check(expansion.errors().is_empty())
	check(expansion.allows("campaigns","red_king"))
	check(not core.allows("campaigns","red_king"))
	check(expansion.rule("red_king_reality_cracks"))
	check(not core.rule("red_king_reality_cracks"))
	for stage: Dictionary in RedKingCampaign.stages():
		check(expansion.allows("scenarios",stage["id"]))
		check(not core.allows("scenarios",stage["id"]))
		check(ScenarioBriefing.available_entries(expansion).has(stage["id"]))
	check(not RedKingCampaign.freeform_permits("red_king_mind"))
	check(RedKingCampaign.freeform_permits("red_king_squatter"))
	check(not ContentProfile.playable({"status":"development"}))
