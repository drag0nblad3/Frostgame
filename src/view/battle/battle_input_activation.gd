class_name BattleInputActivation
extends RefCounted
## Buttons for the active figure once no reaction or scenario prompt is waiting.


## Continues BattleInputMenu.refresh with the active figure.
static func refresh_activation(bi: BattleInput, f: Figure) -> void:
	if f == null:
		if bi.c.can_begin_group():
			bi.available.append("group")
		if BattleAction.legal(bi.c,"pass_phase"):
			bi.available.append("pass_phase")
		bi.mode = "select"
		bi.preview()
		return
	if not bi.c.state.pending_cast.is_empty():
		bi.empower = 0
		bi.mode = "empower"
		bi._empower_buttons()
		bi.preview()
		return
	if bi.c.state.push_winner >= 0 and (bi.c.state.figure(bi.c.state.push_winner).side == f.side or bi.c.awaiting_reaction()):
		bi.available.append("stay")
		if bi.c.can_push(true):
			bi.available.append("push_self")
		for distance in [0.5,1.5,2.0,2.5,3.0]:
			if bi.c.can_push(true,distance):
				bi.available.append("push_self_"+str(int(distance*10)))
		if bi.c.can_push(false):
			bi.available.append("push_enemy")
		bi.mode = "push"
		bi.preview()
		return
	if bi.c.state.pending_gutter>=0:
		bi.available.assign(["gutter_skip"])
		bi.mode="gutter_fight"
		bi.preview()
		return
	if RealityCracks.can_exit_center(bi.c):
		bi.available.append("reality_exit")
	if RedKingRingworld.can_switch(bi.c,f):
		bi.available.append("ring_switch")
	if RedKingRingworld.can_escape(bi.c,f):
		bi.available.append("ring_escape")
	if BattleAction.legal(bi.c,"drink_well"):
		bi.available.append("drink_well")
	if BattleAction.legal(bi.c,"break_ice"):
		bi.available.append("break_ice")
	for weapon in bi.c.selectable_melee():
		bi.available.append("weapon_" + weapon.id)
	for id in ["gear_ring_teleportation", "gear_horn_destruction", "gear_gloves_casting", "gear_wand_light"]:
		if GearActions.can_use(bi.c,id) and (id!="gear_ring_teleportation" or not bi.is_layered() or not GearActions.teleport_floor_points(bi.c,-1,true).is_empty()) and (id!="gear_horn_destruction" or not bi.is_layered() or not bi.c._magic.crumble.options(f).is_empty()):
			bi.available.append(id)
	if not TigerEye.eye_options(bi.c).is_empty():
		bi.available.append("gear_tiger_eye_move")
	if HolyLantern.can_toggle(bi.c):
		bi.available.append("gear_lantern_toggle")
	if WormRider.ready(bi.c):
		bi.available.append("gear_worm_summon")
	if DeathMask.can_toggle(bi.c):
		bi.available.append("gear_death_mask_toggle")
	if ActiveGear.ready(f,RedKingDirection.ITEM):
		bi.available.append("gear_teetotum_arm")
	if ActiveGear.ready(f,RedKingElemental.AMULET):
		bi.available.append("gear_absorb_arm")
	if GearActions.cape_ready(bi.c) and (not bi.is_layered() or LayeredMovement.eligible(bi.c,true)):
		bi.available.append(GearActions.CAPE)
	if (not GearActions.bottle_floor_points(bi.c).is_empty() if bi.is_layered() else not GearActions.bottle_points(bi.c).is_empty()):
		bi.available.append("gear_rk_bottle_imp")
	for t in bi.c.state.figures:
		if GearActions.transfer_max(bi.c, t) > 0:
			bi.available.append("gear_ring_transference")
			break
	for item in f.items:
		var id := str(item.get("potion", ""))
		for t in bi.c.state.figures:
			if bi.c._potions.can_drink(id,t) and (id!="teleportation" or not bi.is_layered() or not bi.c._potions.teleport_floor_points(-1,true).is_empty()) and (id!="explosive_cocktail" or not bi.is_layered() or not bi.c._potions.cocktail_floor_points(-1,true).is_empty()):
				var key := "potion_" + id
				if not bi.available.has(key):
					bi.available.append(key)
				break
	for t in bi.c.state.figures:
		if bi.c._potions.can_breathe(t):
			bi.available.append("breathe_fire")
			break
	for p in bi.c.state.board.pieces:
		if p.kind.id == "spell_bridge" and p.caster_id == f.id:
			bi.available.append("cancel_bridge")
			break
	if BattleAction.legal(bi.c,"use_stored_action"):
		bi.available.append("use_stored_action")
	if RunForIt.ready(bi.c) and (not bi.is_layered() or LayeredMovement.eligible(bi.c)):
		bi.available.append("run_for_it")
	if RunForIt.ready(bi.c,true) and (not bi.is_layered() or LayeredMovement.eligible(bi.c)):
		bi.available.append("run_talisman")
	if bi.c.can_move():
		if bi.is_layered():
			if LayeredMovement.eligible(bi.c):
				bi.available.append("move")
				if not bi.c.floor_exit_nodes().is_empty():
					bi.available.append("exit")
				if not LayeredJump.plans(bi.c).is_empty():
					bi.available.append("jump")
		else:
			bi.reach=bi.c.reach()
			bi.available.append("move")
			for n: Vector2i in bi.reach.nodes():
				if bi.c.can_exit_table(n,bi.reach):
					bi.available.append("exit")
					break
	for enemy in bi.c.state.figures:
		if BattleAction.legal(bi.c,"fight_hand",enemy.id) and not bi.available.has("fight_hand"):
			bi.available.append("fight_hand")
		if BattleAction.legal(bi.c,"fight",enemy.id) and not bi.available.has("fight"):
			bi.available.append("fight")
		if BattleAction.legal(bi.c,"shoot",enemy.id) and not bi.available.has("shoot"):
			bi.available.append("shoot")
		if BattleAction.legal(bi.c,"ammo_shot",enemy.id) and not bi.available.has("ammo_shot"):
			bi.available.append("ammo_shot")
		if BattleAction.legal(bi.c,"wraith_shot",enemy.id) and not bi.available.has("wraith_shot"):
			bi.available.append("wraith_shot")
	for token in bi.c.state.treasures:
		if BattleAction.legal(bi.c,"collect",token.id):
			bi.available.append("collect")
			break
	bi.cast_options.assign(SpellAvailability.menu_options(bi.c._magic,f))
	if bi.is_layered():
		BattleFloorInput.append_spells(bi,f)
	if not bi.cast_options.is_empty():
		bi.available.append("cast")
	for t in bi.c.state.figures:
		if bi.c._magic.can_cancel(t.id):
			bi.available.append("cancel_control")
			break
	if BattleAction.legal(bi.c,"reload"):
		bi.available.append("reload")
	bi.drops.clear()
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			var at := f.pos + Vector2(dx, dy) * 0.5
			if bi.c.can_drop_treasure(at):
				bi.drops.append(at)
	if not bi.drops.is_empty():
		bi.available.append("drop")
		if f.second_treasure_id >= 0:
			bi.available.append("drop_shrunk")
	if BattleAction.legal(bi.c,"end"):
		bi.available.append("end")
	if bi.is_layered():
		# Geometry-dependent gear/potions must be migrated before exposure.
		# Shared melee, shooting, group, reaction and spell menus stay common.
		for key in bi.available.duplicate():
			if key.begins_with("gear_") and key not in [GearActions.CAPE,"gear_rk_bottle_imp","gear_death_mask_toggle","gear_gloves_casting","gear_wand_light","gear_ring_transference","gear_ring_teleportation","gear_horn_destruction","gear_tiger_eye_move","gear_teetotum_arm","gear_absorb_arm","gear_lantern_toggle","gear_worm_summon"]:
				bi.available.erase(key)
		if not LayeredBridge.owned(bi.c.state,f.id).is_empty() and not bi.available.has("cancel_bridge"):
			bi.available.append("cancel_bridge")
	# Keep equipment choices behind one button. Reactions and selected
	# item targets retain their existing dedicated confirmation controls.
	for key in bi.available.duplicate():
		if key.begins_with("weapon_") or key.begins_with("gear_") or key.begins_with("potion_") or key == "breathe_fire":
			bi.item_options.append(key)
			bi.available.erase(key)
	if not bi.item_options.is_empty():
		bi.available.insert(maxi(0, bi.available.size() - (1 if bi.available.has("end") else 0)), "items")
	if bi.available.is_empty():
		bi.preview()
		return
	if not bi.available.has(bi.mode) or bi.mode in ["reload", "end", "items"]:
		bi.mode = bi.available[0] if bi.available[0] not in ["reload", "end"] else ""
	bi.preview()
