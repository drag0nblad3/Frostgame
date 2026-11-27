class_name ControllerMovement
extends RefCounted
## Movement for GameController: reach, moves, interception and staying in combat. Mutates state only on the controller's behalf.


static func reach(c: GameController) -> MoveReach:
	if not c.state.board.floor_layout.is_empty():
		return MoveReach.new()
	var f := c.state.active()
	if f.spell_effects.has("plane_walk"):
		return PlaneWalk.reach(c.state, f)
	if f.spell_effects.has("potion_burrowing") or f.def.traits.has("ethereal") or f.def.traits.has("burrowing"):
		return PlaneWalk.reach(c.state, f, false)
	var grid := MoveGrid.new(c.state.board, f, c.state.figures)
	var r := MovePlanner.straight_reach(grid,f.pos,MoveRules.allowance(f)) if c.state.board.low_gravity else MovePlanner.reach(grid, f.pos, MoveRules.allowance(f))
	return FuryRules.restrict(c.state, f, r)


static func move_to(c: GameController, node: Vector2i,cape: bool=false) -> bool:
	if not (GearActions.cape_ready(c) if cape else c.can_move()):
		return false
	var r := c.reach()
	if not r.can_reach(node) or (cape and float(r.cost[node])<=0.001):
		return false
	var f := c.state.active()
	var path := r.path_to(node)
	if not RedKingHill.before_move(c,f):
		return true
	if f.spell_effects.has("plane_walk"):
		if c.state.scenario_special == "silent_tower":
			for i in range(1, path.size()):
				if ScenarioNull.field_at(c.state.board, path[i]):
					return false
		if RedKingMind.active(c.state):
			for i in range(1,path.size()):
				RedKingMind.collect(c,f,path[i-1],path[i])
		if RedKingHerded.active(c.state):
			for i in range(1,path.size()):
				if RedKingHerded.contact(c,f,path[i]):
					f.actions_left=0
					return true
		f.pos = MoveGrid.to_pos(node)
		f.elevation = c.state.board.height_at(f.pos)
		f.actions_left -= 1
		f.moves_taken += 1
		c.emit("move", {"id": f.id, "path": path, "cost": float(r.cost[node])})
		ScenarioSites.end_move(c, f)
		return true
	var ignored: Array[int]=[]
	if cape:
		for enemy in Contact.enemies_of(c.state.figures,f):
			ignored.append(enemy.id)
	return c._commit_move(f,path,float(r.cost[node]),ignored,cape)


static func _commit_move(c: GameController, f: Figure, path: PackedVector2Array, cost: float, ignored: Array[int],cape: bool=false) -> bool:
	var targets: Array[Figure] = []
	var at := path[path.size() - 1]
	for t in c.state.figures:
		if t.in_play() and t.ring_side==f.ring_side and t.side != f.side and absf(t.elevation - c.state.board.height_at(at)) < 0.5 and Contact.touching(t.pos, at):
			targets.append(t)
	c._magic.beauty.authorize(f, targets, c._move_authorized.bind(f,path,cost,ignored,cape))
	return true


static func _move_authorized(c: GameController, f: Figure, path: PackedVector2Array, cost: float, ignored: Array[int],cape: bool=false) -> void:
	if not f.in_play() or (cape and not GearActions.use_cape(c,f)):
		return
	var intercept := c._displacement.intercept(f, path, ignored) if c.state.forced_combat else {}
	if not intercept.is_empty() and int(intercept["guard"].side) == c.state.reaction_side:
		c.state.pending_intercept = {"mover": f.id, "path": path, "cost": cost, "ignored": ignored, "choice": intercept}
		c.emit("intercept_offer", {"id": intercept["guard"].id, "target": f.id})
		return
	c._apply_move(f, path, cost, intercept)


static func _apply_move(c: GameController, f: Figure, path: PackedVector2Array, cost: float, intercept: Dictionary) -> bool:
	var engaged := Contact.in_combat(c.state.figures,f)
	if not intercept.is_empty():
		path.resize(int(intercept["index"]) + 1)
	f.spell_effects.erase("petrify")
	f.actions_left -= 1
	f.moves_taken += 1
	if not c._magic.terrain.travel(f, path, cost):
		if f.in_play():
			CreatureSenses.reveal_contacts(c,f)
			c._magic.illusions.after_move(f)
			GearActions.gutter_after_move(c,f,engaged)
		return true
	if not intercept.is_empty():
		c._displacement.force_contact(intercept)
	ScenarioSites.end_move(c, f)
	RedKingSquatter.record_contact(c)
	RedKingSinkhole.record_xp(c,f)
	CreatureSenses.reveal_contacts(c,f)
	c._magic.illusions.after_move(f)
	GearActions.gutter_after_move(c,f,engaged)
	return true


static func stay_in_combat(c: GameController) -> bool:
	if c.state.push_winner < 0:
		return false
	if c.state.push_tie and c.state.push_tie_second:
		var old := c.state.push_winner
		c.state.push_winner=c.state.push_loser
		c.state.push_loser=old
		c.state.push_tie_second=false
		var other := c.state.figure(c.state.push_winner)
		if other!=null and other.side!=c.state.reaction_side:
			c._auto_tie_withdraw()
		return true
	c._displacement.clear()
	c.emit("stay_in_combat")
	return true


static func answer_intercept(c: GameController, accept: bool) -> bool:
	var p := c.state.pending_intercept
	if p.is_empty():
		return false
	c.state.pending_intercept = {}
	var mover := c.state.figure(p["mover"])
	var choice: Dictionary = p["choice"]
	var path: PackedVector2Array = p["path"]
	if accept:
		return c._apply_move(mover, path, float(p["cost"]), choice)
	var ignored: Array[int] = []
	ignored.assign(p["ignored"])
	ignored.append(choice["guard"].id)
	return c._commit_move(mover, path, float(p["cost"]), ignored)
