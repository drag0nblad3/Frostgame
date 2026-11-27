class_name BattleInput
extends RefCounted
## Player intents and legal-target previews. All mutations go through GameController.

var c: GameController
var hud: BattleHud
var camera: Camera3D
var markers: BattleMarkers
var mode := ""
var available: Array[String] = []
var reach: MoveReach
var targets: Array[Figure] = []
var tokens: Array[TreasureToken] = []
var nodes: Array[Vector2i] = []
var drops: Array[Vector2] = []
var group_selection: Array[int] = []
var cast_options: Array[String] = []
var item_options: Array[String] = []
var selected_spell := ""
var spell_ammo := false
var selected_potion := ""
var selected_drop := -1
var spell_rotated := false
var spell_extended := false
var spell_first := -1
var counter_index := 0
var counter_choices: Array[Dictionary] = []
var empower := 0
var transfer_target := -1
var transfer_amount := 1


func _init(controller: GameController, command_bar: BattleHud, cam: Camera3D, overlay: BattleMarkers) -> void:
	c = controller
	hud = command_bar
	camera = cam
	markers = overlay


func lock(hint: String) -> void:
	hud.set_actions([], "", hint)
	markers.clear()


func refresh() -> void:
	available.clear()
	item_options.clear()
	reach = null
	var f := c.state.active()
	if c.state.scenario_data.has("rk_priority_choice"):
		var kind := str(c.state.scenario_data["rk_priority_choice"].get("kind",""))
		mode=kind if kind in ["convergence","hill_seam"] else "ruins_piece"
		preview()
		return
	var end_choice: Dictionary=c.state.scenario_data.get("rk_end_choice",{})
	if end_choice.get("kind","") in ["hunt_corner","hunt_place"]:
		mode=end_choice["kind"]
		preview()
		return
	if end_choice.get("kind","")=="sinkhole_pull":
		available.assign(["sinkhole_accept","sinkhole_fight","sinkhole_will","sinkhole_all"])
		mode="sinkhole_pull"
		preview()
		return
	if end_choice.get("kind","")=="memory":
		available.assign(["mind_skip"])
		mode="mind_token"
		preview()
		return
	if end_choice.get("kind","")=="veil":
		available.assign(["veil_keep"])
		mode="veil_target"
		preview()
		return
	if end_choice.get("kind","")=="exchange":
		mode="secret_exchange"
		preview()
		return
	if c.state.pending_initiative:
		available.assign(["telescope_use", "telescope_save"])
		mode = "initiative_choice"
		preview()
		return
	if c.state.scenario_data.has("rk_lightning_absorb"):
		available.assign(["elemental_absorb","elemental_pass"])
		mode="elemental_lightning_reaction"
		preview()
		return
	if c.state.scenario_data.has("rk_direction_choice"):
		var choice: Dictionary=c.state.scenario_data["rk_direction_choice"]
		available.assign(["direction_keep"])
		if int(choice["teetotum"])>=0:
			available.append("direction_teetotum")
		if choice["gem"]:
			available.append("direction_gem")
		mode="direction_reaction"
		preview()
		return
	if c.state.scenario_data.has("rk_spell_absorption"):
		available.assign(["elemental_absorb","elemental_pass"])
		mode="elemental_spell_reaction"
		preview()
		return
	if not c.state.pending_combat.is_empty():
		if c.state.pending_combat.has("absorb_target"):
			available.assign(["elemental_absorb","elemental_pass"])
			mode="elemental_reaction"
		else:
			available.assign(["fate_combat_yes", "fate_combat_no"])
			mode = "fate_combat"
		preview()
		return
	if not c.state.pending_resistance.is_empty():
		empower = 0
		mode = "resist"
		_resist_buttons()
		preview()
		return
	if not c.state.pending_intercept.is_empty():
		available.assign(["intercept_yes", "intercept_no"])
		mode = "intercept"
		preview()
		return
	if f == null:
		if c.can_begin_group():
			available.append("group")
		if c.can_finish_early_phase():
			available.append("pass_phase")
		mode = "select"
		preview()
		return
	if not c.state.pending_cast.is_empty():
		empower = 0
		mode = "empower"
		_empower_buttons()
		preview()
		return
	if c.state.push_winner >= 0 and (c.state.figure(c.state.push_winner).side == f.side or c.awaiting_reaction()):
		available.append("stay")
		if c.can_push(true):
			available.append("push_self")
		for distance in [0.5,1.5,2.0,2.5,3.0]:
			if c.can_push(true,distance):
				available.append("push_self_"+str(int(distance*10)))
		if c.can_push(false):
			available.append("push_enemy")
		mode = "push"
		preview()
		return
	if c.state.pending_gutter>=0:
		available.assign(["gutter_skip"])
		mode="gutter_fight"
		preview()
		return
	if RealityCracks.can_exit_center(c):
		available.append("reality_exit")
	if RedKingRingworld.can_switch(c,f):
		available.append("ring_switch")
	if RedKingRingworld.can_escape(c,f):
		available.append("ring_escape")
	if c.can_drink_well():
		available.append("drink_well")
	if c.can_break_ice():
		available.append("break_ice")
	for weapon in c.selectable_melee():
		available.append("weapon_" + weapon.id)
	for id in ["gear_ring_teleportation", "gear_horn_destruction", "gear_gloves_casting", "gear_wand_light"]:
		if GearActions.can_use(c, id):
			available.append(id)
	if not TigerEye.eye_options(c).is_empty():
		available.append("gear_tiger_eye_move")
	if HolyLantern.can_toggle(c):
		available.append("gear_lantern_toggle")
	if WormRider.ready(c):
		available.append("gear_worm_summon")
	if DeathMask.can_toggle(c):
		available.append("gear_death_mask_toggle")
	if ActiveGear.ready(f,RedKingDirection.ITEM):
		available.append("gear_teetotum_arm")
	if ActiveGear.ready(f,RedKingElemental.AMULET):
		available.append("gear_absorb_arm")
	if GearActions.cape_ready(c) and c.state.board.floor_layout.is_empty():
		available.append(GearActions.CAPE)
	if not GearActions.bottle_points(c).is_empty():
		available.append("gear_rk_bottle_imp")
	for t in c.state.figures:
		if GearActions.transfer_max(c, t) > 0:
			available.append("gear_ring_transference")
			break
	for item in f.items:
		var id := str(item.get("potion", ""))
		for t in c.state.figures:
			if c._potions.can_drink(id, t):
				var key := "potion_" + id
				if not available.has(key):
					available.append(key)
				break
	for t in c.state.figures:
		if c._potions.can_breathe(t):
			available.append("breathe_fire")
			break
	for p in c.state.board.pieces:
		if p.kind.id == "spell_bridge" and p.caster_id == f.id:
			available.append("cancel_bridge")
			break
	if c.can_use_stored_action():
		available.append("use_stored_action")
	if RunForIt.ready(c):
		available.append("run_for_it")
	if RunForIt.ready(c,true):
		available.append("run_talisman")
	if c.can_move():
		reach = c.reach()
		available.append("move")
		for n: Vector2i in reach.nodes():
			if c.can_exit_table(n, reach):
				available.append("exit")
				break
	for enemy in c.state.figures:
		if c.can_fight_hand(enemy.id) and not available.has("fight_hand"):
			available.append("fight_hand")
		if c.can_fight(enemy.id) and not available.has("fight"):
			available.append("fight")
		if c.can_shoot(enemy.id) and not available.has("shoot"):
			available.append("shoot")
		if c.can_shoot(enemy.id,false,true) and not available.has("ammo_shot"):
			available.append("ammo_shot")
		if c.can_shoot(enemy.id,true) and not available.has("wraith_shot"):
			available.append("wraith_shot")
	for token in c.state.treasures:
		if c.can_pick_up(token.id):
			available.append("collect")
			break
	cast_options.clear()
	for id: String in c._magic.available_spells(f):
		if id=="enchant_weapon":
			for t in c.state.figures:
				if c.can_cast(id,t.id,true):
					cast_options.append("enchant_ammo")
					break
		if not c._magic.treasure_options(id).is_empty():
			cast_options.append(id)
			continue
		if not c._magic.counter_options(id).is_empty():
			cast_options.append(id)
			continue
		if not c._magic.placement_points(id,true).is_empty() or (id in ["fog","wall","bridge"] and not c._magic.placement_points(id,true,true).is_empty()) or (id=="bridge" and ActiveGear.ready(f,TerrainMagic.EXTENDED) and (not c._magic.placement_points(id,true,false,true).is_empty() or not c._magic.placement_points(id,true,true,true).is_empty())):
			cast_options.append(id)
			continue
		for t in c.state.figures:
			if c.can_cast(id, t.id):
				cast_options.append(id)
				break
	if not cast_options.is_empty():
		available.append("cast")
	for t in c.state.figures:
		if c._magic.can_cancel(t.id):
			available.append("cancel_control")
			break
	if c.can_reload():
		available.append("reload")
	drops.clear()
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			var at := f.pos + Vector2(dx, dy) * 0.5
			if c.can_drop_treasure(at):
				drops.append(at)
	if not drops.is_empty():
		available.append("drop")
		if f.second_treasure_id >= 0:
			available.append("drop_shrunk")
	if c.can_end_activation():
		available.append("end")
	# Keep equipment choices behind one button. Reactions and selected
	# item targets retain their existing dedicated confirmation controls.
	for key in available.duplicate():
		if key.begins_with("weapon_") or key.begins_with("gear_") or key.begins_with("potion_") or key == "breathe_fire":
			item_options.append(key)
			available.erase(key)
	if not item_options.is_empty():
		available.insert(maxi(0, available.size() - (1 if available.has("end") else 0)), "items")
	if available.is_empty():
		preview()
		return
	if not available.has(mode) or mode in ["reload", "end", "items"]:
		mode = available[0] if available[0] not in ["reload", "end"] else ""
	preview()


