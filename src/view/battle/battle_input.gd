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
	if f == null:
		if c.can_finish_early_phase():
			available.append("pass_phase")
		mode = "select"
		preview()
		return
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
		"select":
			targets.assign(c.activatable())
			radius = 0.65
			if c.can_finish_early_phase():
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
	for t in targets:
		points.append(t.pos)
	markers.show_points(points, color, radius)
	if f != null:
		hint = "%s · %d action(s) · HP %d/%d%s — %s" % [f.label(), f.actions_left, f.health, f.def.health, " · Carrying treasure" if f.treasure_id >= 0 else "", hint]
	hud.set_actions(available, mode, hint)


func action(key: String) -> bool:
	if not available.has(key):
		return false
	match key:
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
	if mode in ["select", "fight", "shoot"]:
		var id := _figure_at(screen)
		if id < 0:
			return false
		match mode:
			"select": return c.activate(id)
			"fight": return c.fight(id)
			"shoot": return c.shoot(id)
	var hit: Variant = Plane(Vector3.UP, 0.0).intersects_ray(camera.project_ray_origin(screen), camera.project_ray_normal(screen))
	if hit == null:
		return false
	var at := TableSpace.to_table(hit)
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
		var point := TableSpace.to_world(f.pos, 0.75)
		if camera.is_position_behind(point):
			continue
		var d := screen.distance_to(camera.unproject_position(point))
		if d < distance:
			distance = d
			id = f.id
	return id
