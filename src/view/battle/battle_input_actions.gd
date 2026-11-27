class_name BattleInputActions
extends RefCounted
## Button presses for scenario prompts, reactions, equipment and potions.


static func action(bi: BattleInput, key: String) -> bool:
	if not bi.available.has(key):
		return false
	if key=="ruins_back":
		bi.mode="ruins_piece"
		bi.available.clear()
		bi.preview()
		return false
	if key=="exchange_join":
		return RealityCracks.answer_exchange(bi.c,int(bi.c.state.scenario_data["rk_end_choice"]["options"][0]))
	if key=="exchange_decline":
		return RealityCracks.answer_exchange(bi.c,-1)
	if key=="worm_keep":
		return WormRider.answer_relocation(bi.c,bi.c.state.scenario_data["rk_worm_relocation"]["at"])
	if key in ["sinkhole_accept","sinkhole_fight","sinkhole_will","sinkhole_all"]:
		return RedKingSinkhole.answer_pull(bi.c,key.trim_prefix("sinkhole_"))
	if key=="veil_keep":
		return RedKingVeil.answer_target(bi.c,int(bi.c.state.scenario_data["rk_end_choice"]["target"]))
	if key=="mind_skip":
		return RedKingMind.answer_memory(bi.c,-1)
	if key=="mind_back":
		bi.mode="mind_token"
		bi.available.assign(["mind_skip"])
		bi.preview()
		return false
	if key == "items":
		bi.available.assign(["items_back"])
		bi.available.append_array(bi.item_options)
		bi.mode = "items_menu"
		bi.preview()
		return false
	if key == "items_back":
		bi.mode = ""
		bi.refresh()
		return false
	if key=="reality_exit":
		return RealityCracks.exit_center(bi.c)
	if key=="ring_switch":
		return RedKingRingworld.switch(bi.c,bi.c.state.active())
	if key=="ring_escape":
		return RedKingRingworld.escape(bi.c,bi.c.state.active())
	if key == "drink_well":
		return BattleAction.execute(bi.c,"drink_well")
	if key == "break_ice":
		return BattleAction.execute(bi.c,"break_ice")
	if key.begins_with("weapon_"):
		return bi.c.select_melee(key.trim_prefix("weapon_"))
	if key in ["direction_keep","direction_teetotum","direction_gem"]:
		return RedKingDirection.answer(bi.c,key.trim_prefix("direction_"))
	if key in ["elemental_absorb","elemental_pass"]:
		return bi.c.answer_elemental_combat(key=="elemental_absorb")
	if key in ["fate_combat_yes", "fate_combat_no"]:
		return bi.c.answer_fate_combat(key == "fate_combat_yes")
	if key in ["telescope_use", "telescope_save"]:
		return bi.c.answer_initiative(key == "telescope_use")
	if key == "potion_cancel":
		bi.mode = ""
		bi.refresh()
		return false
	if key in ["coat_melee", "coat_ranged"]:
		return bi.c._potions.coat(bi.selected_potion, key == "coat_ranged")
	if key in ["gear_gloves_casting", "gear_wand_light"]:
		GearActions.arm(bi.c, key)
		bi.preview()
		return false
	if key == "gear_ring_transference":
		bi.mode = "gear_transfer_target"
		bi.available.assign(["potion_cancel"])
		bi.preview()
		return false
	if key=="gear_tiger_eye_move":
		bi.mode="gear_tiger_point"
		bi.available.assign(["potion_cancel"])
		bi.preview()
		return false
	if key=="gear_lantern_toggle":
		return HolyLantern.toggle(bi.c)
	if key=="gear_worm_summon":
		bi.mode="gear_worm_point"
		bi.available.assign(["potion_cancel"])
		bi.preview()
		return false
	if key=="gear_death_mask_toggle":
		return DeathMask.toggle(bi.c)
	if key=="gear_teetotum_arm":
		RedKingDirection.arm(bi.c)
		bi.refresh()
		return false
	if key=="gear_absorb_arm":
		RedKingElemental.arm(bi.c)
		bi.refresh()
		return false
	if key==GearActions.CAPE:
		bi.mode="gear_cape_move"
		bi.available.assign(["potion_cancel"])
		bi.preview()
		return false
	if key=="gear_rk_bottle_imp":
		bi.mode="gear_bottle_imp"
		bi.available.assign(["potion_cancel"])
		bi.preview()
		return false
	if key == "gear_ring_teleportation":
		bi.mode = "gear_teleport"
		bi.available.assign(["potion_cancel"])
		bi.preview()
		return false
	if key == "gear_horn_destruction":
		bi.counter_choices = bi.c._magic.crumble.options(bi.c.state.active())
		if bi.counter_choices.is_empty():
			return false
		bi.selected_spell = "horn"
		bi.counter_index = 0
		bi.mode = "counter_select"
		bi.available.assign(["spell_cancel", "counter_confirm"])
		if bi.counter_choices.size() > 1:
			bi.available.append("counter_previous")
			bi.available.append("counter_next")
		bi.preview()
		return false
	if key.begins_with("potion_"):
		bi.selected_potion = key.trim_prefix("potion_")
		if bi.selected_potion in PotionActions.POINTS:
			bi.mode = "potion_point"
			bi.available.assign(["potion_cancel"])
			bi.preview()
			return false
		if bi.selected_potion in PotionActions.COATINGS:
			bi.mode = "potion_coat"
			bi.available.assign(["potion_cancel"])
			var f := bi.c.state.active()
			if PotionActions.can_coat(f, bi.selected_potion, f.melee):
				bi.available.append("coat_melee")
			if PotionActions.can_coat(f, bi.selected_potion, f.ranged):
				bi.available.append("coat_ranged")
			bi.preview()
			return false
		if bi.c.state.active().def.id == "apothecary":
			bi.mode = "potion_target"
			bi.available.assign(["potion_cancel"])
			bi.preview()
			return false
		return bi.c._potions.drink(bi.selected_potion)
	if key == "shatter_single":
		return bi.c._magic.single_shatter()
	return BattleInputSpellActions.action_rest(bi, key)
