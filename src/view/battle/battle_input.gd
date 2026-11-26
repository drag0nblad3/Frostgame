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
var selected_spell := ""
var selected_potion := ""
var spell_rotated := false
var spell_first := -1
var counter_index := 0
var counter_choices: Array[Dictionary] = []
var empower := 0


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
	reach = null
	var f := c.state.active()
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
		if c.can_push(false):
			available.append("push_enemy")
		mode = "push"
		preview()
		return
	for item in f.items:
		var id := str(item.get("potion", ""))
		for t in c.state.figures:
			if c._potions.can_drink(id, t):
				var key := "potion_" + id
				if not available.has(key):
					available.append(key)
				break
	if c.can_use_stored_action():
		available.append("use_stored_action")
	if c.can_move():
		reach = c.reach()
		available.append("move")
		for n: Vector2i in reach.nodes():
			if c.can_exit_table(n, reach):
				available.append("exit")
				break
	for enemy in c.state.figures:
		if c.can_fight(enemy.id) and not available.has("fight"):
			available.append("fight")
		if c.can_shoot(enemy.id) and not available.has("shoot"):
			available.append("shoot")
	for token in c.state.treasures:
		if c.can_pick_up(token.id):
			available.append("collect")
			break
	cast_options.clear()
	for id: String in c.state.spellbooks.get(f.side, {}):
		if not c._magic.counter_options(id).is_empty():
			cast_options.append(id)
			continue
		if not c._magic.placement_points(id, true).is_empty() or (id in ["fog", "wall"] and not c._magic.placement_points(id, true, true).is_empty()):
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
	available.append("end")
	if not available.has(mode) or mode in ["reload", "end"]:
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
		"potion_target":
			for t in c.state.figures:
				if c._potions.can_drink(selected_potion, t):
					targets.append(t)
			radius = 0.65
			hint = "Choose a recipient for the potion."
		"spell_menu":
			hint = "Choose a spell."
		"counter_select":
			var option := counter_choices[counter_index]
			hint = "Cancel effect %d/%d: %s" % [counter_index + 1, counter_choices.size(), option["label"]]
			if option["kind"] == "terrain":
				points.append(option["piece"].rect.get_center())
			elif option["kind"] != "storm":
				points.append(c.state.figure(option["target"]).pos)
			radius = 0.7
		"leap_destination":
			points.assign(c._magic.movement.points(f, c.state.figure(spell_first), "leap"))
			hint = "Choose a landing spot for the selected ally."
		"swap_second":
			for t in c.state.figures:
				if c.can_cast("transpose", t.id) and c._magic.movement.can_swap(f, c.state.figure(spell_first), t):
					targets.append(t)
			radius = 0.65
			hint = "Choose the second figure to swap."
		"spell_point":
			points.assign(c._magic.placement_points(selected_spell, false, spell_rotated))
			hint = "Choose a marked spell location."
			if selected_spell in ["fog", "wall"]:
				hint += " · " + ("North–south" if spell_rotated else "East–west")
		"cancel_control":
			for t in c.state.figures:
				if c._magic.can_cancel(t.id):
					targets.append(t)
			radius = 0.65
			hint = "Choose a summoned or controlled creature to release."
		"spell_target":
			for t in c.state.figures:
				if c.can_cast(selected_spell, t.id):
					targets.append(t)
			radius = 0.65
			hint = "Choose a target for %s." % c.state.spell_catalog[selected_spell]["name"]
		"resist":
			var p := c.state.pending_resistance
			var t := c.state.figure(p["id"])
			points.append(t.pos)
			radius = 0.65
			hint = "%s resists: rolled %d + %d Will, needs %d. Spend %d HP → %d." % [t.label(), p["raw"], p["mod"], p["tn"], empower, int(p["raw"]) + int(p["mod"]) + empower]
		"empower":
			var p := c.state.pending_cast
			hint = "%s: rolled %d (modified %d), needs %d. Spend %d HP → %d. Confirm to resolve." % [c.state.spell_catalog[p["id"]]["name"], p["raw"], p["total"], p["tn"], empower, int(p["total"]) + empower]
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
			hint = "Tap a marked treasure."
		"drop":
			points.assign(drops)
			hint = "Tap a marked place to drop treasure."
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
	if f != null:
		hint = "%s · %d action(s) · HP %d/%d%s — %s" % [f.label(), f.actions_left, f.health, f.def.health, " · Carrying treasure" if f.treasure_id >= 0 else "", hint]
	if c.state.group.in_progress():
		hint = ("GROUP: Movement · " if c.state.group.movement_pass() else "GROUP: Second action · ") + hint
	hud.set_actions(available, mode, hint)


