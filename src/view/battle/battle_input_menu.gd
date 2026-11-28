class_name BattleInputMenu
extends RefCounted
## Builds the button list: reaction and scenario prompts first, then BattleInputActivation.


static func refresh(bi: BattleInput) -> void:
	bi.available.clear()
	bi.item_options.clear()
	bi.reach = null
	var core:=CoreScenarioChoice.pending(bi.c)
	if not core.is_empty():
		bi.mode="core_choice"
		if core["kind"]=="column":
			bi.available.assign(["core_collect","core_leave"])
		bi.preview()
		return
	var weapon_choice:=MeleeWeaponChoice.pending(bi.c)
	if not weapon_choice.is_empty():
		bi.mode="melee_weapon_choice"
		var owner:=bi.c.state.figure(int(weapon_choice["owner"]))
		for w in MeleeWeaponChoice.options(owner):
			bi.available.append("combat_weapon_"+w.id)
		bi.preview()
		return
	var f := bi.c.state.active()
	if bi.c.state.scenario_data.has("rk_priority_choice"):
		var kind := str(bi.c.state.scenario_data["rk_priority_choice"].get("kind",""))
		bi.mode=kind if kind in ["convergence","hill_seam"] else "ruins_piece"
		bi.preview()
		return
	var end_choice: Dictionary=bi.c.state.scenario_data.get("rk_end_choice",{})
	if end_choice.get("kind","") in ["hunt_corner","hunt_place"]:
		bi.mode=end_choice["kind"]
		bi.preview()
		return
	if end_choice.get("kind","")=="sinkhole_pull":
		bi.available.assign(["sinkhole_accept","sinkhole_fight","sinkhole_will","sinkhole_all"])
		bi.mode="sinkhole_pull"
		bi.preview()
		return
	if end_choice.get("kind","")=="memory":
		bi.available.assign(["mind_skip"])
		bi.mode="mind_token"
		bi.preview()
		return
	if end_choice.get("kind","")=="veil":
		bi.available.assign(["veil_keep"])
		bi.mode="veil_target"
		bi.preview()
		return
	if end_choice.get("kind","")=="random_exchange_single":
		bi.available.assign(["exchange_join","exchange_decline"])
		bi.mode="random_exchange_single"
		bi.preview()
		return
	if end_choice.get("kind","")=="exchange":
		bi.mode="secret_exchange"
		bi.preview()
		return
	if bi.c.state.pending_initiative:
		bi.available.assign(["telescope_use", "telescope_save"])
		bi.mode = "initiative_choice"
		bi.preview()
		return
	if bi.c.state.scenario_data.has("rk_worm_relocation"):
		bi.available.assign(["worm_keep"])
		bi.mode="worm_relocation"
		bi.preview()
		return
	if bi.c.state.scenario_data.has("rk_lightning_absorb"):
		bi.available.assign(["elemental_absorb","elemental_pass"])
		bi.mode="elemental_lightning_reaction"
		bi.preview()
		return
	if bi.c.state.scenario_data.has("rk_direction_choice"):
		var choice: Dictionary=bi.c.state.scenario_data["rk_direction_choice"]
		bi.available.assign(["direction_keep"])
		if int(choice["teetotum"])>=0:
			bi.available.append("direction_teetotum")
		if choice["gem"]:
			bi.available.append("direction_gem")
		bi.mode="direction_reaction"
		bi.preview()
		return
	if bi.c.state.scenario_data.has("rk_spell_absorption"):
		bi.available.assign(["elemental_absorb","elemental_pass"])
		bi.mode="elemental_spell_reaction"
		bi.preview()
		return
	if not bi.c.state.pending_combat.is_empty():
		if bi.c.state.pending_combat.has("absorb_target"):
			bi.available.assign(["elemental_absorb","elemental_pass"])
			bi.mode="elemental_reaction"
		else:
			bi.available.assign(["fate_combat_yes", "fate_combat_no"])
			bi.mode = "fate_combat"
		bi.preview()
		return
	if not bi.c.state.pending_resistance.is_empty():
		bi.empower = 0
		bi.mode = "resist"
		bi._resist_buttons()
		bi.preview()
		return
	if not bi.c.state.pending_intercept.is_empty():
		bi.available.assign(["intercept_yes", "intercept_no"])
		bi.mode = "intercept"
		bi.preview()
		return
	BattleInputActivation.refresh_activation(bi, f)


