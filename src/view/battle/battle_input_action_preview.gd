class_name BattleInputActionPreview
extends RefCounted
## Highlights for move, gear, potion and spell modes. False when the mode is not one of these.


## Fills `s` for action modes; false when the mode belongs elsewhere.
static func actions(bi: BattleInput, f: Figure, s: BattleInputPreview.State) -> bool:
	match bi.mode:
		"gear_transfer_target":
			for t in bi.c.state.figures:
				if GearActions.transfer_max(bi.c, t) > 0:
					bi.targets.append(t)
			s.radius = 0.65
			s.hint = "Choose a wounded ally in sight."
		"gear_transfer_amount":
			var t := bi.c.state.figure(bi.transfer_target)
			s.points.append(t.pos)
			s.radius = 0.65
			s.hint = "Transfer %d Health to %s (maximum %d)." % [bi.transfer_amount, t.label(), GearActions.transfer_max(bi.c, t)]
			if bi.transfer_amount == f.health:
				s.hint += " Warning: caster will be knocked out."
		"run_for_it","run_talisman":
			bi.reach=RunForIt.reach(bi.c,bi.mode=="run_talisman")
			for n: Vector2i in bi.reach.nodes():
				if float(bi.reach.cost[n])>0.001:
					bi.nodes.append(n)
					s.points.append(MoveGrid.to_pos(n))
			s.hint="Plan a run up to %d″ ignoring movement penalties. Confirm to end activation."%(6 if bi.mode=="run_talisman" else 3)
		"gear_cape_move":
			bi.reach=GearActions.cape_reach(bi.c)
			for n: Vector2i in bi.reach.nodes():
				if float(bi.reach.cost[n])>0.001:
					bi.nodes.append(n)
					s.points.append(MoveGrid.to_pos(n))
			s.hint="Plan a legal escape move. Confirm to authorize the move and spend the cape."
		"gear_tiger_point":
			for option in TigerEye.eye_options(bi.c):
				s.points.append(option["at"])
			s.hint="Move the Wizard Eye along its supporting surface (up to 4″)."
		"gear_worm_point":
			s.points.assign(WormRider.points(bi.c))
			s.hint="Choose a worm summoning token location. On a 1 the rival relocates it."
		"gear_bottle_imp":
			s.points.assign(GearActions.bottle_points(bi.c))
			s.hint="Place the released uncontrolled imp within 1 inch."
		"gear_teleport":
			s.points.assign(GearActions.teleport_points(bi.c))
			s.hint = "Choose a destination within 8 inches."
		"potion_point":
			s.points.assign(bi.c._potions.points(bi.selected_potion))
			s.hint = "Choose the potion destination."
		"potion_coat":
			s.hint = "Choose melee weapon or ammunition."
		"breathe_fire":
			for t in bi.c.state.figures:
				if bi.c._potions.can_breathe(t):
					bi.targets.append(t)
			s.radius = 0.65
			s.hint = "Choose a target for fire breath."
		"potion_target":
			for t in bi.c.state.figures:
				if bi.c._potions.can_drink(bi.selected_potion, t):
					bi.targets.append(t)
			s.radius = 0.65
			s.hint = "Choose a recipient for the potion."
		"spell_menu":
			s.hint = "Choose a spell."
		"items_menu":
			s.hint = "Choose equipment, a weapon, or a consumable."
		"counter_select":
			var option := bi.counter_choices[bi.counter_index]
			s.hint = "%s %d/%d: %s" % ["Choose eye face" if bi.selected_spell == "wizard_eye" else "Destroy terrain" if bi.selected_spell == "crumble" else "Destroy weapon" if bi.selected_spell == "decay" else ("Choose spell" if bi.selected_spell in ["power_word", "draining_word"] else "Cancel effect"), bi.counter_index + 1, bi.counter_choices.size(), option["label"]]
			if option["kind"] == "eye_face":
				if bi.is_layered():
					var at: Vector2=option["at"]
					bi.floor_points[Vector3i.ZERO]=Vector3(at.x,float(option["height"]),at.y)
				else:
					s.points.append(option["at"])
			elif option["kind"] == "terrain":
				var p: TerrainPiece=option["piece"]
				if bi.is_layered() and not p.surface_id.is_empty():
					var n:=bi.floor_layout.node(p.surface_id,p.rect.get_center())
					if n.z>=0:
						bi.floor_points[n]=bi.floor_layout.world(n)
				else:
					s.points.append(p.rect.get_center())
			elif option["kind"]=="floor_bridge":
				var index:=bi.floor_layout.index_of(str(option["surface"]))
				if index>=0:
					var surface:=bi.floor_layout.surfaces[index]
					var node:=bi.floor_layout.node(surface.id,surface.rect.get_center())
					bi.floor_points[node]=bi.floor_layout.world(node)
			elif option["kind"] != "storm":
				s.points.append(bi.c.state.figure(option["target"]).pos)
			s.radius = 0.7
		"treasure_spell":
			bi.tokens.assign(bi.c._magic.treasure_options(bi.selected_spell))
			for token in bi.tokens:
				s.points.append(bi.c._magic.treasure_magic.origin(token))
			s.radius = 0.65
			s.hint = "Choose a treasure to move."
		"treasure_destination":
			s.points.assign(bi.c._magic.treasure_magic.points(f, bi.selected_spell, bi.c.state.treasure(bi.spell_first)))
			s.hint = "Choose the treasure's destination."
		"leap_destination":
			if bi.selected_spell == "suggestion":
				s.points.assign(bi.c._magic.suggestion_points(bi.c.state.figure(bi.spell_first)))
				s.hint = "Choose a destination (or the figure's current position)."
			else:
				s.points.assign(bi.c._magic.movement.points(f, bi.c.state.figure(bi.spell_first), "leap"))
				s.hint = "Choose a landing spot for the selected ally."
		"swap_second":
			for t in bi.c.state.figures:
				if bi.c.can_cast("transpose", t.id) and bi.c._magic.movement.can_swap(f, bi.c.state.figure(bi.spell_first), t):
					bi.targets.append(t)
			s.radius = 0.65
			s.hint = "Choose the second figure to swap."
		"spell_point":
			s.points.assign(bi.c._magic.placement_points(bi.selected_spell,false,bi.spell_rotated,bi.spell_extended))
			s.hint = "Choose a marked spell location."
			if bi.selected_spell in ["fog", "wall", "bridge"]:
				s.hint += " · " + ("North–south" if bi.spell_rotated else "East–west")
			if bi.selected_spell=="bridge":
				s.hint+=" · %d″ bridge" % (9 if bi.spell_extended else 6)
		"cancel_control":
			for t in bi.c.state.figures:
				if bi.c._magic.can_cancel(t.id):
					bi.targets.append(t)
			s.radius = 0.65
			s.hint = "Choose a summoned or controlled creature to release."
		"spell_target":
			for t in bi.c.state.figures:
				if bi.c.can_cast(bi.selected_spell,t.id,bi.spell_ammo):
					bi.targets.append(t)
			s.radius = 0.65
			s.hint = "Choose a bow or crossbow user to enchant ammunition." if bi.spell_ammo else "Choose a target for %s." % bi.c.state.spell_catalog[bi.selected_spell]["name"]
		"resist":
			var p := bi.c.state.pending_resistance
			var t := bi.c.state.figure(p["id"])
			s.points.append(t.pos)
			s.radius = 0.65
			var power := mini(bi.empower, PowerPool.available(t,str(p.get("spell",""))))
			s.hint = "%s resists: %d + %d Will, needs %d. Spend %d power + %d HP → %d." % [t.label(), p["raw"], p["mod"], p["tn"], power, bi.empower - power, int(p["raw"]) + int(p["mod"]) + bi.empower+VampireStaff.amount(bi.c,p,false)]
			s.hint+=bi._vampire_hint(p,false)
		"empower":
			var p := bi.c.state.pending_cast
			var power := mini(bi.empower, PowerPool.available(bi.c.state.figure(p["caster"]),str(p["id"])))
			s.hint = "%s: rolled %d (modified %d), needs %d. Spend %d power + %d HP → %d." % [bi.c.state.spell_catalog[p["id"]]["name"], p["raw"], p["total"], p["tn"], power, bi.empower - power, int(p["total"]) + bi.empower+VampireStaff.amount(bi.c,p,true)]
			s.hint+=bi._vampire_hint(p,true)
			if p.get("gem_extend",false):
				s.hint+=" • Blink 6″"
			if p.get("gem_reroll",false):
				s.hint+=" • Reroll direction"
			if p.get("golden_fang",false):
				s.hint+=" • Golden Fang selected: +1 Fight on success."
			if p.get("scroll", false):
				s.hint = "%s: scroll casting result 14. Confirm to resolve." % bi.c.state.spell_catalog[p["id"]]["name"]
		_:
			return false
	return true