func preview() -> void:
	targets.clear()
	tokens.clear()
	nodes.clear()
	var points: Array[Vector2] = []
	var color := Color(0.28, 0.9, 0.8)
	var radius := 0.17
	var hint := "Tap a highlighted figure to activate."
	var f := c.state.active()
	match mode:
		"gear_transfer_target":
			for t in c.state.figures:
				if GearActions.transfer_max(c, t) > 0:
					targets.append(t)
			radius = 0.65
			hint = "Choose a wounded ally in sight."
		"gear_transfer_amount":
			var t := c.state.figure(transfer_target)
			points.append(t.pos)
			radius = 0.65
			hint = "Transfer %d Health to %s (maximum %d)." % [transfer_amount, t.label(), GearActions.transfer_max(c, t)]
			if transfer_amount == f.health:
				hint += " Warning: caster will be knocked out."
		"run_for_it","run_talisman":
			reach=RunForIt.reach(c,mode=="run_talisman")
			for n: Vector2i in reach.nodes():
				if float(reach.cost[n])>0.001:
					nodes.append(n)
					points.append(MoveGrid.to_pos(n))
			hint="Run %d″ ignoring movement penalties; ends activation."%(6 if mode=="run_talisman" else 3)
		"gear_cape_move":
			reach=GearActions.cape_reach(c)
			for n: Vector2i in reach.nodes():
				if float(reach.cost[n])>0.001:
					nodes.append(n)
					points.append(MoveGrid.to_pos(n))
			hint="Choose a legal escape move. The cape is spent only when the move is authorized."
		"gear_tiger_point":
			for option in TigerEye.eye_options(c):
				points.append(option["at"])
			hint="Move the Wizard Eye along its supporting surface (up to 4″)."
		"gear_worm_point":
			points.assign(WormRider.points(c))
			hint="Choose a worm summoning token location. On a 1 the rival relocates it."
		"gear_bottle_imp":
			points.assign(GearActions.bottle_points(c))
			hint="Place the released uncontrolled imp within 1 inch."
		"gear_teleport":
			points.assign(GearActions.teleport_points(c))
			hint = "Choose a destination within 8 inches."
		"potion_point":
			points.assign(c._potions.points(selected_potion))
			hint = "Choose the potion destination."
		"potion_coat":
			hint = "Choose melee weapon or ammunition."
		"breathe_fire":
			for t in c.state.figures:
				if c._potions.can_breathe(t):
					targets.append(t)
			radius = 0.65
			hint = "Choose a target for fire breath."
		"potion_target":
			for t in c.state.figures:
				if c._potions.can_drink(selected_potion, t):
					targets.append(t)
			radius = 0.65
			hint = "Choose a recipient for the potion."
		"spell_menu":
			hint = "Choose a spell."
		"items_menu":
			hint = "Choose equipment, a weapon, or a consumable."
		"counter_select":
			var option := counter_choices[counter_index]
			hint = "%s %d/%d: %s" % ["Choose eye face" if selected_spell == "wizard_eye" else "Destroy terrain" if selected_spell == "crumble" else "Destroy weapon" if selected_spell == "decay" else ("Choose spell" if selected_spell in ["power_word", "draining_word"] else "Cancel effect"), counter_index + 1, counter_choices.size(), option["label"]]
			if option["kind"] == "eye_face":
				points.append(option["at"])
			elif option["kind"] == "terrain":
				points.append(option["piece"].rect.get_center())
			elif option["kind"] != "storm":
				points.append(c.state.figure(option["target"]).pos)
			radius = 0.7
		"treasure_spell":
			tokens.assign(c._magic.treasure_options(selected_spell))
			for token in tokens:
				points.append(c._magic.treasure_magic.origin(token))
			radius = 0.65
			hint = "Choose a treasure to move."
		"treasure_destination":
			points.assign(c._magic.treasure_magic.points(f, selected_spell, c.state.treasure(spell_first)))
			hint = "Choose the treasure's destination."
		"leap_destination":
			if selected_spell == "suggestion":
				points.assign(c._magic.suggestion_points(c.state.figure(spell_first)))
				hint = "Choose a destination (or the figure's current position)."
			else:
				points.assign(c._magic.movement.points(f, c.state.figure(spell_first), "leap"))
				hint = "Choose a landing spot for the selected ally."
		"swap_second":
			for t in c.state.figures:
				if c.can_cast("transpose", t.id) and c._magic.movement.can_swap(f, c.state.figure(spell_first), t):
					targets.append(t)
			radius = 0.65
			hint = "Choose the second figure to swap."
		"spell_point":
			points.assign(c._magic.placement_points(selected_spell,false,spell_rotated,spell_extended))
			hint = "Choose a marked spell location."
			if selected_spell in ["fog", "wall", "bridge"]:
				hint += " · " + ("North–south" if spell_rotated else "East–west")
			if selected_spell=="bridge":
				hint+=" · %d″ bridge" % (9 if spell_extended else 6)
		"cancel_control":
			for t in c.state.figures:
				if c._magic.can_cancel(t.id):
					targets.append(t)
			radius = 0.65
			hint = "Choose a summoned or controlled creature to release."
		"spell_target":
			for t in c.state.figures:
				if c.can_cast(selected_spell,t.id,spell_ammo):
					targets.append(t)
			radius = 0.65
			hint = "Choose a bow or crossbow user to enchant ammunition." if spell_ammo else "Choose a target for %s." % c.state.spell_catalog[selected_spell]["name"]
		"resist":
			var p := c.state.pending_resistance
			var t := c.state.figure(p["id"])
			points.append(t.pos)
			radius = 0.65
			var power := mini(empower, PowerPool.available(t,str(p.get("spell",""))))
			hint = "%s resists: %d + %d Will, needs %d. Spend %d power + %d HP → %d." % [t.label(), p["raw"], p["mod"], p["tn"], power, empower - power, int(p["raw"]) + int(p["mod"]) + empower+VampireStaff.amount(c,p,false)]
			hint+=_vampire_hint(p,false)
		"empower":
			var p := c.state.pending_cast
			var power := mini(empower, PowerPool.available(c.state.figure(p["caster"]),str(p["id"])))
			hint = "%s: rolled %d (modified %d), needs %d. Spend %d power + %d HP → %d." % [c.state.spell_catalog[p["id"]]["name"], p["raw"], p["total"], p["tn"], power, empower - power, int(p["total"]) + empower+VampireStaff.amount(c,p,true)]
			hint+=_vampire_hint(p,true)
			if p.get("gem_extend",false):
				hint+=" • Blink 6″"
			if p.get("gem_reroll",false):
				hint+=" • Reroll direction"
			if p.get("golden_fang",false):
				hint+=" • Golden Fang selected: +1 Fight on success."
			if p.get("scroll", false):
				hint = "%s: scroll casting result 14. Confirm to resolve." % c.state.spell_catalog[p["id"]]["name"]
		"direction_reaction":
			var choice: Dictionary=c.state.scenario_data["rk_direction_choice"]
			var target := c.state.figure(int(choice["target"]))
			var direction := RedKingDirection.vector(int(choice["heading"]))
			var length := 6.0 if choice["kind"]=="ryce" or choice["extend"] else 4.0
			for step in range(1,int(length)+1):
				var point := target.pos+direction*float(step)
				if c.state.board.contains(point):
					points.append(point)
			hint="%s: marked random heading. Keep it or use an available item to reroll. The new heading is binding."%target.label()
		"elemental_lightning_reaction":
			var offer: Dictionary=c.state.scenario_data["rk_lightning_absorb"]
			var target := c.state.figure(int(offer["target"]))
			points.append(target.pos)
			radius=0.65
			hint="%s: %d elemental damage from Lightning Front. Reduce by 1 or risk full absorption (1–16 success; 17–20 destroys amulet and adds 3 damage)."%[target.label(),offer["damage"]]
		"elemental_spell_reaction":
			var offer: Dictionary=c.state.scenario_data["rk_spell_absorption"]
			var target := c.state.figure(int(offer["event"]["target"]))
			points.append(target.pos)
			radius=0.65
			hint="%s: %d elemental damage from %s. Reduce by 1 or risk full absorption (1–16 success; 17–20 destroys amulet and adds 3 damage)." % [target.label(),offer["damage"],str(offer["event"]["spell"]).replace("_"," ").capitalize()]
		"elemental_reaction":
			var p := c.state.pending_combat
			var target := c.state.figure(int(p["absorb_target"]))
			points.append(target.pos)
			radius=0.65
			hint="%s: %d normal + %d elemental damage. Amulet reduces elemental damage by 1, or risk full absorption (1–16 success; 17–20 destroys amulet and adds 3 damage)." % [target.label(),p["absorb_normal"],p["absorb_elemental"]]
		"fate_combat":
			var p := c.state.pending_combat
			var roller := c.state.figure(p["roller"])
			points.append(roller.pos)
			radius = 0.65
			hint = "%s rolled %d. Opposed totals: %d vs %d. Use Fate Stone? New roll is binding." % [roller.label(), p["roll"], p["own_total"], p["opposing_total"]]
		"ruins_piece":
			for index: int in c.state.scenario_data["rk_priority_choice"]["options"]:
				points.append(c.state.board.pieces[index].rect.get_center())
			radius=0.8
			hint="Shifting ruins: choose a highlighted terrain piece. Each piece can move only once."
		"ruins_destination":
			points.assign(RealityCrackTerrain.shift_points(c,spell_first))
			hint="Choose a legal new centre for the selected terrain (up to 10″). Figures and treasure on it move too."
		"hill_seam":
			var unit := c.state.figure(int(c.state.scenario_data["rk_priority_choice"]["id"]))
			points.assign(RedKingHill.seam_points(c,unit))
			radius=0.5
			hint="Pyramid forms: choose a nearby legal slope for %s."%unit.label()
		"convergence":
			points.assign(RealityConvergence.points(c))
			var figure := c.state.figure(int(c.state.scenario_data["rk_priority_choice"]["id"]))
			hint="Convergence: place %s in base contact with a figure already drawn to the centre."%figure.label()
		"hunt_corner":
			points.assign(RedKingHunt.points(c))
			radius=0.9
			hint="Hrut hunting party: select an unused corner in priority order."
		"hunt_place":
			points.assign(RedKingHunt.points(c))
			var choice: Dictionary=c.state.scenario_data["rk_end_choice"]
			hint="Deploy %s within 6″ of the chosen corner. %d remaining."%["Hrut Stinger" if choice["remaining"]==choice["total"] else "Hrut Warrior",choice["remaining"]]
		"sinkhole_pull":
			var unit := c.state.figure(int(c.state.scenario_data["rk_end_choice"]["id"]))
			points.append(unit.pos)
			radius=0.65
			hint="%s: accept 1″ pull toward the orb, or resist (TN20, Fight %+d / Will %+d). Failure costs 2 Health and still moves the figure."%[unit.label(),unit.effective_fight()+MagicEquipment.bonus(unit,"fight_test")+unit.roll_penalty(),unit.effective_will()+unit.roll_penalty()]
		"mind_token":
			for token in c.state.treasures:
				if token.on_ground():
					tokens.append(token)
					points.append(token.pos)
			radius=0.65
			hint="Mindscape: choose any remaining memory to move up to 4″, or skip."
		"mind_destination":
			points.assign(RedKingMind.memory_points(c.state,spell_first))
			hint="Choose the memory's destination (up to 4″)."
		"veil_target":
			var choice: Dictionary=c.state.scenario_data["rk_end_choice"]
			var original := c.state.figure(int(choice["target"]))
			for id: int in choice["options"]:
				var target := c.state.figure(id)
				if target!=null and target.in_play():
					targets.append(target)
			radius=0.65
			hint="Fractured Reality targets %s. Keep this target or tap another ally (+1 to the enemy's roll)." % original.label()
		"secret_exchange":
			for id: int in c.state.scenario_data["rk_end_choice"]["options"]:
				var target := c.state.figure(id)
				if target!=null and target.in_play():
					targets.append(target)
			radius=0.65
			hint="Secret exchange: choose a marked member of your warband. Rival choices are already committed."
		"initiative_choice":
			hint = "Before initiative is rolled: use the telescope for +5, or save it for a later turn?"
		"intercept":
			var choice: Dictionary = c.state.pending_intercept["choice"]
			var guard: Figure = choice["guard"]
			points.append(guard.pos)
			radius = 0.65
			hint = "%s can intercept the moving enemy. Force combat or let it pass?" % guard.label()
		"push":
			hint = "Won the fight. Stay engaged, move back, or push the opponent."
		"group_select":
			targets.assign(c.activatable())
			radius = 0.65
			hint = "Choose up to 3 soldiers with the caster. Selected: %d/4." % group_selection.size()
		"select":
			targets.assign(c.activatable())
			radius = 0.65
			if c.state.group.in_progress():
				hint = "Choose a group member for movement." if c.state.group.movement_pass() else "Choose a group member for its second action."
			elif c.can_finish_early_phase():
				hint = "Activate a nearby soldier or pass the remaining early activations."
		"move", "exit":
			if reach != null:
				for n: Vector2i in reach.nodes():
					if (mode == "move" and float(reach.cost[n]) > 0.001) or (mode == "exit" and c.can_exit_table(n, reach)):
						nodes.append(n)
						points.append(MoveGrid.to_pos(n))
			hint = "Tap a marked destination." if mode == "move" else "Tap a marked table edge to retreat."
		"fight_hand":
			for t in c.state.figures:
				if c.can_fight_hand(t.id):
					targets.append(t)
			radius = 0.65
			hint = "Attack the skeletal hand holding this figure."
		"gutter_fight":
			targets.assign(GearActions.gutter_targets(c))
			radius=0.65
			hint="Free Gutter Flail attack: select an enemy or skip."
		"ammo_shot":
			for t in c.state.figures:
				if c.can_shoot(t.id,false,true):
					targets.append(t)
			radius=0.65
			hint="Fire enchanted ammunition (%d remaining)." % MagicAmmo.count(f)
		"wraith_shot":
			for t in c.state.figures:
				if c.can_shoot(t.id,true):
					targets.append(t)
			radius=0.65
			hint="Choose a target for the once-per-battle shot through one terrain piece."
		"fight", "shoot":
			for t in c.state.figures:
				if (c.can_fight(t.id) if mode == "fight" else c.can_shoot(t.id)):
					targets.append(t)
			radius = 0.65
			color = Color(1.0, 0.35, 0.25)
			hint = "Tap a marked enemy."
		"collect":
			for token in c.state.treasures:
				if c.can_pick_up(token.id):
					tokens.append(token)
					points.append(token.pos)
			radius = 0.5
			color = Color(1.0, 0.78, 0.15)
			hint = "Tap a marked offering to investigate or collect." if RedKingInvestigations.active(c.state) else "Tap a marked treasure."
		"drop", "drop_shrunk":
			points.assign(drops)
			hint = "Tap a marked place to drop " + ("shrunk treasure." if mode == "drop_shrunk" else "treasure.")
		_:
			hint = "Choose Reload or End."
	var selected: Array[Vector2] = []
	for t in targets:
		if mode == "group_select" and group_selection.has(t.id):
			selected.append(t.pos)
		else:
			points.append(t.pos)
	markers.show_points(points, color, radius)
	if not selected.is_empty():
		markers.show_points(selected, Color(1.0, 0.78, 0.15), 0.85, true)
	if not c._magic.shatter.first.is_empty():
		hint = "Shatterstar: first attempt declared. Choose the second target before rolling. " + hint
	if f != null:
		if FuryRules.target(c.state, f) != null:
			hint = "Fury: charge or fight the nearest eligible enemy. " + hint
		if HolyLantern.lit(f):
			hint="Lantern lit"+(" · shutter at turn end. " if f.used_gear.get(HolyLantern.CLOSE,false) else ". ")+hint
		if f.used_gear.get(RedKingDirection.ARMED,false):
			hint="Direction reroll armed. "+hint
		if f.used_gear.get(RedKingElemental.ARMED,false):
			hint="Full elemental absorption armed. "+hint
		if f.next_cast_gear != "":
			hint = "Armed: %s. " % f.next_cast_gear.trim_prefix("gear_").replace("_", " ").capitalize() + hint
		hint = "%s · %d action(s) · HP %d/%d%s — %s" % [f.label(), f.actions_left, f.health, f.def.health, " · Carrying %d treasure" % f.carried_treasures().size() if f.treasure_id >= 0 else "", hint]
	if c.state.group.in_progress():
		hint = ("GROUP: Movement · " if c.state.group.movement_pass() else "GROUP: Second action · ") + hint
	hud.set_actions(available, mode, hint)


