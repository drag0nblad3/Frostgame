class_name TreasureActions
extends RefCounted
## GameController helper: the only writer of live treasure state.

var _c: GameController


func _init(c: GameController) -> void:
	_c = c


func can_pick_up(id: int) -> bool:
	if RedKingMind.active(_c.state):
		return false
	var token := _c.state.treasure(id)
	if RedKingFire.locked(_c.state,token):
		return RedKingFire.can_unlock(_c,token)
	if token!=null and token.investigation:
		return RedKingInvestigations.can_investigate(_c,token)
	return _c.can_act() and TreasureRules.can_pick_up(_c.state, _c.state.active(), token)


func pick_up(id: int) -> bool:
	if not can_pick_up(id):
		return false
	var f := _c.state.active()
	var token := _c.state.treasure(id)
	if RedKingFire.locked(_c.state,token):
		return RedKingFire.unlock(_c,f,token)
	if token.investigation:
		return RedKingInvestigations.investigate(_c,f,token)
	_c._spend(f)
	if _c.state.museum and not _c._encounters.museum_pickup(f):
		return true
	return _claim(f, token)


func claim_free(f: Figure, token: TreasureToken) -> bool:
	if RedKingHill.guarded(_c.state,token):
		return false
	# Column contact is with its edge, rather than the newly revealed centre.
	if f == null or RedKingMadMan.hunter(f) or token == null or not token.on_ground() or token.frozen or token.investigation or f.side < 0 or f.def.traits.has("animal") or IllusionRules.phantom(f) or f.spell_effects.has("plane_walk"):
		return false
	if f.treasure_id >= 0 and (f.shrunk_treasure_id < 0 or f.second_treasure_id >= 0):
		return false
	for enemy in _c.state.figures:
		if enemy.ring_side!=f.ring_side or enemy.side == f.side or not enemy.in_play() or enemy.spell_effects.has("plane_walk"):
			continue
		if Shooting.distance(enemy, f) <= 1.0 or Vector3(enemy.pos.x, enemy.elevation, enemy.pos.y).distance_to(Vector3(token.pos.x, _c.state.board.height_at(token.pos), token.pos.y)) <= Figure.BASE_RADIUS + TreasureRules.TOKEN_RADIUS + 1.0:
			return false
	return _claim(f, token)


func _claim(f: Figure, token: TreasureToken) -> bool:
	var id := token.id
	ScenarioSites.discover(_c, token.pos, f.side)
	_c._magic.illusions.reveal(f)
	if f.treasure_id >= 0:
		f.second_treasure_id = f.treasure_id
	f.treasure_id = id
	token.ring_side=f.ring_side
	token.carrier_id = f.id
	_c.emit("treasure_pickup", {"id": f.id, "treasure": id})
	if not token.ever_collected:
		token.ever_collected = true
		ScenarioGenie.first_pickup(_c, f, token)
		_c._encounters.on_pickup()
	return true


func can_drop(at: Vector2) -> bool:
	if _c.awaiting_reaction() or _c.state.group.movement_pass() or not _c.state.pending_cast.is_empty():
		return false
	var f := _c.state.active()
	if f == null or not f.in_play() or f.treasure_id < 0 or f.actions_left <= 0:
		return false
	if FuryRules.target(_c.state, f) != null or Contact.in_combat(_c.state.figures, f):
		return false
	if f.pos.distance_to(at) < 0.85 or f.pos.distance_to(at) > 1.25:
		return false
	var height := _c.state.board.height_at(at)
	if not f.surface_id.is_empty():
		var layout := FloorLayout.from_dict(_c.state.board.floor_layout)
		var index := layout.index_of(f.surface_id)
		if index<0 or not layout.surfaces[index].contains(at,TreasureRules.TOKEN_RADIUS):
			return false
		height=layout.surfaces[index].height_at(at)
		if not layout.clearance(Vector3(at.x,height,at.y),TreasureRules.TOKEN_RADIUS,0.5):
			return false
	elif not _c.state.board.can_stand(at,TreasureRules.TOKEN_RADIUS) or not is_equal_approx(height,f.elevation):
		return false
	for other in _c.state.figures:
		if other.in_play() and other.ring_side==f.ring_side and (f.surface_id.is_empty() or absf(other.elevation-height)<0.5) and other.pos.distance_to(at) < Figure.BASE_RADIUS + TreasureRules.TOKEN_RADIUS:
			return false
	return f.moves_taken == 0 or _c.can_act()


