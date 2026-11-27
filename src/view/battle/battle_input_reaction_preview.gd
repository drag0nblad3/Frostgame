class_name BattleInputReactionPreview
extends RefCounted
## Highlights for reactions, scenario prompts and basic activation modes.


## Fills `s` for reaction, scenario and basic modes.
static func reactions(bi: BattleInput, f: Figure, s: BattleInputPreview.State) -> bool:
	match bi.mode:
		"direction_reaction":
			var choice: Dictionary=bi.c.state.scenario_data["rk_direction_choice"]
			var target := bi.c.state.figure(int(choice["target"]))
			var direction := RedKingDirection.vector(int(choice["heading"]))
			var length := 6.0 if choice["kind"]=="ryce" or choice["extend"] else 4.0
			for step in range(1,int(length)+1):
				var point := target.pos+direction*float(step)
				if bi.c.state.board.contains(point):
					s.points.append(point)
			s.hint="%s: marked random heading. Keep it or use an available item to reroll. The new heading is binding."%target.label()
		"elemental_lightning_reaction":
			var offer: Dictionary=bi.c.state.scenario_data["rk_lightning_absorb"]
			var target := bi.c.state.figure(int(offer["target"]))
			s.points.append(target.pos)
			s.radius=0.65
			s.hint="%s: %d elemental damage from Lightning Front. Reduce by 1 or risk full absorption (1–16 success; 17–20 destroys amulet and adds 3 damage)."%[target.label(),offer["damage"]]
		"elemental_spell_reaction":
			var offer: Dictionary=bi.c.state.scenario_data["rk_spell_absorption"]
			var target := bi.c.state.figure(int(offer["event"]["target"]))
			s.points.append(target.pos)
			s.radius=0.65
			s.hint="%s: %d elemental damage from %s. Reduce by 1 or risk full absorption (1–16 success; 17–20 destroys amulet and adds 3 damage)." % [target.label(),offer["damage"],str(offer["event"]["spell"]).replace("_"," ").capitalize()]
		"elemental_reaction":
			var p := bi.c.state.pending_combat
			var target := bi.c.state.figure(int(p["absorb_target"]))
			s.points.append(target.pos)
			s.radius=0.65
			s.hint="%s: %d normal + %d elemental damage. Amulet reduces elemental damage by 1, or risk full absorption (1–16 success; 17–20 destroys amulet and adds 3 damage)." % [target.label(),p["absorb_normal"],p["absorb_elemental"]]
		"fate_combat":
			var p := bi.c.state.pending_combat
			var roller := bi.c.state.figure(p["roller"])
			s.points.append(roller.pos)
			s.radius = 0.65
			s.hint = "%s rolled %d. Opposed totals: %d vs %d. Use Fate Stone? New roll is binding." % [roller.label(), p["roll"], p["own_total"], p["opposing_total"]]
		"ruins_piece":
			for index: int in bi.c.state.scenario_data["rk_priority_choice"]["options"]:
				s.points.append(bi.c.state.board.pieces[index].rect.get_center())
			s.radius=0.8
			s.hint="Shifting ruins: choose a highlighted terrain piece. Each piece can move only once."
		"ruins_destination":
			s.points.assign(RealityCrackTerrain.shift_points(bi.c,bi.spell_first))
			s.hint="Choose a legal new centre for the selected terrain (up to 10″). Figures and treasure on it move too."
		"worm_relocation":
			s.points.assign(WormRider.relocation_points(bi.c))
			s.hint="Rival worm summoning rolled 1. Select a new legal location for the token, or keep its original location."
		"hill_seam":
			var unit := bi.c.state.figure(int(bi.c.state.scenario_data["rk_priority_choice"]["id"]))
			s.points.assign(RedKingHill.seam_points(bi.c,unit))
			s.radius=0.5
			s.hint="Pyramid forms: choose a nearby legal slope for %s."%unit.label()
		"convergence":
			s.points.assign(RealityConvergence.points(bi.c))
			var figure := bi.c.state.figure(int(bi.c.state.scenario_data["rk_priority_choice"]["id"]))
			s.hint="Convergence: place %s in base contact with a figure already drawn to the centre."%figure.label()
		"hunt_corner":
			s.points.assign(RedKingHunt.points(bi.c))
			s.radius=0.9
			s.hint="Hrut hunting party: select an unused corner in priority order."
		"hunt_place":
			s.points.assign(RedKingHunt.points(bi.c))
			var choice: Dictionary=bi.c.state.scenario_data["rk_end_choice"]
			s.hint="Deploy %s within 6″ of the chosen corner. %d remaining."%["Hrut Stinger" if choice["remaining"]==choice["total"] else "Hrut Warrior",choice["remaining"]]
		"sinkhole_pull":
			var unit := bi.c.state.figure(int(bi.c.state.scenario_data["rk_end_choice"]["id"]))
			s.points.append(unit.pos)
			s.radius=0.65
			s.hint="%s: accept 1″ pull toward the orb, or resist (TN20, Fight %+d / Will %+d). Failure costs 2 Health and still moves the figure."%[unit.label(),unit.effective_fight()+MagicEquipment.bonus(unit,"fight_test")+unit.roll_penalty(),unit.effective_will()+unit.roll_penalty()]
		"mind_token":
			for token in bi.c.state.treasures:
				if token.on_ground():
					bi.tokens.append(token)
					s.points.append(token.pos)
			s.radius=0.65
			s.hint="Mindscape: choose any remaining memory to move up to 4″, or skip."
		"mind_destination":
			s.points.assign(RedKingMind.memory_points(bi.c.state,bi.spell_first))
			s.hint="Choose the memory's destination (up to 4″)."
		"veil_target":
			var choice: Dictionary=bi.c.state.scenario_data["rk_end_choice"]
			var original := bi.c.state.figure(int(choice["target"]))
			for id: int in choice["options"]:
				var target := bi.c.state.figure(id)
				if target!=null and target.in_play():
					bi.targets.append(target)
			s.radius=0.65
			s.hint="Fractured Reality targets %s. Keep this target or tap another ally (+1 to the enemy's roll)." % original.label()
		"random_exchange_single":
			var unit := bi.c.state.figure(int(bi.c.state.scenario_data["rk_end_choice"]["options"][0]))
			s.points.append(unit.pos)
			s.radius=0.65
			s.hint="%s is your last figure. Participate in the random exchange or remain in place?"%unit.label()
		"secret_exchange":
			for id: int in bi.c.state.scenario_data["rk_end_choice"]["options"]:
				var target := bi.c.state.figure(id)
				if target!=null and target.in_play():
					bi.targets.append(target)
			s.radius=0.65
			s.hint="Secret exchange: choose a marked member of your warband. Rival choices are already committed."
		"initiative_choice":
			s.hint = "Before initiative is rolled: use the telescope for +5, or save it for a later turn?"
		"intercept":
			var choice: Dictionary = bi.c.state.pending_intercept["choice"]
			var guard: Figure = choice["guard"]
			s.points.append(guard.pos)
			s.radius = 0.65
			s.hint = "%s can intercept the moving enemy. Force combat or let it pass?" % guard.label()
		"push":
			s.hint = "Won the fight. Stay engaged, move back, or push the opponent."
		"group_select":
			bi.targets.assign(bi.c.activatable())
			s.radius = 0.65
			s.hint = "Choose up to 3 soldiers with the caster. Selected: %d/4." % bi.group_selection.size()
		"select":
			bi.targets.assign(bi.c.activatable())
			s.radius = 0.65
			if bi.c.state.group.in_progress():
				s.hint = "Choose a group member for movement." if bi.c.state.group.movement_pass() else "Choose a group member for its second action."
			elif bi.c.can_finish_early_phase():
				s.hint = "Activate a nearby soldier or pass the remaining early activations."
		"move", "exit":
			if bi.reach != null:
				for n: Vector2i in bi.reach.nodes():
					if (bi.mode == "move" and float(bi.reach.cost[n]) > 0.001) or (bi.mode == "exit" and bi.c.can_exit_table(n, bi.reach)):
						bi.nodes.append(n)
						s.points.append(MoveGrid.to_pos(n))
			s.hint = ("Tap or drag within the marked area. %.1f″ movement available. Confirm before spending an action."%MoveRules.allowance(f)) if bi.mode == "move" else "Choose a marked table edge, then confirm to retreat."
		"fight_hand":
			for t in bi.c.state.figures:
				if bi.c.can_fight_hand(t.id):
					bi.targets.append(t)
			s.radius = 0.65
			s.hint = "Attack the skeletal hand holding this figure."
		"gutter_fight":
			bi.targets.assign(GearActions.gutter_targets(bi.c))
			s.radius=0.65
			s.hint="Free Gutter Flail attack: select an enemy or skip."
		"ammo_shot":
			for t in bi.c.state.figures:
				if bi.c.can_shoot(t.id,false,true):
					bi.targets.append(t)
			s.radius=0.65
			s.hint="Fire enchanted ammunition (%d remaining)." % MagicAmmo.count(f)
		"wraith_shot":
			for t in bi.c.state.figures:
				if bi.c.can_shoot(t.id,true):
					bi.targets.append(t)
			s.radius=0.65
			s.hint="Choose a target for the once-per-battle shot through one terrain piece."
		"fight", "shoot":
			for t in bi.c.state.figures:
				if (bi.c.can_fight(t.id) if bi.mode == "fight" else bi.c.can_shoot(t.id)):
					bi.targets.append(t)
			s.radius = 0.65
			s.color = Color(1.0, 0.35, 0.25)
			s.hint = "Choose one of %d marked targets to review the attack before rolling."%bi.targets.size()
		"collect":
			for token in bi.c.state.treasures:
				if bi.c.can_pick_up(token.id):
					bi.tokens.append(token)
					s.points.append(token.pos)
			s.radius = 0.5
			s.color = Color(1.0, 0.78, 0.15)
			s.hint = "Tap a marked offering to investigate or collect." if RedKingInvestigations.active(bi.c.state) else "Tap a marked treasure."
		"drop", "drop_shrunk":
			s.points.assign(bi.drops)
			s.hint = "Tap a marked place to drop " + ("shrunk treasure." if bi.mode == "drop_shrunk" else "treasure.")
		_:
			s.hint = "Choose Reload or End."
			return false
	return true