func action(key: String) -> bool:
	if not available.has(key):
		return false
	if key=="ruins_back":
		mode="ruins_piece"
		available.clear()
		preview()
		return false
	if key in ["sinkhole_accept","sinkhole_fight","sinkhole_will","sinkhole_all"]:
		return RedKingSinkhole.answer_pull(c,key.trim_prefix("sinkhole_"))
	if key=="veil_keep":
		return RedKingVeil.answer_target(c,int(c.state.scenario_data["rk_end_choice"]["target"]))
	if key=="mind_skip":
		return RedKingMind.answer_memory(c,-1)
	if key=="mind_back":
		mode="mind_token"
		available.assign(["mind_skip"])
		preview()
		return false
	if key == "items":
		available.assign(["items_back"])
		available.append_array(item_options)
		mode = "items_menu"
		preview()
		return false
	if key == "items_back":
		mode = ""
		refresh()
		return false
	if key=="reality_exit":
		return RealityCracks.exit_center(c)
	if key=="ring_switch":
		return RedKingRingworld.switch(c,c.state.active())
	if key=="ring_escape":
		return RedKingRingworld.escape(c,c.state.active())
	if key == "drink_well":
		return c.drink_well()
	if key == "break_ice":
		return c.break_ice()
	if key.begins_with("weapon_"):
		return c.select_melee(key.trim_prefix("weapon_"))
	if key in ["direction_keep","direction_teetotum","direction_gem"]:
		return RedKingDirection.answer(c,key.trim_prefix("direction_"))
	if key in ["elemental_absorb","elemental_pass"]:
		return c.answer_elemental_combat(key=="elemental_absorb")
	if key in ["fate_combat_yes", "fate_combat_no"]:
		return c.answer_fate_combat(key == "fate_combat_yes")
	if key in ["telescope_use", "telescope_save"]:
		return c.answer_initiative(key == "telescope_use")
	if key == "potion_cancel":
		mode = ""
		refresh()
		return false
	if key in ["coat_melee", "coat_ranged"]:
		return c._potions.coat(selected_potion, key == "coat_ranged")
	if key in ["gear_gloves_casting", "gear_wand_light"]:
		GearActions.arm(c, key)
		preview()
		return false
	if key == "gear_ring_transference":
		mode = "gear_transfer_target"
		available.assign(["potion_cancel"])
		preview()
		return false
	if key=="gear_tiger_eye_move":
		mode="gear_tiger_point"
		available.assign(["potion_cancel"])
		preview()
		return false
	if key=="gear_lantern_toggle":
		return HolyLantern.toggle(c)
	if key=="gear_worm_summon":
		mode="gear_worm_point"
		available.assign(["potion_cancel"])
		preview()
		return false
	if key=="gear_death_mask_toggle":
		return DeathMask.toggle(c)
	if key=="gear_teetotum_arm":
		RedKingDirection.arm(c)
		refresh()
		return false
	if key=="gear_absorb_arm":
		RedKingElemental.arm(c)
		refresh()
		return false
	if key==GearActions.CAPE:
		mode="gear_cape_move"
		available.assign(["potion_cancel"])
		preview()
		return false
	if key=="gear_rk_bottle_imp":
		mode="gear_bottle_imp"
		available.assign(["potion_cancel"])
		preview()
		return false
	if key == "gear_ring_teleportation":
		mode = "gear_teleport"
		available.assign(["potion_cancel"])
		preview()
		return false
	if key == "gear_horn_destruction":
		counter_choices = c._magic.crumble.options(c.state.active())
		if counter_choices.is_empty():
			return false
		selected_spell = "horn"
		counter_index = 0
		mode = "counter_select"
		available.assign(["spell_cancel", "counter_confirm"])
		if counter_choices.size() > 1:
			available.append("counter_previous")
			available.append("counter_next")
		preview()
		return false
	if key.begins_with("potion_"):
		selected_potion = key.trim_prefix("potion_")
		if selected_potion in PotionActions.POINTS:
			mode = "potion_point"
			available.assign(["potion_cancel"])
			preview()
			return false
		if selected_potion in PotionActions.COATINGS:
			mode = "potion_coat"
			available.assign(["potion_cancel"])
			var f := c.state.active()
			if PotionActions.can_coat(f, selected_potion, f.melee):
				available.append("coat_melee")
			if PotionActions.can_coat(f, selected_potion, f.ranged):
				available.append("coat_ranged")
			preview()
			return false
		if c.state.active().def.id == "apothecary":
			mode = "potion_target"
			available.assign(["potion_cancel"])
			preview()
			return false
		return c._potions.drink(selected_potion)
	if key == "shatter_single":
		return c._magic.single_shatter()
	if key.begins_with("spell_") and key != "spell_cancel":
		spell_ammo=key=="spell_enchant_ammo"
		selected_spell="enchant_weapon" if spell_ammo else key.trim_prefix("spell_")
		spell_rotated = false
		spell_extended=false
		if selected_spell in ["dispel", "spell_eater", "decay", "power_word", "draining_word", "crumble", "wizard_eye"]:
			counter_choices = c._magic.counter_options(selected_spell)
			if counter_choices.is_empty():
				refresh()
				return false
			counter_index = 0
			mode = "counter_select"
			available.assign(["spell_cancel", "counter_confirm"])
			if not c._magic.shatter.first.is_empty():
				available.append("shatter_single")
			if counter_choices.size() > 1:
				available.append("counter_previous")
				available.append("counter_next")
			preview()
			return false
		mode = "spell_point" if c._magic.is_placement(selected_spell) else "spell_target"
		if selected_spell in ["telekinesis", "fools_gold"]:
			mode = "treasure_spell"
		available.assign(["spell_cancel"])
		if not c._magic.shatter.first.is_empty():
			available.append("shatter_single")
		if selected_spell in ["fog", "wall", "bridge"]:
			available.append("rotate_spell")
		if selected_spell=="bridge" and ActiveGear.ready(c.state.active(),TerrainMagic.EXTENDED):
			available.append("extend_bridge")
		preview()
		return false
	match key:
		"transfer_plus", "transfer_minus":
			transfer_amount = clampi(transfer_amount + (1 if key == "transfer_plus" else -1), 1, GearActions.transfer_max(c, c.state.figure(transfer_target)))
			_transfer_buttons()
			preview()
			return false
		"transfer_confirm":
			return GearActions.transfer(c, c.state.figure(transfer_target), transfer_amount)
		"cancel_bridge":
			return c._magic.terrain.cancel_bridge(c.state.active())
		"use_stored_action":
			return c.use_stored_action()
		"resist_plus", "resist_minus":
			empower = clampi(empower + (1 if key == "resist_plus" else -1), 0, int(c.state.pending_resistance["max"]))
			_resist_buttons()
			preview()
			return false
		"resist_fate":
			c._magic.resistance.reroll_fate()
			empower = 0
			_resist_buttons()
			preview()
			return false
		"cast_fate":
			c._magic.reroll_fate()
			empower = 0
			_empower_buttons()
			preview()
			return false
		"resist_amulet":
			c._magic.resistance.use_amulet()
			_resist_buttons()
			preview()
			return false
		"resist_confirm":
			return c._magic.resistance.answer(empower)
		"counter_previous", "counter_next":
			counter_index = posmod(counter_index + (1 if key == "counter_next" else -1), counter_choices.size())
			preview()
			return false
		"counter_confirm":
			if selected_spell == "horn":
				return GearActions.horn(c, counter_choices[counter_index]["piece"])
			return _declared(c._magic.start_counter(selected_spell, counter_index))
		"extend_bridge":
			spell_extended=not spell_extended
			preview()
			return false
		"rotate_spell":
			spell_rotated = not spell_rotated
			preview()
			return false
		"intercept_yes", "intercept_no":
			return c.answer_intercept(key == "intercept_yes")
		"cast":
			available.assign(["spell_cancel"])
			for id in cast_options:
				available.append("spell_" + id)
			mode = "spell_menu"
			preview()
			return false
		"spell_cancel":
			c._magic.shatter.first.clear()
			mode = ""
			refresh()
			return false
		"vampire_donor","vampire_plus","vampire_minus":
			var cast := mode=="empower"
			var p := c.state.pending_cast if cast else c.state.pending_resistance
			if key=="vampire_donor":
				VampireStaff.cycle(c,p,cast)
			else:
				VampireStaff.adjust(c,p,cast,1 if key=="vampire_plus" else -1)
			if cast:
				empower=mini(empower,c.cast_max_empowerment())
				_empower_buttons()
			else:
				_resist_buttons()
			preview()
			return false
		"empower_plus", "empower_minus":
			empower = clampi(empower + (1 if key == "empower_plus" else -1), 0, c.cast_max_empowerment())
			_empower_buttons()
			preview()
			return false
		"cast_scroll":
			return c._magic.insure()
		"gem_extend","gem_reroll":
			c._magic.toggle_gem(key)
			_empower_buttons()
			preview()
			return false
		"cast_fang":
			c._magic.toggle_golden_fang()
			_empower_buttons()
			preview()
			return false
		"cast_confirm":
			return c.finish_cast(empower)
		"gutter_skip":
			return GearActions.gutter_skip(c)
		"stay":
			return c.stay_in_combat()
		"push_self":
			return c.resolve_push(true)
		"push_enemy":
			return c.resolve_push(false)
		"push_self_5","push_self_15","push_self_20","push_self_25","push_self_30":
			return c.resolve_push(true,float(key.trim_prefix("push_self_"))/10.0)
		"group":
			group_selection.assign([int(c.state.early.leaders[c.state.current_side()])])
			mode = "group_select"
			_group_buttons()
			preview()
			return false
		"group_cancel":
			group_selection.clear()
			refresh()
			return false
		"group_begin":
			if not c.begin_group(group_selection):
				return false
			group_selection.clear()
			mode = ""
			return true
		"pass_phase":
			return c.finish_early_phase()
		"reload":
			return c.reload()
		"end":
			c.end_activation()
			mode = ""
			return true
	mode = key
	preview()
	return false