func drop(at: Vector2, token_id: int = -1) -> bool:
	if not can_drop(at):
		return false
	var f := _c.state.active()
	if token_id >= 0 and not f.carried_treasures().has(token_id):
		return false
	if f.moves_taken > 0:
		_c._spend(f)
	else:
		f.actions_left -= 1
	_drop(f, at, token_id)
	return true


func drop_on_death(f: Figure) -> void:
	for id in f.carried_treasures():
		_drop(f, f.pos, id)


func _drop(f: Figure, at: Vector2, id: int = -1) -> void:
	if id < 0:
		id = f.treasure_id
	var token := _c.state.treasure(id)
	if token == null or token.carrier_id != f.id:
		return
	_c._magic.illusions.reveal(f)
	_clear_carrier(token)
	token.pos = at
	token.surface_id = f.surface_id
	token.ring_side=f.ring_side
	var height := _c.state.board.height_at(at)
	if not f.surface_id.is_empty():
		var layout := FloorLayout.from_dict(_c.state.board.floor_layout)
		var index := layout.index_of(f.surface_id)
		if index>=0:
			height=layout.surfaces[index].height_at(at)
	_c.emit("treasure_drop", {"id": f.id, "treasure": token.id, "at": at,"height":height})


func cancel_shrinking(f: Figure) -> void:
	if f.second_treasure_id >= 0:
		# Keep the formerly shrunk treasure; drop the other token.
		var id := f.treasure_id if f.treasure_id != f.shrunk_treasure_id else f.second_treasure_id
		_drop(f, f.pos, id)
	f.shrunk_treasure_id = -1
	f.spell_effects.erase("potion_shrinking")


func can_exit(node: Vector2i, r: MoveReach = null) -> bool:
	if RedKingMind.active(_c.state) or not _c.can_move():
		return false
	var f := _c.state.active()
	if (RedKingVeil.active(_c.state) and f.side==1) or f.control_spell == "mind_control" or f.side < 0 or f.spell_effects.has("plane_walk") or FuryRules.target(_c.state, f) != null:
		return false
	if r == null:
		r = _c.reach()
	var at := MoveGrid.to_pos(node)
	if not r.can_reach(node) or TreasureRules.edge_distance(_c.state.board, at) > Figure.BASE_RADIUS + 0.01 or not ScenarioObjectives.exit_allowed(_c.state, at,f.side):
		return false
	# The lattice keeps the base on the table; budget one more half inch to cross the edge.
	if r.cost[node] + Figure.BASE_RADIUS > MoveRules.allowance(f) + 0.001:
		return false
	for enemy in _c.state.figures:
		if enemy.in_play() and enemy.side != f.side and Contact.touching(enemy.pos, at):
			return false
	return true


func exit_table(node: Vector2i) -> bool:
	if not can_exit(node):
		return false
	var f := _c.state.active()
	if not _c.move_to(node):
		return false
	if not f.in_play() or f.pos.distance_to(MoveGrid.to_pos(node)) > 0.01 or Contact.in_combat(_c.state.figures, f):
		return true
	for id in f.carried_treasures():
		secure(_c.state.treasure(id), f.side)
	f.exited = true
	f.actions_left = 0
	_c.emit("exit", {"id": f.id})
	if RedKingInvestigations.active(_c.state) and _c.state.turn>3:
		_c.emit("investigation_xp",{"side":f.side,"xp":10})
	return true


func secure(token: TreasureToken, side: int) -> void:
	_clear_carrier(token)
	token.secured_by = side
	_c.emit("treasure_secured", {"treasure": token.id, "side": side})


func lose(token: TreasureToken) -> void:
	_clear_carrier(token)
	token.lost = true
	_c.emit("treasure_lost", {"treasure": token.id})


func _clear_carrier(token: TreasureToken) -> void:
	if token.carrier_id >= 0:
		var carrier := _c.state.figure(token.carrier_id)
		if carrier.treasure_id == token.id:
			carrier.treasure_id = carrier.second_treasure_id
			carrier.second_treasure_id = -1
		elif carrier.second_treasure_id == token.id:
			carrier.second_treasure_id = -1
		if carrier.shrunk_treasure_id == token.id:
			carrier.shrunk_treasure_id = -1
			carrier.spell_effects.erase("potion_shrinking")
		token.carrier_id = -1
