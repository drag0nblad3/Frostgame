class_name BattleInputTap
extends RefCounted
## Taps on the table: picking figures, points and surfaces for the current mode.


static func tap(bi: BattleInput, screen: Vector2) -> bool:
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
				return bi.c._potions.breathe(bi.c.state.figure(id))
			"potion_target":
				return bi.c._potions.drink(bi.selected_potion, bi.c.state.figure(id))
			"swap_second":
				return bi._declared(bi.c._magic.start_swap(bi.spell_first, id))
			"spell_target":
				if bi.selected_spell in ["leap", "transpose", "suggestion"]:
					bi.spell_first = id
					bi.mode = "swap_second" if bi.selected_spell == "transpose" else "leap_destination"
					bi.preview()
					return false
				return bi._declared(bi.c.start_cast(bi.selected_spell,id,bi.spell_ammo))
			"cancel_control":
				return bi.c._magic.cancel(id)
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
			"fight_hand": return bi.c.fight_hand(id)
			"gutter_fight": return GearActions.gutter_fight(bi.c,id)
			"fight", "shoot":
				bi.plan_attack(id)
				return false
			"ammo_shot": return bi.c.shoot(id,false,true)
			"wraith_shot": return bi.c.shoot(id,true)
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
		return WormRider.answer_relocation(bi.c,at_grid)
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
			if at.distance_to(bi.c._magic.treasure_magic.origin(token)) <= 0.9:
				bi.spell_first = token.id
				bi.mode = "treasure_destination"
				bi.preview()
				return false
	if bi.mode == "treasure_destination":
		return bi._declared(bi.c._magic.start_treasure(bi.selected_spell, bi.spell_first, MoveGrid.to_pos(MovePlanner.node_at(at))))
	if bi.mode == "leap_destination":
		var t := bi.c.state.figure(bi.spell_first)
		var destination := t.pos if bi.selected_spell == "suggestion" and at.distance_to(t.pos) < 0.4 else MoveGrid.to_pos(MovePlanner.node_at(at))
		return bi._declared(bi.c._magic.start_move(bi.selected_spell, bi.spell_first, destination))
	if bi.mode=="gear_tiger_point":
		return TigerEye.move_eye(bi.c,at)
	if bi.mode=="gear_worm_point":
		return WormRider.summon(bi.c,MoveGrid.to_pos(MovePlanner.node_at(at)))
	if bi.mode=="gear_bottle_imp":
		return GearActions.bottle_imp(bi.c,MoveGrid.to_pos(MovePlanner.node_at(at)))
	if bi.mode == "gear_teleport":
		return GearActions.teleport(bi.c, MoveGrid.to_pos(MovePlanner.node_at(at)))
	if bi.mode == "potion_point":
		return bi.c._potions.use_at(bi.selected_potion, at.round() if bi.selected_potion == "explosive_cocktail" else MoveGrid.to_pos(MovePlanner.node_at(at)))
	if bi.mode == "spell_point":
		var destination := at.round() if TerrainMagic.SPELLS.has(bi.selected_spell) else MoveGrid.to_pos(MovePlanner.node_at(at))
		return bi._declared(bi.c._magic.start_at(bi.selected_spell,destination,bi.spell_rotated,bi.spell_extended))
	if bi.mode == "collect":
		for token in bi.tokens:
			if at.distance_to(token.pos) <= 0.9:
				return bi.c.pick_up(token.id)
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
	return SurfacePicker.pick(bi.c.state.board,bi.camera.project_ray_origin(screen),bi.camera.project_ray_normal(screen))


static func _declared(bi: BattleInput, ok: bool) -> bool:
	if not ok and not bi.c._magic.shatter.first.is_empty():
		var key := "spell_enchant_ammo" if bi.c._magic.shatter.first.get("effect",{}).get("magic_ammo",false) else "spell_" + str(bi.c._magic.shatter.first["id"])
		bi.available.assign([key])
		bi.action(key)
	return ok