func tap(screen: Vector2) -> bool:
	if mode=="veil_target":
		var choice := _figure_at(screen)
		return choice>=0 and RedKingVeil.answer_target(c,choice)
	if mode=="secret_exchange":
		var choice := _figure_at(screen)
		return choice>=0 and RealityCracks.answer_exchange(c,choice)
	if mode in ["select", "fight", "shoot", "group_select", "spell_target", "cancel_control", "swap_second", "potion_target", "fight_hand", "breathe_fire", "gear_transfer_target","gutter_fight","wraith_shot","ammo_shot"]:
		var id := _figure_at(screen)
		if id < 0:
			return false
		match mode:
			"gear_transfer_target":
				transfer_target = id
				transfer_amount = 1
				mode = "gear_transfer_amount"
				_transfer_buttons()
				preview()
				return false
			"breathe_fire":
				return c._potions.breathe(c.state.figure(id))
			"potion_target":
				return c._potions.drink(selected_potion, c.state.figure(id))
			"swap_second":
				return _declared(c._magic.start_swap(spell_first, id))
			"spell_target":
				if selected_spell in ["leap", "transpose", "suggestion"]:
					spell_first = id
					mode = "swap_second" if selected_spell == "transpose" else "leap_destination"
					preview()
					return false
				return _declared(c.start_cast(selected_spell,id,spell_ammo))
			"cancel_control":
				return c._magic.cancel(id)
			"group_select":
				if id == int(c.state.early.leaders[c.state.current_side()]):
					return false
				if group_selection.has(id):
					group_selection.erase(id)
				elif not c.state.figure(id).spell_effects.has("possess") and group_selection.size() < c.state.figure(c.state.early.leaders[c.state.current_side()]).early_limit() + 1:
					group_selection.append(id)
				_group_buttons()
				preview()
				return false
			"select": return c.activate(id)
			"fight_hand": return c.fight_hand(id)
			"gutter_fight": return GearActions.gutter_fight(c,id)
			"fight": return c.fight(id)
			"ammo_shot": return c.shoot(id,false,true)
			"wraith_shot": return c.shoot(id,true)
			"shoot": return c.shoot(id)
	var hit: Variant = _surface_at(screen)
	if hit == null:
		return false
	var at: Vector2 = hit
	if mode=="convergence":
		var best := Vector2(INF,INF)
		var distance := 0.55
		for candidate in RealityConvergence.points(c):
			if candidate.distance_to(at)<distance:
				best=candidate
				distance=candidate.distance_to(at)
		return is_finite(best.x) and RealityConvergence.answer(c,best)
	if mode in ["hunt_corner","hunt_place"]:
		var best := Vector2(INF,INF)
		var distance := 1.5 if mode=="hunt_corner" else 0.55
		for candidate in RedKingHunt.points(c):
			if candidate.distance_to(at)<distance:
				best=candidate
				distance=candidate.distance_to(at)
		return is_finite(best.x) and RedKingHunt.answer(c,best)
	if mode=="hill_seam":
		var unit := c.state.figure(int(c.state.scenario_data["rk_priority_choice"]["id"]))
		var best := Vector2(INF,INF)
		var distance := 0.65
		for candidate in RedKingHill.seam_points(c,unit):
			if candidate.distance_to(at)<distance:
				best=candidate
				distance=candidate.distance_to(at)
		return is_finite(best.x) and RedKingHill.answer_seam(c,best)
	if mode=="ruins_piece":
		for index: int in c.state.scenario_data["rk_priority_choice"]["options"]:
			if c.state.board.pieces[index].rect.has_point(at):
				spell_first=index
				mode="ruins_destination"
				available.assign(["ruins_back"])
				preview()
				return false
	if mode=="ruins_destination":
		var best := Vector2(INF,INF)
		var distance := 0.65
		for candidate in RealityCrackTerrain.shift_points(c,spell_first):
			if candidate.distance_to(at)<distance:
				best=candidate
				distance=candidate.distance_to(at)
		return is_finite(best.x) and RealityCrackTerrain.answer_shift(c,spell_first,best)
	if mode=="mind_token":
		for token in tokens:
			if at.distance_to(token.pos)<=0.9:
				spell_first=token.id
				mode="mind_destination"
				available.assign(["mind_back","mind_skip"])
				preview()
				return false
	if mode=="mind_destination":
		return RedKingMind.answer_memory(c,spell_first,MoveGrid.to_pos(MovePlanner.node_at(at)))
	if mode == "treasure_spell":
		for token in tokens:
			if at.distance_to(c._magic.treasure_magic.origin(token)) <= 0.9:
				spell_first = token.id
				mode = "treasure_destination"
				preview()
				return false
	if mode == "treasure_destination":
		return _declared(c._magic.start_treasure(selected_spell, spell_first, MoveGrid.to_pos(MovePlanner.node_at(at))))
	if mode == "leap_destination":
		var t := c.state.figure(spell_first)
		var destination := t.pos if selected_spell == "suggestion" and at.distance_to(t.pos) < 0.4 else MoveGrid.to_pos(MovePlanner.node_at(at))
		return _declared(c._magic.start_move(selected_spell, spell_first, destination))
	if mode=="gear_tiger_point":
		return TigerEye.move_eye(c,at)
	if mode=="gear_worm_point":
		return WormRider.summon(c,MoveGrid.to_pos(MovePlanner.node_at(at)))
	if mode=="gear_bottle_imp":
		return GearActions.bottle_imp(c,MoveGrid.to_pos(MovePlanner.node_at(at)))
	if mode == "gear_teleport":
		return GearActions.teleport(c, MoveGrid.to_pos(MovePlanner.node_at(at)))
	if mode == "potion_point":
		return c._potions.use_at(selected_potion, at.round() if selected_potion == "explosive_cocktail" else MoveGrid.to_pos(MovePlanner.node_at(at)))
	if mode == "spell_point":
		var destination := at.round() if TerrainMagic.SPELLS.has(selected_spell) else MoveGrid.to_pos(MovePlanner.node_at(at))
		return _declared(c._magic.start_at(selected_spell,destination,spell_rotated,spell_extended))
	if mode == "collect":
		for token in tokens:
			if at.distance_to(token.pos) <= 0.9:
				return c.pick_up(token.id)
	if mode in ["drop", "drop_shrunk"]:
		for p in drops:
			if at.distance_to(p) <= 0.3:
				return c._loot.drop(p, c.state.active().shrunk_treasure_id if mode == "drop_shrunk" else -1)
	if mode in ["run_for_it","run_talisman"]:
		var n := MovePlanner.node_at(at)
		return nodes.has(n) and RunForIt.apply(c,n,mode=="run_talisman")
	if mode=="gear_cape_move":
		var n := MovePlanner.node_at(at)
		return nodes.has(n) and c.move_to(n,true)
	if mode in ["move", "exit"]:
		var n := MovePlanner.node_at(at)
		if nodes.has(n):
			return c.move_to(n) if mode == "move" else c.exit_table(n)
	return false