func action(key: String) -> bool:
	if not available.has(key):
		return false
	if key == "potion_cancel":
		mode = ""
		refresh()
		return false
	if key.begins_with("potion_"):
		selected_potion = key.trim_prefix("potion_")
		if c.state.active().def.id == "apothecary":
			mode = "potion_target"
			available.assign(["potion_cancel"])
			preview()
			return false
		return c._potions.drink(selected_potion)
	if key.begins_with("spell_") and key != "spell_cancel":
		selected_spell = key.trim_prefix("spell_")
		spell_rotated = false
		if selected_spell in ["dispel", "spell_eater"]:
			counter_choices = c._magic.counter_options(selected_spell)
			if counter_choices.is_empty():
				refresh()
				return false
			counter_index = 0
			mode = "counter_select"
			available.assign(["spell_cancel", "counter_confirm"])
			if counter_choices.size() > 1:
				available.append("counter_previous")
				available.append("counter_next")
			preview()
			return false
		mode = "spell_point" if c._magic.is_placement(selected_spell) else "spell_target"
		available.assign(["spell_cancel"])
		if selected_spell in ["fog", "wall"]:
			available.append("rotate_spell")
		preview()
		return false
	match key:
		"use_stored_action":
			return c.use_stored_action()
		"resist_plus", "resist_minus":
			empower = clampi(empower + (1 if key == "resist_plus" else -1), 0, int(c.state.pending_resistance["max"]))
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
			return c._magic.start_counter(selected_spell, counter_index)
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
			mode = ""
			refresh()
			return false
		"empower_plus", "empower_minus":
			empower = clampi(empower + (1 if key == "empower_plus" else -1), 0, c.cast_max_empowerment())
			_empower_buttons()
			preview()
			return false
		"cast_confirm":
			return c.finish_cast(empower)
		"stay":
			return c.stay_in_combat()
		"push_self":
			return c.resolve_push(true)
		"push_enemy":
			return c.resolve_push(false)
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
	if mode in ["select", "fight", "shoot", "group_select", "spell_target", "cancel_control", "swap_second", "potion_target"]:
		var id := _figure_at(screen)
		if id < 0:
			return false
		match mode:
			"potion_target":
				return c._potions.drink(selected_potion, c.state.figure(id))
			"swap_second":
				return c._magic.start_swap(spell_first, id)
			"spell_target":
				if selected_spell in ["leap", "transpose"]:
					spell_first = id
					mode = "leap_destination" if selected_spell == "leap" else "swap_second"
					preview()
					return false
				return c.start_cast(selected_spell, id)
			"cancel_control":
				return c._magic.cancel(id)
			"group_select":
				if id == int(c.state.early.leaders[c.state.current_side()]):
					return false
				if group_selection.has(id):
					group_selection.erase(id)
				elif group_selection.size() < 4:
					group_selection.append(id)
				_group_buttons()
				preview()
				return false
			"select": return c.activate(id)
			"fight": return c.fight(id)
			"shoot": return c.shoot(id)
	var hit: Variant = _surface_at(screen)
	if hit == null:
		return false
	var at: Vector2 = hit
	if mode == "leap_destination":
		return c._magic.start_move("leap", spell_first, MoveGrid.to_pos(MovePlanner.node_at(at)))
	if mode == "spell_point":
		var destination := at.round() if TerrainMagic.SPELLS.has(selected_spell) else MoveGrid.to_pos(MovePlanner.node_at(at))
		return c._magic.start_at(selected_spell, destination, spell_rotated)
	if mode == "collect":
		for token in tokens:
			if at.distance_to(token.pos) <= 0.9:
				return c.pick_up(token.id)
	if mode == "drop":
		for p in drops:
			if at.distance_to(p) <= 0.3:
				return c.drop_treasure(p)
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
	if empower < c.cast_max_empowerment():
		available.append("empower_plus")
	if empower > 0:
		available.append("empower_minus")


## Pick the nearest visible exposed surface rather than always intersecting ground.
func _surface_at(screen: Vector2) -> Variant:
	var origin := camera.project_ray_origin(screen)
	var direction := camera.project_ray_normal(screen)
	var board := c.state.board
	var heights: Array[float] = [0.0]
	for piece in board.pieces:
		if piece.kind.walkable_top and not heights.has(piece.kind.height):
			heights.append(piece.kind.height)
	var best: Variant = null
	var nearest := INF
	for height in heights:
		var hit: Variant = Plane(Vector3.UP, height).intersects_ray(origin, direction)
		if hit == null:
			continue
		var point := TableSpace.to_table(hit)
		if not board.contains(point) or not is_equal_approx(board.height_at(point), height):
			continue
		var distance := origin.distance_to(hit)
		if distance < nearest:
			nearest = distance
			best = point
	return best


func _resist_buttons() -> void:
	available.assign(["resist_confirm"])
	if empower < int(c.state.pending_resistance["max"]):
		available.append("resist_plus")
	if empower > 0:
		available.append("resist_minus")
