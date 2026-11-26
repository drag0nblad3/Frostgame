extends TestCase


func test_distinct_slot_paths_and_legacy_compatibility() -> void:
	check_eq(WarbandSlots.path_for(CampaignProgress.PATH,0),CampaignProgress.PATH)
	check_eq(WarbandSlots.path_for(BattleSnapshot.PATH,0),BattleSnapshot.PATH)
	check(WarbandSlots.path_for(CampaignProgress.PATH,1)!=WarbandSlots.path_for(CampaignProgress.PATH,2))
	check(WarbandSlots.path_for(BattleSnapshot.PATH,1)!=WarbandSlots.path_for(LayeredCheckpoint.PATH,1))


func test_saved_draft_round_trip() -> void:
	var defs := db()
	var draft := WarbandDraft.new(defs)
	draft.school="witch"
	draft.wizard_name="Slot wizard"
	draft.choose_defaults()
	draft.hire("infantryman")
	var restored := WarbandDraft.new(defs)
	check(restored.restore_roster(draft.as_warband()))
	check_eq(restored.as_warband(),draft.as_warband())


func test_slot_files_isolate_rosters_and_campaigns() -> void:
	var defs := db()
	var first := WarbandDraft.new(defs)
	first.choose_defaults()
	first.wizard_name="Test Alpha"
	var second := WarbandDraft.new(defs)
	second.choose_defaults()
	second.wizard_name="Test Beta"
	# Use the last slots only when unoccupied, never replace actual saves.
	var a := WarbandSlots.COUNT-2
	var b := WarbandSlots.COUNT-1
	var pa := WarbandSlots.roster_path(a)
	var pb := WarbandSlots.roster_path(b)
	if FileAccess.file_exists(pa) or FileAccess.file_exists(pb):
		return
	check(WarbandSlots.save_roster(first.as_warband(),a))
	check(WarbandSlots.save_roster(second.as_warband(),b))
	check_eq(WarbandSlots.roster(a).get("name"),"Test Alpha")
	check_eq(WarbandSlots.roster(b).get("name"),"Test Beta")
	DirAccess.remove_absolute(pa)
	DirAccess.remove_absolute(pb)
	var ca := WarbandSlots.path_for(CampaignProgress.PATH,a)
	var cb := WarbandSlots.path_for(CampaignProgress.PATH,b)
	if FileAccess.file_exists(ca) or FileAccess.file_exists(cb):
		return
	var progress := CampaignProgress.new()
	progress.start(first.as_warband())
	check(progress.save(ca))
	progress.start(second.as_warband())
	check(progress.save(cb))
	check(progress.load_save(ca))
	check_eq(progress.data["name"],"Test Alpha")
	check(progress.load_save(cb))
	check_eq(progress.data["name"],"Test Beta")
	DirAccess.remove_absolute(ca)
	DirAccess.remove_absolute(cb)