func _figure_at(screen: Vector2) -> int:
	var id := -1
	var distance := 42.0
	for f in targets:
		var point := TableSpace.to_world(f.pos, 0.75 + f.elevation)
		if camera.is_position_behind(point):
			continue
		var d := screen.distance_to(camera.unproject_position(point))
		if d < distance:
			distance = d
			id = f.id
	return id


func _group_buttons() -> void:
	available.assign(["group_cancel"])
	if group_selection.size() >= 2:
		available.append("group_begin")


func _empower_buttons() -> void:
	available.assign(["cast_confirm"])
	var p := c.state.pending_cast
	var caster := c.state.figure(p["caster"])
	if not p.get("scroll",false) and not PowerPool.words_only(caster,str(p["id"])):
		_vampire_buttons(p,true,caster)
	if p.get("id","")=="blink" and ActiveGear.has(caster,PowerPool.GEM) and not MagicEquipment.suppressed(caster):
		available.append("gem_extend")
	if p.get("id","")=="animate_skull" and RedKingMaterials.fang_count(c.state.figure(p["caster"]))>0:
		available.append("cast_fang")
	if not p.get("scroll", false) and ActiveGear.ready(c.state.figure(p["caster"]), "gear_fate_stone"):
		available.append("cast_fate")
	if c._magic.can_insure():
		available.append("cast_scroll")
	if empower < c.cast_max_empowerment():
		available.append("empower_plus")
	if empower > 0:
		available.append("empower_minus")


