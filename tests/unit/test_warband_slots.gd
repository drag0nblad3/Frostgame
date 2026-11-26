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
