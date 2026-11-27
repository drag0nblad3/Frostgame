class_name BattleInputSpellActions
extends RefCounted
## Button presses for spells and the basic move, fight, shoot and end actions.


## Continues action.
static func action_rest(bi: BattleInput, key: String) -> bool:
	if key.begins_with("spell_") and key != "spell_cancel":
		bi.spell_ammo=key=="spell_enchant_ammo"
		bi.selected_spell="enchant_weapon" if bi.spell_ammo else key.trim_prefix("spell_")
		bi.spell_rotated = false
		bi.spell_extended=false
		if bi.selected_spell in ["dispel", "spell_eater", "decay", "power_word", "draining_word", "crumble", "wizard_eye"]:
			bi.counter_choices = bi.c._magic.counter_options(bi.selected_spell)
			if bi.counter_choices.is_empty():
				bi.refresh()
				return false
			bi.counter_index = 0
			bi.mode = "counter_select"
			bi.available.assign(["spell_cancel", "counter_confirm"])
			if not bi.c._magic.shatter.first.is_empty():
				bi.available.append("shatter_single")
			if bi.counter_choices.size() > 1:
				bi.available.append("counter_previous")
				bi.available.append("counter_next")
			bi.preview()
			return false
		bi.mode = "spell_point" if bi.c._magic.is_placement(bi.selected_spell) else "spell_target"
		if bi.selected_spell in ["telekinesis", "fools_gold"]:
			bi.mode = "treasure_spell"
		bi.available.assign(["spell_cancel"])
		if not bi.c._magic.shatter.first.is_empty():
			bi.available.append("shatter_single")
		if bi.selected_spell in ["fog", "wall", "bridge"]:
			bi.available.append("rotate_spell")
		if bi.selected_spell=="bridge" and ActiveGear.ready(bi.c.state.active(),TerrainMagic.EXTENDED):
			bi.available.append("extend_bridge")
		bi.preview()
		return false
	match key:
		"transfer_plus", "transfer_minus":
			bi.transfer_amount = clampi(bi.transfer_amount + (1 if key == "transfer_plus" else -1), 1, GearActions.transfer_max(bi.c, bi.c.state.figure(bi.transfer_target)))
			bi._transfer_buttons()
			bi.preview()
			return false
		"transfer_confirm":
			return GearActions.transfer(bi.c, bi.c.state.figure(bi.transfer_target), bi.transfer_amount)
		"cancel_bridge":
			return bi.c._magic.terrain.cancel_bridge(bi.c.state.active())
		"use_stored_action":
			return bi.c.use_stored_action()
		"resist_plus", "resist_minus":
			bi.empower = clampi(bi.empower + (1 if key == "resist_plus" else -1), 0, int(bi.c.state.pending_resistance["max"]))
			bi._resist_buttons()
			bi.preview()
			return false
		"resist_fate":
			bi.c._magic.resistance.reroll_fate()
			bi.empower = 0
			bi._resist_buttons()
			bi.preview()
			return false
		"cast_fate":
			bi.c._magic.reroll_fate()
			bi.empower = 0
			bi._empower_buttons()
			bi.preview()
			return false
		"resist_amulet":
			bi.c._magic.resistance.use_amulet()
			bi._resist_buttons()
			bi.preview()
			return false
		"resist_confirm":
			return bi.c._magic.resistance.answer(bi.empower)
		"counter_previous", "counter_next":
			bi.counter_index = posmod(bi.counter_index + (1 if key == "counter_next" else -1), bi.counter_choices.size())
			bi.preview()
			return false
		"counter_confirm":
			if bi.selected_spell == "horn":
				return GearActions.horn(bi.c, bi.counter_choices[bi.counter_index]["piece"])
			return bi._declared(bi.c._magic.start_counter(bi.selected_spell, bi.counter_index))
		"extend_bridge":
			bi.spell_extended=not bi.spell_extended
			bi.preview()
			return false
		"rotate_spell":
			bi.spell_rotated = not bi.spell_rotated
			bi.preview()
			return false
		"intercept_yes", "intercept_no":
			return bi.c.answer_intercept(key == "intercept_yes")
		"cast":
			bi.available.assign(["spell_cancel"])
			for id in bi.cast_options:
				bi.available.append("spell_" + id)
			bi.mode = "spell_menu"
			bi.preview()
			var f := bi.c.state.active()
			if f!=null:
				bi.hud.open_spellbook(f.label(),SpellReference.battle_entries(bi.c.state,f,bi.cast_options))
			return false
		"spell_cancel":
			bi.c._magic.shatter.first.clear()
			bi.mode = ""
			bi.refresh()
			return false
		"vampire_donor","vampire_plus","vampire_minus":
			var cast := bi.mode=="empower"
			var p := bi.c.state.pending_cast if cast else bi.c.state.pending_resistance
			if key=="vampire_donor":
				VampireStaff.cycle(bi.c,p,cast)
			else:
				VampireStaff.adjust(bi.c,p,cast,1 if key=="vampire_plus" else -1)
			if cast:
				bi.empower=mini(bi.empower,bi.c.cast_max_empowerment())
				bi._empower_buttons()
			else:
				bi._resist_buttons()
			bi.preview()
			return false
		"empower_plus", "empower_minus":
			bi.empower = clampi(bi.empower + (1 if key == "empower_plus" else -1), 0, bi.c.cast_max_empowerment())
			bi._empower_buttons()
			bi.preview()
			return false
		"cast_scroll":
			return bi.c._magic.insure()
		"gem_extend","gem_reroll":
			bi.c._magic.toggle_gem(key)
			bi._empower_buttons()
			bi.preview()
			return false
		"cast_fang":
			bi.c._magic.toggle_golden_fang()
			bi._empower_buttons()
			bi.preview()
			return false
		"cast_confirm":
			return bi.c.finish_cast(bi.empower)
		"gutter_skip":
			return GearActions.gutter_skip(bi.c)
		"stay":
			return bi.c.stay_in_combat()
		"push_self":
			return bi.c.resolve_push(true)
		"push_enemy":
			return bi.c.resolve_push(false)
		"push_self_5","push_self_15","push_self_20","push_self_25","push_self_30":
			return bi.c.resolve_push(true,float(key.trim_prefix("push_self_"))/10.0)
		"group":
			bi.group_selection.assign([int(bi.c.state.early.leaders[bi.c.state.current_side()])])
			bi.mode = "group_select"
			bi._group_buttons()
			bi.preview()
			return false
		"group_cancel":
			bi.group_selection.clear()
			bi.refresh()
			return false
		"group_begin":
			if not bi.c.begin_group(bi.group_selection):
				return false
			bi.group_selection.clear()
			bi.mode = ""
			return true
		"pass_phase":
			return bi.c.finish_early_phase()
		"reload":
			return bi.c.reload()
		"end":
			bi.c.end_activation()
			bi.mode = ""
			return true
	bi.mode = key
	bi.preview()
	return false