## Pick the nearest visible exposed surface rather than always intersecting ground.
func _surface_at(screen: Vector2) -> Variant:
	return SurfacePicker.pick(c.state.board,camera.project_ray_origin(screen),camera.project_ray_normal(screen))

func _resist_buttons() -> void:
	available.assign(["resist_confirm"])
	var p := c.state.pending_resistance
	if int(p["raw"]) not in [1,20]:
		_vampire_buttons(p,false,c.state.figure(p["id"]))
	if ActiveGear.ready(c.state.figure(p["id"]), "gear_fate_stone"):
		available.append("resist_fate")
	if int(p["raw"]) != 1 and ActiveGear.ready(c.state.figure(p["id"]), "gear_amulet_resistance"):
		available.append("resist_amulet")
	if empower < int(c.state.pending_resistance["max"]):
		available.append("resist_plus")
	if empower > 0:
		available.append("resist_minus")


func _declared(ok: bool) -> bool:
	if not ok and not c._magic.shatter.first.is_empty():
		var key := "spell_enchant_ammo" if c._magic.shatter.first.get("effect",{}).get("magic_ammo",false) else "spell_" + str(c._magic.shatter.first["id"])
		available.assign([key])
		action(key)
	return ok


func _transfer_buttons() -> void:
	available.assign(["potion_cancel", "transfer_confirm"])
	if transfer_amount > 1:
		available.append("transfer_minus")
	if transfer_amount < GearActions.transfer_max(c, c.state.figure(transfer_target)):
		available.append("transfer_plus")


func _vampire_buttons(p: Dictionary,cast: bool,f: Figure) -> void:
	if VampireStaff.donors(c.state,f).is_empty():
		return
	available.append("vampire_donor")
	if VampireStaff.amount(c,p,cast)<VampireStaff.cap(c,p,cast):
		available.append("vampire_plus")
	if VampireStaff.amount(c,p,cast)>0:
		available.append("vampire_minus")


func _vampire_hint(p: Dictionary,cast: bool) -> String:
	var donor := c.state.figure(int(p.get("vampire_donor",-1)))
	if donor==null:
		return ""
	var amount := VampireStaff.amount(c,p,cast)
	return " • Vampire Staff: %s, +%d for %d Health; surviving donor deserts."%[donor.label(),amount,amount*3]
