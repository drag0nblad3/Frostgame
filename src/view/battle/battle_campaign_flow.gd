class_name BattleCampaignFlow
extends RefCounted
## Campaign battles for BattleScene: starting, resuming, saving and settling them, plus the survival and plant choices.


static func _open_campaign(bs: BattleScene) -> void:
	if bs._campaign_dialog == null:
		bs._campaign_dialog = CampaignPanel.new()
		bs.add_child(bs._campaign_dialog)
		bs._campaign_dialog.setup(bs._campaign, bs._figures)
		bs._campaign_dialog.begin_requested.connect(bs._begin_campaign_battle)
		bs._campaign_dialog.start_requested.connect(bs._create_campaign)
		bs._campaign_dialog.story_requested.connect(bs._create_story_campaign)
		bs._campaign_dialog.restart_requested.connect(bs._restart_campaign)
		bs._campaign_dialog.scenario_selected.connect(func(id: String) -> void:
			bs._scenario_id=id
			bs.hud.select_scenario(id))
	bs._campaign_dialog._show_section(0)
	bs._campaign_dialog.select_scenario(bs._scenario_id)
	bs._campaign_dialog.refresh(bs._campaign_battle)
	bs._campaign_dialog.fit_phone()
	bs._campaign_dialog.show_screen()


static func _create_campaign(bs: BattleScene) -> void:
	if not bs._campaign.data.is_empty():
		return
	var roster := bs._roster
	if roster.is_empty():
		var draft := WarbandDraft.new(bs._figures)
		draft.choose_defaults()
		roster = draft.as_warband()
	bs._campaign.start(roster,bs._figures.content_profile)
	bs._campaign.save()
	bs._campaign_dialog.refresh(false)


static func _create_story_campaign(bs: BattleScene, include_veil: bool,strict_pursuit: bool) -> void:
	if not bs._campaign.data.is_empty():
		return
	bs._create_campaign()
	if RedKingCampaign.start(bs._campaign.data,bs._figures.content_profile,include_veil,strict_pursuit):
		bs._campaign.save()
	bs._campaign_dialog.refresh(false)


static func _restart_campaign(bs: BattleScene) -> void:
	if bs._campaign_battle:
		return
	bs._campaign.data = {}
	bs._create_campaign()


static func _begin_campaign_battle(bs: BattleScene) -> void:
	if bs._campaign_battle or not bs._campaign.can_deploy():
		return
	if RedKingCampaign.active(bs._campaign.data):
		bs._scenario_id=RedKingCampaign.next_id(bs._campaign.data)
		if bs._scenario_id.is_empty() or not ScenarioBriefing.available_entries(bs._figures.content_profile).has(bs._scenario_id):
			return
		bs.hud.select_scenario(bs._scenario_id)
	elif not RedKingCampaign.freeform_permits(bs._scenario_id):
		bs._scenario_id=BattleScene.SCENARIO
		bs.hud.select_scenario(bs._scenario_id)
	for unit: Dictionary in bs._campaign.data["units"]:
		if InjuryRules.blind(unit) and not unit["dead"]:
			unit["dead"] = true
			CampaignInventory.lose_owned(bs._campaign.data, int(unit["id"]))
			bs._campaign.data["last_report"].append("%s retires after losing both eyes." % str(unit["type"]).capitalize())
	if RedKingCampaign.active(bs._campaign.data) and RaggedWarbands.stage(bs._scenario_id) and not RaggedWarbands.active(bs._campaign.data):
		RaggedWarbands.enter(bs._campaign.data)
		bs._campaign.save()
		bs._campaign_dialog.refresh(false)
		return
	if not bs._campaign.save():
		return
	var source: Dictionary=JsonFile.read(ScenarioLoader.DIR+bs._scenario_id+".json")
	source["warbands"][0]=bs._campaign.deployment()
	source["reality_cracks"]=bs._campaign.data.get("reality_cracks",false)
	var began := Time.get_ticks_usec()
	var candidate := ScenarioLoader.from_dict(source,bs._figures,bs._terrain)
	print("Map load: campaign deployment %.1f ms"%[float(Time.get_ticks_usec()-began)/1000.0])
	if candidate.scenario_data.has("deployment_error"):
		bs.hud.notify(str(candidate.scenario_data["deployment_error"]))
		bs._campaign_dialog.refresh(false)
		return
	bs._previous_campaign_battle=bs._campaign_battle
	bs._campaign_battle = true
	bs.watch_mode = false
	bs._campaign_dialog.hide()
	bs.new_game(0,candidate,true)


static func _save_battle(bs: BattleScene) -> bool:
	if bs._training >= 0:
		bs.hud.notify("Training does not replace your saved battle.")
		return false
	if bs.controller == null or not bs.player.idle() or not BattleSnapshot.can_save(bs.controller):
		bs.hud.notify("Finish the current roll or animation before saving.")
		return false
	var meta := {"scenario": bs._active_scenario_id, "campaign": bs._campaign_battle, "campaign_hash": bs._campaign_fingerprint() if bs._campaign_battle else "", "watch": bs.watch_mode}
	if BattleSnapshot.save(bs.controller, meta):
		bs.hud.notify("Battle saved.")
		return true
	bs.hud.notify("Could not save this battle.")
	return false