static func _group_buttons(bi: BattleInput) -> void:
	bi.available.assign(["group_cancel"])
	if bi.group_selection.size() >= 2:
		bi.available.append("group_begin")


static func _empower_buttons(bi: BattleInput) -> void:
	bi.available.assign(["cast_confirm"])
	var p := bi.c.state.pending_cast
	var caster := bi.c.state.figure(p["caster"])
	if not p.get("scroll",false) and not PowerPool.words_only(caster,str(p["id"])):
		bi._vampire_buttons(p,true,caster)
	if p.get("id","")=="blink" and ActiveGear.has(caster,PowerPool.GEM) and not MagicEquipment.suppressed(caster):
		bi.available.append("gem_extend")
	if p.get("id","")=="animate_skull" and RedKingMaterials.fang_count(bi.c.state.figure(p["caster"]))>0:
		bi.available.append("cast_fang")
	if not p.get("scroll", false) and ActiveGear.ready(bi.c.state.figure(p["caster"]), "gear_fate_stone"):
		bi.available.append("cast_fate")
	if bi.c._magic.can_insure():
		bi.available.append("cast_scroll")
	if bi.empower < bi.c.cast_max_empowerment():
		bi.available.append("empower_plus")
	if bi.empower > 0:
		bi.available.append("empower_minus")


static func _resist_buttons(bi: BattleInput) -> void:
	bi.available.assign(["resist_confirm"])
	var p := bi.c.state.pending_resistance
	if int(p["raw"]) not in [1,20]:
		bi._vampire_buttons(p,false,bi.c.state.figure(p["id"]))
	if ActiveGear.ready(bi.c.state.figure(p["id"]), "gear_fate_stone"):
		bi.available.append("resist_fate")
	if int(p["raw"]) != 1 and ActiveGear.ready(bi.c.state.figure(p["id"]), "gear_amulet_resistance"):
		bi.available.append("resist_amulet")
	if bi.empower < int(bi.c.state.pending_resistance["max"]):
		bi.available.append("resist_plus")
	if bi.empower > 0:
		bi.available.append("resist_minus")


static func _transfer_buttons(bi: BattleInput) -> void:
	bi.available.assign(["potion_cancel", "transfer_confirm"])
	if bi.transfer_amount > 1:
		bi.available.append("transfer_minus")
	if bi.transfer_amount < GearActions.transfer_max(bi.c, bi.c.state.figure(bi.transfer_target)):
		bi.available.append("transfer_plus")


static func _vampire_buttons(bi: BattleInput, p: Dictionary,cast: bool,f: Figure) -> void:
	if VampireStaff.donors(bi.c.state,f).is_empty():
		return
	bi.available.append("vampire_donor")
	if VampireStaff.amount(bi.c,p,cast)<VampireStaff.cap(bi.c,p,cast):
		bi.available.append("vampire_plus")
	if VampireStaff.amount(bi.c,p,cast)>0:
		bi.available.append("vampire_minus")


static func _vampire_hint(bi: BattleInput, p: Dictionary,cast: bool) -> String:
	var donor := bi.c.state.figure(int(p.get("vampire_donor",-1)))
	if donor==null:
		return ""
	var amount := VampireStaff.amount(bi.c,p,cast)
	return " • Vampire Staff: %s, +%d for %d Health; surviving donor deserts."%[donor.label(),amount,amount*3]
