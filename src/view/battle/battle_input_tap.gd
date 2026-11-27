class_name BattleInputTap
extends RefCounted
## Taps on the table: picking figures, points and surfaces for the current mode.


static func tap(bi: BattleInput, screen: Vector2) -> bool:
	if bi.is_layered() and (bi.mode in BattleMovePlan.MODES or bi.mode in BattleFloorInput.POINT_MODES or bi.mode=="floor_leap_target"):
		return BattleFloorInput.tap(bi,screen)
	if bi.is_layered() and bi.mode in ["gear_worm_point","worm_relocation"]:
		var best: Variant=null
		var distance:=28.0
		var points:=WormRider.relocation_points(bi.c) if bi.mode=="worm_relocation" else WormRider.points(bi.c)
		for at in points:
			var point:=WormRider.world_point(bi.c,at)
			if bi.camera.is_position_behind(point):
				continue
			var d:=bi.camera.unproject_position(point).distance_to(screen)
			if d<distance:
				best=at
				distance=d
		if best==null:
			return false
		return BattleEquipmentAction.execute(bi.c,"worm_relocation" if bi.mode=="worm_relocation" else "worm_summon",{"at":best})
	if bi.is_layered() and bi.mode=="gear_tiger_point":
		var best: Variant=null
		var distance:=28.0
		for option in TigerEye.eye_options(bi.c):
			var point: Vector3=option["world"]
			if bi.camera.is_position_behind(point):
				continue
			var d:=bi.camera.unproject_position(point).distance_to(screen)
			if d<distance:
				best=option["at"]
				distance=d
		return best!=null and BattleEquipmentAction.execute(bi.c,"tiger_eye_move",{"at":best})
	if bi.is_layered() and bi.mode=="treasure_spell":
		var best: TreasureToken
		var distance:=28.0
		for token in bi.tokens:
			if not BattleFloorInput.visible(bi,bi.c._magic.treasure_magic.origin_surface(token)):
				continue
			var point:=bi.c._magic.treasure_magic.origin_world(token)
			if bi.camera.is_position_behind(point):
				continue
			var d:=bi.camera.unproject_position(point).distance_to(screen)
			if d<distance:
				best=token
				distance=d
		if best!=null:
			bi.spell_first=best.id
			bi.mode="floor_treasure_destination"
			bi.preview()
		return false
	if bi.mode=="veil_target":
		var choice := bi._figure_at(screen)
		return choice>=0 and RedKingVeil.answer_target(bi.c,choice)
	if bi.mode=="secret_exchange":
		var choice := bi._figure_at(screen)
		return choice>=0 and RealityCracks.answer_exchange(bi.c,choice)
	if bi.mode in ["select", "fight", "shoot", "group_select", "spell_target", "cancel_control", "swap_second", "potion_target", "fight_hand", "breathe_fire", "gear_transfer_target","gutter_fight","wraith_shot","ammo_shot"]:
		var id := bi._figure_at(screen)
		if id < 0:
			return false
		match bi.mode:
			"gear_transfer_target":
				bi.transfer_target = id
				bi.transfer_amount = 1
				bi.mode = "gear_transfer_amount"
				bi._transfer_buttons()
				bi.preview()
				return false
			"breathe_fire":
				return BattleEquipmentAction.execute(bi.c,"breathe",{"target":id})
			"potion_target":
				return BattleEquipmentAction.execute(bi.c,"drink",{"id":bi.selected_potion,"target":id})
			"swap_second":
				return bi._declared(BattleSpellAction.execute(bi.c,"swap",{"target":bi.spell_first,"second":id}))
			"spell_target":
				if bi.selected_spell in ["leap", "transpose", "suggestion"]:
					bi.spell_first = id
					bi.mode = "swap_second" if bi.selected_spell=="transpose" else ("floor_suggestion" if bi.is_layered() and bi.selected_spell=="suggestion" else "leap_destination")
					bi.preview()
					return false
				return bi._declared(BattleAction.execute(bi.c,"cast",id,bi.selected_spell,bi.spell_ammo))
			"cancel_control":
				return BattleSpellAction.execute(bi.c,"cancel_control",{"target":id})
			"group_select":
				if id == int(bi.c.state.early.leaders[bi.c.state.current_side()]):
					return false
				if bi.group_selection.has(id):
					bi.group_selection.erase(id)
				elif not bi.c.state.figure(id).spell_effects.has("possess") and bi.group_selection.size() < bi.c.state.figure(bi.c.state.early.leaders[bi.c.state.current_side()]).early_limit() + 1:
					bi.group_selection.append(id)
				bi._group_buttons()
				bi.preview()
				return false
			"select": return bi.c.activate(id)
			"fight_hand": return BattleAction.execute(bi.c,"fight_hand",id)
			"gutter_fight": return BattleEquipmentAction.execute(bi.c,"gutter_fight",{"target":id})
			"fight","shoot","ammo_shot","wraith_shot":
				bi.plan_attack(id)
				return false
	var hit: Variant = bi._surface_at(screen)
	if hit == null:
		return false
	var at: Vector2 = hit
	if bi.mode=="convergence":
		var best := Vector2(INF,INF)
		var distance := 0.55
		for candidate in RealityConvergence.points(bi.c):
			if candidate.distance_to(at)<distance:
				best=candidate
				distance=candidate.distance_to(at)
		return is_finite(best.x) and RealityConvergence.answer(bi.c,best)
	if bi.mode in ["hunt_corner","hunt_place"]:
		var best := Vector2(INF,INF)
		var distance := 1.5 if bi.mode=="hunt_corner" else 0.55
		for candidate in RedKingHunt.points(bi.c):
			if candidate.distance_to(at)<distance:
				best=candidate
				distance=candidate.distance_to(at)
		return is_finite(best.x) and RedKingHunt.answer(bi.c,best)
	if bi.mode=="worm_relocation":
		var at_grid := at.round()
		return BattleEquipmentAction.execute(bi.c,"worm_relocation",{"at":at_grid})
	if bi.mode=="hill_seam":
		var unit := bi.c.state.figure(int(bi.c.state.scenario_data["rk_priority_choice"]["id"]))
		var best := Vector2(INF,INF)
		var distance := 0.65
		for candidate in RedKingHill.seam_points(bi.c,unit):
			if candidate.distance_to(at)<distance:
				best=candidate
				distance=candidate.distance_to(at)
		return is_finite(best.x) and RedKingHill.answer_seam(bi.c,best)
	if bi.mode=="ruins_piece":
		for index: int in bi.c.state.scenario_data["rk_priority_choice"]["options"]:
			if bi.c.state.board.pieces[index].rect.has_point(at):
				bi.spell_first=index
				bi.mode="ruins_destination"
				bi.available.assign(["ruins_back"])
				bi.preview()
				return false
	if bi.mode=="ruins_destination":
		var best := Vector2(INF,INF)
		var distance := 0.65
		for candidate in RealityCrackTerrain.shift_points(bi.c,bi.spell_first):
			if candidate.distance_to(at)<distance:
				best=candidate
				distance=candidate.distance_to(at)
		return is_finite(best.x) and RealityCrackTerrain.answer_shift(bi.c,bi.spell_first,best)
	if bi.mode=="mind_token":
		for token in bi.tokens:
			if at.distance_to(token.pos)<=0.9:
				bi.spell_first=token.id
				bi.mode="mind_destination"
				bi.available.assign(["mind_back","mind_skip"])
				bi.preview()
				return false
	if bi.mode=="mind_destination":
		return RedKingMind.answer_memory(bi.c,bi.spell_first,MoveGrid.to_pos(MovePlanner.node_at(at)))
	if bi.mode == "treasure_spell":
		for token in bi.tokens:
			if at.distance_to(bi.c._magic.treasure_magic.origin(token)) <= 0.9 and (not bi.is_layered() or BattleFloorInput.visible(bi,bi.c._magic.treasure_magic.origin_surface(token))):
				bi.spell_first = token.id
				bi.mode = "floor_treasure_destination" if bi.is_layered() else "treasure_destination"
				bi.preview()
				return false
	if bi.mode == "treasure_destination":
		return bi._declared(BattleSpellAction.execute(bi.c,"treasure",{"spell":bi.selected_spell,"target":bi.spell_first,"at":MoveGrid.to_pos(MovePlanner.node_at(at))}))
	if bi.mode == "leap_destination":
		var t := bi.c.state.figure(bi.spell_first)
		var destination := t.pos if bi.selected_spell == "suggestion" and at.distance_to(t.pos) < 0.4 else MoveGrid.to_pos(MovePlanner.node_at(at))
		return bi._declared(BattleSpellAction.execute(bi.c,"move",{"spell":bi.selected_spell,"target":bi.spell_first,"at":destination}))
	if bi.mode=="gear_tiger_point":
		return BattleEquipmentAction.execute(bi.c,"tiger_eye_move",{"at":at})
	if bi.mode=="gear_worm_point":
		return BattleEquipmentAction.execute(bi.c,"worm_summon",{"at":MoveGrid.to_pos(MovePlanner.node_at(at))})
	if bi.mode=="gear_bottle_imp":
		return BattleEquipmentAction.execute(bi.c,"bottle_imp",{"at":MoveGrid.to_pos(MovePlanner.node_at(at))})
	if bi.mode == "gear_teleport":
		return BattleEquipmentAction.execute(bi.c,"ring_teleport",{"at":MoveGrid.to_pos(MovePlanner.node_at(at))})
	if bi.mode == "potion_point":
		return BattleEquipmentAction.execute(bi.c,"potion_"+bi.selected_potion,{"at":at.round() if bi.selected_potion=="explosive_cocktail" else MoveGrid.to_pos(MovePlanner.node_at(at))})
	if bi.mode == "spell_point":
		var destination := at.round() if TerrainMagic.SPELLS.has(bi.selected_spell) else MoveGrid.to_pos(MovePlanner.node_at(at))
		return bi._declared(BattleSpellAction.execute(bi.c,"place",{"spell":bi.selected_spell,"at":destination,"rotated":bi.spell_rotated,"extended":bi.spell_extended}))
	if bi.mode == "collect":
		for token in bi.tokens:
			if at.distance_to(token.pos) <= 0.9 and (not bi.is_layered() or BattleFloorInput.visible(bi,token.surface_id)):
				return BattleAction.execute(bi.c,"collect",token.id)
	if bi.mode in ["drop", "drop_shrunk"]:
		for p in bi.drops:
			if at.distance_to(p) <= 0.3:
				return bi.c._loot.drop(p, bi.c.state.active().shrunk_treasure_id if bi.mode == "drop_shrunk" else -1)
	if bi.mode in BattleMovePlan.MODES:
		bi.move_plan.choose(bi,at)
		return false
	return false


static func _figure_at(bi: BattleInput, screen: Vector2) -> int:
	var id := -1
	var distance := 42.0
	for f in bi.targets:
		if bi.is_layered() and not BattleFloorInput.visible(bi,f.surface_id):
			continue
		var point := TableSpace.to_world(f.pos, 0.75 + f.elevation)
		if bi.camera.is_position_behind(point):
			continue
		var d := screen.distance_to(bi.camera.unproject_position(point))
		if d < distance:
			distance = d
			id = f.id
	return id


## Pick the nearest visible exposed surface rather than always intersecting ground.
static func _surface_at(bi: BattleInput, screen: Vector2) -> Variant:
	return BattleFloorInput.surface_point(bi,screen) if bi.is_layered() else SurfacePicker.pick(bi.c.state.board,bi.camera.project_ray_origin(screen),bi.camera.project_ray_normal(screen))


static func _declared(bi: BattleInput, ok: bool) -> bool:
	if not ok and not bi.c._magic.shatter.first.is_empty():
		var key := "spell_enchant_ammo" if bi.c._magic.shatter.first.get("effect",{}).get("magic_ammo",false) else "spell_" + str(bi.c._magic.shatter.first["id"])
		bi.available.assign([key])
		bi.action(key)
	return ok