static func _resume_battle(bs: BattleScene) -> void:
	if bs.controller != null and not bs.player.idle():
		bs.hud.notify("Finish the current animation before resuming.")
		return
	var data := BattleSnapshot.read()
	if data.is_empty():
		bs.hud.notify("No compatible saved battle.")
		return
	var meta: Dictionary = data.get("meta", {})
	if not bs._figures.content_profile.same(meta.get("expansions",[])):
		bs.hud.notify("Restore this checkpoint's rulebook content selection from Home before resuming.")
		return
	if meta.get("campaign", false) and (meta.get("campaign_hash", "") == "" or meta["campaign_hash"] != bs._campaign_fingerprint()):
		bs.hud.notify("Campaign changed since this checkpoint; cannot resume it.")
		return
	var restored := BattleSnapshot.rebuild(data, bs._figures)
	if restored == null:
		bs.hud.notify("Could not restore the saved battle.")
		return
	if bs._training >= 0:
		bs._rig.distance = 34.0
	bs._training = -1
	bs._training_complete = false
	bs._training_failed = false
	bs.hud.set_training(-1, false)
	bs._scenario_id = str(meta.get("scenario", BattleScene.SCENARIO))
	bs._active_scenario_id = bs._scenario_id
	bs.hud.select_scenario(bs._scenario_id)
	bs._campaign_battle = bool(meta.get("campaign", false))
	bs.watch_mode = bool(meta.get("watch", false))
	bs._attach_battle(restored, false)
	bs.hud.notify("Battle resumed.")


static func _choose_plant(bs: BattleScene, candidates: Array[int]) -> void:
	if is_instance_valid(bs._plant_dialog):
		return
	bs._plant_dialog=ConfirmationDialog.new()
	bs._plant_dialog.title="Lifelong Plant"
	bs._plant_dialog.dialog_text="Choose one casualty to receive +1 survival before any rolls. A natural 20 consumes the plant."
	bs._plant_dialog.ok_button_text="Use leaf"
	bs._plant_dialog.cancel_button_text="Skip"
	var choices := OptionButton.new()
	choices.custom_minimum_size.y=48
	for index in candidates:
		var unit: Dictionary=bs._campaign.data["units"][index]
		choices.add_item("%s #%d"%[str(unit["type"]).capitalize(),index+1])
		choices.set_item_metadata(choices.item_count-1,index)
	bs._plant_dialog.add_child(choices)
	bs.add_child(bs._plant_dialog)
	bs._plant_dialog.confirmed.connect(func() -> void: bs._finish_campaign_battle(int(choices.get_selected_metadata())))
	bs._plant_dialog.canceled.connect(func() -> void: bs._finish_campaign_battle(-1))
	PhoneSafeArea.popup_dialog(bs._plant_dialog,Vector2(360,220))


static func _finish_campaign_battle(bs: BattleScene, plant_target: int,survival_choice: int=-1) -> void:
	if not bs._campaign_battle:
		return
	if is_instance_valid(bs._plant_dialog):
		bs._plant_dialog.hide()
		bs._plant_dialog.queue_free()
		bs._plant_dialog=null
	if survival_choice<0 and not bs.watch_mode:
		var offer := bs._campaign.survival_offer(bs.controller,bs.controller.dice,0,plant_target)
		if not offer.is_empty():
			bs._choose_survival(plant_target,offer,false)
			return
	var previous := bs._campaign.data.duplicate(true)
	var rng := bs.controller.dice._rng.state
	if not bs._campaign.settle(bs.controller,bs.controller.dice,0,plant_target,{"choice":survival_choice}):
		bs._campaign.data=previous
		bs.controller.dice._rng.state=rng
		bs.hud.notify("Campaign settlement could not be applied.")
		return
	if not bs._campaign.save():
		bs._campaign.data=previous
		bs.controller.dice._rng.state=rng
		bs.hud.notify("Could not save campaign settlement. Battle retained.")
		return
	bs._campaign_battle=false
	var checkpoint := BattleSnapshot.read()
	if checkpoint.get("meta",{}).get("campaign",false):
		DirAccess.remove_absolute(WarbandSlots.path_for(BattleSnapshot.PATH))
	bs._open_campaign()


static func _choose_survival(bs: BattleScene, plant_target: int,offer: Dictionary,rolled: bool) -> void:
	if is_instance_valid(bs._survival_dialog):
		bs._survival_dialog.hide()
		bs._survival_dialog.queue_free()
	bs._survival_dialog=ConfirmationDialog.new()
	bs._survival_dialog.title="Mindscape survival reward"
	bs._survival_dialog.dialog_text="Original roll: %d\nAdjusted outcome: %s"%[offer["first"],offer["first_outcome"]]
	if rolled:
		bs._survival_dialog.dialog_text+="\nNew roll: %d\nAdjusted outcome: %s\nChoose which result to keep."%[offer["second"],offer["second_outcome"]]
		bs._survival_dialog.ok_button_text="Keep new roll"
		bs._survival_dialog.cancel_button_text="Keep original"
		bs._survival_dialog.confirmed.connect(func() -> void: bs._commit_survival(plant_target,2))
		bs._survival_dialog.canceled.connect(func() -> void: bs._commit_survival(plant_target,1))
	else:
		bs._survival_dialog.dialog_text+="\nSpend the one-time reroll? You can keep either result."
		bs._survival_dialog.ok_button_text="Roll again"
		bs._survival_dialog.cancel_button_text="Keep original"
		bs._survival_dialog.confirmed.connect(func() -> void: bs._choose_survival(plant_target,offer,true))
		bs._survival_dialog.canceled.connect(func() -> void: bs._commit_survival(plant_target,0))
	bs.add_child(bs._survival_dialog)
	PhoneSafeArea.popup_dialog(bs._survival_dialog,Vector2(460,280))


static func _commit_survival(bs: BattleScene, plant_target: int,choice: int) -> void:
	if is_instance_valid(bs._survival_dialog):
		bs._survival_dialog.hide()
		bs._survival_dialog.queue_free()
		bs._survival_dialog=null
	bs._finish_campaign_battle(plant_target,choice)
